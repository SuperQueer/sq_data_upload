import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
// Matches the secret name actually set on the project (`supabase secrets list`);
// an earlier version of this file used FCM_SERVICE_ACCOUNT_JSON, which was
// never set, so JSON.parse(undefined) failed at runtime.
const FCM_SA_JSON = Deno.env.get('FIREBASE_SERVICE_ACCOUNT_KEY')!

interface ServiceAccount {
  project_id: string
  client_email: string
  private_key: string
}

async function getAccessToken(sa: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000)
  const claim = {
    iss: sa.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
  }

  const encode = (obj: object) =>
    btoa(JSON.stringify(obj)).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '')

  const header = encode({ alg: 'RS256', typ: 'JWT' })
  const payload = encode(claim)
  const signingInput = `${header}.${payload}`

  const pemBody = sa.private_key
    .replace(/\\n/g, '\n')
    .replace('-----BEGIN PRIVATE KEY-----', '')
    .replace('-----END PRIVATE KEY-----', '')
    .replace(/\s/g, '')

  const keyBytes = Uint8Array.from(atob(pemBody), (c) => c.charCodeAt(0))
  const cryptoKey = await crypto.subtle.importKey(
    'pkcs8',
    keyBytes,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  )

  const sigBytes = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    cryptoKey,
    new TextEncoder().encode(signingInput),
  )

  const sig = btoa(String.fromCharCode(...new Uint8Array(sigBytes)))
    .replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '')

  const jwt = `${signingInput}.${sig}`

  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  })
  const data = await res.json()
  return data.access_token as string
}

Deno.serve(async (req) => {
  try {
    const body = await req.json()
    console.log('[NOTIF][Edge] Received payload:', JSON.stringify(body))

    // notify_user_on_approval (and notify_admins_on_submission) always POST
    // { recipient_id, title, message } — this is the shape every trigger in
    // both Dev and Prod sends, so it's the contract this function must match.
    const { recipient_id, title, message } = body

    if (!recipient_id || !title || !message) {
      console.error(
        `[NOTIF][Edge] Missing required fields: recipient_id=${recipient_id} title=${title} message=${message} — raw payload=${JSON.stringify(body)}`,
      )
      return new Response(
        JSON.stringify({ error: 'Missing required fields: recipient_id, title, message' }),
        { status: 400 },
      )
    }

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY)

    // Look up the recipient's FCM token
    const { data: tokenRow } = await supabase
      .from('user_fcm_tokens')
      .select('token')
      .eq('user_id', recipient_id)
      .maybeSingle()

    if (!tokenRow?.token) {
      console.warn(`[NOTIF][Edge] No FCM token registered for recipient_id=${recipient_id} — skipping push`)
      return new Response(JSON.stringify({ sent: false, reason: 'no_fcm_token' }), { status: 200 })
    }
    console.log(`[NOTIF][Edge] Found FCM token for recipient_id=${recipient_id}, sending push...`)

    // Get FCM access token and send push
    const sa: ServiceAccount = JSON.parse(FCM_SA_JSON)
    const accessToken = await getAccessToken(sa)

    const fcmRes = await fetch(
      `https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`,
      {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${accessToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          message: {
            token: tokenRow.token,
            notification: { title, body: message },
            android: { priority: 'high' },
            apns: {
              payload: { aps: { alert: { title, body: message }, sound: 'default' } },
            },
          },
        }),
      },
    )

    const fcmData = await fcmRes.json()

    if (!fcmRes.ok) {
      console.error(`[NOTIF][Edge] FCM send failed for recipient_id=${recipient_id}: ${JSON.stringify(fcmData)}`)

      // Token is stale — clean it up so future calls don't waste a round-trip.
      const isUnregistered = fcmData.error?.details?.some(
        (d: { errorCode?: string }) => d.errorCode === 'UNREGISTERED',
      )
      if (isUnregistered) {
        await supabase.from('user_fcm_tokens').delete().eq('user_id', recipient_id)
        console.warn(`[NOTIF][Edge] Removed stale FCM token for recipient_id=${recipient_id}`)
      }

      return new Response(JSON.stringify({ sent: false, fcm: fcmData }), { status: 500 })
    }

    console.log(`[NOTIF][Edge] Push sent successfully to recipient_id=${recipient_id}: ${JSON.stringify(fcmData)}`)
    return new Response(JSON.stringify({ sent: true, fcm: fcmData }), { status: 200 })
  } catch (e) {
    console.error('[NOTIF][Edge] Unexpected error:', e)
    return new Response(JSON.stringify({ error: String(e) }), { status: 500 })
  }
})
