// Valores gerados por flutterfire configure (projeto connactions). Para atualizar, rode o comando de novo; não edite à mão.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Opções do Firebase por plataforma. Só o Android está configurado nesta fatia.
abstract final class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions não tem configuração para a web.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions não tem configuração para esta plataforma.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAMABCCqOnLHDTik1ZsZH_0so6Z7l23Nsg',
    appId: '1:332546582088:android:251bea18a640dfd1265a7d',
    messagingSenderId: '332546582088',
    projectId: 'connactions',
    storageBucket: 'connactions.firebasestorage.app',
  );
}
