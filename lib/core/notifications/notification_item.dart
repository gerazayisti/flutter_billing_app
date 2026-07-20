import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:billing_app/core/data/hive_database.dart';

enum NotificationType { sale, stockAlert, movement, payment }

class NotificationItem {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime createdAt;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type.name,
    'title': title,
    'body': body,
    'createdAt': createdAt.toIso8601String(),
    'isRead': isRead,
  };

  factory NotificationItem.fromMap(Map<String, dynamic> map) => NotificationItem(
    id: map['id'] as String,
    type: NotificationType.values.firstWhere(
      (e) => e.name == map['type'],
      orElse: () => NotificationType.sale,
    ),
    title: map['title'] as String,
    body: map['body'] as String,
    createdAt: DateTime.parse(map['createdAt'] as String),
    isRead: map['isRead'] as bool? ?? false,
  );

  static final _currency = NumberFormat('#,##0', 'fr');

  static NotificationItem sale({
    required String cashierId,
    required double amount,
    required int itemCount,
    required String paymentMethod,
  }) {
    final cashierName = _lookupName(cashierId);
    return NotificationItem(
      id: const Uuid().v4(),
      type: NotificationType.sale,
      title: 'Vente · ${_currency.format(amount)} FCFA',
      body: '$cashierName · $itemCount article${itemCount > 1 ? 's' : ''} · $paymentMethod',
      createdAt: DateTime.now(),
    );
  }

  static NotificationItem stockAlert({
    required String productName,
    required int currentStock,
    required int minStock,
  }) =>
      NotificationItem(
        id: const Uuid().v4(),
        type: NotificationType.stockAlert,
        title: 'Alerte stock : $productName',
        body: 'Stock : $currentStock (seuil min : $minStock)',
        createdAt: DateTime.now(),
      );

  static String _lookupName(String id) {
    final user = HiveDatabase.usersBox.get(id);
    return user?.name ?? id;
  }
}
