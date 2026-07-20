
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import 'package:billing_app/core/theme/app_theme.dart';
import 'package:billing_app/core/service_locator.dart' as di;
import 'package:billing_app/features/onboarding/domain/usecases/onboarding_usecases.dart';
import 'package:billing_app/l10n/app_localizations.dart';


class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _finishOnboarding() async {
    await di.sl<CompleteOnboardingUseCase>().call();
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isLast = _currentPage == 3;


    return Scaffold(
      backgroundColor: const Color(0xFF09090E),
      body: Stack(
        children: [
          // ── Slide Content ──────────────────────────────────────────────────
          PageView(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _currentPage = i),
            children: [
              _OnboardingSlide(
                title: l10n.onboardingTitle1,
                description: l10n.onboardingDesc1,
                lottiePath: 'assets/onboarding_1.json',
                iconData: Icons.point_of_sale_rounded,
                bgImagePath: 'assets/onboarding_bg_1.png',
              ),
              _OnboardingSlide(
                title: l10n.onboardingTitle2,
                description: l10n.onboardingDesc2,
                lottiePath: 'assets/onboarding_2.json',
                iconData: Icons.inventory_2_rounded,
                bgImagePath: 'assets/onboarding_bg_2.png',
              ),
              _OnboardingSlide(
                title: l10n.onboardingTitle3,
                description: l10n.onboardingDesc3,
                lottiePath: 'assets/onboarding_3.json',
                iconData: Icons.cloud_sync_rounded,
                bgImagePath: 'assets/onboarding_bg_3.png',
              ),
              _OnboardingSlide(
                title: l10n.onboardingTitle4,
                description: l10n.onboardingDesc4,
                lottiePath: '',
                iconData: Icons.phone_android_rounded,
                bgImagePath: 'assets/onboarding_bg_4.png',
              ),
            ],
          ),

          // ── Skip button ────────────────────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 20,
            child: TextButton(
              onPressed: _finishOnboarding,
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.06),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1),
                ),
              ),
              child: Text(
                l10n.skip,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          // ── Dots indicator + next/finish button ───────────────────────────
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 28,
            left: 28,
            right: 28,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SmoothPageIndicator(
                  controller: _pageController,
                  count: 4,
                  effect: ExpandingDotsEffect(
                    activeDotColor: AppTheme.primaryColor,
                    dotColor: Colors.white.withValues(alpha: 0.2),
                    dotHeight: 8,
                    dotWidth: 8,
                    expansionFactor: 4,
                    spacing: 8,
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (isLast) {
                      _finishOnboarding();
                    } else {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(16),
                    backgroundColor: AppTheme.primaryColor,
                    elevation: 8,
                    shadowColor: AppTheme.primaryColor.withValues(alpha: 0.4),
                  ),
                  child: Icon(
                    isLast ? Icons.check_rounded : Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Slide ────────────────────────────────────────────────────────────────────

class _OnboardingSlide extends StatelessWidget {
  final String title;
  final String description;
  final String lottiePath;
  final IconData iconData;
  final String bgImagePath;

  const _OnboardingSlide({
    required this.title,
    required this.description,
    required this.lottiePath,
    required this.iconData,
    required this.bgImagePath,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Stack(
      children: [
        // ── Background Image — full screen ─────────────────────────────────
        Positioned.fill(
          child: Image.asset(
            bgImagePath,
            fit: BoxFit.cover,
          ),
        ),
        // ── Soft dark overlay at 15% ───────────────────────────────────────
        Positioned.fill(
          child: Container(
            color: Colors.black.withValues(alpha: 0.15),
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.50, 0.90, 1.0],
                colors: [
                  Colors.transparent,
                  Colors.transparent,
                  Color(0xBB09090E),
                  Color(0xFF09090E),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: size.height * 0.30,
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, 0, 24, bottomPad + 90),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.70),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}


