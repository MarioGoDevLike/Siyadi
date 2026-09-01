// Generated for Firebase project siyadi-lb (shared with mobile app).
// ignore_for_file: lines_longer_than_80_chars

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return web;
      case TargetPlatform.iOS:
        return web;
      case TargetPlatform.macOS:
        return web;
      case TargetPlatform.windows:
        return web;
      case TargetPlatform.linux:
        return web;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA0ZFB3P9N3dqoJsnf2x3g6zkSnkKOpxmo',
    appId: '1:910645534873:web:39ecb59e95e33c45629808',
    messagingSenderId: '910645534873',
    projectId: 'siyadi-lb',
    authDomain: 'siyadi-lb.firebaseapp.com',
    storageBucket: 'siyadi-lb.firebasestorage.app',
  );
}
