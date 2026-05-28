import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:billing_app/core/data/hive_database.dart';
import 'package:billing_app/features/product/data/models/product_model.dart';
import 'package:billing_app/features/billing/data/models/order_model.dart';
import 'package:billing_app/features/billing/data/models/order_item_model.dart';
import 'package:billing_app/features/stock/data/models/stock_movement_model.dart';
import 'package:billing_app/features/stock/data/models/cash_register_closure_model.dart';
import 'package:billing_app/features/stock/data/models/supplier_model.dart';
import 'package:billing_app/features/shop/data/models/shop_model.dart';
import 'package:billing_app/features/subscription/domain/subscription.dart';
import 'package:billing_app/core/services/subscription_service.dart';
import 'cloud_sync_service.dart';

/// Supabase implementation of [CloudSyncService].
class SupabaseSyncService implements CloudSyncService {
  static const String _table = 'gestock_sync';

  SupabaseClient get _client => Supabase.instance.client;

  // ── Public API ────────────────────────────────────────────────────────────

  @override
  bool get isConfigured => true;

  @override
  bool get isSignedIn => _client.auth.currentUser != null;

  @override
  String? get userEmail => _client.auth.currentUser?.email;

  @override
  Future<void> initialize() async {}

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
      await _pushSuppliers();
      await _pushShop();
    } catch (_) {}
    return now;
  }

  @override
  Future<void> pullAll() async {
    if (!isSignedIn) return;
    try {
      await _pullSubscription();

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

  /// Pull uniquement l'abonnement (appel léger au démarrage de l'app).
  Future<void> pullSubscriptionOnly() async {
    if (!isSignedIn) return;
    await _pullSubscription();
  }

  @override
  Future<void> deleteRecord(String entityType, String id) async {
    if (!isSignedIn) return;
    try {
      await _client
          .from(_table)
          .delete()
          .eq('id', '${_shopId}_${entityType}_$id');
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

  Future<void> _pushSuppliers() async {
    for (final s in HiveDatabase.suppliersBox.values) {
      await _upsertRecord('supplier', s.id, {
        'id':      s.id,
        'name':    s.name,
        'phone':   s.phone,
        'address': s.address,
        'notes':   s.notes,
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
      case 'stock_movement':
        _mergeStockMovement(payload);
      case 'cash_closure':
        _mergeCashClosure(payload);
      case 'supplier':
        _mergeSupplier(payload);
      case 'shop':
        _mergeShop(payload);
      default:
        break;
    }
  }

  /// Fusion produit — stock local préservé si le produit existe déjà sur cet appareil,
  /// stock cloud utilisé pour un nouvel appareil (premier login d'un employé).
  void _mergeProduct(Map<String, dynamic> p) {
    final id = p['id'] as String?;
    if (id == null || id.isEmpty) return;

    final existing = HiveDatabase.productBox.get(id);

    final model = ProductModel(
      id:            id,
      name:          p['name'] as String? ?? '',
      barcode:       p['barcode'] as String? ?? '',
      price:         (p['price'] as num?)?.toDouble() ?? 0.0,
      stock:         existing?.stock ?? (p['stock'] as num?)?.toInt() ?? 0,
      category:      p['category'] as String? ?? 'Général',
      minStockAlert: (p['minStockAlert'] as num?)?.toInt() ?? 5,
      variants:      (p['variants'] as List<dynamic>?)
                       ?.map((v) => v.toString())
                       .toList() ?? [],
    );
    HiveDatabase.productBox.put(id, model);
  }

  /// Fusion commande — mode ajout seulement (on ne remplace jamais une commande locale).
  void _mergeOrder(Map<String, dynamic> o) {
    final id = o['id'] as String?;
    if (id == null || id.isEmpty) return;
    if (HiveDatabase.orderBox.containsKey(id)) return;

    final rawItems = (o['items'] as List<dynamic>?) ?? [];
    final items = rawItems.map((i) {
      final m = i as Map<String, dynamic>;
      return OrderItemModel(
        productId:       m['productId']   as String? ?? '',
        productName:     m['productName'] as String? ?? '',
        price:           (m['price']      as num?)?.toDouble() ?? 0.0,
        quantity:        (m['quantity']   as num?)?.toInt()    ?? 1,
        selectedVariant: m['variant']     as String?,
      );
    }).toList();

    final model = OrderModel(
      id:            id,
      date:          DateTime.tryParse(o['date'] as String? ?? '') ?? DateTime.now(),
      totalAmount:   (o['totalAmount']   as num?)?.toDouble() ?? 0.0,
      paymentMethod: o['paymentMethod'] as String? ?? 'cash',
      items:         items,
    );
    HiveDatabase.orderBox.put(id, model);
  }

  /// Fusion mouvement de stock — mode ajout seulement.
  void _mergeStockMovement(Map<String, dynamic> m) {
    final id = m['id'] as String?;
    if (id == null || id.isEmpty) return;
    if (HiveDatabase.stockMovementsBox.containsKey(id)) return;

    final model = StockMovementModel(
      id:           id,
      productId:    m['productId']    as String? ?? '',
      productName:  m['productName']  as String? ?? '',
      typeName:     m['typeName']     as String? ?? 'saleOut',
      quantity:     (m['quantity']    as num?)?.toInt()    ?? 0,
      operatorId:   m['operatorId']   as String? ?? '',
      date:         DateTime.tryParse(m['date'] as String? ?? '') ?? DateTime.now(),
      supplierId:   m['supplierId']   as String?,
      supplierName: m['supplierName'] as String?,
      orderId:      m['orderId']      as String?,
      note:         m['note']         as String?,
      unitCost:     (m['unitCost']    as num?)?.toDouble(),
    );
    HiveDatabase.stockMovementsBox.put(id, model);
  }

  /// Fusion fermeture de caisse — mode ajout seulement.
  void _mergeCashClosure(Map<String, dynamic> c) {
    final id = c['id'] as String?;
    if (id == null || id.isEmpty) return;
    if (HiveDatabase.cashClosuresBox.containsKey(id)) return;

    final model = CashRegisterClosureModel(
      id:               id,
      closedAt:         DateTime.tryParse(c['closedAt']    as String? ?? '') ?? DateTime.now(),
      periodStart:      DateTime.tryParse(c['periodStart'] as String? ?? '') ?? DateTime.now(),
      cashierId:        c['cashierId']        as String? ?? '',
      cashTotal:        (c['cashTotal']       as num?)?.toDouble() ?? 0.0,
      orangeMoneyTotal: (c['orangeMoneyTotal'] as num?)?.toDouble() ?? 0.0,
      mtnMomoTotal:     (c['mtnMomoTotal']    as num?)?.toDouble() ?? 0.0,
      cardTotal:        (c['cardTotal']       as num?)?.toDouble() ?? 0.0,
      grandTotal:       (c['grandTotal']      as num?)?.toDouble() ?? 0.0,
      transactionCount: (c['transactionCount'] as num?)?.toInt() ?? 0,
      notes:            c['notes']            as String?,
    );
    HiveDatabase.cashClosuresBox.put(id, model);
  }

  /// Fusion fournisseur — mode ajout seulement (le local prime en cas de conflit).
  void _mergeSupplier(Map<String, dynamic> s) {
    final id = s['id'] as String?;
    if (id == null || id.isEmpty) return;
    if (HiveDatabase.suppliersBox.containsKey(id)) return;

    final model = SupplierModel(
      id:      id,
      name:    s['name']    as String? ?? '',
      phone:   s['phone']   as String?,
      address: s['address'] as String?,
      notes:   s['notes']   as String?,
    );
    HiveDatabase.suppliersBox.put(id, model);
  }

  /// Fusion infos boutique — met à jour Hive uniquement si le champ est non vide dans le cloud.
  /// Préserve les données locales déjà configurées.
  void _mergeShop(Map<String, dynamic> s) {
    if (HiveDatabase.shopBox.isEmpty) return;
    final existing = HiveDatabase.shopBox.values.first;

    String pick(String cloudKey, String localVal) {
      final cloudVal = s[cloudKey] as String? ?? '';
      return cloudVal.isNotEmpty ? cloudVal : localVal;
    }

    final model = ShopModel(
      name:                pick('name',         existing.name),
      addressLine1:        pick('addressLine1',  existing.addressLine1),
      addressLine2:        pick('addressLine2',  existing.addressLine2),
      phoneNumber:         pick('phoneNumber',   existing.phoneNumber),
      upiId:               existing.upiId,
      footerText:          existing.footerText,
      orangeMoneyMerchant: existing.orangeMoneyMerchant,
      mtnMomoMerchant:     existing.mtnMomoMerchant,
      city:                pick('city',         existing.city),
      district:            pick('district',     existing.district),
      shopType:            pick('shopType',     existing.shopType),
      taxId:               pick('taxId',        existing.taxId),
    );
    HiveDatabase.shopBox.putAt(0, model);
  }

  // ── Subscription pull ─────────────────────────────────────────────────────

  Future<void> _pullSubscription() async {
    try {
      final row = await _client
          .from('subscriptions')
          .select()
          .eq('shop_id', _shopId)
          .maybeSingle();

      if (row == null) return;

      final startRaw  = row['start_date']  as String?;
      final expiryRaw = row['expiry_date'] as String?;
      if (startRaw == null || expiryRaw == null) return;

      final info = SubscriptionInfo(
        tier: SubscriptionTier.values.firstWhere(
          (t) => t.name == (row['tier'] as String),
          orElse: () => SubscriptionTier.trial,
        ),
        cycle: BillingCycle.values.firstWhere(
          (c) => c.name == (row['billing_cycle'] as String? ?? 'monthly'),
          orElse: () => BillingCycle.monthly,
        ),
        startDate:          DateTime.parse(startRaw),
        expiryDate:         DateTime.parse(expiryRaw),
        freemopayReference: row['freemopay_reference'] as String?,
      );

      await SubscriptionService.save(info);
    } catch (_) {}
  }
}
