import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'api_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;

  static const String _channelId = 'quiniela_notifications';
  static const String _channelName = 'Quiniela Notifications';
  static const String _channelDescription =
      'Notificaciones de resultados de quinielas';

  // Inicializar el servicio de notificaciones
  static Future<void> initialize() async {
    try {
      // Configurar notificaciones locales
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Crear canal de notificaciones para Android
      const androidChannel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(androidChannel);

      // Configurar Firebase Messaging
      await _configureFirebaseMessaging();

      // Solicitar permisos
      await _requestPermissions();
    } catch (e) {
      print('Error initializing notifications: $e');
    }
  }

  // Configurar Firebase Messaging
  static Future<void> _configureFirebaseMessaging() async {
    try {
      // Manejar mensajes en primer plano
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Manejar cuando se abre la app desde una notificación
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      // Manejar cuando se abre la app desde una notificación cerrada
      FirebaseMessaging.instance.getInitialMessage().then(
        _handleInitialMessage,
      );
    } catch (e) {
      print('Error configuring Firebase Messaging: $e');
    }
  }

  // Solicitar permisos
  static Future<void> _requestPermissions() async {
    try {
      // Permisos para notificaciones locales (Android 13+)
      if (await _localNotifications
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.areNotificationsEnabled() ==
          false) {
        // En Android 13+, los permisos se manejan automáticamente
        print('Notifications not enabled on Android');
      }

      // Permisos para Firebase
      NotificationSettings settings = await _firebaseMessaging
          .requestPermission(
            alert: true,
            announcement: false,
            badge: true,
            carPlay: false,
            criticalAlert: false,
            provisional: false,
            sound: true,
          );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('User granted permission');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        print('User granted provisional permission');
      } else {
        print('User declined or has not accepted permission');
      }
    } catch (e) {
      print('Error requesting permissions: $e');
    }
  }

  // Obtener token de FCM
  static Future<String?> getToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();

      if (token != null) {
        print('FCM Token obtenido: ${token.substring(0, 20)}...');

        // Enviar token al servidor automáticamente
        await _sendTokenToServer(token);

        // Suscribirse a temas generales
        await _subscribeToGeneralTopics();
      }

      return token;
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }

  // Enviar token FCM al servidor
  static Future<void> _sendTokenToServer(String token) async {
    try {
      // Usar tu API real para enviar el token FCM
      final success = await ApiService.sendFcmToken(token);

      if (success) {
        print('Token FCM enviado exitosamente al servidor');
      } else {
        print('Error enviando token FCM al servidor');
      }
    } catch (e) {
      print('Error enviando token FCM al servidor: $e');
    }
  }

  // Suscribirse a temas generales
  static Future<void> _subscribeToGeneralTopics() async {
    try {
      await _firebaseMessaging.subscribeToTopic('quinielas_general');
      await _firebaseMessaging.subscribeToTopic('resultados_nfl');
      print('Suscrito a temas generales de quinielas');
    } catch (e) {
      print('Error suscribiéndose a temas generales: $e');
    }
  }

  // Suscribirse a un tema (quiniela específica)
  static Future<void> subscribeToQuiniela(int quinielaId) async {
    try {
      await _firebaseMessaging.subscribeToTopic('quiniela_$quinielaId');
      print('Subscribed to quiniela_$quinielaId');
    } catch (e) {
      print('Error subscribing to quiniela: $e');
    }
  }

  // Desuscribirse de un tema
  static Future<void> unsubscribeFromQuiniela(int quinielaId) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic('quiniela_$quinielaId');
      print('Unsubscribed from quiniela_$quinielaId');
    } catch (e) {
      print('Error unsubscribing from quiniela: $e');
    }
  }

  // Manejar mensaje en primer plano
  static void _handleForegroundMessage(RemoteMessage message) {
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.data}');

    if (message.notification != null) {
      print('Message also contained a notification: ${message.notification}');
      _showLocalNotification(message);
    }
  }

  // Manejar cuando se abre la app desde una notificación
  static void _handleMessageOpenedApp(RemoteMessage message) {
    print('Message opened app: ${message.data}');
    _handleNotificationData(message.data);
  }

  // Manejar mensaje inicial
  static void _handleInitialMessage(RemoteMessage? message) {
    if (message != null) {
      print('Initial message: ${message.data}');
      _handleNotificationData(message.data);
    }
  }

  // Mostrar notificación local
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('notification_sound'),
        icon: '@mipmap/ic_launcher',
        color: Color(0xFFD50A0A),
        largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        styleInformation: BigTextStyleInformation(''),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'notification_sound.aiff',
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        message.hashCode,
        message.notification?.title ?? 'Nueva Notificación',
        message.notification?.body ?? 'Tienes una nueva notificación',
        details,
        payload: jsonEncode(message.data),
      );
    } catch (e) {
      print('Error showing local notification: $e');
    }
  }

  // Manejar datos de la notificación
  static void _handleNotificationData(Map<String, dynamic> data) {
    // Aquí puedes navegar a pantallas específicas basado en los datos
    // Por ejemplo, ir a la quiniela específica cuando se toca la notificación
    if (data['type'] == 'resultado_quiniela') {
      // Navegar a la quiniela específica
      print('Navigate to quiniela: ${data['quiniela_id']}');
    }
  }

  // Manejar cuando se toca una notificación local
  static void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!);
        _handleNotificationData(data);
      } catch (e) {
        print('Error parsing notification payload: $e');
      }
    }
  }

  // Mostrar notificación personalizada para resultados
  static Future<void> showResultNotification({
    required String quinielaName,
    required String equipoGanador,
    required String equipoPerdedor,
    required int quinielaId,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFF4CAF50),
        largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        styleInformation: BigTextStyleInformation(''),
        category: AndroidNotificationCategory.message,
        actions: [
          AndroidNotificationAction('view', 'Ver Quiniela'),
          AndroidNotificationAction('dismiss', 'Descartar'),
        ],
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        categoryIdentifier: 'RESULTADO_QUINIELA',
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        quinielaId,
        '🏈 Resultado de Quiniela',
        '$equipoGanador vs $equipoPerdedor\nGanador: $equipoGanador',
        details,
        payload: jsonEncode({
          'type': 'resultado_quiniela',
          'quiniela_id': quinielaId,
          'quiniela_name': quinielaName,
          'equipo_ganador': equipoGanador,
          'equipo_perdedor': equipoPerdedor,
        }),
      );
    } catch (e) {
      print('Error showing result notification: $e');
    }
  }

  // Limpiar todas las notificaciones
  static Future<void> clearAllNotifications() async {
    try {
      await _localNotifications.cancelAll();
    } catch (e) {
      print('Error clearing notifications: $e');
    }
  }

  // Limpiar notificación específica
  static Future<void> clearNotification(int id) async {
    try {
      await _localNotifications.cancel(id);
    } catch (e) {
      print('Error clearing notification: $e');
    }
  }
}
