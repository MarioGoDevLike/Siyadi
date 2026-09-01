// File generated for Firebase project siyadi-lb.
// Prefer regenerating with: flutterfire configure --project=siyadi-lb
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
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux — '
          'run flutterfire configure.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBlvHuaqe1hcJjY8DDa-61MHEkudbbKLQo',
    appId: '1:910645534873:android:40289125b4352c76629808',
    messagingSenderId: '910645534873',
    projectId: 'siyadi-lb',
    storageBucket: 'siyadi-lb.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBmi_tSwyQMVVw-JMMcDSAEIl-xaOMH6Fw',
    appId: '1:910645534873:ios:862aef7eb3c2a71f629808',
    messagingSenderId: '910645534873',
    projectId: 'siyadi-lb',
    storageBucket: 'siyadi-lb.firebasestorage.app',
    iosBundleId: 'com.siyadi.siyadi',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBmi_tSwyQMVVw-JMMcDSAEIl-xaOMH6Fw',
    appId: '1:910645534873:ios:862aef7eb3c2a71f629808',
    messagingSenderId: '910645534873',
    projectId: 'siyadi-lb',
    storageBucket: 'siyadi-lb.firebasestorage.app',
    iosBundleId: 'com.siyadi.siyadi',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyA0ZFB3P9N3dqoJsnf2x3g6zkSnkKOpxmo',
    appId: '1:910645534873:web:39ecb59e95e33c45629808',
    messagingSenderId: '910645534873',
    projectId: 'siyadi-lb',
    authDomain: 'siyadi-lb.firebaseapp.com',
    storageBucket: 'siyadi-lb.firebasestorage.app',
  );
}
