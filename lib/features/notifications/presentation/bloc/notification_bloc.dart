import 'package:bloc/bloc.dart';
import 'package:billing_app/core/notifications/notification_item.dart';
import 'package:billing_app/core/notifications/notification_service.dart';

// ── Events ────────────────────────────────────────────────────────────────────

abstract class NotificationEvent {}

class LoadNotificationsEvent extends NotificationEvent {}

class MarkAllReadEvent extends NotificationEvent {}

class ClearAllNotificationsEvent extends NotificationEvent {}

class RefreshUnreadCountEvent extends NotificationEvent {}

// ── State ─────────────────────────────────────────────────────────────────────

class NotificationState {
  final List<NotificationItem> items;

  const NotificationState({required this.items});

  int get unreadCount => items.where((n) => !n.isRead).length;

  factory NotificationState.empty() => const NotificationState(items: []);
}

// ── Bloc ──────────────────────────────────────────────────────────────────────

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  NotificationBloc() : super(NotificationState.empty()) {
    on<LoadNotificationsEvent>(_onLoad);
    on<MarkAllReadEvent>(_onMarkAllRead);
    on<ClearAllNotificationsEvent>(_onClearAll);
    on<RefreshUnreadCountEvent>(_onLoad);
  }

  void _onLoad(NotificationEvent event, Emitter<NotificationState> emit) {
    emit(NotificationState(items: NotificationService.getAll()));
  }

  Future<void> _onMarkAllRead(
      MarkAllReadEvent event, Emitter<NotificationState> emit) async {
    await NotificationService.markAllRead();
    emit(NotificationState(items: NotificationService.getAll()));
  }

  Future<void> _onClearAll(
      ClearAllNotificationsEvent event, Emitter<NotificationState> emit) async {
    await NotificationService.clear();
    emit(NotificationState.empty());
  }
}
