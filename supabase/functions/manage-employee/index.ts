// Gestock+ — Edge Function : gestion des employés (création / suppression)
//
// Actions :
//   create → crée un compte Supabase Auth + insère dans shop_members
//   delete → supprime le compte Supabase Auth (shop_members supprimé par CASCADE)
//
// Seul le propriétaire (role = 'owner') de la boutique peut appeler cette fonction.

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const SUPABASE_URL              = Deno.env.get('SUPABASE_URL')!
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
const SUPABASE_ANON_KEY         = Deno.env.get('SUPABASE_ANON_KEY')!

const corsHeaders = {
  'Access-Control-Allow-Origin':  '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }
  if (req.method !== 'POST') {
    return new Response('Method Not Allowed', { status: 405, headers: corsHeaders })
  }

  // ── 1. Vérifier le JWT ────────────────────────────────────────────────────

  const authHeader = req.headers.get('Authorization')
  if (!authHeader?.startsWith('Bearer ')) {
    return json401('Authentification requise')
  }

  const userClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: { headers: { Authorization: authHeader } },
  })

  const { data: { user }, error: authError } = await userClient.auth.getUser()
  if (authError || !user) {
    return json401('Token invalide ou expiré')
  }

  // ── 2. Parser le body ─────────────────────────────────────────────────────

  let body: Record<string, unknown>
  try {
    body = await req.json()
  } catch {
    return json400('JSON invalide')
  }

  const action = body['action'] as string | undefined
  const shopId = body['shop_id'] as string | undefined

  if (!action || !shopId) {
    return json400('Champs manquants : action, shop_id requis')
  }

  // ── 3. Vérifier que l'appelant est propriétaire ───────────────────────────

  const adminClient = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

  const { data: membership } = await adminClient
    .from('shop_members')
    .select('role')
    .eq('shop_id', shopId)
    .eq('user_id', user.id)
    .maybeSingle()

  if (!membership || membership.role !== 'owner') {
    return json403('Seul le propriétaire peut gérer les employés')
  }

  // ── 4. Exécuter l'action ──────────────────────────────────────────────────

  if (action === 'create') {
    return await handleCreate(body, shopId, adminClient)
  }

  if (action === 'delete') {
    return await handleDelete(body, adminClient)
  }

  return json400(`Action inconnue : "${action}"`)
})

// ── Handlers ──────────────────────────────────────────────────────────────────

async function handleCreate(
  body: Record<string, unknown>,
  shopId: string,
  adminClient: ReturnType<typeof createClient>,
): Promise<Response> {
  const name     = body['name']     as string | undefined
  const email    = body['email']    as string | undefined
  const password = body['password'] as string | undefined
  const role     = body['role']     as string | undefined

  if (!name || !email || !password || !role) {
    return json400('Champs manquants : name, email, password, role requis')
  }

  if (!['cashier', 'manager'].includes(role)) {
    return json400('Rôle invalide — valeurs acceptées : cashier, manager')
  }

  // Créer le compte auth
  const { data: created, error: createError } = await adminClient.auth.admin.createUser({
    email,
    password,
    email_confirm: true,
  })

  if (createError || !created?.user) {
    const msg = createError?.message ?? ''
    if (msg.includes('already registered') || msg.includes('already exists')) {
      return json400('Cette adresse e-mail est déjà utilisée.')
    }
    console.error('createUser error:', createError)
    return json500('Erreur lors de la création du compte')
  }

  const uid = created.user.id

  // Ajouter à shop_members
  const { error: insertError } = await adminClient.from('shop_members').insert({
    shop_id: shopId,
    user_id: uid,
    role,
    name,
    email,
  })

  if (insertError) {
    // Rollback : supprimer le compte auth créé
    await adminClient.auth.admin.deleteUser(uid)
    console.error('shop_members insert error:', insertError)
    return json500('Erreur lors de l\'ajout à la boutique')
  }

  return new Response(JSON.stringify({ user_id: uid }), {
    status: 201,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

async function handleDelete(
  body: Record<string, unknown>,
  adminClient: ReturnType<typeof createClient>,
): Promise<Response> {
  const userId = body['user_id'] as string | undefined
  if (!userId) {
    return json400('Champ manquant : user_id requis')
  }

  const { error } = await adminClient.auth.admin.deleteUser(userId)
  if (error) {
    console.error('deleteUser error:', error)
    return json500('Erreur lors de la suppression du compte')
  }

  return new Response(JSON.stringify({ success: true }), {
    status: 200,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

// ── Helpers ───────────────────────────────────────────────────────────────────

function json400(error: string): Response {
  return new Response(JSON.stringify({ error }), {
    status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}
function json401(error: string): Response {
  return new Response(JSON.stringify({ error }), {
    status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}
function json403(error: string): Response {
  return new Response(JSON.stringify({ error }), {
    status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}
function json500(error: string): Response {
  return new Response(JSON.stringify({ error }), {
    status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}
