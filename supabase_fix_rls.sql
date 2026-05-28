-- ============================================================
-- Gestock+ — Fix RLS + Realtime
-- Coller dans : Supabase → SQL Editor → New query → Run
-- Idempotent : safe à réexécuter plusieurs fois
-- ============================================================

-- ────────────────────────────────────────────────────────────
-- 1. Fonctions de sécurité (recréées proprement)
-- ────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION is_shop_member(shop_id_val UUID)
RETURNS BOOLEAN SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM shop_members
    WHERE shop_id = shop_id_val
      AND user_id = auth.uid()
  );
END;
$$;

CREATE OR REPLACE FUNCTION is_shop_owner(shop_id_val UUID)
RETURNS BOOLEAN SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM shops
    WHERE id = shop_id_val
      AND owner_uid = auth.uid()
  );
END;
$$;

-- ────────────────────────────────────────────────────────────
-- 2. RLS activé sur toutes les tables
-- ────────────────────────────────────────────────────────────
ALTER TABLE shops             ENABLE ROW LEVEL SECURITY;
ALTER TABLE shop_members      ENABLE ROW LEVEL SECURITY;
ALTER TABLE products          ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders            ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items       ENABLE ROW LEVEL SECURITY;
ALTER TABLE momo_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE suppliers         ENABLE ROW LEVEL SECURITY;
ALTER TABLE stock_movements   ENABLE ROW LEVEL SECURITY;
ALTER TABLE cash_closures     ENABLE ROW LEVEL SECURITY;
ALTER TABLE gestock_sync      ENABLE ROW LEVEL SECURITY;

-- ────────────────────────────────────────────────────────────
-- 3. Suppression des anciennes policies (évite les conflits)
-- ────────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "shops_select"          ON shops;
DROP POLICY IF EXISTS "shops_insert"          ON shops;
DROP POLICY IF EXISTS "shops_update"          ON shops;
DROP POLICY IF EXISTS "shops_delete"          ON shops;

DROP POLICY IF EXISTS "members_select"        ON shop_members;
DROP POLICY IF EXISTS "members_insert"        ON shop_members;
DROP POLICY IF EXISTS "members_update"        ON shop_members;
DROP POLICY IF EXISTS "members_delete"        ON shop_members;

DROP POLICY IF EXISTS "products_select"       ON products;
DROP POLICY IF EXISTS "products_all"          ON products;

DROP POLICY IF EXISTS "orders_select"         ON orders;
DROP POLICY IF EXISTS "orders_all"            ON orders;

DROP POLICY IF EXISTS "order_items_select"    ON order_items;
DROP POLICY IF EXISTS "order_items_all"       ON order_items;

DROP POLICY IF EXISTS "momo_select"           ON momo_transactions;
DROP POLICY IF EXISTS "momo_all"              ON momo_transactions;

DROP POLICY IF EXISTS "suppliers_select"      ON suppliers;
DROP POLICY IF EXISTS "suppliers_all"         ON suppliers;

DROP POLICY IF EXISTS "stock_movements_select" ON stock_movements;
DROP POLICY IF EXISTS "stock_movements_all"    ON stock_movements;

DROP POLICY IF EXISTS "closures_select"       ON cash_closures;
DROP POLICY IF EXISTS "closures_all"          ON cash_closures;

DROP POLICY IF EXISTS "sync_auth"             ON gestock_sync;
DROP POLICY IF EXISTS "public_access"         ON gestock_sync;
DROP POLICY IF EXISTS "owner_access"          ON gestock_sync;

-- ────────────────────────────────────────────────────────────
-- 4. Recréation des policies
-- ────────────────────────────────────────────────────────────

-- shops
CREATE POLICY "shops_select" ON shops FOR SELECT
  USING (owner_uid = auth.uid() OR is_shop_member(id));

CREATE POLICY "shops_insert" ON shops FOR INSERT
  WITH CHECK (owner_uid = auth.uid());

CREATE POLICY "shops_update" ON shops FOR UPDATE
  USING  (owner_uid = auth.uid())
  WITH CHECK (owner_uid = auth.uid());

CREATE POLICY "shops_delete" ON shops FOR DELETE
  USING (owner_uid = auth.uid());

-- shop_members
CREATE POLICY "members_select" ON shop_members FOR SELECT
  USING (user_id = auth.uid() OR is_shop_member(shop_id));

CREATE POLICY "members_insert" ON shop_members FOR INSERT
  WITH CHECK (user_id = auth.uid() OR is_shop_owner(shop_id));

CREATE POLICY "members_update" ON shop_members FOR UPDATE
  USING (is_shop_owner(shop_id));

CREATE POLICY "members_delete" ON shop_members FOR DELETE
  USING (is_shop_owner(shop_id));

-- products
CREATE POLICY "products_all" ON products FOR ALL
  USING  (is_shop_member(shop_id))
  WITH CHECK (is_shop_member(shop_id));

-- orders
CREATE POLICY "orders_all" ON orders FOR ALL
  USING  (is_shop_member(shop_id))
  WITH CHECK (is_shop_member(shop_id));

-- order_items (pas de shop_id direct → jointure orders)
CREATE POLICY "order_items_all" ON order_items FOR ALL
  USING (
    order_id IN (
      SELECT id FROM orders WHERE is_shop_member(shop_id)
    )
  )
  WITH CHECK (
    order_id IN (
      SELECT id FROM orders WHERE is_shop_member(shop_id)
    )
  );

-- momo_transactions
CREATE POLICY "momo_all" ON momo_transactions FOR ALL
  USING  (is_shop_member(shop_id))
  WITH CHECK (is_shop_member(shop_id));

-- suppliers
CREATE POLICY "suppliers_all" ON suppliers FOR ALL
  USING  (is_shop_member(shop_id))
  WITH CHECK (is_shop_member(shop_id));

-- stock_movements
CREATE POLICY "stock_movements_all" ON stock_movements FOR ALL
  USING  (is_shop_member(shop_id))
  WITH CHECK (is_shop_member(shop_id));

-- cash_closures
CREATE POLICY "closures_all" ON cash_closures FOR ALL
  USING  (is_shop_member(shop_id))
  WITH CHECK (is_shop_member(shop_id));

-- gestock_sync (tout utilisateur authentifié)
CREATE POLICY "sync_auth" ON gestock_sync FOR ALL
  USING  (auth.uid() IS NOT NULL)
  WITH CHECK (auth.uid() IS NOT NULL);

-- ────────────────────────────────────────────────────────────
-- 5. Realtime — activer la publication pour toutes les tables
-- ────────────────────────────────────────────────────────────
ALTER PUBLICATION supabase_realtime ADD TABLE shops;
ALTER PUBLICATION supabase_realtime ADD TABLE shop_members;
ALTER PUBLICATION supabase_realtime ADD TABLE products;
ALTER PUBLICATION supabase_realtime ADD TABLE orders;
ALTER PUBLICATION supabase_realtime ADD TABLE order_items;
ALTER PUBLICATION supabase_realtime ADD TABLE momo_transactions;
ALTER PUBLICATION supabase_realtime ADD TABLE suppliers;
ALTER PUBLICATION supabase_realtime ADD TABLE stock_movements;
ALTER PUBLICATION supabase_realtime ADD TABLE cash_closures;
ALTER PUBLICATION supabase_realtime ADD TABLE gestock_sync;
ALTER PUBLICATION supabase_realtime ADD TABLE subscriptions;

-- ────────────────────────────────────────────────────────────
-- 6. Vérification finale
-- ────────────────────────────────────────────────────────────
SELECT
  t.tablename,
  t.rowsecurity AS rls_enabled,
  COUNT(p.policyname) AS nb_policies,
  EXISTS (
    SELECT 1 FROM pg_publication_tables pt
    WHERE pt.pubname = 'supabase_realtime'
      AND pt.tablename = t.tablename
  ) AS realtime_active
FROM pg_tables t
LEFT JOIN pg_policies p ON p.tablename = t.tablename AND p.schemaname = 'public'
WHERE t.schemaname = 'public'
GROUP BY t.tablename, t.rowsecurity
ORDER BY t.tablename;
