import 'package:connactions_app/api/api_connactions.dart';
import 'package:connactions_app/app/app.dart';
import 'package:connactions_app/app/autenticador.dart';
import 'package:connactions_app/app/compartilhador.dart';
import 'package:connactions_app/app/dependencias.dart';
import 'package:connactions_app/app/preferencias.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'autenticador_falso.dart';
import 'compartilhador_falso.dart';
import 'fake_api.dart';
import 'preferencias_em_memoria.dart';

/// O app inteiro com dublês. Sem argumentos: logado, com perfil na API, sem turmas.
Widget appDeTeste({
  Autenticador? autenticador,
  ApiConnactions? api,
  Preferencias? preferencias,
  Compartilhador? compartilhador,
}) => ProviderScope(
  overrides: [
    autenticadorProvider.overrideWithValue(
      autenticador ?? AutenticadorFalso(conta: contaDeTeste),
    ),
    apiProvider.overrideWithValue(api ?? FakeApi(eu: euDeTeste())),
    preferenciasProvider.overrideWithValue(
      preferencias ?? PreferenciasEmMemoria(),
    ),
    compartilhadorProvider.overrideWithValue(
      compartilhador ?? CompartilhadorFalso(),
    ),
  ],
  child: const AppConnactions(),
);
