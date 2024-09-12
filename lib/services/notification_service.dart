// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:flutter/material.dart';
//
// class NotificationService {
//   final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
//   final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
//
//   NotificationService() {
//     _initialize();
//   }
//
//   void _initialize() async {
//     // Request permissions for iOS
//     NotificationSettings settings = await _firebaseMessaging.requestPermission(
//       alert: true,
//       announcement: false,
//       badge: true,
//       carPlay: false,
//       criticalAlert: false,
//       provisional: false,
//       sound: true,
//     );
//
//     if (settings.authorizationStatus == AuthorizationStatus.authorized) {
//       print('User granted permission');
//     } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
//       print('User granted provisional permission');
//     } else {
//       print('User declined or has not accepted permission');
//     }
//
//     // Initialize local notifications for Android and iOS
//     const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@drawable/ic_stat_directions_run');
//     const DarwinInitializationSettings initializationSettingsDarwin = DarwinInitializationSettings();
//     const InitializationSettings initializationSettings = InitializationSettings(
//       android: initializationSettingsAndroid,
//       iOS: initializationSettingsDarwin,
//     );
//
//     await _flutterLocalNotificationsPlugin.initialize(
//       initializationSettings,
//       onDidReceiveNotificationResponse: (NotificationResponse response) async {
//         // Handle notification tapped logic here
//       },
//     );
//
//     FirebaseMessaging.onMessage.listen((RemoteMessage message) {
//       print('Received a message in the foreground: ${message.messageId}');
//       _showNotification(message);
//     });
//
//     FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
//       print('Message clicked!');
//       // Handle the message
//     });
//
//     String? token = await getToken();
//     if (token != null) {
//       print("FCM Token: $token");
//       // Send the token to your backend server if needed
//     }
//   }
//
//   Future<String?> getToken() async {
//     return await _firebaseMessaging.getToken();
//   }
//
//   Future<void> _showNotification(RemoteMessage message) async {
//     const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
//       'virtualfitnessph_channel',
//       'VirtualFitness PH Notifications',
//       channelDescription: 'This channel is used for VirtualFitness PH notifications.',
//       importance: Importance.max,
//       priority: Priority.high,
//       icon: '@drawable/ic_stat_directions_run', // Reference your custom icon here
//     );
//     const DarwinNotificationDetails iosPlatformChannelSpecifics = DarwinNotificationDetails();
//
//     const NotificationDetails platformChannelSpecifics = NotificationDetails(
//       android: androidPlatformChannelSpecifics,
//       iOS: iosPlatformChannelSpecifics,
//     );
//
//     await _flutterLocalNotificationsPlugin.show(
//       0,
//       message.data['title'] ?? 'VirtualFitness PH',
//       message.data['message'] ?? 'You have a new message.',
//       platformChannelSpecifics,
//     );
//   }
// }