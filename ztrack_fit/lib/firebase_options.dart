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
    apiKey: 'AIzaSyC9VaNOAUSbl7m8vHv865zU90fonTRbhcs',
    appId: '1:404355715471:web:7e0dbb2f79cb1756e8fbfa',
    messagingSenderId: '404355715471',
    projectId: 'fittrack-486dd',
    authDomain: 'fittrack-486dd.firebaseapp.com',
    databaseURL: 'https://fittrack-486dd-default-rtdb.firebaseio.com',
    storageBucket: 'fittrack-486dd.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBNx9oh4WC-2g6iXvKoT6cvSxWNB6Zfo0I',
    appId: '1:404355715471:android:1ddfae21e7acce5ae8fbfa',
    messagingSenderId: '404355715471',
    projectId: 'fittrack-486dd',
    databaseURL: 'https://fittrack-486dd-default-rtdb.firebaseio.com',
    storageBucket: 'fittrack-486dd.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAc-Rm4R3dqifchUWzZuIPRwUhyQ9cSywM',
    appId: '1:404355715471:ios:1f2c01ea4513b195e8fbfa',
    messagingSenderId: '404355715471',
    projectId: 'fittrack-486dd',
    databaseURL: 'https://fittrack-486dd-default-rtdb.firebaseio.com',
    storageBucket: 'fittrack-486dd.firebasestorage.app',
    iosBundleId: 'com.example.ztrackFit',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAc-Rm4R3dqifchUWzZuIPRwUhyQ9cSywM',
    appId: '1:404355715471:ios:1f2c01ea4513b195e8fbfa',
    messagingSenderId: '404355715471',
    projectId: 'fittrack-486dd',
    databaseURL: 'https://fittrack-486dd-default-rtdb.firebaseio.com',
    storageBucket: 'fittrack-486dd.firebasestorage.app',
    iosBundleId: 'com.example.ztrackFit',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyC9VaNOAUSbl7m8vHv865zU90fonTRbhcs',
    appId: '1:404355715471:web:310838805cc2febbe8fbfa',
    messagingSenderId: '404355715471',
    projectId: 'fittrack-486dd',
    authDomain: 'fittrack-486dd.firebaseapp.com',
    databaseURL: 'https://fittrack-486dd-default-rtdb.firebaseio.com',
    storageBucket: 'fittrack-486dd.firebasestorage.app',
  );
}
