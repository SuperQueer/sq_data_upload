import { config } from 'dotenv'
import { createClient } from '@supabase/supabase-js'
// @ts-ignore
import { Database } from './database/types'

// Deletes all rows from the `prides` table.
// events.pride_id and pride_admin_assignments.pride_id are ON DELETE SET NULL,
// so dependent events/assignments are kept but lose their pride link.
//
// Usage:
//   SEED_ENV=dev  CONFIRM=DELETE npx tsx src/delete_prides.ts
//   SEED_ENV=prod CONFIRM=DELETE npx tsx src/delete_prides.ts
//
// CONFIRM=DELETE is required or the script exits without touching the database.

async function run() {
    const envPath = process.env.SEED_ENV === 'dev' ? '.env.dev' : '.env'
    const result = config({ path: envPath })
    console.log('SEED_ENV:', process.env.SEED_ENV)
    console.log('Loading env file:', envPath)
    console.log('dotenv error:', result.error ?? 'none')
    console.log('SUPABASE_URL:', process.env.SUPABASE_URL ? 'set' : 'MISSING')
    console.log('SUPABASE_SERVICE_ROLE_KEY:', process.env.SUPABASE_SERVICE_ROLE_KEY ? 'set' : 'MISSING')

    if (process.env.CONFIRM !== 'DELETE') {
        console.error('Refusing to run: set CONFIRM=DELETE to actually delete all prides rows.')
        process.exitCode = 1
        return
    }

    const supabase = createClient<Database>(
        process.env.SUPABASE_URL!,
        process.env.SUPABASE_SERVICE_ROLE_KEY!
    )

    const { count: before, error: beforeErr } = await supabase
        .from('prides')
        .select('*', { count: 'exact', head: true })
    if (beforeErr) throw beforeErr
    console.log('prides count before delete:', before)

    const { count: deleted, error: deleteErr } = await supabase
        .from('prides')
        .delete({ count: 'exact' })
        .not('id', 'is', null)
    if (deleteErr) throw deleteErr
    console.log('rows deleted:', deleted)

    const { count: after, error: afterErr } = await supabase
        .from('prides')
        .select('*', { count: 'exact', head: true })
    if (afterErr) throw afterErr
    console.log('prides count after delete:', after)
}

run().catch((e) => {
    console.error('Delete failed:', e)
    process.exitCode = 1
})
