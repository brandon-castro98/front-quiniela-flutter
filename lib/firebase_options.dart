import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBvEXAMPLE_KEY_HERE',
    appId: '1:123456789012:web:abcdef1234567890',
    messagingSenderId: '123456789012',
    projectId: 'quinielas-nfl-app',
    authDomain: 'quinielas-nfl-app.firebaseapp.com',
    storageBucket: 'quinielas-nfl-app.appspot.com',
    measurementId: 'G-EXAMPLE123',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBvEXAMPLE_KEY_HERE',
    appId: '1:123456789012:android:abcdef1234567890',
    messagingSenderId: '123456789012',
    projectId: 'quinielas-nfl-app',
    storageBucket: 'quinielas-nfl-app.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBvEXAMPLE_KEY_HERE',
    appId: '1:123456789012:ios:abcdef1234567890',
    messagingSenderId: '123456789012',
    projectId: 'quinielas-nfl-app',
    storageBucket: 'quinielas-nfl-app.appspot.com',
    iosClientId: '123456789012-abcdef1234567890.apps.googleusercontent.com',
    iosBundleId: 'com.example.quinielasApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBvEXAMPLE_KEY_HERE',
    appId: '1:123456789012:ios:abcdef1234567890',
    messagingSenderId: '123456789012',
    projectId: 'quinielas-nfl-app',
    storageBucket: 'quinielas-nfl-app.appspot.com',
    iosClientId: '123456789012-abcdef1234567890.apps.googleusercontent.com',
    iosBundleId: 'com.example.quinielasApp',
  );
}
