import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/notification_model.dart';
import '../../../../core/network/dio_client.dart';

class NotificationsNotifier extends AsyncNotifier<List<NotificationModel>> {
  @override
  Future<List<NotificationModel>> build() async {
    return await _fetchNotifications();
  }

  Future<List<NotificationModel>> _fetchNotifications() async {
    try {
      final client = ref.read(dioClientProvider);
      final response = await client.get('/api/notifications/');
      final List<dynamic> data = response.data is List
          ? response.data
          : response.data['results'] ?? [];
      return data
          .map((json) => NotificationModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Endpoint not yet implemented — return empty list gracefully
      return [];
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchNotifications());
  }

  Future<void> markAsRead(String id) async {
    final current = state.asData?.value;
    if (current == null) return;
    state = AsyncData(
      current.map((n) => n.id == id ? n.copyWith(isRead: true) : n).toList(),
    );
    // Fire and forget PATCH when endpoint is available
    try {
      final client = ref.read(dioClientProvider);
      await client.patch('/api/notifications/$id/', data: {'is_read': true});
    } catch (_) {
      // Silently ignore until endpoint exists
    }
  }

  Future<void> markAllAsRead() async {
    final current = state.asData?.value;
    if (current == null) return;
    state = AsyncData(
      current.map((n) => n.copyWith(isRead: true)).toList(),
    );
  }

  int get unreadCount =>
      state.asData?.value.where((n) => !n.isRead).length ?? 0;
}

final notificationsProvider =
    AsyncNotifierProvider<NotificationsNotifier, List<NotificationModel>>(
        () => NotificationsNotifier());