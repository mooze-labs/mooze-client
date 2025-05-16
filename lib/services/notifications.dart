import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final StreamController<RemoteMessage> _messageStreamController =
      StreamController<RemoteMessage>.broadcast();

  // Stream that can be listened to for notification events
  Stream<RemoteMessage> get onNotificationReceived =>
      _messageStreamController.stream;

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  Future<void> initialize() async {
    // Initialize Firebase if not already initialized
    await Firebase.initializeApp();

    // Request permission
    await _requestPermissions();

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Configure FCM callbacks
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Listen for token refreshes
    _messaging.onTokenRefresh.listen(_handleTokenRefresh);

    // Check for initial message (app opened from terminated state)
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleInitialMessage(initialMessage);
    }

    // Get FCM token and store it
    await getToken();
  }

  Future<void> _requestPermissions() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint('User granted permission: ${settings.authorizationStatus}');
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        );

    final InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Notification response received: ${response.payload}');
        // Handle notification tap
        if (response.payload != null) {
          final Map<String, dynamic> data = json.decode(response.payload!);
          // Handle the payload
          _handleNotificationTap(data);
        }
      },
    );

    // Create notification channel for Android
    await _createNotificationChannel();
  }

  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'mooze_notifications', // id
      'Mooze Notifications', // title
      description: 'Notifications from Mooze app', // description
      importance: Importance.high,
    );

    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _localNotifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(channel);
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Got a message whilst in the foreground!');
    debugPrint('Message data: ${message.data}');

    if (message.notification != null) {
      debugPrint(
        'Message also contained a notification: ${message.notification!.title}',
      );

      // Display local notification
      _showLocalNotification(message);
    }

    // Add to stream
    _messageStreamController.add(message);
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('A new onMessageOpenedApp event was published!');
    debugPrint('Message data: ${message.data}');

    // Add to stream
    _messageStreamController.add(message);

    // Handle navigation or other logic when app is opened from notification
    _handleNotificationTap(message.data);
  }

  void _handleInitialMessage(RemoteMessage message) {
    debugPrint(
      'App opened from terminated state with message: ${message.data}',
    );

    // Add to stream
    _messageStreamController.add(message);

    // Handle navigation or other logic
    _handleNotificationTap(message.data);
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'mooze_notifications',
            'Mooze Notifications',
            channelDescription: 'Notifications from Mooze app',
            icon: android.smallIcon,
            // Other customization options
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        payload: json.encode(message.data),
      );
    }
  }

  void _handleNotificationTap(Map<String, dynamic> data) {
    // Implement navigation logic based on notification data
    // For example, if the notification contains a transactionId, navigate to the transaction details screen
    if (data.containsKey('transactionId')) {
      // Example: NavigationService.navigateTo('/transaction/${data['transactionId']}');
      debugPrint('Should navigate to transaction: ${data['transactionId']}');
    }
  }

  Future<String?> getToken() async {
    String? token = (kDebugMode) ? "mockFcmToken" : await _messaging.getToken();

    if (token != null) {
      debugPrint('FCM Token: $token');

      // Store the token in SharedPreferences for later use
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', token);
    }

    return token;
  }

  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    debugPrint('Subscribed to topic: $topic');
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    debugPrint('Unsubscribed from topic: $topic');
  }

  void dispose() {
    _messageStreamController.close();
  }

  void _handleTokenRefresh(String token) async {
    debugPrint('FCM Token refreshed: $token');

    // Store the refreshed token
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fcm_token', token);

    // Update the token on your backend
    await _updateTokenOnServer(token);
  }

  Future<void> _updateTokenOnServer(String token) async {
    // Get the stored hashed descriptor (user_id)
    final prefs = await SharedPreferences.getInstance();
    final hashedDescriptor = prefs.getString('hashed_descriptor');

    if (hashedDescriptor != null) {
      try {
        // Get platform information
        final platform = Platform.isAndroid ? "android" : "ios";

        // Update token on server using the API endpoint
        final response = await http.post(
          Uri.parse('https://api.mooze.app/users/fcm'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'user_id': hashedDescriptor,
            'fcm_token': token,
            'platform': platform,
          }),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          debugPrint('FCM token successfully updated on server');
        } else {
          debugPrint(
            'Failed to update FCM token on server: ${response.statusCode}',
          );
          if (kDebugMode) {
            debugPrint('Response: ${response.body}');
          }
        }
      } catch (e) {
        debugPrint('Error updating FCM token on server: $e');
      }
    } else {
      debugPrint('Could not update FCM token: user ID not found');
    }
  }
}

// Must be a top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase if needed (might be necessary for background handling)
  await Firebase.initializeApp();

  debugPrint("Handling a background message: ${message.messageId}");
  // We can't access the instance methods here, so we need to handle
  // background notifications differently
}
