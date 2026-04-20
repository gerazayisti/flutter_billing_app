part of 'billing_bloc.dart';

class BillingState extends Equatable {
  final List<CartItem> cartItems;
  final String? error;
  final bool isPrinting;
  final bool printSuccess;
  final PaymentMethod paymentMethod;
  final List<HeldOrderModel> heldOrders;

  const BillingState({
    this.cartItems = const [],
    this.error,
    this.isPrinting = false,
    this.printSuccess = false,
    this.paymentMethod = PaymentMethod.cash,
    this.heldOrders = const [],
  });

  double get totalAmount => cartItems.fold(0, (sum, item) => sum + item.total);

  BillingState copyWith({
    List<CartItem>? cartItems,
    String? error,
    bool clearError = false,
    bool? isPrinting,
    bool? printSuccess,
    PaymentMethod? paymentMethod,
    List<HeldOrderModel>? heldOrders,
  }) {
    return BillingState(
      cartItems: cartItems ?? this.cartItems,
      error: clearError ? null : (error ?? this.error),
      isPrinting: isPrinting ?? this.isPrinting,
      printSuccess: printSuccess ?? this.printSuccess,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      heldOrders: heldOrders ?? this.heldOrders,
    );
  }

  @override
  List<Object?> get props =>
      [cartItems, error, isPrinting, printSuccess, paymentMethod, heldOrders];
}
