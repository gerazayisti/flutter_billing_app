import 'dart:io';
import 'package:billing_app/features/product/domain/entities/product.dart';
import 'package:billing_app/features/stock/domain/entities/stock_movement.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

class InventoryExporter {
  static final _dateFormat = DateFormat('dd/MM/yyyy');
  static final _timeFormat = DateFormat('dd/MM/yyyy HH:mm');

  // ── CSV Export: Current Catalog ──
  static Future<void> exportProductsCSV(List<Product> products, String shopName) async {
    final StringBuffer csv = StringBuffer();
    csv.writeln('Nom du Produit,Categorie,Prix (FCFA),Stock Actuel,Alerte Stock');

    for (final p in products) {
      final name = p.name.replaceAll('"', '""');
      final cat = p.category.replaceAll('"', '""');
      csv.writeln('"$name","$cat",${p.price},${p.stock},${p.minStockAlert}');
    }

    final file = await _saveFile('Catalogue_Produits', 'csv', csv.toString(), isBytes: false);
    if (file != null) {
      await Share.shareXFiles([XFile(file.path)], text: 'Catalogue Produits - $shopName');
    }
  }

  // ── PDF Export: Current Catalog ──
  static Future<void> exportProductsPDF(List<Product> products, String shopName) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Catalogue des Produits', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.Text(shopName, style: const pw.TextStyle(fontSize: 16)),
                ],
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text('Date : ${_dateFormat.format(DateTime.now())}'),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              context: context,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
              cellAlignment: pw.Alignment.centerLeft,
              data: [
                ['Nom du Produit', 'Catégorie', 'Prix (FCFA)', 'Stock Actuel'],
                ...products.map((p) => [
                      p.name,
                      p.category,
                      p.price.toStringAsFixed(0),
                      p.stock.toString(),
                    ])
              ],
            ),
          ];
        },
      ),
    );

    final file = await _saveFile('Catalogue_Produits', 'pdf', await pdf.save(), isBytes: true);
    if (file != null) {
      await Share.shareXFiles([XFile(file.path)], text: 'Catalogue Produits - $shopName');
    }
  }

  // ── CSV Export: Periodic Movements ──
  static Future<void> exportMovementReportCSV(
      List<StockMovement> movements, DateTime start, DateTime end, String shopName) async {
    final StringBuffer csv = StringBuffer();
    csv.writeln('Date,Produit,Type,Quantite,Operateur,Fournisseur,Cout Unitaire,Note');

    for (final m in movements) {
      final date = _timeFormat.format(m.date);
      final product = m.productName.replaceAll('"', '""');
      final type = m.type.name;
      final qty = m.type.isIn ? m.quantity : -m.quantity;
      final supplier = m.supplierName?.replaceAll('"', '""') ?? '';
      final note = m.note?.replaceAll('"', '""') ?? '';
      final cost = m.unitCost?.toStringAsFixed(0) ?? '';

      csv.writeln('"$date","$product","$type",$qty,"${m.operatorId}","$supplier",$cost,"$note"');
    }

    final file = await _saveFile('Rapport_Mouvements', 'csv', csv.toString(), isBytes: false);
    if (file != null) {
      await Share.shareXFiles([XFile(file.path)], text: 'Rapport Mouvements - $shopName');
    }
  }

  // ── PDF Export: Periodic Movements ──
  static Future<void> exportMovementReportPDF(
      List<StockMovement> movements, DateTime start, DateTime end, String shopName) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Rapport des Mouvements', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.Text(shopName, style: const pw.TextStyle(fontSize: 16)),
                ],
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text('Période : ${_dateFormat.format(start)} - ${_dateFormat.format(end)}'),
            pw.Text('Date de génération : ${_timeFormat.format(DateTime.now())}'),
            pw.SizedBox(height: 20),
            if (movements.isEmpty)
              pw.Text('Aucun mouvement enregistré pour cette période.', style: const pw.TextStyle(fontSize: 14))
            else
              pw.TableHelper.fromTextArray(
                context: context,
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
                cellAlignment: pw.Alignment.centerLeft,
                cellStyle: const pw.TextStyle(fontSize: 10),
                data: [
                  ['Date', 'Produit', 'Type', 'Qté', 'Fournisseur'],
                  ...movements.map((m) {
                    final qtyStr = m.type.isIn ? '+${m.quantity}' : '-${m.quantity}';
                    return [
                      _timeFormat.format(m.date),
                      m.productName,
                      m.type.name,
                      qtyStr,
                      m.supplierName ?? '-',
                    ];
                  })
                ],
              ),
          ];
        },
      ),
    );

    final file = await _saveFile('Rapport_Mouvements', 'pdf', await pdf.save(), isBytes: true);
    if (file != null) {
      await Share.shareXFiles([XFile(file.path)], text: 'Rapport Mouvements - $shopName');
    }
  }

  // ── Utility: Save File ──
  static Future<File?> _saveFile(String baseName, String extension, dynamic content, {required bool isBytes}) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('${directory.path}/${baseName}_$timestamp.$extension');

      if (isBytes) {
        await file.writeAsBytes(content as List<int>);
      } else {
        await file.writeAsString(content as String);
      }
      return file;
    } catch (e) {
      return null;
    }
  }
}
