import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/notificador.dart';
import '../../design/cores.dart';
import '../../design/medidas.dart';
import '../../design/tipografia.dart';
import 'permissao.dart';

/// O pedido de permissão, no Feed com turma: aparece até a pessoa responder, com qualquer um dos
/// dois botões, e nunca para quem já deu a permissão.
class CartaoDePermissao extends ConsumerWidget {
  const CartaoDePermissao({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(permissaoProvider).value;
    final pergunta =
        estado != null &&
        !estado.perguntou &&
        estado.permissao == PermissaoDeAviso.negada;
    if (!pergunta) return const SizedBox.shrink();
    final cores = Cores.de(context);
    final tipografia = Tipografia.de(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: Espacos.md),
      child: Container(
        decoration: BoxDecoration(
          color: cores.superficieBaixa,
          borderRadius: BorderRadius.circular(Raios.medio),
          boxShadow: Sombras.nivel1,
        ),
        padding: const EdgeInsets.all(Espacos.cartao),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Quer saber quando for a sua vez?',
              style: tipografia.tituloPequeno,
            ),
            const SizedBox(height: Espacos.xs),
            Text(
              'O ConnActions avisa quando for a sua vez de propor, quando alguém '
              'lançar uma atividade ou postar um registro, e no último dia do prazo.',
              style: tipografia.corpoMedio,
            ),
            const SizedBox(height: Espacos.md),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () =>
                        ref.read(permissaoProvider.notifier).agoraNao(),
                    child: const Text('Agora não'),
                  ),
                ),
                const SizedBox(width: Espacos.sm),
                // o FilledButton do tema pede a largura toda: solto na Row, ela estoura
                Expanded(
                  child: FilledButton(
                    onPressed: () =>
                        ref.read(permissaoProvider.notifier).ativar(),
                    child: const Text('Ativar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
