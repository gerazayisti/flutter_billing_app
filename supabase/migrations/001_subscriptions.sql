-- ============================================================
-- Gestock+ — Table des abonnements
-- ============================================================

-- 1. Table subscriptions
create table if not exists public.subscriptions (
  id                  uuid        default gen_random_uuid() primary key,
  shop_id             uuid        not null unique,                          -- ✅ uuid au lieu de text
  tier                text        not null default 'trial'
                        check (tier in ('trial', 'starter', 'pro', 'business')),
  billing_cycle       text        default 'monthly'
                        check (billing_cycle in ('monthly', 'yearly')),
  start_date          timestamptz,
  expiry_date         timestamptz,
  freemopay_reference text,
  activated_by        uuid        references auth.users(id),
  created_at          timestamptz default now(),
  updated_at          timestamptz default now()
);

-- 2. Row Level Security
alter table public.subscriptions enable row level security;

-- Tout membre de la boutique peut lire l'abonnement
create policy "shop_members_read_subscription"
  on public.subscriptions for select
  using (
    shop_id in (
      select shop_id from public.shop_members where user_id = auth.uid()
    )
  );

-- Seul le propriétaire peut créer un abonnement
create policy "owner_insert_subscription"
  on public.subscriptions for insert
  with check (
    shop_id in (
      select shop_id from public.shop_members
      where user_id = auth.uid() and role = 'owner'
    )
  );

-- Seul le propriétaire peut modifier un abonnement
create policy "owner_update_subscription"
  on public.subscriptions for update
  using (
    shop_id in (
      select shop_id from public.shop_members
      where user_id = auth.uid() and role = 'owner'
    )
  );

-- 3. Trigger auto-update updated_at
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger subscriptions_updated_at
  before update on public.subscriptions
  for each row execute function public.set_updated_at();