-- ============================================================
-- Gestock+ — Phase 4 : Stock calculé depuis les mouvements
-- ============================================================
-- À exécuter APRÈS avoir ajouté initial_stock aux produits
-- et migré les données existantes.
--
-- Principe : stock = initial_stock + Σ(entrées) - Σ(sorties)
-- Les mouvements sont la source de vérité — plus de last-write-wins.
-- ============================================================

-- Fonction pour calculer le stock actuel d'un produit depuis ses mouvements
create or replace function public.compute_product_stock(
  p_shop_id text,
  p_product_id text
)
returns integer
language plpgsql
stable
as $$
declare
  v_initial integer := 0;
  v_delta   integer := 0;
begin
  -- Stock initial (valeur au moment de la création du produit)
  select coalesce((payload->>'initial_stock')::integer, (payload->>'stock')::integer, 0)
  into v_initial
  from public.gestock_sync
  where shop_id = p_shop_id
    and entity_type = 'product'
    and payload->>'id' = p_product_id
  limit 1;

  -- Somme algébrique de tous les mouvements pour ce produit
  -- isIn  : restockIn, adjustmentIn, returnIn  → +quantity
  -- isOut : saleOut, manualOut, adjustmentOut  → -quantity
  select coalesce(sum(
    case
      when payload->>'typeName' in ('restockIn', 'adjustmentIn', 'returnIn')
        then (payload->>'quantity')::integer
      else
        -(payload->>'quantity')::integer
    end
  ), 0)
  into v_delta
  from public.gestock_sync
  where shop_id = p_shop_id
    and entity_type = 'stock_movement'
    and payload->>'productId' = p_product_id;

  return greatest(v_initial + v_delta, 0);
end;
$$;

-- Vue utile pour l'admin : stock de tous les produits d'une boutique
create or replace view public.v_product_stocks as
select
  shop_id,
  payload->>'id'   as product_id,
  payload->>'name' as product_name,
  public.compute_product_stock(
    shop_id,
    payload->>'id'
  )                as computed_stock,
  (payload->>'stock')::integer as synced_stock
from public.gestock_sync
where entity_type = 'product';

-- ============================================================
-- Pour activer pleinement cette Phase 4, modifier aussi :
-- 1. _pushProducts() → ajouter 'initial_stock': p.initialStock
-- 2. _mergeProduct()  → utiliser compute_product_stock() via RPC
-- 3. ProductModel     → ajouter le champ initialStock (HiveField)
-- ============================================================
