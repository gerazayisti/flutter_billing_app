import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:billing_app/core/theme/app_theme.dart';
import 'package:billing_app/core/theme/app_color_config.dart';
import 'package:billing_app/l10n/app_localizations.dart';

class SpotlightStep {
  final GlobalKey targetKey;
  final String title;
  final String description;
  final Alignment tooltipAlignment;

  const SpotlightStep({
    required this.targetKey,
    required this.title,
    required this.description,
    this.tooltipAlignment = Alignment.bottomCenter,
  });
}

class SpotlightTutorial {
  static OverlayEntry? _overlayEntry;

  static void show(
    BuildContext context, {
    required List<SpotlightStep> steps,
    VoidCallback? onFinished,
    VoidCallback? onSkipped,
  }) {
    // Dismiss any existing overlay first
    dismiss();

    if (steps.isEmpty) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => _SpotlightOverlayWidget(
        steps: steps,
        onFinished: () {
          dismiss();
          if (onFinished != null) onFinished();
        },
        onSkipped: () {
          dismiss();
          if (onSkipped != null) onSkipped();
        },
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  static void dismiss() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
  }

  static bool get isShowing => _overlayEntry != null;
}

class _SpotlightOverlayWidget extends StatefulWidget {
  final List<SpotlightStep> steps;
  final VoidCallback onFinished;
  final VoidCallback onSkipped;

  const _SpotlightOverlayWidget({
    required this.steps,
    required this.onFinished,
    required this.onSkipped,
  });

  @override
  State<_SpotlightOverlayWidget> createState() => _SpotlightOverlayWidgetState();
}

class _SpotlightOverlayWidgetState extends State<_SpotlightOverlayWidget>
    with SingleTickerProviderStateMixin {
  int _currentStepIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStepIndex < widget.steps.length - 1) {
      setState(() {
        _currentStepIndex++;
      });
      _animationController.reset();
      _animationController.forward();
    } else {
      widget.onFinished();
    }
  }

  void _previousStep() {
    if (_currentStepIndex > 0) {
      setState(() {
        _currentStepIndex--;
      });
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.steps[_currentStepIndex];
    final contextRef = step.targetKey.currentContext;
    final l10n = AppLocalizations.of(context)!;

    Rect targetRect = Rect.zero;
    bool hasTarget = false;

    if (contextRef != null) {
      final RenderBox? renderBox = contextRef.findRenderObject() as RenderBox?;
      if (renderBox != null && renderBox.hasSize) {
        final position = renderBox.localToGlobal(Offset.zero);
        targetRect = position & renderBox.size;
        hasTarget = true;
      }
    }

    final size = MediaQuery.of(context).size;
    final accent = AppColorConfig.accentColor;

    // Determine tooltip position
    double? tooltipTop;
    double? tooltipBottom;
    double tooltipLeft = 16.0;
    double tooltipWidth = size.width - 32.0;

    if (hasTarget) {
      // Add padding to target Rect for visual spacing
      final paddedRect = Rect.fromLTRB(
        targetRect.left - 8.0,
        targetRect.top - 8.0,
        targetRect.right + 8.0,
        targetRect.bottom + 8.0,
      );

      if (step.tooltipAlignment == Alignment.bottomCenter) {
        tooltipTop = paddedRect.bottom + 12.0;
        // Make sure it doesn't overflow bottom of the screen
        if (tooltipTop + 180 > size.height) {
          tooltipTop = null;
          tooltipBottom = size.height - paddedRect.top + 12.0;
        }
      } else {
        tooltipBottom = size.height - paddedRect.top + 12.0;
        // Make sure it doesn't overflow top of the screen
        if (tooltipBottom + 180 > size.height) {
          tooltipBottom = null;
          tooltipTop = paddedRect.bottom + 12.0;
        }
      }
    } else {
      // Center the tooltip if no target is found
      tooltipTop = (size.height - 180.0) / 2.0;
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Stack(
        children: [
          // 1. Semi-transparent blurred backdrop mask
          GestureDetector(
            onTap: () {}, // Block background touches
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
              child: CustomPaint(
                size: Size.infinite,
                painter: _SpotlightPainter(
                  targetRect: hasTarget ? targetRect : null,
                  accentColor: accent,
                ),
              ),
            ),
          ),

          // 2. Animated Floating Tooltip Card
          Positioned(
            top: tooltipTop,
            bottom: tooltipBottom,
            left: tooltipLeft,
            width: tooltipWidth,
            child: Material(
              color: Colors.transparent,
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 300),
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: 0.95 + (0.05 * scale),
                    child: child,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 25,
                        offset: const Offset(0, 10),
                      ),
                      BoxShadow(
                        color: accent.withOpacity(0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Page indicators & Close Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: accent.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              l10n.stepProgress(_currentStepIndex + 1, widget.steps.length),
                              style: TextStyle(
                                color: accent,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: widget.onSkipped,
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Text(
                                l10n.skip,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Title
                      Text(
                        step.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Description
                      Text(
                        step.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Navigation Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (_currentStepIndex > 0)
                            TextButton(
                              onPressed: _previousStep,
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.grey[600],
                              ),
                              child: Text(
                                l10n.previous,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            )
                          else
                            const SizedBox.shrink(),
                           ElevatedButton(
                            onPressed: _nextStep,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 2,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                            ),
                            child: Text(
                              _currentStepIndex == widget.steps.length - 1
                                  ? l10n.finish
                                  : l10n.next,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  final Rect? targetRect;
  final Color accentColor;

  _SpotlightPainter({this.targetRect, required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.70)
      ..style = PaintingStyle.fill;

    if (targetRect == null) {
      // Just paint the full dark overlay
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);
      return;
    }

    // Add padding to cutout rect
    final cutoutRect = Rect.fromLTRB(
      targetRect!.left - 8.0,
      targetRect!.top - 8.0,
      targetRect!.right + 8.0,
      targetRect!.bottom + 8.0,
    );

    final RRect rrect = RRect.fromRectAndRadius(cutoutRect, const Radius.circular(16));

    // Combine paths to carve a hole in the overlay mask
    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final cutoutPath = Path()..addRRect(rrect);
    final combinedPath = Path.combine(PathOperation.difference, backgroundPath, cutoutPath);

    canvas.drawPath(combinedPath, backgroundPaint);

    // Draw glowing border around the cutout
    final borderPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    // Subtle outer glow
    final glowPaint = Paint()
      ..color = accentColor.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..imageFilter = ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0);

    canvas.drawRRect(rrect, glowPaint);
    canvas.drawRRect(rrect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) {
    return oldDelegate.targetRect != targetRect || oldDelegate.accentColor != accentColor;
  }
}
