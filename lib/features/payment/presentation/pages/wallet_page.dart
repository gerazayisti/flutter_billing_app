import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:billing_app/core/theme/app_theme.dart';
import 'package:billing_app/core/utils/xaf_formatter.dart';
import 'package:billing_app/features/payment/domain/entities/shop_withdrawal.dart';
import 'package:billing_app/features/payment/presentation/bloc/wallet_bloc.dart';
import 'package:billing_app/features/payment/presentation/bloc/wallet_event.dart';
import 'package:billing_app/features/payment/presentation/bloc/wallet_state.dart';
import 'package:intl/intl.dart';
import 'package:billing_app/core/data/hive_database.dart';

class WalletPage extends StatelessWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Portefeuille Gestock', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
      ),
      body: BlocConsumer<WalletBloc, WalletState>(
        listenWhen: (previous, current) {
          return previous.isWithdrawing != current.isWithdrawing || 
                 previous.withdrawalSuccessMessage != current.withdrawalSuccessMessage || 
                 previous.withdrawalErrorMessage != current.withdrawalErrorMessage;
        },
        listener: (context, state) {
          if (state.withdrawalSuccessMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.withdrawalSuccessMessage!), backgroundColor: Colors.green),
            );
          }
          if (state.withdrawalErrorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.withdrawalErrorMessage!), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          return RefreshIndicator(
            onRefresh: () async {
              context.read<WalletBloc>().add(LoadWalletDataEvent());
            },
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildBalanceCard(state),
                if (state.errorMessage.isNotEmpty) _buildErrorTile(state.errorMessage),
                const SizedBox(height: 16),

                // ── Score de Crédit ─────────────────────────────────────────
                const _CreditScoreBanner(),
                const SizedBox(height: 16),

                ElevatedButton.icon(
                  onPressed: state.status == WalletStatus.loading || state.isWithdrawing
                      ? null
                      : () => _showWithdrawalDialog(context),
                  icon: const Icon(Icons.send_rounded),
                  label: const Text('RETIRER MON ARGENT'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                if (state.isWithdrawing)
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Center(child: Text("Initiation du retrait en cours...", style: TextStyle(color: Colors.grey, fontSize: 12))),
                  ),
                const SizedBox(height: 32),
                const Text('Activités récentes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                
                if (state.status == WalletStatus.loading)
                  const Center(child: CircularProgressIndicator())
                else if (state.withdrawals.isEmpty)
                  _buildEmptyState()
                else
                  ...state.withdrawals.map((w) => _buildWithdrawalItem(w)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBalanceCard(WalletState state) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('SOLDE DISPONIBLE', style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 8),
          if (state.status == WalletStatus.loading)
            const CircularProgressIndicator(color: Colors.white)
          else
            Text(XafFormatter.format(state.balance), style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildErrorTile(String errorMessage) => Text(errorMessage, style: const TextStyle(color: Colors.red, fontSize: 12));
  
  Widget _buildEmptyState() => const Center(child: Padding(
    padding: EdgeInsets.all(20.0),
    child: Text('Aucun retrait trouvé'),
  ));

  Widget _buildWithdrawalItem(ShopWithdrawal w) {
    Color statusColor;
    switch(w.status) {
      case WithdrawalStatus.completed: statusColor = Colors.green; break;
      case WithdrawalStatus.failed: statusColor = Colors.red; break;
      case WithdrawalStatus.accepted: statusColor = Colors.blue; break;
      default: statusColor = Colors.orange;
    }

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: Colors.transparent,
        child: Icon(
          w.status == WithdrawalStatus.completed ? Icons.check : Icons.access_time_rounded,
          color: statusColor,
          size: 24,
        ),
      ),
      title: Text(XafFormatter.format(w.grossAmount), style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text('Vers ${w.phoneNumber} • ${DateFormat('dd/MM HH:mm').format(w.createdAt)}'),
      trailing: Text(
        w.status == WithdrawalStatus.completed ? 'TERMINÉ' : 
        w.status == WithdrawalStatus.failed ? 'ÉCHOUÉ' : 
        w.status == WithdrawalStatus.accepted ? 'EN COURS' : 'ATTENTE',
        style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }

  void _showWithdrawalDialog(BuildContext context) {
    final amountController = TextEditingController();
    final phoneController = TextEditingController();
    final pinController = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);
    final walletBloc = context.read<WalletBloc>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (_, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
              left: 20, right: 20, top: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Nouveau Retrait',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Solde : ${XafFormatter.format(walletBloc.state.balance)}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Montant (XAF)',
                    prefixIcon: Icon(Icons.attach_money),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Téléphone (ex: 237699999999)',
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: pinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 4,
                  decoration: const InputDecoration(
                    labelText: 'Code PIN (4 chiffres)',
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    final amountText = amountController.text.trim();
                    final phoneText = phoneController.text.trim();
                    final pinText = pinController.text.trim();

                    if (amountText.isEmpty || phoneText.isEmpty || pinText.isEmpty) {
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Veuillez remplir tous les champs')),
                      );
                      return;
                    }

                    final amount = double.tryParse(amountText);
                    if (amount == null || amount <= 0) {
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Montant invalide')),
                      );
                      return;
                    }

                    if (amount > walletBloc.state.balance) {
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Solde insuffisant')),
                      );
                      return;
                    }

                    final savedPin = HiveDatabase.settingsBox.get('user_pin', defaultValue: '') as String;
                    if (pinText != savedPin) {
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Code PIN incorrect')),
                      );
                      return;
                    }

                    walletBloc.add(InitiateWithdrawalEvent(amount: amount, phoneNumber: phoneText));
                    Navigator.of(sheetCtx).pop();
                  },
                  child: const Text('CONFIRMER LE RETRAIT'),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Bannière Score de Crédit ─────────────────────────────────────────────────

class _CreditScoreBanner extends StatelessWidget {
  const _CreditScoreBanner();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/credit-score'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF1A1A2E),
              AppTheme.primaryDark.withValues(alpha: 0.85),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.credit_score_rounded,
                color: AppTheme.primaryColor, size: 30),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Score de Crédit Gestock',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                  Text('Vérifiez votre éligibilité au prêt bancaire',
                      style: TextStyle(color: Colors.white60, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white38),
          ],
        ),
      ),
    );
  }
}
