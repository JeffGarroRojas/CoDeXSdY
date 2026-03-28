import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return web;
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBEGLETW0SSTgg8tcxJxAjDoKkn8Tdr5o8',
    authDomain: 'studyappdevelopment.firebaseapp.com',
    projectId: 'studyappdevelopment',
    storageBucket: 'studyappdevelopment.firebasestorage.app',
    messagingSenderId: '379115258066',
    appId: '1:379115258066:web:07e301722aac8577b5ad0b',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBEGLETW0SSTgg8tcxJxAjDoKkn8Tdr5o8',
    authDomain: 'studyappdevelopment.firebaseapp.com',
    projectId: 'studyappdevelopment',
    storageBucket: 'studyappdevelopment.firebasestorage.app',
    messagingSenderId: '379115258066',
    appId: '1:379115258066:android:07e301722aac8577b5ad0b',
  );
}
