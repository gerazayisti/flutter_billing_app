-- 1. Configuration pawaPay
create table if not exists pawapay_config (
  id int primary key default 1,
  active_conf jsonb not null,
  fetched_at timestamptz not null default now()
);

-- 2. Transactions de paiement mobile money
create table if not exists mobile_money_payments (
  id uuid primary key default gen_random_uuid(),
  deposit_id uuid not null unique,
  sale_id text,
  status text not null default 'PENDING',
  amount text not null,
  currency text not null default 'XAF',
  phone_number text not null,
  provider text not null,
  failure_code text,
  failure_message text,
  provider_transaction_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 3. Table des soldes virtuels par boutique
create table if not exists shop_balances (
  shop_id text primary key,
  balance numeric(15, 2) not null default 0.00,
  updated_at timestamptz not null default now()
);

-- 4. Table pour stocker les gains Gestock
create table if not exists gestock_earnings (
  id int primary key default 1,
  total_commissions numeric(15, 2) not null default 0.00,
  updated_at timestamptz not null default now(),
  constraint single_row check (id = 1)
);

insert into gestock_earnings (id, total_commissions)
values (1, 0.00)
on conflict (id) do nothing;

-- 5. Table des retraits boutiques (Payouts)
create table if not exists shop_withdrawals (
  id uuid primary key default gen_random_uuid(),
  payout_id uuid not null unique,
  shop_id text not null,
  phone_number text not null,
  provider text not null,
  gross_amount numeric(15, 2) not null, 
  fee_amount numeric(15, 2) not null,   
  net_amount numeric(15, 2) not null,   
  status text not null default 'PENDING', 
  failure_code text,
  failure_message text,
  provider_transaction_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 6. Fonction et Trigger
create or replace function handle_completed_deposit()
returns trigger as $$
declare
  v_shop_id text;
begin
  if new.status = 'COMPLETED' and (old.status is null or old.status != 'COMPLETED') then
    if position('_' in new.sale_id) > 0 then
      v_shop_id := substring(new.sale_id from '(.*)_');
    else
      v_shop_id := 'default_shop';
    end if;

    insert into shop_balances (shop_id, balance, updated_at)
    values (v_shop_id, cast(new.amount as numeric(15, 2)), now())
    on conflict (shop_id) do update
    set balance = shop_balances.balance + cast(new.amount as numeric(15, 2)),
        updated_at = now();
  end if;
  return new;
end;
$$ language plpgsql;

drop trigger if exists on_deposit_completed on mobile_money_payments;
create trigger on_deposit_completed
  after update on mobile_money_payments
  for each row
  execute function handle_completed_deposit();

-- 7. RECHARGEMENT DU CACHE
NOTIFY pgrst, 'reload schema';
