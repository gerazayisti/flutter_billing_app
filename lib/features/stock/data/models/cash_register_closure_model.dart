import 'package:hive/hive.dart';
import '../../domain/entities/cash_register_closure.dart';

part 'cash_register_closure_model.g.dart';

@HiveType(typeId: 11)
class CashRegisterClosureModel extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) DateTime closedAt;
  @HiveField(2) DateTime periodStart;
  @HiveField(3) String cashierId;
  @HiveField(4) double cashTotal;
  @HiveField(5) double orangeMoneyTotal;
  @HiveField(6) double mtnMomoTotal;
  @HiveField(7) double cardTotal;
  @HiveField(8) double grandTotal;
  @HiveField(9) int transactionCount;
  @HiveField(10) String? notes;

  CashRegisterClosureModel({
    required this.id,
    required this.closedAt,
    required this.periodStart,
    required this.cashierId,
    required this.cashTotal,
    required this.orangeMoneyTotal,
    required this.mtnMomoTotal,
    required this.cardTotal,
    required this.grandTotal,
    required this.transactionCount,
    this.notes,
  });

  factory CashRegisterClosureModel.fromEntity(CashRegisterClosure e) =>
      CashRegisterClosureModel(
        id: e.id,
        closedAt: e.closedAt,
        periodStart: e.periodStart,
        cashierId: e.cashierId,
        cashTotal: e.cashTotal,
        orangeMoneyTotal: e.orangeMoneyTotal,
        mtnMomoTotal: e.mtnMomoTotal,
        cardTotal: e.cardTotal,
        grandTotal: e.grandTotal,
        transactionCount: e.transactionCount,
        notes: e.notes,
      );

  CashRegisterClosure toEntity() => CashRegisterClosure(
        id: id,
        closedAt: closedAt,
        periodStart: periodStart,
        cashierId: cashierId,
        cashTotal: cashTotal,
        orangeMoneyTotal: orangeMoneyTotal,
        mtnMomoTotal: mtnMomoTotal,
        cardTotal: cardTotal,
        grandTotal: grandTotal,
        transactionCount: transactionCount,
        notes: notes,
      );
}
