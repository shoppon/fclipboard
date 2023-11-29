// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
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
    apiKey: 'AIzaSyDgaX-I-JjZDg2-e5NnLG69F2V-LkWSgUg',
    appId: '1:748110936399:web:084d9e5fc6c0e1261a2d3a',
    messagingSenderId: '748110936399',
    projectId: 'shoppon',
    authDomain: 'shoppon.firebaseapp.com',
    storageBucket: 'shoppon.appspot.com',
    measurementId: 'G-Q3BY4ZB6EL',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD1SwJ9EmNj0ULV21jRz_0G5RjA8kioE_g',
    appId: '1:748110936399:android:a0881e37b170ab791a2d3a',
    messagingSenderId: '748110936399',
    projectId: 'shoppon',
    storageBucket: 'shoppon.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCpK1dQELhDMBKRbQ2HMEyzAIcG6KmjcBE',
    appId: '1:748110936399:ios:8884265599bd30841a2d3a',
    messagingSenderId: '748110936399',
    projectId: 'shoppon',
    storageBucket: 'shoppon.appspot.com',
    iosClientId: '748110936399-pv5r7gkeb46ch66c4g8hoh8n0ojqq7dn.apps.googleusercontent.com',
    iosBundleId: 'com.shoppon.fclipboard',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCpK1dQELhDMBKRbQ2HMEyzAIcG6KmjcBE',
    appId: '1:748110936399:ios:100885d7ae0500661a2d3a',
    messagingSenderId: '748110936399',
    projectId: 'shoppon',
    storageBucket: 'shoppon.appspot.com',
    iosClientId: '748110936399-muciuelgki5n6klvpmtd5s61urm673ca.apps.googleusercontent.com',
    iosBundleId: 'com.shoppon.fclipboard.RunnerTests',
  );
}