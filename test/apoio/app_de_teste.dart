import 'package:connactions_app/api/api_connactions.dart';
import 'package:connactions_app/app/app.dart';
import 'package:connactions_app/app/autenticador.dart';
import 'package:connactions_app/app/sessao.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'autenticador_falso.dart';
import 'fake_api.dart';

/// O app inteiro com dublês. Sem argumentos: logado, com perfil na API.
Widget appDeTeste({Autenticador? autenticador, ApiConnactions? api}) =>
    ProviderScope(
      overrides: [
        autenticadorProvider.overrideWithValue(
          autenticador ?? AutenticadorFalso(conta: contaDeTeste),
        ),
        apiProvider.overrideWithValue(api ?? FakeApi(eu: euDeTeste())),
      ],
      child: const AppConnactions(),
    );
