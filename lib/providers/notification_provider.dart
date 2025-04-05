import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:mooze_mobile/services/notification_service.dart';

part 'notification_provider.g.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final service = NotificationService();
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

@riverpod
Stream<RemoteMessage> notifications(NotificationsRef ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  return notificationService.onNotificationReceived;
}