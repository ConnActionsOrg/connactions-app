import 'package:flutter_riverpod/flutter_riverpod.dart';

/// O "agora" das telas (contagem regressiva, "há 2 h"). Tem padrão, então não mora em
/// dependencias.dart; os testes congelam sobrescrevendo.
final relogioProvider = Provider<DateTime Function()>((_) => DateTime.now);
