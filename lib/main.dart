import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api/api_http.dart';
import 'app/app.dart';
import 'app/autenticador_firebase.dart';
import 'app/compartilhador.dart';
import 'app/config.dart';
import 'app/dependencias.dart';
import 'app/notificador.dart';
import 'app/preferencias.dart';
import 'app/seletor_de_foto.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final autenticador = AutenticadorFirebase();
  final preferencias = await PreferenciasDoAparelho.abrir();
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
        preferenciasProvider.overrideWithValue(preferencias),
        compartilhadorProvider.overrideWithValue(
          const CompartilhadorDoSistema(),
        ),
        seletorDeFotoProvider.overrideWithValue(SeletorDeFotoDoAparelho()),
        notificadorProvider.overrideWithValue(NotificadorFirebase()),
      ],
      child: const AppConnactions(),
    ),
  );
}
