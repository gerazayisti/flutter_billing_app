part of 'billing_bloc.dart';

class BillingState extends Equatable {
  final List<CartItem> cartItems;
  final String? error;
  final bool isPrinting;
  final bool printSuccess;
  final PaymentMethod paymentMethod;
  final List<HeldOrderModel> heldOrders;
  /// true quand l'abonnement est expiré et qu'une action de vente a été bloquée.
  final bool subscriptionExpired;

  const BillingState({
    this.cartItems = const [],
    this.error,
    this.isPrinting = false,
    this.printSuccess = false,
    this.paymentMethod = PaymentMethod.cash,
    this.heldOrders = const [],
    this.subscriptionExpired = false,
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
    bool? subscriptionExpired,
  }) {
    return BillingState(
      cartItems: cartItems ?? this.cartItems,
      error: clearError ? null : (error ?? this.error),
      isPrinting: isPrinting ?? this.isPrinting,
      printSuccess: printSuccess ?? this.printSuccess,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      heldOrders: heldOrders ?? this.heldOrders,
      subscriptionExpired: subscriptionExpired ?? this.subscriptionExpired,
    );
  }

  @override
  List<Object?> get props =>
      [cartItems, error, isPrinting, printSuccess, paymentMethod, heldOrders, subscriptionExpired];
}
