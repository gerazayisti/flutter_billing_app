import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';

import 'package:billing_app/core/data/hive_database.dart';
import 'package:billing_app/features/product/data/models/product_model.dart';
import 'package:billing_app/features/shop/data/models/shop_model.dart';
import 'package:billing_app/features/billing/data/models/order_model.dart';
import 'package:billing_app/features/billing/data/models/order_item_model.dart';

class BackupService {
  static Future<void> exportData(BuildContext context) async {
    try {
      final Map<String, dynamic> data = {
        'products': HiveDatabase.productBox.values.map((p) => {
          'id': p.id,
          'name': p.name,
          'barcode': p.barcode,
          'price': p.price,
          'stock': p.stock,
        }).toList(),
        
        'orders': HiveDatabase.orderBox.values.map((o) => {
          'id': o.id,
          'date': o.date.toIso8601String(),
          'totalAmount': o.totalAmount,
          'paymentMethod': o.paymentMethod,
          'items': o.items.map((i) => {
            'productId': i.productId,
            'productName': i.productName,
            'price': i.price,
            'quantity': i.quantity,
          }).toList(),
        }).toList(),
      };
      
      final shop = HiveDatabase.shopBox.get('shop');
      if (shop != null) {
        data['shop'] = {
          'name': shop.name,
          'addressLine1': shop.addressLine1,
          'addressLine2': shop.addressLine2,
          'phoneNumber': shop.phoneNumber,
          'footerText': shop.footerText,
          'upiId': shop.upiId,
        };
      }

      final jsonStr = jsonEncode(data);
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/backup_pos_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(jsonStr);

      final xFile = XFile(file.path);
      await Share.shareXFiles([xFile], text: 'Backup POS Database');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  static Future<void> importData(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.any,
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        String jsonString = await file.readAsString();
        Map<String, dynamic> data = jsonDecode(jsonString);

        if (data.containsKey('products')) {
          await HiveDatabase.productBox.clear();
          for (var p in data['products']) {
            await HiveDatabase.productBox.put(p['id'], ProductModel(
              id: p['id'].toString(),
              name: p['name'].toString(),
              barcode: p['barcode'].toString(),
              price: (p['price'] as num).toDouble(),
              stock: (p['stock'] as num?)?.toInt() ?? 0,
              category: p['category']?.toString() ?? 'General',
              minStockAlert: (p['minStockAlert'] as num?)?.toInt() ?? 5,
              variants: (p['variants'] as List?)?.map((v) => v.toString()).toList() ?? [],
            ));
          }
        }

        if (data.containsKey('orders')) {
          await HiveDatabase.orderBox.clear();
          for (var o in data['orders']) {
            await HiveDatabase.orderBox.put(o['id'], OrderModel(
              id: o['id'].toString(),
              date: DateTime.parse(o['date']),
              totalAmount: (o['totalAmount'] as num).toDouble(),
              paymentMethod: o['paymentMethod']?.toString() ?? 'cash',
              items: (o['items'] as List).map((i) => OrderItemModel(
                productId: i['productId'].toString(),
                productName: i['productName'].toString(),
                price: (i['price'] as num).toDouble(),
                quantity: (i['quantity'] as num).toInt(),
                selectedVariant: i['selectedVariant']?.toString(),
              )).toList(),
            ));
          }
        }

        if (data.containsKey('shop')) {
          var s = data['shop'];
          await HiveDatabase.shopBox.put('shop', ShopModel(
             name: s['name'].toString(),
             addressLine1: s['addressLine1'].toString(),
             addressLine2: s['addressLine2'].toString(),
             phoneNumber: s['phoneNumber'].toString(),
             footerText: s['footerText'].toString(),
             upiId: s['upiId'].toString(),
          ));
        }

        if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Import successful! Base Restored.'), backgroundColor: Colors.green));
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import failed: $e'), backgroundColor: Colors.red));
      }
    }
  }
}
