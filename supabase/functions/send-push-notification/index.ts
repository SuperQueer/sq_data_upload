import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
const FCM_SA_JSON = Deno.env.get('FCM_SERVICE_ACCOUNT_JSON')!

interface ServiceAccount {
  project_id: string
  client_email: string
  private_key: string
}

const NOTIFICATION_COPY: Record<string, { title: string; body: (name: string, type: string) => string }> = {
  approved: {
    title: '🎉 Content Approved!',
    body: (name, type) => `Your ${type} "${name}" is now live.`,
  },
  rejected: {
    title: 'Submission Needs Revisions',
    body: (name, type) => `Your ${type} "${name}" needs some changes before it can go live.`,
  },
  cancelled: {
    title: 'Content Cancelled',
    body: (name, type) => `Your ${type} "${name}" has been cancelled.`,
  },
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
    const { contentId, contentType, status } = await req.json()

    if (!contentId || !contentType || !status) {
      return new Response(JSON.stringify({ error: 'Missing required fields' }), { status: 400 })
    }

    const copy = NOTIFICATION_COPY[status]
    if (!copy) {
      return new Response(JSON.stringify({ sent: false, reason: 'unknown_status' }), { status: 200 })
    }

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY)

    // Fetch content to get owner_id and display name
    const table = contentType === 'event' ? 'events' : 'locations'
    const nameCol = contentType === 'event' ? 'event_name' : 'name'

    const { data: content } = await supabase
      .from(table)
      .select(`owner_id, ${nameCol}`)
      .eq('id', contentId)
      .maybeSingle()

    if (!content?.owner_id) {
      return new Response(JSON.stringify({ sent: false, reason: 'no_owner' }), { status: 200 })
    }

    const contentName = (content[nameCol] as string | null) ?? contentType

    // Look up the owner's FCM token
    const { data: tokenRow } = await supabase
      .from('user_fcm_tokens')
      .select('token')
      .eq('user_id', content.owner_id)
      .maybeSingle()

    if (!tokenRow?.token) {
      return new Response(JSON.stringify({ sent: false, reason: 'no_fcm_token' }), { status: 200 })
    }

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
            notification: {
              title: copy.title,
              body: copy.body(contentName, contentType),
            },
            data: { contentId, contentType, status },
          },
        }),
      },
    )

    const fcmData = await fcmRes.json()
    return new Response(JSON.stringify({ sent: fcmRes.ok, fcm: fcmData }), { status: 200 })
  } catch (e) {
    console.error('[send-push-notification]', e)
    return new Response(JSON.stringify({ error: String(e) }), { status: 500 })
  }
})