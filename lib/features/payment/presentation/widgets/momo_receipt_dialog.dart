import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:billing_app/core/theme/app_theme.dart';
import 'package:billing_app/core/data/hive_database.dart';
import 'package:billing_app/core/utils/printer_helper.dart';
import 'package:billing_app/l10n/app_localizations.dart';

class MomoReceiptDialog extends StatefulWidget {
  final String depositId;
  final double amount;
  final String phoneNumber;
  final String provider;
  final List<Map<String, dynamic>>? items;

  const MomoReceiptDialog({
    required this.depositId,
    required this.amount,
    required this.phoneNumber,
    required this.provider,
    this.items,
    super.key,
  });

  static Future<void> show(
    BuildContext context, {
    required String depositId,
    required double amount,
    required String phoneNumber,
    required String provider,
    List<Map<String, dynamic>>? items,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => MomoReceiptDialog(
        depositId: depositId,
        amount: amount,
        phoneNumber: phoneNumber,
        provider: provider,
        items: items,
      ),
    );
  }

  @override
  State<MomoReceiptDialog> createState() => _MomoReceiptDialogState();
}

class _MomoReceiptDialogState extends State<MomoReceiptDialog> {
  final GlobalKey _repaintKey = GlobalKey();
  bool _isSavingImage = false;
  bool _isPrinting = false;

  String get _shopName {
    final shopBox = HiveDatabase.shopBox;
    return shopBox.values.isNotEmpty ? shopBox.values.first.name : 'Gestock+ Store';
  }

  String get _shopAddress {
    final shopBox = HiveDatabase.shopBox;
    return shopBox.values.isNotEmpty ? shopBox.values.first.addressLine1 : '';
  }

  String get _shopPhone {
    final shopBox = HiveDatabase.shopBox;
    return shopBox.values.isNotEmpty ? shopBox.values.first.phoneNumber : '';
  }

  String get _shopFooter {
    final shopBox = HiveDatabase.shopBox;
    return shopBox.values.isNotEmpty ? shopBox.values.first.footerText : 'Merci pour votre paiement !';
  }

  Future<void> _saveAsImage() async {
    setState(() => _isSavingImage = true);
    try {
      final boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final pngBytes = byteData.buffer.asUint8List();

      final dir = await getApplicationDocumentsDirectory();
      final timeStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filePath = '${dir.path}/recu_momo_$timeStr.png';
      final file = File(filePath);
      await file.writeAsBytes(pngBytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('📸 Reçu enregistré sous : recu_momo_$timeStr.png'),
          backgroundColor: AppTheme.primaryColor,
          duration: const Duration(seconds: 4),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur d\'enregistrement image : $e'),
          backgroundColor: AppTheme.errorColor,
        ));
      }
    } finally {
      if (mounted) setState(() => _isSavingImage = false);
    }
  }

  Future<void> _printReceipt() async {
    setState(() => _isPrinting = true);
    try {
      final l10n = AppLocalizations.of(context)!;
      final printer = PrinterHelper();
      if (!printer.isConnected) {
        final devices = await printer.getBondedDevices();
        if (devices.isNotEmpty) {
          await printer.connect(devices.first.macAdress);
        }
      }

      await printer.printReceipt(
        shopName: _shopName,
        address1: _shopAddress,
        address2: 'Réf MoMo: ${widget.depositId.substring(0, widget.depositId.length > 8 ? 8 : widget.depositId.length)}',
        phone: widget.phoneNumber,
        items: widget.items ?? [
          {'name': 'Paiement Mobile Money (${widget.provider})', 'quantity': 1, 'price': widget.amount, 'total': widget.amount}
        ],
        total: widget.amount,
        footer: _shopFooter,
        l10n: l10n,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('🖨️ Impression du reçu Mobile Money envoyée à l\'imprimante !'),
          backgroundColor: AppTheme.primaryColor,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur d\'impression : $e'),
          backgroundColor: AppTheme.errorColor,
        ));
      }
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nowStr = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    final fmtAmount = NumberFormat('#,###', 'fr_FR').format(widget.amount).replaceAll(',', ' ');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Boundary for image capturing
              RepaintBoundary(
                key: _repaintKey,
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Header Logo / Name
                      const Icon(Icons.check_circle, color: AppTheme.primaryColor, size: 48),
                      const SizedBox(height: 8),
                      Text(
                        _shopName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        textAlign: TextAlign.center,
                      ),
                      if (_shopAddress.isNotEmpty)
                        Text(_shopAddress, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                      if (_shopPhone.isNotEmpty)
                        Text('Tél: $_shopPhone', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                      const SizedBox(height: 12),
                      const Divider(),

                      // Title
                      const Text(
                        'REÇU DE PAIEMENT MOBILE MONEY',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),

                      // Ref & Date
                      _rowInfo('Date & Heure', nowStr),
                      _rowInfo('Réf. Transaction', widget.depositId),
                      _rowInfo('Opérateur', widget.provider),
                      _rowInfo('Téléphone Client', widget.phoneNumber),
                      _rowInfo('Statut', 'PAIEMENT EFFECTUÉ', isSuccess: true),

                      const Divider(height: 24),

                      // Montant Total
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('MONTANT PAYÉ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          Text('$fmtAmount FCFA',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primaryColor)),
                        ],
                      ),

                      const SizedBox(height: 16),
                      Text(
                        _shopFooter,
                        style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppTheme.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isSavingImage ? null : _saveAsImage,
                      icon: _isSavingImage
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.image_rounded, size: 18),
                      label: const Text('Sauver Image', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isPrinting ? null : _printReceipt,
                      icon: _isPrinting
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.print_rounded, size: 18, color: Colors.white),
                      label: const Text('Imprimer', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fermer / Continuer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rowInfo(String label, String value, {bool isSuccess = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSuccess ? AppTheme.primaryColor : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
