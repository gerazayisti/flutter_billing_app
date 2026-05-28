import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import 'package:billing_app/core/data/hive_database.dart';
import 'package:billing_app/core/cloud/cloud_sync_service.dart';
import 'package:billing_app/features/product/data/models/product_model.dart';
import '../../domain/entities/stock_movement.dart';
import '../../domain/entities/supplier.dart';
import '../../domain/entities/cash_register_closure.dart';
import '../../domain/repositories/stock_repository.dart';
import '../../../billing/domain/entities/payment_method.dart';

// ── Events ─────────────────────────────────────────────────────────────────

abstract class StockEvent extends Equatable {
  const StockEvent();
  @override
  List<Object?> get props => [];
}

class LoadStockEvent extends StockEvent {}

class AddStockMovementEvent extends StockEvent {
  final String productId;
  final String productName;
  final MovementType type;
  final int quantity;
  final String operatorId;
  final String? supplierId;
  final String? supplierName;
  final String? note;
  final double? unitCost;

  const AddStockMovementEvent({
    required this.productId,
    required this.productName,
    required this.type,
    required this.quantity,
    required this.operatorId,
    this.supplierId,
    this.supplierName,
    this.note,
    this.unitCost,
  });

  @override
  List<Object?> get props => [productId, type, quantity];
}

class SaveSupplierEvent extends StockEvent {
  final Supplier supplier;
  const SaveSupplierEvent(this.supplier);
  @override
  List<Object?> get props => [supplier];
}

class DeleteSupplierEvent extends StockEvent {
  final String supplierId;
  const DeleteSupplierEvent(this.supplierId);
  @override
  List<Object?> get props => [supplierId];
}

class CloseCashRegisterEvent extends StockEvent {
  final String cashierId;
  final String? notes;
  const CloseCashRegisterEvent({required this.cashierId, this.notes});
  @override
  List<Object?> get props => [cashierId];
}

// ── State ──────────────────────────────────────────────────────────────────

class StockState extends Equatable {
  final List<StockMovement> movements;
  final List<Supplier> suppliers;
  final List<CashRegisterClosure> closures;
  final bool isLoading;
  final String? error;
  final String? successMessage;

  const StockState({
    this.movements = const [],
    this.suppliers = const [],
    this.closures = const [],
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  StockState copyWith({
    List<StockMovement>? movements,
    List<Supplier>? suppliers,
    List<CashRegisterClosure>? closures,
    bool? isLoading,
    String? error,
    String? successMessage,
    bool clearMessages = false,
  }) =>
      StockState(
        movements: movements ?? this.movements,
        suppliers: suppliers ?? this.suppliers,
        closures: closures ?? this.closures,
        isLoading: isLoading ?? this.isLoading,
        error: clearMessages ? null : error ?? this.error,
        successMessage:
            clearMessages ? null : successMessage ?? this.successMessage,
      );

  CashRegisterClosure? get lastClosure =>
      closures.isNotEmpty ? closures.first : null;

  @override
  List<Object?> get props =>
      [movements, suppliers, closures, isLoading, error, successMessage];
}

// ── Bloc ───────────────────────────────────────────────────────────────────

class StockBloc extends Bloc<StockEvent, StockState> {
  final StockRepository repository;
  final CloudSyncService? syncService;

  StockBloc({required this.repository, this.syncService}) : super(const StockState()) {
    on<LoadStockEvent>(_onLoad);
    on<AddStockMovementEvent>(_onAddMovement);
    on<SaveSupplierEvent>(_onSaveSupplier);
    on<DeleteSupplierEvent>(_onDeleteSupplier);
    on<CloseCashRegisterEvent>(_onCloseCashRegister);
  }

  Future<void> _onLoad(LoadStockEvent event, Emitter<StockState> emit) async {
    emit(state.copyWith(isLoading: true));
    final movements = repository.getRecentMovements();
    final suppliers = repository.getSuppliers();
    final closures = repository.getClosures();
    emit(state.copyWith(
      isLoading: false,
      movements: movements,
      suppliers: suppliers,
      closures: closures,
    ));
  }

  Future<void> _onAddMovement(
      AddStockMovementEvent event, Emitter<StockState> emit) async {
    final movement = StockMovement(
      id: const Uuid().v4(),
      productId: event.productId,
      productName: event.productName,
      type: event.type,
      quantity: event.quantity,
      operatorId: event.operatorId,
      date: DateTime.now(),
      supplierId: event.supplierId,
      supplierName: event.supplierName,
      note: event.note,
      unitCost: event.unitCost,
    );

    await repository.addMovement(movement);

    // Update product stock
    final productBox = HiveDatabase.productBox;
    final productModel = productBox.get(event.productId);
    if (productModel != null) {
      final delta = event.type.isIn ? event.quantity : -event.quantity;
      final newStock = (productModel.stock + delta).clamp(0, 999999);
      await productBox.put(
        event.productId,
        ProductModel(
          id: productModel.id,
          name: productModel.name,
          barcode: productModel.barcode,
          price: productModel.price,
          stock: newStock,
          category: productModel.category,
          minStockAlert: productModel.minStockAlert,
          variants: productModel.variants,
        ),
      );
    }

    final updated = repository.getRecentMovements();
    emit(state.copyWith(movements: updated, successMessage: 'ok'));
    emit(state.copyWith(clearMessages: true));
    _autoSync();
  }

  Future<void> _onSaveSupplier(
      SaveSupplierEvent event, Emitter<StockState> emit) async {
    await repository.saveSupplier(event.supplier);
    emit(state.copyWith(suppliers: repository.getSuppliers()));
    _autoSync();
  }

  Future<void> _onDeleteSupplier(
      DeleteSupplierEvent event, Emitter<StockState> emit) async {
    await repository.deleteSupplier(event.supplierId);
    emit(state.copyWith(suppliers: repository.getSuppliers()));
  }

  Future<void> _onCloseCashRegister(
      CloseCashRegisterEvent event, Emitter<StockState> emit) async {
    final lastClosure = repository.getLastClosure();
    final periodStart = lastClosure?.closedAt ??
        DateTime.now().subtract(const Duration(days: 365));

    // Aggregate orders since last closure
    final orders = HiveDatabase.orderBox.values
        .where((o) => o.date.isAfter(periodStart))
        .toList();

    double cash = 0, orange = 0, mtn = 0, card = 0;
    for (final o in orders) {
      switch (PaymentMethodExtension.fromString(o.paymentMethod)) {
        case PaymentMethod.cash:
          cash += o.totalAmount;
        case PaymentMethod.orangeMoney:
          orange += o.totalAmount;
        case PaymentMethod.mtnMomo:
          mtn += o.totalAmount;
        case PaymentMethod.card:
          card += o.totalAmount;
        default:
          cash += o.totalAmount;
      }
    }

    final closure = CashRegisterClosure(
      id: const Uuid().v4(),
      closedAt: DateTime.now(),
      periodStart: periodStart,
      cashierId: event.cashierId,
      cashTotal: cash,
      orangeMoneyTotal: orange,
      mtnMomoTotal: mtn,
      cardTotal: card,
      grandTotal: cash + orange + mtn + card,
      transactionCount: orders.length,
      notes: event.notes,
    );

    await repository.saveClosure(closure);
    emit(state.copyWith(
      closures: repository.getClosures(),
      successMessage: 'closed',
    ));
    emit(state.copyWith(clearMessages: true));
    _autoSync();
  }

  void _autoSync() {
    if (syncService == null || !syncService!.isConfigured || !syncService!.isSignedIn) return;
    syncService!.pushAll();
  }
}
