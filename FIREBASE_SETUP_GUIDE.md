# Guía de Configuración de Firebase para Notificaciones Push

## Problema Identificado

Tu app no está recibiendo notificaciones push porque:

1. **Archivos de configuración con datos de ejemplo**: Los archivos `firebase_options.dart` y `google-services.json` contienen valores de ejemplo, no las claves reales.
2. **Falta configuración de Cloud Messaging**: Firebase Cloud Messaging no está configurado correctamente.
3. **Token FCM no se envía al servidor**: El token de dispositivo no se está enviando a tu backend.

## Pasos para Solucionar

### 1. Configurar Firebase Console

1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Crea un nuevo proyecto o selecciona tu proyecto existente
3. Agrega una app Android:
   - Package name: `com.example.quinielas_app_v3`
   - Nickname: `Quinielas App`
   - Debug signing certificate SHA-1: (opcional por ahora)

### 2. Descargar google-services.json

1. En la configuración de tu app Android, descarga el archivo `google-services.json`
2. Reemplaza el archivo existente en `android/app/google-services.json`
3. **IMPORTANTE**: El archivo debe contener la configuración completa de FCM

### 3. Configurar firebase_options.dart

1. Instala FlutterFire CLI:
   ```bash
   dart pub global activate flutterfire_cli
   ```

2. Ejecuta la configuración:
   ```bash
   flutterfire configure
   ```

3. Esto generará automáticamente el archivo `firebase_options.dart` con las claves reales.

### 4. Verificar Configuración de Android

Tu `android/app/build.gradle.kts` ya está configurado correctamente:
- `minSdk = 23` ✅
- `desugar_jdk_libs:2.1.4` ✅

### 5. Implementar Envío de Token al Servidor

En `lib/services/notification_service.dart`, implementa la función `_sendTokenToServer`:

```dart
static Future<void> _sendTokenToServer(String token) async {
  try {
    final response = await http.post(
      Uri.parse('https://tu-api.com/fcm-tokens'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': 'user_id_here', // Obtener del estado de la app
        'fcm_token': token,
        'device_type': 'android',
        'app_version': '1.0.0'
      }),
    );
    
    if (response.statusCode == 200) {
      print('Token FCM enviado exitosamente al servidor');
    } else {
      print('Error enviando token al servidor: ${response.statusCode}');
    }
    
  } catch (e) {
    print('Error enviando token FCM al servidor: $e');
  }
}
```

### 6. Configurar Servidor para Enviar Notificaciones

Tu servidor debe enviar notificaciones usando la API de Firebase:

```bash
POST https://fcm.googleapis.com/fcm/send
Headers:
  Authorization: key=YOUR_SERVER_KEY
  Content-Type: application/json

Body:
{
  "to": "/topics/quinielas_general",
  "notification": {
    "title": "🏈 Nuevo Resultado",
    "body": "Se ha actualizado el resultado de una quiniela"
  },
  "data": {
    "type": "resultado_quiniela",
    "quiniela_id": "123",
    "equipo_ganador": "Patriots",
    "equipo_perdedor": "Jets"
  }
}
```

### 7. Probar Notificaciones

1. Ejecuta la app y ve a la pantalla de debug: `/debug`
2. Verifica que el token FCM se obtenga correctamente
3. Prueba las notificaciones locales
4. Envía el token al servidor
5. Suscríbete a temas de prueba

## Verificaciones Importantes

### En la Consola de Firebase:
- ✅ Cloud Messaging está habilitado
- ✅ La app Android está registrada
- ✅ Las credenciales del servidor están disponibles

### En tu App:
- ✅ Firebase se inicializa correctamente
- ✅ Se obtiene el token FCM
- ✅ Se solicitan permisos de notificación
- ✅ El token se envía al servidor

### En tu Servidor:
- ✅ Endpoint para recibir tokens FCM
- ✅ Lógica para enviar notificaciones push
- ✅ Manejo de temas y usuarios

## Comandos de Debug

```bash
# Limpiar y reconstruir
flutter clean
flutter pub get
flutter build apk --debug

# Ver logs de Firebase
flutter logs
```

## Archivos a Verificar

1. `android/app/google-services.json` - Configuración de Firebase
2. `lib/firebase_options.dart` - Opciones de Firebase
3. `lib/services/notification_service.dart` - Servicio de notificaciones
4. `lib/main.dart` - Inicialización de Firebase

## Próximos Pasos

1. Configura Firebase Console con tu proyecto real
2. Descarga y configura `google-services.json`
3. Ejecuta `flutterfire configure`
4. Implementa el envío de token al servidor
5. Prueba las notificaciones desde la pantalla de debug
6. Configura tu servidor para enviar notificaciones push

Una vez completados estos pasos, las notificaciones push deberían funcionar correctamente.
