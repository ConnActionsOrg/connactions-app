import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app/dependencias.dart';
import '../../app/notificador.dart';
import '../../design/cores.dart';
import '../../design/medidas.dart';
import '../../design/tipografia.dart';
import 'permissao.dart';

/// No Perfil, para quem já respondeu ao Feed e ficou sem notificações. Some quando a permissão
/// volta, inclusive a que a pessoa liga pelas configurações do Android.
class CartaoDeNotificacoesDesligadas extends ConsumerWidget {
  const CartaoDeNotificacoesDesligadas({super.key});

  Future<void> _ativar(WidgetRef ref) async {
    final permissao = ref.read(permissaoProvider.notifier);
    final notificador = ref.read(notificadorProvider);
    if (await permissao.ativar() == PermissaoDeAviso.negada) {
      // depois de duas recusas o Android não mostra mais a caixa: só as configurações ligam
      await notificador.abrirConfiguracoes();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(permissaoProvider).value;
    final desligadas =
        estado != null &&
        estado.perguntou &&
        estado.permissao == PermissaoDeAviso.negada;
    if (!desligadas) return const SizedBox.shrink();
    final cores = Cores.de(context);
    final tipografia = Tipografia.de(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: Espacos.md),
      child: Container(
        decoration: BoxDecoration(
          color: cores.superficieBaixa,
          borderRadius: BorderRadius.circular(Raios.padrao),
          boxShadow: Sombras.nivel1,
        ),
        padding: const EdgeInsets.all(Espacos.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cores.superficieContainer,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Symbols.notifications_off,
                    size: 22,
                    color: cores.primaria,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notificações desligadas',
                        style: tipografia.rotuloTitulo,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Você não vai saber quando for a sua vez de propor.',
                        style: tipografia.corpoPequeno.copyWith(
                          color: cores.sobreSuperficieVariante,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: Espacos.md),
            OutlinedButton(
              onPressed: () => _ativar(ref),
              child: const Text('Ativar'),
            ),
          ],
        ),
      ),
    );
  }
}
