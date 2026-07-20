import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:billing_app/core/theme/app_theme.dart';
import 'package:billing_app/core/data/hive_database.dart';
import 'package:billing_app/core/utils/xaf_formatter.dart';

// ─── Modèle de score ────────────────────────────────────────────────────────

class CreditScoreResult {
  final int score;
  final int maxScore;
  final String eligibilityLevel; // HIGH, MEDIUM, LOW
  final String eligibilityLabel;
  final String eligibilityColor;
  final double maxLoanAmount;
  final List<ScoreBreakdownItem> breakdown;
  final Map<String, dynamic> stats;

  const CreditScoreResult({
    required this.score,
    required this.maxScore,
    required this.eligibilityLevel,
    required this.eligibilityLabel,
    required this.eligibilityColor,
    required this.maxLoanAmount,
    required this.breakdown,
    required this.stats,
  });

  factory CreditScoreResult.fromJson(Map<String, dynamic> json) {
    return CreditScoreResult(
      score: json['score'] as int,
      maxScore: json['maxScore'] as int,
      eligibilityLevel: json['eligibilityLevel'] as String,
      eligibilityLabel: json['eligibilityLabel'] as String,
      eligibilityColor: json['eligibilityColor'] as String,
      maxLoanAmount: (json['maxLoanAmount'] as num).toDouble(),
      breakdown: (json['breakdown'] as List)
          .map((b) => ScoreBreakdownItem.fromJson(b))
          .toList(),
      stats: json['stats'] as Map<String, dynamic>,
    );
  }
}

class ScoreBreakdownItem {
  final String label;
  final int points;
  final int earned;
  final bool achieved;

  const ScoreBreakdownItem({
    required this.label,
    required this.points,
    required this.earned,
    required this.achieved,
  });

  factory ScoreBreakdownItem.fromJson(Map<String, dynamic> json) {
    return ScoreBreakdownItem(
      label: json['label'] as String,
      points: json['points'] as int,
      earned: json['earned'] as int,
      achieved: json['achieved'] as bool,
    );
  }
}

// ─── Page principale ─────────────────────────────────────────────────────────

class CreditScorePage extends StatefulWidget {
  const CreditScorePage({super.key});

  @override
  State<CreditScorePage> createState() => _CreditScorePageState();
}

class _CreditScorePageState extends State<CreditScorePage>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  String _error = '';
  CreditScoreResult? _result;

  late AnimationController _scoreController;
  late Animation<double> _scoreAnim;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    _scoreController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);

    _fetchScore();
  }

  @override
  void dispose() {
    _scoreController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _fetchScore() async {
    setState(() { _isLoading = true; _error = ''; });
    try {
      final s = HiveDatabase.settingsBox;
      final shopId = s.get('cloud_shop_id', defaultValue: '') as String;
      final registeredAt = s.get('registered_at', defaultValue: '') as String;

      final resp = await Supabase.instance.client.functions.invoke(
        'calculate-credit-score',
        body: {
          'shopId': shopId.isNotEmpty ? shopId : 'default_shop',
          if (registeredAt.isNotEmpty) 'registeredAt': registeredAt,
        },
      );

      if (resp.status != 200) throw Exception('Erreur serveur');

      final result = CreditScoreResult.fromJson(resp.data as Map<String, dynamic>);

      _scoreAnim = Tween<double>(begin: 0, end: result.score / result.maxScore)
          .animate(CurvedAnimation(parent: _scoreController, curve: Curves.easeOutCubic));

      setState(() {
        _result = result;
        _isLoading = false;
      });

      _scoreController.forward();
      _fadeController.forward();
    } catch (e) {
      setState(() {
        _error = 'Impossible de calculer le score : $e';
        _isLoading = false;
      });
    }
  }

  Color _eligibilityColor() {
    if (_result == null) return Colors.grey;
    switch (_result!.eligibilityLevel) {
      case 'HIGH':
      case 'MEDIUM':
        return AppTheme.primaryColor;
      default:
        return AppTheme.errorColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F12),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F12),
        elevation: 0,
        title: const Text('Score de Crédit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchScore,
            tooltip: 'Recalculer',
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoading()
          : _error.isNotEmpty
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildLoading() => const Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(color: AppTheme.primaryColor),
        SizedBox(height: 16),
        Text('Analyse de votre activité en cours…',
            style: TextStyle(color: Colors.white70)),
      ],
    ),
  );

  Widget _buildError() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppTheme.errorColor),
          const SizedBox(height: 16),
          Text(_error, textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _fetchScore,
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    ),
  );

  Widget _buildContent() {
    final result = _result!;
    final color = _eligibilityColor();

    return FadeTransition(
      opacity: _fadeAnim,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Carte score principale ──────────────────────────────────
          _ScoreGaugeCard(
            scoreAnimation: _scoreAnim,
            scoreController: _scoreController,
            result: result,
            color: color,
          ),
          const SizedBox(height: 24),

          // ── Badge éligibilité ───────────────────────────────────────
          _EligibilityBanner(result: result, color: color),
          const SizedBox(height: 24),

          // ── Statistiques rapides ────────────────────────────────────
          _StatsRow(result: result),
          const SizedBox(height: 24),

          // ── Détail du score ─────────────────────────────────────────
          // ── Détail du score ─────────────────────────────────────────
          Text('Détail de votre score',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                  color: Colors.white.withOpacity(0.9))),
          const SizedBox(height: 12),
          ...result.breakdown.map((item) => _BreakdownTile(item: item)),
          const SizedBox(height: 24),

          // ── Comment améliorer ───────────────────────────────────────
          if (result.eligibilityLevel != 'HIGH') ...[
            _ImprovementCard(result: result),
            const SizedBox(height: 24),
          ],

          // ── CTA Prêt ────────────────────────────────────────────────
          if (result.eligibilityLevel != 'LOW')
            _LoanCTAButton(result: result, color: color),

          const SizedBox(height: 8),
          Center(
            child: Text(
              'Score calculé sur la base de votre activité Gestock+\nMis à jour en temps réel',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.35)),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─── Widgets composants ───────────────────────────────────────────────────────

class _ScoreGaugeCard extends StatelessWidget {
  final Animation<double> scoreAnimation;
  final AnimationController scoreController;
  final CreditScoreResult result;
  final Color color;

  const _ScoreGaugeCard({
    required this.scoreAnimation,
    required this.scoreController,
    required this.result,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A1A2E),
            Color.lerp(const Color(0xFF1A1A2E), color, 0.4)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'VOTRE SCORE GESTOCK',
            style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 2),
          ),
          const SizedBox(height: 20),
          AnimatedBuilder(
            animation: scoreAnimation,
            builder: (_, __) => CustomPaint(
              size: const Size(180, 180),
              painter: _GaugePainter(
                progress: scoreAnimation.value,
                color: color,
                score: (scoreAnimation.value * result.maxScore).round(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            result.eligibilityLabel,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (result.maxLoanAmount > 0) ...[
            const SizedBox(height: 4),
            Text(
              'Jusqu\'à ${XafFormatter.format(result.maxLoanAmount)}',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double progress;
  final Color color;
  final int score;

  _GaugePainter({required this.progress, required this.color, required this.score});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 16;
    const startAngle = pi * 0.75;
    const sweepTotal = pi * 1.5;

    // Track
    final trackPaint = Paint()
      ..color = Colors.white12
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle, sweepTotal, false, trackPaint,
    );

    // Progress
    final progressPaint = Paint()
      ..shader = SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + sweepTotal,
        colors: [color.withOpacity(0.6), color],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle, sweepTotal * progress, false, progressPaint,
    );

    // Score text
    final textPainter = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$score',
            style: TextStyle(
              color: color,
              fontSize: 48,
              fontWeight: FontWeight.w900,
            ),
          ),
          const TextSpan(
            text: '\n/100',
            style: TextStyle(color: Colors.white38, fontSize: 14),
          ),
        ],
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(_GaugePainter old) => old.progress != progress;
}

class _EligibilityBanner extends StatelessWidget {
  final CreditScoreResult result;
  final Color color;
  const _EligibilityBanner({required this.result, required this.color});

  @override
  Widget build(BuildContext context) {
    final icon = result.eligibilityLevel == 'HIGH'
        ? Icons.verified_rounded
        : result.eligibilityLevel == 'MEDIUM'
            ? Icons.info_outline_rounded
            : Icons.lock_outline_rounded;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(result.eligibilityLabel,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                if (result.maxLoanAmount > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Montant de prêt disponible : ${XafFormatter.format(result.maxLoanAmount)}',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final CreditScoreResult result;
  const _StatsRow({required this.result});

  @override
  Widget build(BuildContext context) {
    final stats = result.stats;
    return Row(
      children: [
        _StatChip(
          icon: Icons.shopping_bag_outlined,
          value: '${stats['salesCountThisMonth']}',
          label: 'ventes/mois',
          color: AppTheme.primaryColor,
        ),
        const SizedBox(width: 8),
        _StatChip(
          icon: Icons.account_balance_wallet_outlined,
          value: '${XafFormatter.format((stats['volumeThisMonth'] as num).toDouble())}',
          label: 'volume',
          color: const Color(0xFF0891B2),
        ),
        const SizedBox(width: 8),
        _StatChip(
          icon: Icons.send_rounded,
          value: '${stats['withdrawalCount']}',
          label: 'retraits',
          color: const Color(0xFF7C3AED),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _StatChip({required this.icon, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(value,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(fontSize: 9, color: Colors.white38, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _BreakdownTile extends StatelessWidget {
  final ScoreBreakdownItem item;
  const _BreakdownTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final color = item.achieved ? AppTheme.primaryColor : const Color(0xFF9CA3AF);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Icon(
            item.achieved ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(item.label,
                style: TextStyle(
                    fontSize: 13,
                    color: item.achieved ? Colors.white : Colors.white54)),
          ),
          Text(
            '+${item.earned}/${item.points} pts',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: item.achieved ? AppTheme.primaryColor : Colors.white38),
          ),
        ],
      ),
    );
  }
}

class _ImprovementCard extends StatelessWidget {
  final CreditScoreResult result;
  const _ImprovementCard({required this.result});

  List<String> get _tips {
    final tips = <String>[];
    for (final item in result.breakdown) {
      if (!item.achieved) {
        if (item.label.contains('vente')) tips.add('Augmentez vos ventes Mobile Money ce mois');
        if (item.label.contains('Volume')) tips.add('Atteignez 50 000 XAF de volume mensuel');
        if (item.label.contains('mois')) tips.add('Continuez à utiliser Gestock+ régulièrement');
        if (item.label.contains('retrait')) tips.add('Effectuez au moins 1 retrait sur 3 mois');
        if (item.label.contains('échoué')) tips.add('Réduisez les paiements échoués de vos clients');
      }
    }
    return tips.take(3).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_tips.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tips_and_updates_rounded, color: AppTheme.primaryColor, size: 18),
              const SizedBox(width: 8),
              Text('Comment améliorer votre score',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 13)),
            ],
          ),
          const SizedBox(height: 10),
          ..._tips.map((tip) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ',
                        style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                    Expanded(
                      child: Text(tip,
                          style: const TextStyle(fontSize: 12, color: Colors.white70)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _LoanCTAButton extends StatelessWidget {
  final CreditScoreResult result;
  final Color color;
  const _LoanCTAButton({required this.result, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: const Row(
                  children: [
                    Icon(Icons.account_balance, color: AppTheme.primaryColor),
                    SizedBox(width: 8),
                    Text('Demande de prêt'),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Votre score : ${result.score}/100'),
                    const SizedBox(height: 4),
                    Text('Montant max : ${XafFormatter.format(result.maxLoanAmount)}'),
                    const SizedBox(height: 16),
                    const Text(
                      'Un rapport de votre activité Gestock+ sera généré et transmis à notre partenaire bancaire (Afriland First Bank / UBA).',
                      style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '⚠️ Fonctionnalité disponible bientôt — Partenariats bancaires en cours.',
                      style: TextStyle(fontSize: 12, color: AppTheme.textDisabled, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Fermer'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Être notifié'),
                  ),
                ],
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          icon: const Icon(Icons.account_balance_rounded),
          label: const Text(
            'DEMANDER UN PRÊT BANCAIRE',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
