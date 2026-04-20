import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:billing_app/features/billing/domain/entities/cart_item.dart';

/// Service for generating and sharing digital receipts as text or PDF.
class ReceiptShareService {
  // ─── Share as plain text (SMS, WhatsApp, etc.) ────────────────────────────
  static Future<void> shareAsText({
    required String shopName,
    required String address,
    required String phone,
    required List<CartItem> items,
    required double total,
    required String footer,
  }) async {
    final buffer = StringBuffer();
    final now = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    final currency = NumberFormat.currency(symbol: '', decimalDigits: 2);

    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln(' $shopName');
    if (address.isNotEmpty) buffer.writeln(' $address');
    if (phone.isNotEmpty) buffer.writeln(' $phone');
    buffer.writeln('  $now');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━');

    for (final item in items) {
      final lineTotal = currency.format(item.total);
      buffer.writeln(
          '${item.product.name} x${item.quantity}  →  ${lineTotal.trim()}');
    }

    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('TOTAL : ${currency.format(total).trim()}');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━');
    if (footer.isNotEmpty) buffer.writeln(footer);
    buffer.writeln('Merci pour votre achat ! ');

    await Share.share(
      buffer.toString(),
      subject: 'Reçu — $shopName',
    );
  }

  // ─── Share as PDF ──────────────────────────────────────────────────────────
  static Future<void> shareAsPdf({
    required String shopName,
    required String address,
    required String phone,
    required List<CartItem> items,
    required double total,
    required String footer,
    required BuildContext context,
  }) async {
    final pdf = pw.Document();
    // Use a monospaced font available in pdf/google_fonts
    final font = await PdfGoogleFonts.courierPrimeRegular();
    final fontBold = await PdfGoogleFonts.courierPrimeBold();
    final now = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    final currency = NumberFormat.currency(symbol: '', decimalDigits: 2);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Center(
                child: pw.Text(shopName,
                    style: pw.TextStyle(font: fontBold, fontSize: 16)),
              ),
              if (address.isNotEmpty)
                pw.Center(
                    child: pw.Text(address,
                        style: pw.TextStyle(font: font, fontSize: 9))),
              if (phone.isNotEmpty)
                pw.Center(
                    child: pw.Text('Tél: $phone',
                        style: pw.TextStyle(font: font, fontSize: 9))),
              pw.Center(
                  child: pw.Text(now,
                      style: pw.TextStyle(font: font, fontSize: 9))),
              pw.Divider(),

              // Items
              ...items.map((item) => pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(
                        child: pw.Text(
                            '${item.product.name} x${item.quantity}',
                            style: pw.TextStyle(font: font, fontSize: 10)),
                      ),
                      pw.Text(currency.format(item.total).trim(),
                          style:
                              pw.TextStyle(font: fontBold, fontSize: 10)),
                    ],
                  )),

              pw.Divider(),

              // Total
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL',
                      style: pw.TextStyle(font: fontBold, fontSize: 13)),
                  pw.Text(currency.format(total).trim(),
                      style: pw.TextStyle(font: fontBold, fontSize: 13)),
                ],
              ),

              pw.Divider(),

              // Footer
              if (footer.isNotEmpty)
                pw.Center(
                    child: pw.Text(footer,
                        style: pw.TextStyle(font: font, fontSize: 9))),
              pw.Center(
                child: pw.Text('Merci pour votre achat !',
                    style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 10,
                        color: PdfColors.grey700)),
              ),
            ],
          );
        },
      ),
    );

    // Save PDF to temp dir and share
    final pdfBytes = await pdf.save();
    final tempDir = await getTemporaryDirectory();
    final file = File(
        '${tempDir.path}/recu_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(pdfBytes);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/pdf')],
      subject: 'Reçu — $shopName',
    );
  }
}
