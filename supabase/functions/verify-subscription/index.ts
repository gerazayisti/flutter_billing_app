// Gestock+ — Edge Function : vérification de paiement FreemoPay et activation abonnement
//
// Flow :
//   App Flutter → POST verify-subscription { reference, shop_id, tier, cycle }
//             → vérifie JWT + appartenance à la boutique
//             → vérifie GET https://api-v2.freemopay.com/api/v2/payment/:reference
//             → si SUCCESS + montant correct → upsert subscriptions
//             → retourne { start_date, expiry_date, tier, cycle }
//
// Secrets Supabase à configurer (Edge Functions → Secrets) :
//   FREEMOPAY_APP_KEY    → votre appKey (username Basic Auth)
//   FREEMOPAY_SECRET_KEY → votre secretKey (password Basic Auth)

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const SUPABASE_URL              = Deno.env.get('SUPABASE_URL')!
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
const SUPABASE_ANON_KEY         = Deno.env.get('SUPABASE_ANON_KEY')!
const FREEMOPAY_APP_KEY         = Deno.env.get('FREEMOPAY_APP_KEY') ?? ''
const FREEMOPAY_SECRET_KEY      = Deno.env.get('FREEMOPAY_SECRET_KEY') ?? ''
const FREEMOPAY_BASE_URL        = 'https://api-v2.freemopay.com'

// Prix attendus par plan (en FCFA) — doit correspondre à PlanConfig dans subscription.dart
const PLAN_AMOUNTS: Record<string, Record<string, number>> = {
  starter:  { monthly: 1500,  yearly: 13000  },
  pro:      { monthly: 3500,  yearly: 35000  },
  business: { monthly: 15000, yearly: 165000 },
}

const PLAN_DAYS: Record<string, Record<string, number>> = {
  starter:  { monthly: 31,  yearly: 366 },
  pro:      { monthly: 31,  yearly: 366 },
  business: { monthly: 31,  yearly: 366 },
}

const corsHeaders = {
  'Access-Control-Allow-Origin':  '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req: Request) => {
  // Preflight CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  if (req.method !== 'POST') {
    return new Response('Method Not Allowed', { status: 405, headers: corsHeaders })
  }

  // ── 0. Vérifier l'authentification JWT ────────────────────────────────────

  const authHeader = req.headers.get('Authorization')
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return json401('Authentification requise')
  }

  // Client avec le JWT de l'utilisateur (respecte les RLS)
  const userJwt = authHeader.slice(7)
  const userClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: { headers: { Authorization: authHeader } },
  })

  const { data: { user }, error: authError } = await userClient.auth.getUser()
  if (authError || !user) {
    return json401('Token invalide ou expiré')
  }

  let body: Record<string, unknown>
  try {
    body = await req.json()
  } catch {
    return new Response(JSON.stringify({ error: 'JSON invalide' }), {
      status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  const reference = (body['reference'] as string | undefined)?.trim()
  const shopId    = body['shop_id']   as string | undefined
  const tier      = body['tier']      as string | undefined
  const cycle     = body['cycle']     as string | undefined

  if (!reference || !shopId || !tier || !cycle) {
    return json400('Champs manquants : reference, shop_id, tier, cycle requis')
  }

  if (!PLAN_AMOUNTS[tier] || !PLAN_AMOUNTS[tier][cycle]) {
    return json400(`Plan invalide : tier="${tier}" cycle="${cycle}"`)
  }

  // ── 0b. Vérifier que l'utilisateur est propriétaire de la boutique ─────────

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

  const { data: membership } = await supabase
    .from('shop_members')
    .select('role')
    .eq('shop_id', shopId)
    .eq('user_id', user.id)
    .maybeSingle()

  if (!membership || membership.role !== 'owner') {
    return json403('Seul le propriétaire peut activer un abonnement')
  }

  // ── 1. Vérifier la référence via l'API FreemoPay ───────────────────────────

  const credentials = btoa(`${FREEMOPAY_APP_KEY}:${FREEMOPAY_SECRET_KEY}`)
  let payment: Record<string, unknown>

  try {
    const resp = await fetch(
      `${FREEMOPAY_BASE_URL}/api/v2/payment/${encodeURIComponent(reference)}`,
      { headers: { Authorization: `Basic ${credentials}` } },
    )

    if (!resp.ok) {
      const text = await resp.text()
      console.error('FreemoPay error:', resp.status, text)
      return json400(`Référence introuvable chez FreemoPay (${resp.status})`)
    }

    payment = await resp.json() as Record<string, unknown>
  } catch (err) {
    console.error('FreemoPay fetch error:', err)
    return json500('Impossible de contacter FreemoPay — réessayez dans quelques instants')
  }

  // ── 2. Valider le statut et le montant ─────────────────────────────────────

  const status = payment['status'] as string | undefined
  if (status !== 'SUCCESS') {
    const msg = payment['message'] as string | undefined
    return json400(`Paiement non confirmé (statut : ${status ?? 'inconnu'}${msg ? ' — ' + msg : ''})`)
  }

  const paidAmount     = (payment['amount'] as number | undefined) ?? 0
  const expectedAmount = PLAN_AMOUNTS[tier][cycle]

  if (paidAmount < expectedAmount) {
    return json400(
      `Montant incorrect : ${paidAmount} FCFA reçu, ${expectedAmount} FCFA attendu pour le plan ${tier} ${cycle}`
    )
  }

  // ── 3. Vérifier que la référence n'est pas déjà utilisée (toutes boutiques) ─

  const { data: existing } = await supabase
    .from('subscriptions')
    .select('shop_id')
    .eq('freemopay_reference', reference)
    .maybeSingle()

  if (existing) {
    return json400('Cette référence de paiement a déjà été utilisée')
  }

  // ── 4. Activer l'abonnement dans Supabase ─────────────────────────────────

  const days   = PLAN_DAYS[tier][cycle]
  const now    = new Date()
  const expiry = new Date(now.getTime() + days * 24 * 60 * 60 * 1000)

  const { error: upsertError } = await supabase.from('subscriptions').upsert({
    shop_id:             shopId,
    tier,
    billing_cycle:       cycle,
    start_date:          now.toISOString(),
    expiry_date:         expiry.toISOString(),
    freemopay_reference: reference,
    updated_at:          now.toISOString(),
  }, { onConflict: 'shop_id' })

  if (upsertError) {
    console.error('Supabase upsert error:', upsertError)
    return json500('Erreur lors de l\'activation — contactez le support')
  }

  console.log(`Abonnement activé — shop: ${shopId}, plan: ${tier}/${cycle}, expire: ${expiry.toISOString()}`)

  return new Response(JSON.stringify({
    start_date:  now.toISOString(),
    expiry_date: expiry.toISOString(),
    tier,
    cycle,
  }), {
    status: 200,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
})

// ── Helpers ───────────────────────────────────────────────────────────────────

function json400(error: string): Response {
  return new Response(JSON.stringify({ error }), {
    status: 400,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

function json401(error: string): Response {
  return new Response(JSON.stringify({ error }), {
    status: 401,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

function json403(error: string): Response {
  return new Response(JSON.stringify({ error }), {
    status: 403,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

function json500(error: string): Response {
  return new Response(JSON.stringify({ error }), {
    status: 500,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}
