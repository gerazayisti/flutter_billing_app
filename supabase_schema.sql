-- ============================================================
-- Gestock+ — Schéma Supabase complet
-- Exécuter une seule fois dans : SQL Editor → New query
-- ============================================================

-- ── Extensions ──────────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS "pgcrypto";   -- gen_random_uuid()

-- ============================================================
-- Fonctions de sécurité pour RLS (évite la récursion infinie)
-- ============================================================
CREATE OR REPLACE FUNCTION is_shop_member(shop_id_val UUID)
RETURNS BOOLEAN SECURITY DEFINER AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM shop_members
    WHERE shop_id = shop_id_val AND user_id = auth.uid()
  );
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION is_shop_owner(shop_id_val UUID)
RETURNS BOOLEAN SECURITY DEFINER AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM shops
    WHERE id = shop_id_val AND owner_uid = auth.uid()
  );
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- 1. Boutiques (shops)
--    Créée par SupabaseAuthService.signUpOwner()
--    Lue    par SupabaseAuthService._loadMembership()
-- ============================================================
CREATE TABLE IF NOT EXISTS shops (
  id               UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  owner_uid        UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  name             TEXT NOT NULL,
  address1         TEXT DEFAULT '',
  address2         TEXT DEFAULT '',
  phone            TEXT DEFAULT '',
  upi_id           TEXT DEFAULT '',          -- conservé pour compatibilité ShopModel
  city             TEXT DEFAULT '',
  district         TEXT DEFAULT '',
  shop_type        TEXT DEFAULT '',
  tax_id           TEXT DEFAULT '',
  orange_merchant  TEXT DEFAULT '',
  mtn_merchant     TEXT DEFAULT '',
  receipt_footer   TEXT DEFAULT '',
  created_at       TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE shops ENABLE ROW LEVEL SECURITY;

CREATE POLICY "shops_select" ON shops FOR SELECT
  USING (
    owner_uid = auth.uid() OR
    is_shop_member(id)
  );

CREATE POLICY "shops_insert" ON shops FOR INSERT
  WITH CHECK (owner_uid = auth.uid());

CREATE POLICY "shops_update" ON shops FOR UPDATE
  USING  (owner_uid = auth.uid())
  WITH CHECK (owner_uid = auth.uid());

CREATE POLICY "shops_delete" ON shops FOR DELETE
  USING (owner_uid = auth.uid());

-- ============================================================
-- 2. Membres de boutique (shop_members)
--    Propriétaire + employés (cashier / stockManager)
--    Créée par SupabaseAuthService.signUpOwner() / createEmployee()
-- ============================================================
CREATE TABLE IF NOT EXISTS shop_members (
  id         UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  shop_id    UUID REFERENCES shops(id) ON DELETE CASCADE NOT NULL,
  user_id    UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  role       TEXT NOT NULL
    CHECK (role IN ('owner', 'cashier', 'stockManager')),
  name       TEXT NOT NULL,
  email      TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (shop_id, user_id)
);

ALTER TABLE shop_members ENABLE ROW LEVEL SECURITY;

CREATE POLICY "members_select" ON shop_members FOR SELECT
  USING (
    user_id = auth.uid() OR
    is_shop_member(shop_id)
  );

CREATE POLICY "members_insert" ON shop_members FOR INSERT
  WITH CHECK (
    user_id = auth.uid() OR
    is_shop_owner(shop_id)
  );

CREATE POLICY "members_update" ON shop_members FOR UPDATE
  USING (is_shop_owner(shop_id));

CREATE POLICY "members_delete" ON shop_members FOR DELETE
  USING (is_shop_owner(shop_id));

-- ============================================================
-- 3. Produits (products)
--    Modèle Flutter : ProductModel (typeId:0)
--    Champs : id, name, barcode, price, stock, category,
--             minStockAlert, variants (List<String>)
-- ============================================================
CREATE TABLE IF NOT EXISTS products (
  id               TEXT PRIMARY KEY,           -- UUID généré par l'app (uuid package)
  shop_id          UUID REFERENCES shops(id) ON DELETE CASCADE NOT NULL,
  name             TEXT NOT NULL,
  barcode          TEXT DEFAULT '',
  price            NUMERIC(12, 0) NOT NULL,    -- FCFA = entiers
  stock            INTEGER DEFAULT 0,
  category         TEXT DEFAULT 'Général',
  min_stock_alert  INTEGER DEFAULT 5,
  variants         JSONB DEFAULT '[]'::JSONB,  -- List<String>
  updated_at       TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE products ENABLE ROW LEVEL SECURITY;

CREATE POLICY "products_select" ON products FOR SELECT
  USING (is_shop_member(shop_id));

CREATE POLICY "products_all" ON products FOR ALL
  USING  (is_shop_member(shop_id))
  WITH CHECK (is_shop_member(shop_id));

CREATE INDEX IF NOT EXISTS idx_products_shop    ON products (shop_id);
CREATE INDEX IF NOT EXISTS idx_products_barcode ON products (barcode) WHERE barcode <> '';

-- ============================================================
-- 4. Commandes / Ventes (orders)
--    Modèle Flutter : OrderModel (typeId:2)
--    Champs : id, date, totalAmount, paymentMethod, items[]
-- ============================================================
CREATE TABLE IF NOT EXISTS orders (
  id              TEXT PRIMARY KEY,            -- UUID généré par l'app
  shop_id         UUID REFERENCES shops(id) ON DELETE CASCADE NOT NULL,
  date            TIMESTAMPTZ NOT NULL,
  total_amount    NUMERIC(12, 0) NOT NULL,
  payment_method  TEXT DEFAULT 'cash'
    CHECK (payment_method IN ('cash', 'orangeMoney', 'mtnMomo', 'card', 'mobileMoney')),
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

CREATE POLICY "orders_select" ON orders FOR SELECT
  USING (is_shop_member(shop_id));

CREATE POLICY "orders_all" ON orders FOR ALL
  USING  (is_shop_member(shop_id))
  WITH CHECK (is_shop_member(shop_id));

CREATE INDEX IF NOT EXISTS idx_orders_shop ON orders (shop_id);
CREATE INDEX IF NOT EXISTS idx_orders_date ON orders (shop_id, date DESC);

-- ============================================================
-- 5. Lignes de commande (order_items)
--    Modèle Flutter : OrderItemModel (typeId:3)
--    Champs : productId, productName, price, quantity, selectedVariant
-- ============================================================
CREATE TABLE IF NOT EXISTS order_items (
  id               UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  order_id         TEXT REFERENCES orders(id) ON DELETE CASCADE NOT NULL,
  product_id       TEXT NOT NULL,
  product_name     TEXT NOT NULL,
  price            NUMERIC(12, 0) NOT NULL,
  quantity         INTEGER NOT NULL CHECK (quantity > 0),
  selected_variant TEXT
);

ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "order_items_select" ON order_items FOR SELECT
  USING (order_id IN (
    SELECT id FROM orders WHERE is_shop_member(shop_id)
  ));

CREATE POLICY "order_items_all" ON order_items FOR ALL
  USING (order_id IN (
    SELECT id FROM orders WHERE is_shop_member(shop_id)
  ))
  WITH CHECK (order_id IN (
    SELECT id FROM orders WHERE is_shop_member(shop_id)
  ));

CREATE INDEX IF NOT EXISTS idx_order_items_order   ON order_items (order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_product ON order_items (product_id);

-- ============================================================
-- 6. Transactions Mobile Money (momo_transactions)
--    Modèle Flutter : MomoTransactionModel (typeId:8)
--    Opérateurs : orange | mtn
--    Statuts    : pending | confirmed | failed | manualConfirm | cancelled
-- ============================================================
CREATE TABLE IF NOT EXISTS momo_transactions (
  id              TEXT PRIMARY KEY,
  shop_id         UUID REFERENCES shops(id) ON DELETE CASCADE NOT NULL,
  order_id        TEXT REFERENCES orders(id) ON DELETE SET NULL,
  operator        TEXT NOT NULL
    CHECK (operator IN ('orange', 'mtn')),
  customer_phone  TEXT NOT NULL,
  amount          NUMERIC(12, 0) NOT NULL,
  status          TEXT NOT NULL
    CHECK (status IN ('pending', 'confirmed', 'failed', 'manualConfirm', 'cancelled')),
  reference       TEXT,
  external_id     TEXT,
  initiated_at    TIMESTAMPTZ NOT NULL,
  confirmed_at    TIMESTAMPTZ,
  error_message   TEXT,
  cashier_id      TEXT NOT NULL              -- UUID du caissier (shop_members.user_id)
);

ALTER TABLE momo_transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "momo_select" ON momo_transactions FOR SELECT
  USING (is_shop_member(shop_id));

CREATE POLICY "momo_all" ON momo_transactions FOR ALL
  USING  (is_shop_member(shop_id))
  WITH CHECK (is_shop_member(shop_id));

CREATE INDEX IF NOT EXISTS idx_momo_shop  ON momo_transactions (shop_id);
CREATE INDEX IF NOT EXISTS idx_momo_order ON momo_transactions (order_id);
CREATE INDEX IF NOT EXISTS idx_momo_date  ON momo_transactions (shop_id, initiated_at DESC);

-- ============================================================
-- 7. Fournisseurs (suppliers)
--    Modèle Flutter : SupplierModel (typeId:10)
--    Champs : id, name, phone, address, notes
-- ============================================================
CREATE TABLE IF NOT EXISTS suppliers (
  id         TEXT PRIMARY KEY,
  shop_id    UUID REFERENCES shops(id) ON DELETE CASCADE NOT NULL,
  name       TEXT NOT NULL,
  phone      TEXT,
  address    TEXT,
  notes      TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE suppliers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "suppliers_select" ON suppliers FOR SELECT
  USING (is_shop_member(shop_id));

CREATE POLICY "suppliers_all" ON suppliers FOR ALL
  USING  (is_shop_member(shop_id))
  WITH CHECK (is_shop_member(shop_id));

CREATE INDEX IF NOT EXISTS idx_suppliers_shop ON suppliers (shop_id);

-- ============================================================
-- 8. Mouvements de stock (stock_movements)
--    Modèle Flutter : StockMovementModel (typeId:9)
--    Types : saleOut | manualOut | restockIn |
--            adjustmentIn | adjustmentOut | returnIn
-- ============================================================
CREATE TABLE IF NOT EXISTS stock_movements (
  id            TEXT PRIMARY KEY,
  shop_id       UUID REFERENCES shops(id) ON DELETE CASCADE NOT NULL,
  product_id    TEXT NOT NULL,
  product_name  TEXT NOT NULL,
  type          TEXT NOT NULL
    CHECK (type IN ('saleOut','manualOut','restockIn','adjustmentIn','adjustmentOut','returnIn')),
  quantity      INTEGER NOT NULL,
  operator_id   TEXT NOT NULL,               -- UUID caissier ou stockManager
  date          TIMESTAMPTZ NOT NULL,
  supplier_id   TEXT REFERENCES suppliers(id) ON DELETE SET NULL,
  supplier_name TEXT,
  order_id      TEXT REFERENCES orders(id) ON DELETE SET NULL,
  note          TEXT,
  unit_cost     NUMERIC(12, 0)               -- coût unitaire achat (FCFA)
);

ALTER TABLE stock_movements ENABLE ROW LEVEL SECURITY;

CREATE POLICY "stock_movements_select" ON stock_movements FOR SELECT
  USING (is_shop_member(shop_id));

CREATE POLICY "stock_movements_all" ON stock_movements FOR ALL
  USING  (is_shop_member(shop_id))
  WITH CHECK (is_shop_member(shop_id));

CREATE INDEX IF NOT EXISTS idx_stock_mvt_shop    ON stock_movements (shop_id);
CREATE INDEX IF NOT EXISTS idx_stock_mvt_product ON stock_movements (product_id);
CREATE INDEX IF NOT EXISTS idx_stock_mvt_date    ON stock_movements (shop_id, date DESC);

-- ============================================================
-- 9. Clôtures de caisse (cash_closures)
--    Modèle Flutter : CashRegisterClosureModel (typeId:11)
--    TVA 19,25 % calculée côté app ; montants en FCFA.
-- ============================================================
CREATE TABLE IF NOT EXISTS cash_closures (
  id                  TEXT PRIMARY KEY,
  shop_id             UUID REFERENCES shops(id) ON DELETE CASCADE NOT NULL,
  closed_at           TIMESTAMPTZ NOT NULL,
  period_start        TIMESTAMPTZ NOT NULL,
  cashier_id          TEXT NOT NULL,
  cash_total          NUMERIC(12, 0) NOT NULL DEFAULT 0,
  orange_money_total  NUMERIC(12, 0) NOT NULL DEFAULT 0,
  mtn_momo_total      NUMERIC(12, 0) NOT NULL DEFAULT 0,
  card_total          NUMERIC(12, 0) NOT NULL DEFAULT 0,
  grand_total         NUMERIC(12, 0) NOT NULL DEFAULT 0,
  transaction_count   INTEGER NOT NULL DEFAULT 0,
  notes               TEXT
);

ALTER TABLE cash_closures ENABLE ROW LEVEL SECURITY;

CREATE POLICY "closures_select" ON cash_closures FOR SELECT
  USING (is_shop_member(shop_id));

CREATE POLICY "closures_all" ON cash_closures FOR ALL
  USING  (is_shop_member(shop_id))
  WITH CHECK (is_shop_member(shop_id));

CREATE INDEX IF NOT EXISTS idx_closures_shop ON cash_closures (shop_id);
CREATE INDEX IF NOT EXISTS idx_closures_date ON cash_closures (shop_id, closed_at DESC);

-- ============================================================
-- 10. Synchronisation offline-first (gestock_sync)
--     Table JSONB plate utilisée par SupabaseSyncService.
--     Permet le push/pull de toutes les entités en un seul endpoint.
--     entity_type : order | product | stock_movement |
--                   cash_closure | shop | supplier | momo_transaction
-- ============================================================
CREATE TABLE IF NOT EXISTS gestock_sync (
  id           TEXT PRIMARY KEY,    -- format : '{shop_id}_{entity_type}_{entity_id}'
  shop_id      TEXT NOT NULL,       -- UUID boutique (TEXT pour les anciens IDs)
  entity_type  TEXT NOT NULL
    CHECK (entity_type IN (
      'order', 'product', 'stock_movement',
      'cash_closure', 'shop', 'supplier', 'momo_transaction'
    )),
  payload      JSONB NOT NULL,
  synced_at    TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE gestock_sync ENABLE ROW LEVEL SECURITY;

-- Supprimer les anciennes politiques si elles existent déjà
DROP POLICY IF EXISTS "public_access" ON gestock_sync;
DROP POLICY IF EXISTS "owner_access"  ON gestock_sync;
DROP POLICY IF EXISTS "sync_auth"     ON gestock_sync;

CREATE POLICY "sync_auth" ON gestock_sync
  FOR ALL
  USING  (auth.uid() IS NOT NULL)
  WITH CHECK (auth.uid() IS NOT NULL);

CREATE INDEX IF NOT EXISTS idx_sync_shop ON gestock_sync (shop_id);
CREATE INDEX IF NOT EXISTS idx_sync_type ON gestock_sync (shop_id, entity_type);

-- ============================================================
-- ✅ Terminé !
--
-- Tables requises par l'app (obligatoires) :
--   shops, shop_members, gestock_sync
--
-- Tables structurées pour requêtes directes / analytics :
--   products, orders, order_items, momo_transactions,
--   suppliers, stock_movements, cash_closures
--
-- Configuration app_config.dart :
--   supabaseUrl           → Settings → API → Project URL
--   supabaseAnonKey       → Settings → API → anon / public key
--   supabaseServiceRoleKey → Settings → API → service_role key
-- ============================================================
