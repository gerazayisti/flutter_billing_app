/// Abstract contract for onboarding state persistence.
/// The Domain layer depends on this interface, NOT on any concrete implementation.
abstract class OnboardingRepository {
  /// Returns [true] if the user has already completed the onboarding flow.
  Future<bool> hasSeenOnboarding();

  /// Marks the onboarding as completed so it is never shown again.
  Future<void> completeOnboarding();
}
