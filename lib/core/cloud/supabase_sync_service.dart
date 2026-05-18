import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:billing_app/core/data/hive_database.dart';
import 'cloud_sync_service.dart';

/// Supabase implementation of [CloudSyncService].
/// Uses the globally-initialized [Supabase.instance.client] (from app_config.dart).
class SupabaseSyncService implements CloudSyncService {
  static const String _table = 'gestock_sync';

  SupabaseClient get _client => Supabase.instance.client;

  // ── Public API ────────────────────────────────────────────────────────────

  @override
  bool get isConfigured => true; // Supabase is always initialized via app_config.dart

  @override
  bool get isSignedIn => _client.auth.currentUser != null;

  @override
  String? get userEmail => _client.auth.currentUser?.email;

  @override
  Future<void> initialize() async {} // no-op — Supabase.initialize() called in main()

  @override
  Future<bool> signIn(String email, String password) async {
    try {
      final res = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return res.user != null;
    } on AuthException {
      return false;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (_) {}
  }

  @override
  Future<void> pushOrder(Map<String, dynamic> orderJson) async {
    if (!isSignedIn) return;
    try {
      await _upsertRecord('order', orderJson['id'] as String, orderJson);
    } catch (_) {}
  }

  @override
  Future<DateTime> pushAll({DateTime? lastSync}) async {
    if (!isSignedIn) return DateTime.now();
    final now = DateTime.now();
    try {
      await _pushOrders(since: lastSync);
      await _pushProducts();
      await _pushStockMovements(since: lastSync);
      await _pushCashClosures(since: lastSync);
      await _pushShop();
    } catch (_) {}
    return now;
  }

  @override
  Future<void> pullAll() async {
    if (!isSignedIn) return;
    try {
      final rows = await _client
          .from(_table)
          .select()
          .eq('shop_id', _shopId)
          .order('synced_at');

      for (final row in rows) {
        final type    = row['entity_type'] as String;
        final payload = row['payload'] as Map<String, dynamic>;
        await _mergeRecord(type, payload);
      }
    } catch (_) {}
  }

  // ── Shop ID ───────────────────────────────────────────────────────────────

  String get _shopId {
    final s = HiveDatabase.settingsBox;
    var id = s.get('cloud_shop_id', defaultValue: '') as String;
    if (id.isEmpty) {
      final shop = HiveDatabase.shopBox.values.isNotEmpty
          ? HiveDatabase.shopBox.values.first
          : null;
      id = shop != null
          ? shop.name.toLowerCase().replaceAll(RegExp(r'\s+'), '_')
          : 'shop_${DateTime.now().millisecondsSinceEpoch}';
      s.put('cloud_shop_id', id);
    }
    return id;
  }

  // ── Push helpers ──────────────────────────────────────────────────────────

  Future<void> _pushOrders({DateTime? since}) async {
    var values = HiveDatabase.orderBox.values.toList();
    if (since != null) {
      values = values.where((o) => o.date.isAfter(since)).toList();
    }
    for (final o in values) {
      await _upsertRecord('order', o.id, {
        'id':            o.id,
        'date':          o.date.toIso8601String(),
        'totalAmount':   o.totalAmount,
        'paymentMethod': o.paymentMethod,
        'items': o.items.map((i) => {
          'productId':   i.productId,
          'productName': i.productName,
          'price':       i.price,
          'quantity':    i.quantity,
          'variant':     i.selectedVariant,
        }).toList(),
      });
    }
  }

  Future<void> _pushProducts() async {
    for (final p in HiveDatabase.productBox.values) {
      await _upsertRecord('product', p.id, {
        'id':           p.id,
        'name':         p.name,
        'barcode':      p.barcode,
        'price':        p.price,
        'stock':        p.stock,
        'category':     p.category,
        'minStockAlert': p.minStockAlert,
        'variants':     p.variants,
      });
    }
  }

  Future<void> _pushStockMovements({DateTime? since}) async {
    var values = HiveDatabase.stockMovementsBox.values.toList();
    if (since != null) {
      values = values.where((m) => m.date.isAfter(since)).toList();
    }
    for (final m in values) {
      await _upsertRecord('stock_movement', m.id, {
        'id':           m.id,
        'productId':    m.productId,
        'productName':  m.productName,
        'typeName':     m.typeName,
        'quantity':     m.quantity,
        'operatorId':   m.operatorId,
        'date':         m.date.toIso8601String(),
        'supplierId':   m.supplierId,
        'supplierName': m.supplierName,
        'orderId':      m.orderId,
        'note':         m.note,
        'unitCost':     m.unitCost,
      });
    }
  }

  Future<void> _pushCashClosures({DateTime? since}) async {
    var values = HiveDatabase.cashClosuresBox.values.toList();
    if (since != null) {
      values = values.where((c) => c.closedAt.isAfter(since)).toList();
    }
    for (final c in values) {
      await _upsertRecord('cash_closure', c.id, {
        'id':                c.id,
        'closedAt':          c.closedAt.toIso8601String(),
        'periodStart':       c.periodStart.toIso8601String(),
        'cashierId':         c.cashierId,
        'cashTotal':         c.cashTotal,
        'orangeMoneyTotal':  c.orangeMoneyTotal,
        'mtnMomoTotal':      c.mtnMomoTotal,
        'cardTotal':         c.cardTotal,
        'grandTotal':        c.grandTotal,
        'transactionCount':  c.transactionCount,
        'notes':             c.notes,
      });
    }
  }

  Future<void> _pushShop() async {
    if (HiveDatabase.shopBox.isEmpty) return;
    final shop = HiveDatabase.shopBox.values.first;
    await _upsertRecord('shop', _shopId, {
      'id':           _shopId,
      'name':         shop.name,
      'addressLine1': shop.addressLine1,
      'addressLine2': shop.addressLine2,
      'phoneNumber':  shop.phoneNumber,
      'city':         shop.city,
      'district':     shop.district,
      'shopType':     shop.shopType,
      'taxId':        shop.taxId,
    });
  }

  Future<void> _upsertRecord(
      String entityType, String id, Map<String, dynamic> payload) async {
    await _client.from(_table).upsert({
      'id':          '${_shopId}_${entityType}_$id',
      'shop_id':     _shopId,
      'entity_type': entityType,
      'payload':     payload,
    });
  }

  // ── Pull / merge ──────────────────────────────────────────────────────────

  Future<void> _mergeRecord(String type, Map<String, dynamic> payload) async {
    switch (type) {
      case 'product':
        _mergeProduct(payload);
      case 'order':
        _mergeOrder(payload);
      default:
        break;
    }
  }

  void _mergeProduct(Map<String, dynamic> p) {
    final box = HiveDatabase.productBox;
    if (!box.containsKey(p['id'])) {
      // New product from another device — merge deferred to Phase 4+
    }
  }

  void _mergeOrder(Map<String, dynamic> o) {
    // Local Hive is source of truth — full two-way merge is Phase 4+
  }
}
