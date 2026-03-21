import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        return android;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyExample',
    appId: '1:example:web:example',
    messagingSenderId: '000000000000',
    projectId: 'small-store-720bb',
    storageBucket: 'small-store-720bb.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyExample',
    appId: '1:example:android:example',
    messagingSenderId: '000000000000',
    projectId: 'small-store-720bb',
    storageBucket: 'small-store-720bb.firebasestorage.app',
  );
}
