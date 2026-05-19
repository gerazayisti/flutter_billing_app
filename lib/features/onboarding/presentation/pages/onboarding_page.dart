import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:lottie/lottie.dart';
import 'package:billing_app/core/theme/app_theme.dart';
import 'package:billing_app/core/data/hive_database.dart';
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
    await HiveDatabase.settingsBox.put('has_seen_onboarding', true);
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isLast = _currentPage == 2;
    // Page 1 has colored top → skip text must be white; others have white top
    final skipColor = _currentPage == 1 ? Colors.white : AppTheme.primaryColor;

    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _currentPage = i),
            children: [
              _OnboardingSlide(
                title: l10n.onboardingTitle1.toUpperCase(),
                description: l10n.onboardingDesc1,
                lottiePath: 'assets/onboarding_1.json',
                iconData: Icons.point_of_sale_rounded,
                coloredOnTop: false,
              ),
              _OnboardingSlide(
                title: l10n.onboardingTitle2.toUpperCase(),
                description: l10n.onboardingDesc2,
                lottiePath: 'assets/onboarding_2.json',
                iconData: Icons.inventory_2_rounded,
                coloredOnTop: true,
              ),
              _OnboardingSlide(
                title: l10n.onboardingTitle3.toUpperCase(),
                description: l10n.onboardingDesc3,
                lottiePath: 'assets/onboarding_3.json',
                iconData: Icons.cloud_sync_rounded,
                coloredOnTop: false,
              ),
            ],
          ),

          // Skip button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 20,
            child: TextButton(
              onPressed: _finishOnboarding,
              child: Text(
                l10n.skip,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: skipColor,
                ),
              ),
            ),
          ),

          // Dots indicator + next/finish button
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 28,
            left: 28,
            right: 28,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SmoothPageIndicator(
                  controller: _pageController,
                  count: 3,
                  effect: ExpandingDotsEffect(
                    activeDotColor: AppTheme.primaryColor,
                    dotColor: AppTheme.primaryColor.withOpacity(0.25),
                    dotHeight: 8,
                    dotWidth: 8,
                    expansionFactor: 4,
                    spacing: 6,
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
                    elevation: 6,
                    shadowColor: AppTheme.primaryColor.withOpacity(0.45),
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
  final bool coloredOnTop;

  const _OnboardingSlide({
    required this.title,
    required this.description,
    required this.lottiePath,
    required this.iconData,
    required this.coloredOnTop,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final accent = AppTheme.primaryColor;

    return Stack(
      children: [
        Container(color: Colors.white),

        // Diagonal colored background
        CustomPaint(
          size: size,
          painter: _DiagonalPainter(
            color: accent,
            coloredOnTop: coloredOnTop,
          ),
        ),

        // Slide content
        coloredOnTop
            ? _ColoredTopContent(
                title: title,
                description: description,
                lottie: _lottie(accent),
              )
            : _WhiteTopContent(
                title: title,
                description: description,
                lottie: _lottie(accent),
              ),
      ],
    );
  }

  Widget _lottie(Color accent) {
    return Lottie.asset(
      lottiePath,
      width: 260,
      height: 260,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Container(
        width: 130,
        height: 130,
        decoration: BoxDecoration(
          color: accent.withOpacity(0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(iconData, size: 62, color: accent),
      ),
    );
  }
}

// White top, colored bottom (pages 1 & 3)
class _WhiteTopContent extends StatelessWidget {
  final String title;
  final String description;
  final Widget lottie;

  const _WhiteTopContent({
    required this.title,
    required this.description,
    required this.lottie,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Illustration in white section
        Expanded(
          flex: 55,
          child: Center(child: lottie),
        ),
        // Text in colored section
        Expanded(
          flex: 45,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 36, 28, 88),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 12),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.88),
                    height: 1.55,
                  ),
                  textAlign: TextAlign.right,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Colored top, white bottom (page 2)
class _ColoredTopContent extends StatelessWidget {
  final String title;
  final String description;
  final Widget lottie;

  const _ColoredTopContent({
    required this.title,
    required this.description,
    required this.lottie,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Text in colored section
        Expanded(
          flex: 45,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              28,
              MediaQuery.of(context).padding.top + 56,
              28,
              24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.88),
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Illustration in white section
        Expanded(
          flex: 55,
          child: Center(child: lottie),
        ),
      ],
    );
  }
}

// ─── Diagonal background painter ─────────────────────────────────────────────

class _DiagonalPainter extends CustomPainter {
  final Color color;
  final bool coloredOnTop;

  const _DiagonalPainter({required this.color, required this.coloredOnTop});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    final h = size.height;
    final w = size.width;

    if (coloredOnTop) {
      // Color covers top ~45%, diagonal slopes down from left to right
      path.moveTo(0, 0);
      path.lineTo(w, 0);
      path.lineTo(w, h * 0.40);
      path.lineTo(0, h * 0.52);
      path.close();
    } else {
      // Color covers bottom ~45%, diagonal slopes up from left to right
      path.moveTo(0, h * 0.48);
      path.lineTo(w, h * 0.40);
      path.lineTo(w, h);
      path.lineTo(0, h);
      path.close();
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_DiagonalPainter old) =>
      old.color != color || old.coloredOnTop != coloredOnTop;
}

// ─── Installation guide sheet (kept for future use) ──────────────────────────

class _InstallationGuideSheet extends StatelessWidget {
  const _InstallationGuideSheet();

  @override
  Widget build(BuildContext context) {
    final accent = AppTheme.primaryColor;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Icon(Icons.rocket_launch_rounded, color: accent, size: 28),
              const SizedBox(width: 12),
              Text(
                l10n.helpGuideTitle,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildStep(
            stepNum: '1',
            title: l10n.stepOwner1Title,
            description: l10n.stepOwner1Desc,
            icon: Icons.inventory_2_outlined,
            accent: accent,
          ),
          const SizedBox(height: 18),
          _buildStep(
            stepNum: '2',
            title: l10n.stepOwner2Title,
            description: l10n.stepOwner2Desc,
            icon: Icons.point_of_sale_rounded,
            accent: accent,
          ),
          const SizedBox(height: 18),
          _buildStep(
            stepNum: '3',
            title: l10n.stepOwner3Title,
            description: l10n.stepOwner3Desc,
            icon: Icons.print_rounded,
            accent: accent,
          ),
          const SizedBox(height: 18),
          _buildStep(
            stepNum: '4',
            title: l10n.stepOwner4Title,
            description: l10n.stepOwner4Desc,
            icon: Icons.people_outline_rounded,
            accent: accent,
          ),
        ],
      ),
    );
  }

  Widget _buildStep({
    required String stepNum,
    required String title,
    required String description,
    required IconData icon,
    required Color accent,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: accent.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            stepNum,
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
