import '../repositories/onboarding_repository.dart';

/// Use case: vérifie si l'utilisateur a déjà vu l'onboarding.
class HasSeenOnboardingUseCase {
  final OnboardingRepository repository;
  const HasSeenOnboardingUseCase(this.repository);

  Future<bool> call() => repository.hasSeenOnboarding();
}

/// Use case: marque l'onboarding comme terminé.
class CompleteOnboardingUseCase {
  final OnboardingRepository repository;
  const CompleteOnboardingUseCase(this.repository);

  Future<void> call() => repository.completeOnboarding();
}
