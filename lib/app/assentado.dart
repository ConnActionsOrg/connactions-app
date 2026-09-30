import 'package:flutter_riverpod/flutter_riverpod.dart';

/// O valor com que uma mutação pode trabalhar. Espera um build em voo (que sobrescreveria o que
/// gravarmos), mas uma recarga que falhou não impede a ação: o erro já virou aviso na tela, e
/// repeti-lo aqui prenderia lançar/encerrar/registrar até o próximo puxar bem-sucedido.
mixin EsperaOBuild<T> on AsyncNotifier<T> {
  Future<T> get assentado async {
    if (state.hasError && state.hasValue && !state.isLoading) {
      return state.requireValue;
    }
    return future;
  }
}
