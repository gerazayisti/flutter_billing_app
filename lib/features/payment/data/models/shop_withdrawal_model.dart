import 'package:hive/hive.dart';
import '../../domain/entities/shop_withdrawal.dart';

part 'shop_withdrawal_model.g.dart';

@HiveType(typeId: 13)
class ShopWithdrawalModel extends HiveObject {
  @HiveField(0)
  final String payoutId;

  @HiveField(1)
  final String shopId;

  @HiveField(2)
  final String phoneNumber;

  @HiveField(3)
  final String provider;

  @HiveField(4)
  final double grossAmount;

  @HiveField(5)
  final double feeAmount;

  @HiveField(6)
  final double netAmount;

  @HiveField(7)
  late String statusName;

  @HiveField(8)
  final String? failureCode;

  @HiveField(9)
  final String? failureMessage;

  @HiveField(10)
  final DateTime createdAt;

  ShopWithdrawalModel({
    required this.payoutId,
    required this.shopId,
    required this.phoneNumber,
    required this.provider,
    required this.grossAmount,
    required this.feeAmount,
    required this.netAmount,
    required this.statusName,
    this.failureCode,
    this.failureMessage,
    required this.createdAt,
  });

  factory ShopWithdrawalModel.fromEntity(ShopWithdrawal entity) {
    return ShopWithdrawalModel(
      payoutId: entity.payoutId,
      shopId: entity.shopId,
      phoneNumber: entity.phoneNumber,
      provider: entity.provider,
      grossAmount: entity.grossAmount,
      feeAmount: entity.feeAmount,
      netAmount: entity.netAmount,
      statusName: entity.status.name,
      failureCode: entity.failureCode,
      failureMessage: entity.failureMessage,
      createdAt: entity.createdAt,
    );
  }

  WithdrawalStatus _parseStatus(String s) {
    return WithdrawalStatus.values.firstWhere(
      (v) => v.name == s,
      orElse: () => WithdrawalStatus.pending,
    );
  }

  ShopWithdrawal toEntity() {
    return ShopWithdrawal(
      payoutId: payoutId,
      shopId: shopId,
      phoneNumber: phoneNumber,
      provider: provider,
      grossAmount: grossAmount,
      feeAmount: feeAmount,
      netAmount: netAmount,
      status: WithdrawalStatus.values.firstWhere((e) => e.name == statusName),
      failureCode: failureCode,
      failureMessage: failureMessage,
      createdAt: createdAt,
    );
  }
}
