import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api/api_http.dart';
import 'app/app.dart';
import 'app/autenticador_firebase.dart';
import 'app/config.dart';
import 'app/sessao.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // initializeApp não valida a apiKey: com o provisório, o erro só apareceria no login.
  if (DefaultFirebaseOptions.android.apiKey == 'PROVISORIO') {
    throw StateError(
      'firebase_options.dart provisório: rode flutterfire configure (Tarefa 9).',
    );
  }
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final autenticador = AutenticadorFirebase();
  runApp(
    ProviderScope(
      overrides: [
        autenticadorProvider.overrideWithValue(autenticador),
        apiProvider.overrideWithValue(
          ApiHttp(
            base: Uri.parse(Config.apiUrl),
            obterToken: autenticador.obterIdToken,
          ),
        ),
      ],
      child: const AppConnactions(),
    ),
  );
}
