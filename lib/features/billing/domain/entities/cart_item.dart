import 'package:equatable/equatable.dart';
import 'package:billing_app/features/product/domain/entities/product.dart';

class CartItem extends Equatable {
  final Product product;
  final int quantity;
  final String? selectedVariant;

  const CartItem({
    required this.product,
    this.quantity = 1,
    this.selectedVariant,
  });

  double get total => product.price * quantity;

  CartItem copyWith({
    Product? product,
    int? quantity,
    String? selectedVariant,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      selectedVariant: selectedVariant ?? this.selectedVariant,
    );
  }

  @override
  List<Object?> get props => [product, quantity, selectedVariant];
}
