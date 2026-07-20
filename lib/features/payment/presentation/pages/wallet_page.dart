import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:billing_app/core/theme/app_theme.dart';
import 'package:billing_app/core/data/hive_database.dart';
import 'package:billing_app/core/service_locator.dart' as di;
import 'package:billing_app/core/utils/xaf_formatter.dart';
import 'package:billing_app/features/payment/domain/entities/shop_withdrawal.dart';
import 'package:billing_app/features/payment/domain/repositories/payment_repository.dart';
import 'package:intl/intl.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  bool _isLoading = true;
  double _balance = 0.0;
  String _errorMessage = '';
  String _shopIdDebug = '';
  List<ShopWithdrawal> _withdrawals = [];
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _fetchBalance();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _checkPendingWithdrawals();
    });
  }

  Future<void> _checkPendingWithdrawals() async {
    final pending = _withdrawals.where((w) =>
      w.status == WithdrawalStatus.pending || w.status == WithdrawalStatus.accepted
    ).toList();

    if (pending.isEmpty) return;

    final repository = di.sl<PaymentRepository>();
    bool hasChanged = false;

    for (var w in pending) {
      try {
        final updated = await repository.checkPawaPayPayoutStatus(w.payoutId);
        if (updated.status != w.status) {
          hasChanged = true;
        }
      } catch (e) {
        debugPrint('Polling error: $e');
      }
    }

    if (hasChanged && mounted) {
      _fetchBalance();
    }
  }

  void _loadLocalWithdrawals() {
    final items = HiveDatabase.shopWithdrawalsBox.values
        .map((m) => m.toEntity())
        .toList();
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    setState(() {
      _withdrawals = items;
    });
  }

  Future<void> _fetchBalance() async {
    setState(() { _isLoading = true; });
    try {
      final s = HiveDatabase.settingsBox;
      var shopId = s.get('cloud_shop_id', defaultValue: '') as String;
      
      if (shopId.isEmpty) {
        final shop = HiveDatabase.shopBox.values.isNotEmpty ? HiveDatabase.shopBox.values.first : null;
        shopId = shop != null ? shop.name.toLowerCase().replaceAll(RegExp(r'\s+'), '_') : 'default_shop';
      }

      final resp = await Supabase.instance.client.functions.invoke(
        'pawapay-get-balance',
        body: {'shopId': shopId},
      );

      if (resp.status == 200) {
        final data = resp.data as Map<String, dynamic>;
        _balance = (data['balance'] as num? ?? 0).toDouble();
        _shopIdDebug = data['shop_id'] as String? ?? shopId;
        if (data['shop_id'] != null) s.put('cloud_shop_id', data['shop_id']);
      }

      // Synchronisation de l'historique
      final localShopName = HiveDatabase.shopBox.values.isNotEmpty 
          ? HiveDatabase.shopBox.values.first.name.toLowerCase().replaceAll(RegExp(r'\s+'), '_') 
          : 'default_shop';

      final query = Supabase.instance.client
          .from('shop_withdrawals')
          .select();
      
      // On filtre soit par l'ID cloud (UUID), soit par le slug local (shop_id peut être l'un ou l'autre)
      final List<dynamic> remoteData = await query
          .or('shop_id.eq.$_shopIdDebug,shop_id.eq.$shopId,shop_id.eq.$localShopName')
          .order('created_at', ascending: false);

      setState(() {
        _withdrawals = remoteData.map((json) => ShopWithdrawal(
          payoutId: json['payout_id'] ?? '',
          shopId: json['shop_id'] ?? '',
          phoneNumber: json['phone_number'] ?? '',
          provider: json['provider'] ?? '',
          grossAmount: (json['gross_amount'] as num? ?? 0).toDouble(),
          feeAmount: (json['fee_amount'] as num? ?? 0).toDouble(),
          netAmount: (json['net_amount'] as num? ?? 0).toDouble(),
          status: _mapStatus(json['status']),
          createdAt: DateTime.parse(json['created_at']),
        )).toList();
        _isLoading = false;
        _errorMessage = '';
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Erreur synchro : $e";
        _isLoading = false;
      });
      _loadLocalWithdrawals();
    }
  }

  WithdrawalStatus _mapStatus(String? status) {
    switch (status?.toUpperCase()) {
      case 'COMPLETED': return WithdrawalStatus.completed;
      case 'ACCEPTED': return WithdrawalStatus.accepted;
      case 'FAILED': return WithdrawalStatus.failed;
      default: return WithdrawalStatus.pending;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Portefeuille Gestock', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => context.pop()),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchBalance,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildBalanceCard(),
            if (_errorMessage.isNotEmpty) _buildErrorTile(),
            const SizedBox(height: 16),

            // ── Score de Crédit ─────────────────────────────────────────
            _CreditScoreBanner(),
            const SizedBox(height: 16),

            ElevatedButton.icon(
              onPressed: () => _showWithdrawalDialog(context),
              icon: const Icon(Icons.send_rounded),
              label: const Text('RETIRER MON ARGENT'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 32),
            const Text('Activités récentes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (_withdrawals.isEmpty && !_isLoading) _buildEmptyState(),
            ..._withdrawals.map((w) => _buildWithdrawalItem(w)),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
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
          Text(XafFormatter.format(_balance), style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildErrorTile() => Text(_errorMessage, style: const TextStyle(color: Colors.red, fontSize: 12));
  Widget _buildEmptyState() => const Center(child: Text('Aucun retrait trouvé'));

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

  void _showWithdrawalDialog(BuildContext pageContext) {
    final amountController = TextEditingController();
    final phoneController = TextEditingController();

    // ⚠️ Déclaré ICI pour persister entre les rebuilds du StatefulBuilder
    bool isSubmitting = false;
    StateSetter? _setState;

    // Capturer le messenger de la PAGE (reste valide après fermeture du bottom sheet)
    final messenger = ScaffoldMessenger.of(pageContext);

    showModalBottomSheet(
      context: pageContext,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (_, setModalState) {
          _setState = setModalState; // lier le setter pour l'utiliser hors builder

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
                  'Solde : ${XafFormatter.format(_balance)}',
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
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final amountText = amountController.text.trim();
                          final phoneText = phoneController.text.trim();

                          if (amountText.isEmpty || phoneText.isEmpty) {
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

                          if (amount > _balance) {
                            messenger.showSnackBar(
                              const SnackBar(content: Text('Solde insuffisant')),
                            );
                            return;
                          }

                          _setState?.call(() => isSubmitting = true);

                          try {
                            debugPrint('🔄 Retrait shopId=$_shopIdDebug amount=$amount phone=$phoneText');
                            await di.sl<PaymentRepository>().initiatePawaPayPayout(
                              shopId: _shopIdDebug,
                              amountRequested: amount,
                              phoneNumberRaw: phoneText,
                            );
                            debugPrint('✅ Retrait initié avec succès');

                            // Fermer le bottom sheet via le contexte de la page
                            Navigator.of(pageContext).pop();

                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('✅ Retrait initié avec succès !'),
                                backgroundColor: Colors.green,
                                duration: Duration(seconds: 4),
                              ),
                            );
                            _fetchBalance();
                          } catch (e, stack) {
                            debugPrint('❌ Erreur retrait: $e\n$stack');
                            _setState?.call(() => isSubmitting = false);
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('❌ Erreur: $e'),
                                backgroundColor: Colors.red,
                                duration: const Duration(seconds: 6),
                              ),
                            );
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          height: 22, width: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text('CONFIRMER LE RETRAIT'),
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
              AppTheme.primaryDark.withOpacity(0.85),
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
