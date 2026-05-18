part of 'billing_bloc.dart';

abstract class BillingEvent extends Equatable {
  const BillingEvent();
  @override
  List<Object> get props => [];
}

class ScanBarcodeEvent extends BillingEvent {
  final String barcode;
  const ScanBarcodeEvent(this.barcode);
  @override
  List<Object> get props => [barcode];
}

class AddProductToCartEvent extends BillingEvent {
  final Product product;
  const AddProductToCartEvent(this.product);
  @override
  List<Object> get props => [product];
}

class RemoveProductFromCartEvent extends BillingEvent {
  final String productId;
  const RemoveProductFromCartEvent(this.productId);
  @override
  List<Object> get props => [productId];
}

class UpdateQuantityEvent extends BillingEvent {
  final String productId;
  final int quantity;
  const UpdateQuantityEvent(this.productId, this.quantity);
  @override
  List<Object> get props => [productId, quantity];
}

class ClearCartEvent extends BillingEvent {}

class LoadHeldOrdersEvent extends BillingEvent {}

class HoldCartEvent extends BillingEvent {}

class RestoreHeldOrderEvent extends BillingEvent {
  final String holdId;
  const RestoreHeldOrderEvent(this.holdId);
  @override
  List<Object> get props => [holdId];
}

class SetPaymentMethodEvent extends BillingEvent {
  final PaymentMethod method;
  const SetPaymentMethodEvent(this.method);
  @override
  List<Object> get props => [method];
}

class PrintReceiptEvent extends BillingEvent {
  final String shopName;
  final String address1;
  final String address2;
  final String phone;
  final String footer;
  final AppLocalizations l10n;

  const PrintReceiptEvent({
    required this.shopName,
    required this.address1,
    required this.address2,
    required this.phone,
    required this.footer,
    required this.l10n,
  });

  @override
  List<Object> get props => [shopName, address1, address2, phone, footer, l10n];
}

class SelectVariantEvent extends BillingEvent {
  final String productId;
  final String variant;
  const SelectVariantEvent(this.productId, this.variant);
  @override
  List<Object> get props => [productId, variant];
}

class SaveOrderWithoutPrintEvent extends BillingEvent {
  const SaveOrderWithoutPrintEvent();
}
