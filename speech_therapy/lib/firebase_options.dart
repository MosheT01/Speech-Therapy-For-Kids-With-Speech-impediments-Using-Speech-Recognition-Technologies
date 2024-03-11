// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
//needs fixing

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
    apiKey: 'AIzaSyC31BJJ3rk64QtJERsUpr_ZV29qfMjDx20',
    appId: '1:474954764415:web:b619094c282c6039cf6f4a',
    messagingSenderId: '474954764415',
    projectId: 'speechtherapyapp-88a94',
    authDomain: 'speechtherapyapp-88a94.firebaseapp.com',
    storageBucket: 'speechtherapyapp-88a94.appspot.com',
    measurementId: 'G-XWYL0VQGLJ',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB5MPO6d4ZFTW4tFcrkRa50IHJzb5K4eEA',
    appId: '1:474954764415:android:fd107191eeb8a016cf6f4a',
    messagingSenderId: '474954764415',
    projectId: 'speechtherapyapp-88a94',
    storageBucket: 'speechtherapyapp-88a94.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDZcGx48qmyuvyyzTrnAQ3qu6O3LqZphEI',
    appId: '1:474954764415:ios:75a2c58e108a525ecf6f4a',
    messagingSenderId: '474954764415',
    projectId: 'speechtherapyapp-88a94',
    storageBucket: 'speechtherapyapp-88a94.appspot.com',
    iosBundleId: 'com.example.speechTherapy',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDZcGx48qmyuvyyzTrnAQ3qu6O3LqZphEI',
    appId: '1:474954764415:ios:161ae96b1df6db4ccf6f4a',
    messagingSenderId: '474954764415',
    projectId: 'speechtherapyapp-88a94',
    storageBucket: 'speechtherapyapp-88a94.appspot.com',
    iosBundleId: 'com.example.speechTherapy.RunnerTests',
  );
}
