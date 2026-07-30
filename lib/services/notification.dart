import 'dart:io';
import 'dart:math';

import 'package:wallrio/services/export.dart';
import 'package:wallrio/services/firebase/export.dart';
import 'package:wallrio/services/packages/export.dart';
import 'package:wallrio/ui/widgets/export.dart';

class NotificationService {
  AndroidNotificationChannel channel = const AndroidNotificationChannel(
    'new_walls_notifications',
    'New Content Notifications',
    description: 'This channel is used for new content notifications.',
    playSound: true,
    importance: Importance.high,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // 1. Request iOS & Android System Notification Permissions
    await Permission.notification.request();

    if (Platform.isIOS) {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      logger.i('[NotificationService] iOS FCM Permission Status: ${settings.authorizationStatus}');
      
      try {
        final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        logger.i('[NotificationService] iOS APNs Token: $apnsToken');
      } catch (e) {
        logger.w('[NotificationService] Error fetching iOS APNs Token: $e');
      }
    }

    // 2. Configure Local Notification Settings for Android & iOS (Darwin)
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('ic_notification');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse:
          (NotificationResponse notificationResponse) {
        if (notificationResponse.notificationResponseType ==
            NotificationResponseType.selectedNotification) {
          onDidReceiveLocalNotification(notificationResponse.payload ?? "");
        }
      },
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 3. Configure Foreground Notification Presentation Options for iOS & Android
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 4. Subscribe to default broadcast topics
    try {
      await FirebaseMessaging.instance.subscribeToTopic('all');
      await FirebaseMessaging.instance.subscribeToTopic('new_walls');
      logger.i('[NotificationService] Subscribed to default notification topics ("all", "new_walls").');
    } catch (e) {
      logger.e('[NotificationService] Topic subscription error: $e');
    }

    initFirebaseListeners();
  }

  void onDidReceiveLocalNotification(String payload) {
    if (payload.isNotEmpty) {
      launch(payload);
    }
  }

  void initFirebaseListeners() {
    // A. Foreground message listener
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      logger.i('[NotificationService] Foreground message received: ${message.notification?.title}');
      showNotifications(message: message);
    });

    // B. Background notification tap listener
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      logger.i('[NotificationService] Notification opened app from background: ${message.data}');
      final String? link = message.data['link'];
      if (link != null && link.isNotEmpty) {
        launch(link);
      }
    });

    // C. Terminated app notification tap listener
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        logger.i('[NotificationService] App launched from terminated state via notification: ${message.data}');
        final String? link = message.data['link'];
        if (link != null && link.isNotEmpty) {
          launch(link);
        }
      }
    });
  }

  Future<void> showNotifications({required RemoteMessage message}) async {
    final RemoteNotification? notification = message.notification;
    if (notification == null) return;

    final int id = Random().nextInt(900) + 10;
    await flutterLocalNotificationsPlugin.show(
      id: id,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          channelShowBadge: true,
          playSound: true,
          color: bgDarkAccentColor,
          priority: Priority.high,
          importance: Importance.high,
          styleInformation: BigTextStyleInformation(notification.body ?? ''),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: message.data["link"],
    );
  }

  void launch(String url) => LaunchUrlWidget.launch(url);
}
