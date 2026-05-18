enum SubscriptionTier { trial, starter, pro, business }

enum BillingCycle { monthly, yearly }

class SubscriptionInfo {
  final SubscriptionTier tier;
  final BillingCycle cycle;
  final DateTime startDate;
  final DateTime expiryDate;
  final String? freemopayReference;

  const SubscriptionInfo({
    required this.tier,
    required this.cycle,
    required this.startDate,
    required this.expiryDate,
    this.freemopayReference,
  });

  bool get isExpired => DateTime.now().isAfter(expiryDate);
  bool get isActive => !isExpired;

  int get daysRemaining {
    final d = expiryDate.difference(DateTime.now()).inDays;
    return d < 0 ? 0 : d;
  }

  Map<String, dynamic> toMap() => {
        'tier': tier.name,
        'cycle': cycle.name,
        'startDate': startDate.toIso8601String(),
        'expiryDate': expiryDate.toIso8601String(),
        'freemopayReference': freemopayReference,
      };

  factory SubscriptionInfo.fromMap(Map<String, dynamic> map) => SubscriptionInfo(
        tier: SubscriptionTier.values.firstWhere(
          (t) => t.name == map['tier'],
          orElse: () => SubscriptionTier.trial,
        ),
        cycle: BillingCycle.values.firstWhere(
          (c) => c.name == map['cycle'],
          orElse: () => BillingCycle.monthly,
        ),
        startDate: DateTime.parse(map['startDate'] as String),
        expiryDate: DateTime.parse(map['expiryDate'] as String),
        freemopayReference: map['freemopayReference'] as String?,
      );
}

// ── Plan metadata (prices, limits, pay-links) ──────────────────────────────

class PlanConfig {
  final SubscriptionTier tier;
  final int monthlyPrice;
  final int yearlyPrice;
  final String monthlyPayLink;
  final String yearlyPayLink;
  final int maxBoutiques;  // -1 = unlimited
  final int maxProducts;   // -1 = unlimited
  final int maxEmployees;  // -1 = unlimited
  final List<String> features;

  const PlanConfig({
    required this.tier,
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.monthlyPayLink,
    required this.yearlyPayLink,
    required this.maxBoutiques,
    required this.maxProducts,
    required this.maxEmployees,
    required this.features,
  });

  static const List<PlanConfig> all = [_starter, _pro, _business];

  static const _starter = PlanConfig(
    tier: SubscriptionTier.starter,
    monthlyPrice: 1500,
    yearlyPrice: 13000,
    monthlyPayLink:
        'https://business.freemopay.com/pay-link/3bcd23b713e9ec8f19411c6095525d',
    yearlyPayLink:
        'https://business.freemopay.com/pay-link/cab2ac95c6063e094194479258b534',
    maxBoutiques: 1,
    maxProducts: 100,
    maxEmployees: 2,
    features: [
      'rapports_daily',
      'pos',
      'stock',
    ],
  );

  static const _pro = PlanConfig(
    tier: SubscriptionTier.pro,
    monthlyPrice: 3500,
    yearlyPrice: 35000,
    monthlyPayLink:
        'https://business.freemopay.com/pay-link/291134fa9f453dd8e420e5a4ff40ac',
    yearlyPayLink:
        'https://business.freemopay.com/pay-link/27b1282a2bbb6a3f1ab8a0f12c15e6',
    maxBoutiques: 3,
    maxProducts: 500,
    maxEmployees: 10,
    features: [
      'rapports_daily',
      'rapports_pdf',
      'cloud_sync',
      'multi_boutiques',
      'momo_api',
      'pos',
      'stock',
    ],
  );

  static const _business = PlanConfig(
    tier: SubscriptionTier.business,
    monthlyPrice: 15000,
    yearlyPrice: 165000,
    monthlyPayLink:
        'https://business.freemopay.com/pay-link/d43fb1dabda88266f9a8a4dd99acb6',
    yearlyPayLink:
        'https://business.freemopay.com/pay-link/63c0fdd1b47df54316a8816d997a35',
    maxBoutiques: -1,
    maxProducts: -1,
    maxEmployees: -1,
    features: [
      'rapports_daily',
      'rapports_pdf',
      'cloud_sync',
      'multi_boutiques',
      'momo_api',
      'support_prioritaire',
      'custom_features',
      'pos',
      'stock',
    ],
  );

  bool hasFeature(String feature) => features.contains(feature);
}
