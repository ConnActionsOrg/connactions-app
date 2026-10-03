import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/dependencias.dart';
import '../../app/notificador.dart';
import '../../app/preferencias.dart';

/// A permissão do sistema e se o app já perguntou. A marca é do app porque o "Agora não" nem passa
/// pelo sistema, e é ela que separa o cartão do Feed (nunca perguntou) do cartão do Perfil (negou).
typedef EstadoDaPermissao = ({PermissaoDeAviso permissao, bool perguntou});

class Permissao extends AsyncNotifier<EstadoDaPermissao> {
  @override
  Future<EstadoDaPermissao> build() async {
    final notificador = ref.watch(notificadorProvider);
    final preferencias = ref.watch(preferenciasProvider);
    // a pessoa pode ter ligado pelas configurações do Android: de volta ao app, relê
    final aoVoltar = AppLifecycleListener(onResume: ref.invalidateSelf);
    ref.onDispose(aoVoltar.dispose);
    final permissao = await notificador.permissao();
    var perguntou =
        preferencias.ler(ChaveDePreferencia.notificacoesPerguntadas) == 'true';
    if (permissao == PermissaoDeAviso.concedida && !perguntou) {
      // já concedida (Android 12 ou antes, ou dada antes): se um dia for negada, quem avisa é o
      // Perfil, e não o Feed
      await preferencias.gravar(
        ChaveDePreferencia.notificacoesPerguntadas,
        'true',
      );
      perguntou = true;
    }
    return (permissao: permissao, perguntou: perguntou);
  }

  /// A caixa do sistema; devolve o que a pessoa escolheu. A marca vai antes: a caixa tira o app do
  /// primeiro plano, e a releitura da volta tem de encontrá-la gravada.
  Future<PermissaoDeAviso> ativar() async {
    final notificador = ref.read(notificadorProvider);
    await _marcarQuePerguntou();
    final permissao = await notificador.pedirPermissao();
    if (ref.mounted) state = AsyncData((permissao: permissao, perguntou: true));
    return permissao;
  }

  Future<void> agoraNao() => _marcarQuePerguntou();

  /// Grava a marca e já tira o cartão da tela, sem esperar a caixa do sistema.
  Future<void> _marcarQuePerguntou() async {
    await ref
        .read(preferenciasProvider)
        .gravar(ChaveDePreferencia.notificacoesPerguntadas, 'true');
    final atual = state.value;
    if (ref.mounted && atual != null) {
      state = AsyncData((permissao: atual.permissao, perguntou: true));
    }
  }
}

// Sem retry automático: sem a leitura os cartões só não aparecem, e a volta ao app relê.
final permissaoProvider = AsyncNotifierProvider<Permissao, EstadoDaPermissao>(
  Permissao.new,
  retry: (_, _) => null,
);
