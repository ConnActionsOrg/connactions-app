import 'package:connactions_app/app/dependencias.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'autenticador_falso.dart';
import 'compartilhador_falso.dart';
import 'fake_api.dart';
import 'preferencias_em_memoria.dart';
import 'seletor_de_foto_falso.dart';

/// Um container de Riverpod com os dublês de sempre e a [api] dada, para testar estado sem widget.
/// Com [autenticador], o teste sai e entra de novo, como na troca de conta.
ProviderContainer containerDeTeste(
  FakeApi api, {
  AutenticadorFalso? autenticador,
}) => ProviderContainer.test(
  overrides: [
    autenticadorProvider.overrideWithValue(
      autenticador ?? AutenticadorFalso(conta: contaDeTeste),
    ),
    apiProvider.overrideWithValue(api),
    preferenciasProvider.overrideWithValue(PreferenciasEmMemoria()),
    compartilhadorProvider.overrideWithValue(CompartilhadorFalso()),
    seletorDeFotoProvider.overrideWithValue(SeletorDeFotoFalso()),
  ],
);
