import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

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
        return web;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDdOVyhfYHhzwyg8Hstd8-RcCgx_VQq2mE',
    appId: '1:892513363343:web:84c836b3a2a239fa7697fa',
    messagingSenderId: '892513363343',
    projectId: 'mxpertztest-da18a',
    authDomain: 'mxpertztest-da18a.firebaseapp.com',
    storageBucket: 'mxpertztest-da18a.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC5pjd5lclNb3srI4L9TMyru0U67aUs7Wk',
    appId: '1:892513363343:android:d27f06bc879b2dae7697fa',
    messagingSenderId: '892513363343',
    projectId: 'mxpertztest-da18a',
    storageBucket: 'mxpertztest-da18a.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC89E4C-rJFi6Po7QwjvLj26ugJ9xtZugk',
    appId: '1:892513363343:ios:78e2282a5964d4e17697fa',
    messagingSenderId: '892513363343',
    projectId: 'mxpertztest-da18a',
    storageBucket: 'mxpertztest-da18a.firebasestorage.app',
    iosBundleId: 'com.example.mxpertzTest',
  );
}
