// Reuse the project's Firebase options. Generated minimal shim to allow initializeApp
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      default:
        return android;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDaOBY6iFMLXhsiuCb-cRPAHh6hfC3atJg',
    appId: '1:866148282057:web:9b9d52a72144923e14a718',
    messagingSenderId: '866148282057',
    projectId: 'coder-s-cup-minigames',
    authDomain: 'coder-s-cup-minigames.firebaseapp.com',
    storageBucket: 'coder-s-cup-minigames.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAGXXiX9M-pHN6p3spzSbnEZ6uM-2gPm5Q',
    appId: '1:866148282057:android:820a4a338bf3519014a718',
    messagingSenderId: '866148282057',
    projectId: 'coder-s-cup-minigames',
    storageBucket: 'coder-s-cup-minigames.firebasestorage.app',
  );
}
