import 'package:billing_app/core/data/hive_database.dart';
import 'notification_item.dart';

class NotificationService {
  static const _key = 'app_notifications';
  static const _maxCount = 100;

  static List<NotificationItem> getAll() {
    final raw = HiveDatabase.settingsBox.get(_key) as List?;
    if (raw == null) return [];
    return raw
        .map((e) => NotificationItem.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static Future<void> add(NotificationItem item) async {
    final current = getAll()..insert(0, item);
    await _save(current.take(_maxCount).toList());
  }

  static Future<void> markAllRead() async {
    final items = getAll().map((n) => n..isRead = true).toList();
    await _save(items);
  }

  static Future<void> clear() async {
    await HiveDatabase.settingsBox.delete(_key);
  }

  static int get unreadCount =>
      getAll().where((n) => !n.isRead).length;

  static Future<void> _save(List<NotificationItem> items) async {
    await HiveDatabase.settingsBox.put(
      _key,
      items.map((e) => e.toMap()).toList(),
    );
  }
}
