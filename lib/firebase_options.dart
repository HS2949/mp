// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        return windows;
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
    apiKey: 'AIzaSyBSH5sEhfLJMbcwdZbz87l47WVw21D1O84',
    appId: '1:92720287535:web:cc939a4c065b408dcc5bda',
    messagingSenderId: '92720287535',
    projectId: 'mice-plan-bc6ae',
    authDomain: 'mice-plan-bc6ae.firebaseapp.com',
    storageBucket: 'mice-plan-bc6ae.firebasestorage.app',
    measurementId: 'G-TPCQ23BXFQ',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD2pGremjNFmXOq8NXKXTBf5v9rbw23am4',
    appId: '1:92720287535:android:841f0a4c3b6f5b86cc5bda',
    messagingSenderId: '92720287535',
    projectId: 'mice-plan-bc6ae',
    storageBucket: 'mice-plan-bc6ae.firebasestorage.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBSH5sEhfLJMbcwdZbz87l47WVw21D1O84',
    appId: '1:92720287535:web:dc2d4076a567ddefcc5bda',
    messagingSenderId: '92720287535',
    projectId: 'mice-plan-bc6ae',
    authDomain: 'mice-plan-bc6ae.firebaseapp.com',
    storageBucket: 'mice-plan-bc6ae.firebasestorage.app',
    measurementId: 'G-8QM87B2166',
  );

}