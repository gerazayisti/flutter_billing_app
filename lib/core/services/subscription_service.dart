import '../data/hive_database.dart';
import '../../features/subscription/domain/subscription.dart';

class SubscriptionService {
  static const _subKey = 'subscription_info';
  static const _trialKey = 'subscription_trial_start';

  // ── Read ──────────────────────────────────────────────────────────────────

  static SubscriptionInfo? get current {
    final raw = HiveDatabase.settingsBox.get(_subKey);
    if (raw == null) return null;
    try {
      return SubscriptionInfo.fromMap(Map<String, dynamic>.from(raw as Map));
    } catch (_) {
      return null;
    }
  }

  static SubscriptionTier get activeTier {
    final sub = current;
    if (sub != null && sub.isActive) return sub.tier;
    // Trial period gives full Pro access for 30 days
    if (isTrialActive) return SubscriptionTier.pro;
    return SubscriptionTier.trial;
  }

  // Returns days left in trial (0–30). Starts counting on first call.
  static int get trialDaysRemaining {
    final startRaw = HiveDatabase.settingsBox.get(_trialKey);
    if (startRaw == null) {
      HiveDatabase.settingsBox.put(_trialKey, DateTime.now().toIso8601String());
      return 30;
    }
    final start = DateTime.parse(startRaw as String);
    final remaining =
        start.add(const Duration(days: 30)).difference(DateTime.now()).inDays;
    return remaining < 0 ? 0 : remaining;
  }

  static bool get isTrialActive => trialDaysRemaining > 0;

  static bool get hasActiveSubscription {
    final sub = current;
    return sub != null && sub.isActive;
  }

  // ── Write ─────────────────────────────────────────────────────────────────

  static Future<void> save(SubscriptionInfo info) async {
    await HiveDatabase.settingsBox.put(_subKey, info.toMap());
  }

  static Future<void> clear() async {
    await HiveDatabase.settingsBox.delete(_subKey);
  }
}
