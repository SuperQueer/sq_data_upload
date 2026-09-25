import { config } from 'dotenv'
import { createClient } from '@supabase/supabase-js'

// Initial associations catalog — keep in sync with the seed list in
// supabase/migrations/20260820000000_add_associations.sql
const ASSOCIATIONS: { label: string; sort_order: number }[] = [
    { label: 'InterPride', sort_order: 1 },
    { label: 'US Prides', sort_order: 2 },
    { label: 'Canada Pride', sort_order: 3 },
    { label: 'Chambers of Commerce', sort_order: 4 },
]

async function seed() {
    const envPath = process.env.SEED_ENV === 'dev' ? '.env.dev' : '.env'
    const result = config({ path: envPath })
    console.log('SEED_ENV:', process.env.SEED_ENV)
    console.log('Loading env file:', envPath)
    console.log('dotenv error:', result.error ?? 'none')
    console.log('SUPABASE_URL:', process.env.SUPABASE_URL ? 'set' : 'MISSING')
    console.log('SUPABASE_SERVICE_ROLE_KEY:', process.env.SUPABASE_SERVICE_ROLE_KEY ? 'set' : 'MISSING')

    const supabase = createClient(
        process.env.SUPABASE_URL!,
        process.env.SUPABASE_SERVICE_ROLE_KEY!
    )

    const { data, error } = await supabase
        .from('associations')
        .upsert(ASSOCIATIONS, { onConflict: 'label' })
        .select('id,label,sort_order')

    if (error) throw error

    console.log(`Seeded ${data?.length ?? 0} associations`)
}

seed().catch((e) => {
    console.error('Seed failed:', e)
    process.exitCode = 1
})
