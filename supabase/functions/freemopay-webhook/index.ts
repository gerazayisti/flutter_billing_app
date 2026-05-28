// Gestock+ — Edge Function FreemoPay Webhook
// Déployer via: supabase functions deploy freemopay-webhook
// Configurer dans FreemoPay : URL = https://<project-ref>.supabase.co/functions/v1/freemopay-webhook
// Ajouter dans les secrets Supabase: FREEMOPAY_WEBHOOK_SECRET

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const SUPABASE_URL             = Deno.env.get('SUPABASE_URL')!
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
const FREEMOPAY_SECRET          = Deno.env.get('FREEMOPAY_WEBHOOK_SECRET') ?? ''

// Correspondance pay-link → plan (depuis PlanConfig dans subscription.dart)
const PAY_LINK_PLANS: Record<string, { tier: string; cycle: string; days: number }> = {
  '3bcd23b713e9ec8f19411c6095525d': { tier: 'starter',  cycle: 'monthly', days: 31  },
  'cab2ac95c6063e094194479258b534': { tier: 'starter',  cycle: 'yearly',  days: 366 },
  '291134fa9f453dd8e420e5a4ff40ac': { tier: 'pro',      cycle: 'monthly', days: 31  },
  '27b1282a2bbb6a3f1ab8a0f12c15e6': { tier: 'pro',      cycle: 'yearly',  days: 366 },
  'd43fb1dabda88266f9a8a4dd99acb6': { tier: 'business', cycle: 'monthly', days: 31  },
  '63c0fdd1b47df54316a8816d997a35': { tier: 'business', cycle: 'yearly',  days: 366 },
}

serve(async (req: Request) => {
  if (req.method !== 'POST') {
    return new Response('Method Not Allowed', { status: 405 })
  }

  // Vérification de la signature FreemoPay (header X-Freemopay-Signature)
  const signature = req.headers.get('x-freemopay-signature') ?? ''
  if (FREEMOPAY_SECRET && signature !== FREEMOPAY_SECRET) {
    return new Response('Unauthorized', { status: 401 })
  }

  let body: Record<string, unknown>
  try {
    body = await req.json()
  } catch {
    return new Response('Invalid JSON', { status: 400 })
  }

  // FreemoPay envoie: { reference, status, amount, metadata: { shop_id, pay_link_id } }
  const reference   = body['reference'] as string | undefined
  const status      = body['status'] as string | undefined
  const metadata    = body['metadata'] as Record<string, string> | undefined
  const shopId      = metadata?.['shop_id']
  const payLinkId   = metadata?.['pay_link_id']

  if (!reference || status !== 'SUCCESS' || !shopId) {
    console.warn('Webhook ignoré — champs manquants ou statut invalide:', body)
    return new Response('Ignored', { status: 200 })
  }

  const plan = payLinkId ? PAY_LINK_PLANS[payLinkId] : undefined
  if (!plan) {
    console.warn('pay_link_id inconnu:', payLinkId, '— fallback starter mensuel')
  }

  const tier  = plan?.tier  ?? 'starter'
  const cycle = plan?.cycle ?? 'monthly'
  const days  = plan?.days  ?? 31

  const now    = new Date()
  const expiry = new Date(now.getTime() + days * 24 * 60 * 60 * 1000)

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

  const { error } = await supabase.from('subscriptions').upsert({
    shop_id:             shopId,
    tier,
    billing_cycle:       cycle,
    start_date:          now.toISOString(),
    expiry_date:         expiry.toISOString(),
    freemopay_reference: reference,
    updated_at:          now.toISOString(),
  }, { onConflict: 'shop_id' })

  if (error) {
    console.error('Erreur Supabase:', error)
    return new Response('Database error', { status: 500 })
  }

  console.log(`Abonnement activé — shop: ${shopId}, tier: ${tier}, expire: ${expiry.toISOString()}`)
  return new Response(JSON.stringify({ success: true }), {
    headers: { 'Content-Type': 'application/json' },
  })
})
