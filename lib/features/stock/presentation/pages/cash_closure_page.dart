import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:billing_app/l10n/app_localizations.dart';
import 'package:billing_app/core/utils/xaf_formatter.dart';
import 'package:billing_app/core/theme/app_theme.dart';
import 'package:billing_app/core/widgets/app_drawer.dart';
import 'package:billing_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/cash_register_closure.dart';
import '../bloc/stock_bloc.dart';

class CashClosurePage extends StatefulWidget {
  const CashClosurePage({super.key});

  @override
  State<CashClosurePage> createState() => _CashClosurePageState();
}

class _CashClosurePageState extends State<CashClosurePage> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        leading: context.canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => context.pop(),
              )
            : null,
        title: Text(l10n.cashClosure,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      drawer: const AppDrawer(),
      body: BlocConsumer<StockBloc, StockState>(
        listener: (context, state) {
          if (state.successMessage == 'closed') {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(l10n.closureSuccess),
              backgroundColor: AppTheme.primaryColor,
            ));
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _CurrentPeriodCard(state: state, l10n: l10n),
                const SizedBox(height: 16),
                _CloseButton(state: state, l10n: l10n),
                const SizedBox(height: 24),
                if (state.closures.isNotEmpty) ...[
                  Text(l10n.lastClosure.toUpperCase(),
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          letterSpacing: 1.2)),
                  const SizedBox(height: 8),
                  ...state.closures.map((c) => _ClosureTile(closure: c, l10n: l10n)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Current period summary ────────────────────────────────────────────────

class _CurrentPeriodCard extends StatelessWidget {
  final StockState state;
  final AppLocalizations l10n;

  const _CurrentPeriodCard({required this.state, required this.l10n});

  @override
  Widget build(BuildContext context) {
    // Compute live totals from orders (since last closure)
    // We rely on the stock bloc's closure logic for consistency
    final lastClosure = state.lastClosure;
    final sinceLabel = lastClosure != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(lastClosure.closedAt)
        : l10n.noClosure;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.primaryColor.withValues(alpha: 0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.cashClosureTitle,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 12, letterSpacing: 1)),
          const SizedBox(height: 4),
          Text(DateFormat('EEEE dd MMMM yyyy', 'fr').format(DateTime.now()),
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.history_rounded, color: Colors.white70, size: 14),
                const SizedBox(width: 6),
                Text('${l10n.periodFrom}: $sinceLabel',
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Close button ──────────────────────────────────────────────────────────

class _CloseButton extends StatelessWidget {
  final StockState state;
  final AppLocalizations l10n;

  const _CloseButton({required this.state, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final cashierId =
        authState is AuthAuthenticated ? authState.user.id : 'unknown';

    return ElevatedButton.icon(
      onPressed: state.isLoading
          ? null
          : () => _confirmClose(context, cashierId),
      icon: const Icon(Icons.lock_clock_rounded),
      label: Text(l10n.closeCashRegister,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  void _confirmClose(BuildContext context, String cashierId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.closeCashRegister),
        content: Text(l10n.cashClosureConfirm),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              context
                  .read<StockBloc>()
                  .add(CloseCashRegisterEvent(cashierId: cashierId));
            },
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
  }
}

// ── Past closure tile ─────────────────────────────────────────────────────

class _ClosureTile extends StatelessWidget {
  final CashRegisterClosure closure;
  final AppLocalizations l10n;

  const _ClosureTile({required this.closure, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(DateFormat('dd/MM/yyyy HH:mm').format(closure.closedAt),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('${closure.transactionCount} tx',
                    style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _row(l10n.cash, closure.cashTotal, AppTheme.primaryColor),
          if (closure.orangeMoneyTotal > 0)
            _row(l10n.orangeMoney, closure.orangeMoneyTotal, AppTheme.primaryColor),
          if (closure.mtnMomoTotal > 0)
            _row(l10n.mtnMomo, closure.mtnMomoTotal, AppTheme.primaryDark),
          if (closure.cardTotal > 0)
            _row(l10n.card, closure.cardTotal, AppTheme.textPrimary),
          const Divider(height: 12),
          _row(l10n.totalATax, closure.grandTotal, Colors.black87,
              isBold: true),
          _row(l10n.totalHTax, closure.totalHT, Colors.grey),
          _row(l10n.tvaLabel, closure.tvaAmount, Colors.grey),
        ],
      ),
    );
  }

  Widget _row(String label, double amount, Color color,
      {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  color: isBold ? Colors.black87 : Colors.grey[600],
                  fontWeight:
                      isBold ? FontWeight.bold : FontWeight.normal)),
          Text(XafFormatter.format(amount),
              style: TextStyle(
                  fontSize: 13,
                  color: color,
                  fontWeight:
                      isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}
