import 'package:billing_app/core/data/hive_database.dart';
import '../../domain/repositories/onboarding_repository.dart';

/// Implémentation concrète du [OnboardingRepository] via HiveDatabase.
/// C'est la SEULE classe qui connaît Hive dans cette feature.
class OnboardingRepositoryImpl implements OnboardingRepository {
  static const _key = 'has_seen_onboarding';

  @override
  Future<bool> hasSeenOnboarding() async {
    // La valeur est stockée comme `true` quand l'onboarding est terminé.
    final value = HiveDatabase.settingsBox.get(_key, defaultValue: false);
    return value == true;
  }

  @override
  Future<void> completeOnboarding() async {
    await HiveDatabase.settingsBox.put(_key, true);
  }
}
