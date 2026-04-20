import 'package:equatable/equatable.dart';

class Product extends Equatable {
  final String id;
  final String name;
  final String barcode;
  final double price;
  final int stock;
  final String category;
  final int minStockAlert;
  final List<String> variants;

  const Product({
    required this.id,
    required this.name,
    required this.barcode,
    required this.price,
    this.stock = 0,
    this.category = 'General',
    this.minStockAlert = 5,
    this.variants = const [],
  });

  @override
  List<Object?> get props =>
      [id, name, barcode, price, stock, category, minStockAlert, variants];
}
