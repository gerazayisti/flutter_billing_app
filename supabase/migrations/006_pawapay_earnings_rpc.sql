-- SQL RPC function for safely incrementing Gestock earnings (prevents concurrent write issues)
create or replace function increment_gestock_earnings(fee_val numeric)
returns void as $$
begin
  insert into gestock_earnings (id, total_commissions, updated_at)
  values (1, fee_val, now())
  on conflict (id) do update
  set total_commissions = gestock_earnings.total_commissions + fee_val,
      updated_at = now();
end;
$$ language plpgsql;
