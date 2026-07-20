import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:billing_app/core/data/hive_database.dart';
import 'package:billing_app/core/utils/xaf_formatter.dart';

class BarcodePrintService {
  static Future<void> printBarcodeLabel({
    required String productName,
    required double productPrice,
    required String barcodeData,
  }) async {
    final pdf = pw.Document();

    // Récupérer le nom de la boutique pour personnaliser l'étiquette
    final shop = HiveDatabase.shopBox.values.isNotEmpty
        ? HiveDatabase.shopBox.values.first
        : null;
    final shopName = shop?.name ?? 'Gestock+';

    pdf.addPage(
      pw.Page(
        // Taille standard d'étiquette de vente au détail (50mm x 30mm en points PDF : 1mm = 2.83 points)
        pageFormat: const PdfPageFormat(50 * 2.83, 30 * 2.83, marginAll: 2 * 2.83),
        build: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.center,
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // Nom de la boutique
                pw.Text(
                  shopName.toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 6,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: pw.TextOverflow.clip,
                ),
                pw.SizedBox(height: 1),

                // Nom du produit
                pw.Text(
                  productName,
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: pw.TextOverflow.clip,
                ),
                pw.SizedBox(height: 1),

                // Prix
                pw.Text(
                  XafFormatter.format(productPrice),
                  style: pw.TextStyle(
                    fontSize: 7,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 2),

                // Code-barres
                pw.Container(
                  width: 110,
                  height: 35,
                  child: pw.BarcodeWidget(
                    barcode: pw.Barcode.code128(),
                    data: barcodeData,
                    drawText: false, // On affiche le texte en dessous manuellement pour mieux contrôler la taille
                  ),
                ),
                pw.SizedBox(height: 1),

                // Texte du code-barres
                pw.Text(
                  barcodeData,
                  style: const pw.TextStyle(
                    fontSize: 6,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    // Lancer l'impression système (ouvert au Bluetooth, WiFi, imprimantes de reçus/étiquettes)
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'etiquette_$barcodeData',
    );
  }
}
