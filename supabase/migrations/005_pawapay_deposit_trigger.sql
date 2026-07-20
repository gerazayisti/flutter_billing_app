-- Trigger et fonctions SQL pour créditer automatiquement le solde d'une boutique lors d'un paiement réussi (Deposit)

create or replace function handle_completed_deposit()
returns trigger as $$
begin
  -- Si le statut passe à COMPLETED
  if new.status = 'COMPLETED' and (old.status is null or old.status != 'COMPLETED') then
    -- On extrait le shop_id à partir de la référence ou de la vente (ici on assume que le sale_id contient ou permet de retrouver le shop_id, ou on utilise le shop_id passé dans une autre colonne.
    -- Pour être générique, si sale_id contient le préfixe du shop_id, ou si nous extrayons le shop_id.
    -- Option recommandée : extraire le shop_id s'il est préfixé, sinon on récupère le cloud_shop_id ou on l'initialise.
    -- Dans notre architecture, le sale_id est généralement une chaîne liée à la boutique locale (ex: "shopName_123456").
    -- Nous allons extraire tout ce qui se trouve avant le premier underscore '_'
    declare
      v_shop_id text;
    begin
      if position('_' in new.sale_id) > 0 then
        v_shop_id := split_part(new.sale_id, '_', 1);
      else
        v_shop_id := 'default_shop';
      end if;

      -- Insérer ou mettre à jour le solde virtuel de la boutique
      insert into shop_balances (shop_id, balance, updated_at)
      values (v_shop_id, cast(new.amount as numeric(15, 2)), now())
      on conflict (shop_id) do update
      set balance = shop_balances.balance + cast(new.amount as numeric(15, 2)),
          updated_at = now();
    end;
  end if;
  return new;
end;
$$ language plpgsql;

create or replace trigger on_deposit_completed
  after update on mobile_money_payments
  for each row
  execute function handle_completed_deposit();
