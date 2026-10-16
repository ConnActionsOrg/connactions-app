import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../api/erro_da_api.dart';
import '../../api/mensagens.dart';
import '../../api/modelos/atividade_da_comunidade.dart';
import '../../api/modelos/foto_sem_autor.dart';
import '../../api/modelos/turma.dart';
import '../../app/sessao.dart';
import '../../design/cores.dart';
import '../../design/medidas.dart';
import '../../design/tipografia.dart';
import '../../design/widgets/aviso.dart';
import '../../design/widgets/disco_de_emoji.dart';
import '../../design/widgets/etiqueta.dart';
import '../atividades/atividade_aberta.dart';
import '../atividades/cartao_da_atividade.dart';
import '../atividades/foto_para_ver.dart';
import '../atividades/tempo.dart';
import '../atividades/visualizador_de_fotos.dart';
import '../ideias/ideias.dart';
import '../turmas/turmas.dart';
import 'comunidade.dart';
import 'texto_de_inspiradas.dart';

/// Uma atividade de outra turma: a turma (sem pessoas), o que foi feito, as fotos e quantas turmas
/// se inspiraram. Com turma ativa, dá para guardá-la no backlog dela e propô-la de volta.
class CartaoDaComunidade extends ConsumerStatefulWidget {
  const CartaoDaComunidade({
    super.key,
    required this.atividade,
    required this.agora,
    required this.turmaAtiva,
  });

  final AtividadeDaComunidade atividade;
  final DateTime agora;
  final Turma? turmaAtiva;

  @override
  ConsumerState<CartaoDaComunidade> createState() => _EstadoDoCartao();
}

class _EstadoDoCartao extends ConsumerState<CartaoDaComunidade> {
  // o 2º toque em rede lenta voltaria 409 ja_no_backlog para quem acabou de salvar
  bool _salvando = false;

  Future<void> _salvar(Turma ativa) async {
    setState(() => _salvando = true);
    try {
      await ref
          .read(ideiasProvider(ativa.id).notifier)
          .salvarDaComunidade(widget.atividade.id);
      if (mounted) {
        mostrarAviso(
          context,
          'Ideia salva no backlog de ${ativa.emoji} ${ativa.nome}',
        );
      }
    } on ErroDaApi catch (e) {
      if (!mounted) return;
      mostrarAviso(context, e.mensagem);
      if (e.conflito) {
        // já estava no backlog, ou ele encheu: a lista relida diz o que há
        ref.invalidate(ideiasProvider(ativa.id));
      } else if (e.naoEncontrado) {
        // a atividade saiu da minha Comunidade (entrei na turma dela)
        ref.invalidate(comunidadeProvider);
      } else if (e.semAcesso) {
        // já não sou membro da turma ativa
        ref.invalidate(turmasProvider);
      }
    } catch (e) {
      if (mounted) mostrarAviso(context, mensagemDoErro(e));
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final atividade = widget.atividade;
    final agora = widget.agora;
    final cores = Cores.de(context);
    final tipografia = Tipografia.de(context);
    final ativa = widget.turmaAtiva;
    final euId = ref.watch(perfilAtualProvider).value?.id;
    final ideias = ativa == null
        ? null
        : ref.watch(ideiasProvider(ativa.id)).value;
    final aberta = ativa == null
        ? null
        : ref.watch(atividadeAbertaProvider(ativa.id));
    final salva = ideias != null && guardada(ideias, atividade.id);
    final minhas = ideias == null || euId == null
        ? null
        : minhasLivres(ideias, euId);
    // sem aberta JÁ carregada: enquanto a leitura não chega, o botão não aparece e some depois
    final podePropor =
        ativa != null &&
        ativa.vezDe.id == euId &&
        aberta != null &&
        aberta.hasValue &&
        aberta.value == null;
    final inspiradas = textoDeInspiradas(atividade.inspiradas);
    final rotuloDoSalvar = [
      salva ? 'Salva ✓' : 'Salvar no backlog',
      if (minhas != null) '$minhas/$tetoDeIdeias',
    ].join(' ');
    return Container(
      decoration: BoxDecoration(
        color: cores.superficieBaixa,
        borderRadius: BorderRadius.circular(Raios.medio),
        boxShadow: Sombras.nivel1,
      ),
      padding: const EdgeInsets.all(Espacos.cartao),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DiscoDeEmoji(emoji: atividade.turmaEmoji, tamanho: 36),
              const SizedBox(width: Espacos.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(atividade.turmaNome, style: tipografia.rotuloTitulo),
                    Text(
                      haQuantoTempo(atividade.encerradaEm, agora),
                      style: tipografia.corpoPequeno.copyWith(
                        color: cores.sobreSuperficieVariante,
                      ),
                    ),
                  ],
                ),
              ),
              Etiqueta(
                texto: atividade.formato.rotulo,
                tom: TomDaEtiqueta.salvia,
              ),
            ],
          ),
          const SizedBox(height: Espacos.md),
          Text(atividade.titulo, style: tipografia.tituloMedio),
          if (atividade.descricao.isNotEmpty) ...[
            const SizedBox(height: Espacos.sm),
            Text(atividade.descricao, style: tipografia.corpoMedio),
          ],
          if (atividade.regras.isNotEmpty) ...[
            const SizedBox(height: Espacos.md),
            CaixaDeRegras(regras: atividade.regras),
          ],
          if (atividade.fotos.isNotEmpty) ...[
            const SizedBox(height: Espacos.md),
            _Miniaturas(fotos: atividade.fotos, agora: agora),
          ],
          if (inspiradas != null) ...[
            const SizedBox(height: Espacos.md),
            Text(
              inspiradas,
              style: tipografia.corpoPequeno.copyWith(
                color: cores.sobreSuperficieVariante,
              ),
            ),
          ],
          if (ativa != null) ...[
            const SizedBox(height: Espacos.md),
            // em coluna: o tema dá largura mínima infinita aos botões cheios, e numa Row ou Wrap eles estourariam
            OutlinedButton.icon(
              onPressed: salva || _salvando ? null : () => _salvar(ativa),
              icon: _salvando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(salva ? Symbols.check : Symbols.bookmark_add),
              label: Text(rotuloDoSalvar),
            ),
            if (podePropor) ...[
              const SizedBox(height: Espacos.sm),
              FilledButton.icon(
                onPressed: () => context.push(
                  '/turmas/${ativa.id}/propor',
                  extra: atividade,
                ),
                icon: const Icon(Symbols.lightbulb),
                label: const Text('Propor pro meu grupo'),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

/// A fileira rolável de fotos; tocar abre o visualizador, que aqui não mostra autor.
class _Miniaturas extends StatelessWidget {
  const _Miniaturas({required this.fotos, required this.agora});

  final List<FotoSemAutor> fotos;
  final DateTime agora;

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: fotos.length,
        separatorBuilder: (_, _) => const SizedBox(width: Espacos.sm),
        itemBuilder: (_, i) => Semantics(
          button: true,
          label: 'Ver foto ${i + 1} de ${fotos.length}',
          excludeSemantics: true,
          child: GestureDetector(
            onTap: () => mostrarVisualizadorDeFotos(
              context,
              fotos: [for (final f in fotos) FotoParaVer.semAutor(f)],
              indiceInicial: i,
              agora: agora,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Raios.pequeno),
              child: Image.network(
                fotos[i].miniaturaUrl,
                width: 96,
                height: 96,
                fit: BoxFit.cover,
                // sem rede a miniatura vira um fundo neutro, nunca uma exceção
                errorBuilder: (_, _, _) => Container(
                  width: 96,
                  height: 96,
                  color: cores.superficieContainer,
                  alignment: Alignment.center,
                  child: Icon(
                    Symbols.image,
                    color: cores.sobreSuperficieVariante,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
