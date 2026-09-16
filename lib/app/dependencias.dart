import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_connactions.dart';
import 'autenticador.dart';
import 'compartilhador.dart';
import 'preferencias.dart';

/// Pontos de entrada externos. Sem padrão de propósito: o main e os testes têm de sobrescrever.
final autenticadorProvider = Provider<Autenticador>(
  (_) => throw UnimplementedError(
    'sobrescreva autenticadorProvider no ProviderScope',
  ),
);
final apiProvider = Provider<ApiConnactions>(
  (_) => throw UnimplementedError('sobrescreva apiProvider no ProviderScope'),
);
final preferenciasProvider = Provider<Preferencias>(
  (_) => throw UnimplementedError(
    'sobrescreva preferenciasProvider no ProviderScope',
  ),
);
final compartilhadorProvider = Provider<Compartilhador>(
  (_) => throw UnimplementedError(
    'sobrescreva compartilhadorProvider no ProviderScope',
  ),
);
