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
    apiKey: 'AIzaSyAO46EuPdTFaPjnsaI6fdpMmcAzQvUi9QQ',
    appId: '1:1068036128780:web:68cd37686775fd8e292e29',
    messagingSenderId: '1068036128780',
    projectId: 'agro-ia-iot',
    authDomain: 'agro-ia-iot.firebaseapp.com',
    databaseURL: 'https://agro-ia-iot-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'agro-ia-iot.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBuNKyWhOA5eV8SN5ipDAOGlke6jwp6SjE',
    appId: '1:1068036128780:android:deba5daa5c1c52c0292e29',
    messagingSenderId: '1068036128780',
    projectId: 'agro-ia-iot',
    databaseURL: 'https://agro-ia-iot-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'agro-ia-iot.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC695V4ju4hdo_JkcBS2W41FPONHtHtyjI',
    appId: '1:1068036128780:ios:9a0340b34ce5b449292e29',
    messagingSenderId: '1068036128780',
    projectId: 'agro-ia-iot',
    databaseURL: 'https://agro-ia-iot-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'agro-ia-iot.firebasestorage.app',
    iosBundleId: 'fr.agroIA.agroIa',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyC695V4ju4hdo_JkcBS2W41FPONHtHtyjI',
    appId: '1:1068036128780:ios:9a0340b34ce5b449292e29',
    messagingSenderId: '1068036128780',
    projectId: 'agro-ia-iot',
    databaseURL: 'https://agro-ia-iot-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'agro-ia-iot.firebasestorage.app',
    iosBundleId: 'fr.agroIA.agroIa',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAO46EuPdTFaPjnsaI6fdpMmcAzQvUi9QQ',
    appId: '1:1068036128780:web:bf102cbf4f39a648292e29',
    messagingSenderId: '1068036128780',
    projectId: 'agro-ia-iot',
    authDomain: 'agro-ia-iot.firebaseapp.com',
    databaseURL: 'https://agro-ia-iot-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'agro-ia-iot.firebasestorage.app',
  );
}
