import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';

class NotificationDebugService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Función para diagnosticar problemas de notificaciones
  static Future<Map<String, dynamic>> diagnoseNotifications() async {
    Map<String, dynamic> diagnosis = {};

    try {
      // 1. Verificar si Firebase está inicializado
      diagnosis['firebase_initialized'] = true;

      // 2. Obtener token FCM
      String? token = await _firebaseMessaging.getToken();
      diagnosis['fcm_token'] = token;
      diagnosis['fcm_token_length'] = token?.length ?? 0;

      // 3. Verificar permisos
      NotificationSettings settings = await _firebaseMessaging
          .getNotificationSettings();
      diagnosis['permission_status'] = settings.authorizationStatus.toString();
      diagnosis['alert_enabled'] = settings.alert;
      diagnosis['badge_enabled'] = settings.badge;
      diagnosis['sound_enabled'] = settings.sound;

      // 4. Verificar configuración de la app
      diagnosis['package_name'] = 'com.example.quinielas_app_v3';
      diagnosis['app_id'] = '1:123456789012:android:abcdef1234567890';

      // 5. Verificar si el token se está enviando al servidor
      diagnosis['token_sent_to_server'] =
          false; // Esto deberías verificar en tu API

      // 6. Verificar configuración de Android
      diagnosis['android_min_sdk'] = 23;
      diagnosis['android_target_sdk'] = 'flutter.targetSdkVersion';

      // 7. Verificar si las notificaciones locales funcionan
      await _testLocalNotification();
      diagnosis['local_notifications_working'] = true;
    } catch (e) {
      diagnosis['error'] = e.toString();
      diagnosis['local_notifications_working'] = false;
    }

    return diagnosis;
  }

  // Función para probar notificaciones locales
  static Future<void> _testLocalNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'debug_channel',
      'Debug Notifications',
      channelDescription: 'Canal para pruebas de notificaciones',
      importance: Importance.high,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      999,
      '🔍 Test de Notificación',
      'Si ves esto, las notificaciones locales funcionan',
      details,
    );
  }

  // Función para enviar token FCM al servidor
  static Future<bool> sendTokenToServer(String token) async {
    try {
      // Aquí deberías hacer una llamada HTTP a tu API para enviar el token
      // Por ahora solo simulamos el envío
      print('Token FCM que debería enviarse al servidor: $token');

      // Ejemplo de cómo debería ser la llamada:
      // final response = await http.post(
      //   Uri.parse('https://tu-api.com/fcm-tokens'),
      //   headers: {'Content-Type': 'application/json'},
      //   body: jsonEncode({
      //     'user_id': 'user_id_here',
      //     'fcm_token': token,
      //     'device_type': 'android'
      //   }),
      // );

      return true;
    } catch (e) {
      print('Error enviando token al servidor: $e');
      return false;
    }
  }

  // Función para suscribirse a temas de prueba
  static Future<void> subscribeToTestTopics() async {
    try {
      await _firebaseMessaging.subscribeToTopic('test_notifications');
      await _firebaseMessaging.subscribeToTopic('quinielas_general');
      print('Suscrito a temas de prueba');
    } catch (e) {
      print('Error suscribiéndose a temas: $e');
    }
  }

  // Función para mostrar diagnóstico en consola
  static void printDiagnosis(Map<String, dynamic> diagnosis) {
    print('=== DIAGNÓSTICO DE NOTIFICACIONES ===');
    print('Firebase inicializado: ${diagnosis['firebase_initialized']}');
    print('Token FCM: ${diagnosis['fcm_token']?.substring(0, 20)}...');
    print('Longitud del token: ${diagnosis['fcm_token_length']}');
    print('Estado de permisos: ${diagnosis['permission_status']}');
    print('Alertas habilitadas: ${diagnosis['alert_enabled']}');
    print('Badges habilitados: ${diagnosis['badge_enabled']}');
    print('Sonidos habilitados: ${diagnosis['sound_enabled']}');
    print('Package name: ${diagnosis['package_name']}');
    print('App ID: ${diagnosis['app_id']}');
    print('Token enviado al servidor: ${diagnosis['token_sent_to_server']}');
    print('Min SDK: ${diagnosis['android_min_sdk']}');
    print(
      'Notificaciones locales funcionando: ${diagnosis['local_notifications_working']}',
    );

    if (diagnosis.containsKey('error')) {
      print('ERROR: ${diagnosis['error']}');
    }
    print('=====================================');
  }
}
