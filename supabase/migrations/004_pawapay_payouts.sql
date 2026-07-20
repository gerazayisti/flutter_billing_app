-- Migration pour la gestion des soldes virtuels et des retraits (Payouts) avec commissions Gestock de 3%

-- 1. Table des soldes virtuels par boutique
create table if not exists shop_balances (
  shop_id text primary key,
  balance numeric(15, 2) not null default 0.00,
  updated_at timestamptz not null default now()
);

-- 2. Table pour stocker les gains globaux accumulés par Gestock (les 3% de frais)
create table if not exists gestock_earnings (
  id int primary key default 1,
  total_commissions numeric(15, 2) not null default 0.00,
  updated_at timestamptz not null default now(),
  constraint single_row check (id = 1)
);

-- Insérer la ligne de gains Gestock par défaut si elle n'existe pas
insert into gestock_earnings (id, total_commissions)
values (1, 0.00)
on conflict (id) do nothing;

-- 3. Table des retraits boutiques (Payouts)
create table if not exists shop_withdrawals (
  id uuid primary key default gen_random_uuid(),
  payout_id uuid not null unique,
  shop_id text not null,
  phone_number text not null,
  provider text not null,
  gross_amount numeric(15, 2) not null, -- Somme retirée du solde de la boutique
  fee_amount numeric(15, 2) not null,   -- Les 3% de commission Gestock
  net_amount numeric(15, 2) not null,   -- Le montant réel envoyé sur le Mobile Money (97%)
  status text not null default 'PENDING', -- PENDING | ACCEPTED | COMPLETED | FAILED
  failure_code text,
  failure_message text,
  provider_transaction_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 4. Activer le Realtime pour les soldes et les retraits
alter publication supabase_realtime add table shop_balances;
alter publication supabase_realtime add table shop_withdrawals;
