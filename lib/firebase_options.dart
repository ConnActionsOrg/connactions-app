// Provisório: a Tarefa 9 roda flutterfire configure e substitui este arquivo pelo gerado.
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
    apiKey: 'PROVISORIO',
    appId: 'PROVISORIO',
    messagingSenderId: 'PROVISORIO',
    projectId: 'connactions',
  );
}
