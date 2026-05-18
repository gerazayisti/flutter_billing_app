import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/cart_item.dart';
import 'package:billing_app/features/product/domain/entities/product.dart';
import 'package:billing_app/features/product/domain/usecases/product_usecases.dart';
import '../../../../core/utils/printer_helper.dart';
import '../../../../core/data/hive_database.dart';
import '../../data/models/order_model.dart';
import '../../data/models/order_item_model.dart';
import '../../domain/usecases/save_order_usecase.dart';
import '../../domain/entities/payment_method.dart';
import '../../data/models/held_order_model.dart';
import '../../data/repositories/held_order_repository.dart';
import 'package:billing_app/features/product/data/models/product_model.dart';
import 'package:billing_app/features/stock/data/models/stock_movement_model.dart';
import 'package:billing_app/l10n/app_localizations.dart';

part 'billing_event.dart';
part 'billing_state.dart';

class BillingBloc extends Bloc<BillingEvent, BillingState> {
  final GetProductByBarcodeUseCase getProductByBarcodeUseCase;
  final SaveOrderUseCase saveOrderUseCase;
  final HeldOrderRepository heldOrderRepository;

  BillingBloc({
    required this.getProductByBarcodeUseCase,
    required this.saveOrderUseCase,
    required this.heldOrderRepository,
  }) : super(const BillingState()) {
    on<ScanBarcodeEvent>(_onScanBarcode);
    on<AddProductToCartEvent>(_onAddProductToCart);
    on<LoadHeldOrdersEvent>(_onLoadHeldOrders);
    on<HoldCartEvent>(_onHoldCart);
    on<RestoreHeldOrderEvent>(_onRestoreHeldOrder);
    on<RemoveProductFromCartEvent>(_onRemoveProductFromCart);
    on<UpdateQuantityEvent>(_onUpdateQuantity);
    on<ClearCartEvent>(_onClearCart);
    on<SetPaymentMethodEvent>(_onSetPaymentMethod);
    on<PrintReceiptEvent>(_onPrintReceipt);
    on<SaveOrderWithoutPrintEvent>(_onSaveOrderWithoutPrint);
    on<SelectVariantEvent>(_onSelectVariant);
  }

  Future<void> _onScanBarcode(
      ScanBarcodeEvent event, Emitter<BillingState> emit) async {
    final result = await getProductByBarcodeUseCase(event.barcode);
    result.fold(
      (failure) =>
          emit(state.copyWith(error: 'Product not found: ${event.barcode}')),
      (product) {
        add(AddProductToCartEvent(product));
      },
    );
  }

  void _onAddProductToCart(
      AddProductToCartEvent event, Emitter<BillingState> emit) {
    // Clear error when adding
    final cleanState = state.copyWith(error: null);

    final existingIndex = cleanState.cartItems
        .indexWhere((item) => item.product.id == event.product.id);
    if (existingIndex >= 0) {
      final existingItem = cleanState.cartItems[existingIndex];
      final backendItems = List<CartItem>.from(cleanState.cartItems);
      backendItems[existingIndex] =
          existingItem.copyWith(quantity: existingItem.quantity + 1);
      emit(cleanState.copyWith(cartItems: backendItems, error: null));
    } else {
      final newItem = CartItem(product: event.product);
      emit(cleanState.copyWith(
          cartItems: [...cleanState.cartItems, newItem], error: null));
    }
  }

  void _onRemoveProductFromCart(
      RemoveProductFromCartEvent event, Emitter<BillingState> emit) {
    final updatedList = state.cartItems
        .where((item) => item.product.id != event.productId)
        .toList();
    emit(state.copyWith(cartItems: updatedList));
  }

  void _onUpdateQuantity(
      UpdateQuantityEvent event, Emitter<BillingState> emit) {
    if (event.quantity <= 0) {
      add(RemoveProductFromCartEvent(event.productId));
      return;
    }

    final index = state.cartItems
        .indexWhere((item) => item.product.id == event.productId);
    if (index >= 0) {
      final items = List<CartItem>.from(state.cartItems);
      items[index] = items[index].copyWith(quantity: event.quantity);
      emit(state.copyWith(cartItems: items));
    }
  }

  void _onClearCart(ClearCartEvent event, Emitter<BillingState> emit) {
    emit(BillingState(heldOrders: heldOrderRepository.getAllHeldOrders()));
  }

  void _onLoadHeldOrders(
      LoadHeldOrdersEvent event, Emitter<BillingState> emit) {
    emit(state.copyWith(heldOrders: heldOrderRepository.getAllHeldOrders()));
  }

  Future<void> _onHoldCart(HoldCartEvent event, Emitter<BillingState> emit) async {
    if (state.cartItems.isEmpty) return;
    
    // Max 5 carts
    if (heldOrderRepository.getAllHeldOrders().length >= 5) {
      emit(state.copyWith(error: 'Maximum 5 paniers en attente', clearError: false));
      emit(state.copyWith(clearError: true));
      return;
    }

    final heldOrder = HeldOrderModel(
      id: const Uuid().v4(),
      savedAt: DateTime.now(),
      items: state.cartItems
          .map((item) => HeldCartItemModel(
                product: ProductModel.fromEntity(item.product),
                quantity: item.quantity,
                selectedVariant: item.selectedVariant,
              ))
          .toList(),
    );

    await heldOrderRepository.saveHeldOrder(heldOrder);
    
    emit(BillingState(heldOrders: heldOrderRepository.getAllHeldOrders()));
  }

  Future<void> _onRestoreHeldOrder(
      RestoreHeldOrderEvent event, Emitter<BillingState> emit) async {
    final heldOrders = heldOrderRepository.getAllHeldOrders();
    final index = heldOrders.indexWhere((o) => o.id == event.holdId);
    if (index == -1) return;

    final order = heldOrders[index];

    // Delete it from held orders
    await heldOrderRepository.deleteHeldOrder(order.id);

    final restoredItems = order.items.map((heldItem) {
      return CartItem(
        product: heldItem.product.toEntity(),
        quantity: heldItem.quantity,
        selectedVariant: heldItem.selectedVariant,
      );
    }).toList();

    emit(BillingState(
      cartItems: restoredItems,
      heldOrders: heldOrderRepository.getAllHeldOrders()
    ));
  }

  void _onSetPaymentMethod(
      SetPaymentMethodEvent event, Emitter<BillingState> emit) {
    emit(state.copyWith(paymentMethod: event.method));
  }

  Future<void> _onPrintReceipt(
      PrintReceiptEvent event, Emitter<BillingState> emit) async {
    final printerHelper = PrinterHelper();

    if (!printerHelper.isConnected) {
      final savedMac = HiveDatabase.settingsBox.get('printer_mac');
      if (savedMac != null) {
        final connected = await printerHelper.connect(savedMac);
        if (!connected) {
          emit(state.copyWith(
              error: 'Failed to auto-connect to printer!', clearError: false));
          emit(state.copyWith(clearError: true));
          return;
        }
      } else {
        emit(state.copyWith(
            error: 'Printer not connected & no saved printer found!',
            clearError: false));
        emit(state.copyWith(clearError: true));
        return;
      }
    }

    emit(state.copyWith(
        isPrinting: true, printSuccess: false, clearError: true));

    try {
      final items = state.cartItems
          .map((item) => {
                'name': item.product.name,
                'qty': item.quantity,
                'price': item.product.price,
                'total': item.total,
              })
          .toList();

      await printerHelper.printReceipt(
          shopName: event.shopName,
          address1: event.address1,
          address2: event.address2,
          phone: event.phone,
          items: items,
          total: state.totalAmount,
          footer: event.footer,
          l10n: event.l10n,
      );

      // ✅ Save the order to local history after successful print
      final order = OrderModel(
        id: const Uuid().v4(),
        date: DateTime.now(),
        totalAmount: state.totalAmount,
        paymentMethod: state.paymentMethod.stringValue,
        items: state.cartItems
            .map((item) => OrderItemModel(
                  productId: item.product.id,
                  productName: item.product.name,
                  price: item.product.price,
                  quantity: item.quantity,
                  selectedVariant: item.selectedVariant,
                ))
            .toList(),
      );
      await saveOrderUseCase(order);
      await _decrementStockAndRecord(order.id, event.cashierId);

      emit(state.copyWith(isPrinting: false, printSuccess: true));
    } catch (e) {
      emit(state.copyWith(
          isPrinting: false, error: 'Print failed: $e', clearError: false));
      // Reset error instantly avoids sticky error
      emit(state.copyWith(clearError: true));
    }
  }

  Future<void> _onSaveOrderWithoutPrint(
      SaveOrderWithoutPrintEvent event, Emitter<BillingState> emit) async {
    final order = OrderModel(
      id: const Uuid().v4(),
      date: DateTime.now(),
      totalAmount: state.totalAmount,
      paymentMethod: state.paymentMethod.stringValue,
      items: state.cartItems
          .map((item) => OrderItemModel(
                productId: item.product.id,
                productName: item.product.name,
                price: item.product.price,
                quantity: item.quantity,
                selectedVariant: item.selectedVariant,
              ))
          .toList(),
    );
    await saveOrderUseCase(order);
    await _decrementStockAndRecord(order.id, event.cashierId);

    emit(state.copyWith(printSuccess: true));
  }

  Future<void> _decrementStockAndRecord(String orderId, String cashierId) async {
    for (final item in state.cartItems) {
      final productBox = HiveDatabase.productBox;
      final productModel = productBox.get(item.product.id);
      if (productModel != null) {
        final newStock = productModel.stock - item.quantity;
        await productBox.put(
          item.product.id,
          ProductModel(
            id: productModel.id,
            name: productModel.name,
            barcode: productModel.barcode,
            price: productModel.price,
            stock: newStock >= 0 ? newStock : 0,
            category: productModel.category,
            minStockAlert: productModel.minStockAlert,
            variants: productModel.variants,
          ),
        );
      }
      // Record saleOut movement
      final movement = StockMovementModel(
        id: const Uuid().v4(),
        productId: item.product.id,
        productName: item.product.name,
        typeName: 'saleOut',
        quantity: item.quantity,
        operatorId: cashierId,
        date: DateTime.now(),
        orderId: orderId,
      );
      await HiveDatabase.stockMovementsBox.put(movement.id, movement);
    }
  }

  void _onSelectVariant(SelectVariantEvent event, Emitter<BillingState> emit) {
    final index = state.cartItems.indexWhere((i) => i.product.id == event.productId);
    if (index >= 0) {
      final items = List<CartItem>.from(state.cartItems);
      items[index] = items[index].copyWith(selectedVariant: event.variant);
      emit(state.copyWith(cartItems: items));
    }
  }
}
