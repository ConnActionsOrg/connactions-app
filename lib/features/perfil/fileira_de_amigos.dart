import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../api/modelos/pessoa.dart';
import '../../design/cores.dart';
import '../../design/medidas.dart';
import '../../design/tipografia.dart';
import '../../design/widgets/avatar.dart';

/// O cartão "Conectar amigo" primeiro e um cartão por amigo, que abre o perfil dele, numa fileira
/// que rola para o lado. O nome e o `@handle` longos saem com reticências.
class FileiraDeAmigos extends StatelessWidget {
  const FileiraDeAmigos({
    super.key,
    required this.amigos,
    this.carregando = false,
  });

  final List<Pessoa> amigos;

  /// Enquanto a lista não chega: o indicador no lugar dos amigos.
  final bool carregando;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    // a altura é a do cartão mais alto, que cresce com a fonte do Android: com uma altura fixa, a
    // fonte grande estouraria os cartões
    child: IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _CartaoDeConectar(),
          if (carregando) ...[
            const SizedBox(width: 12),
            const SizedBox(
              width: _largura,
              child: Center(child: CircularProgressIndicator()),
            ),
          ],
          for (final amigo in amigos) ...[
            const SizedBox(width: 12),
            _CartaoDeAmigo(pessoa: amigo),
          ],
        ],
      ),
    ),
  );
}

const _largura = 112.0;

class _CartaoDeConectar extends StatelessWidget {
  const _CartaoDeConectar();

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    final tipografia = Tipografia.de(context);
    return _Cartao(
      cor: cores.superficieAlta,
      aoTocar: () => context.push('/amigos/conectar'),
      filhos: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: cores.primariaFixa,
          ),
          alignment: Alignment.center,
          child: Icon(
            Symbols.person_add,
            color: cores.sobrePrimariaFixaVariante,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Conectar amigo',
          style: tipografia.etiquetaMedia.copyWith(fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          'pelo código',
          style: tipografia.corpoPequeno.copyWith(color: cores.primaria),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _CartaoDeAmigo extends StatelessWidget {
  const _CartaoDeAmigo({required this.pessoa});

  final Pessoa pessoa;

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    final tipografia = Tipografia.de(context);
    return _Cartao(
      cor: cores.superficieBaixa,
      aoTocar: () => context.push('/pessoas/${pessoa.id}'),
      filhos: [
        Avatar(nome: pessoa.nome, fotoUrl: pessoa.fotoUrl, tamanho: 48),
        const SizedBox(height: Espacos.sm),
        Text(
          pessoa.primeiroNome,
          style: tipografia.etiquetaGrande,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          '@${pessoa.handle}',
          style: tipografia.corpoPequeno.copyWith(
            color: cores.sobreSuperficieVariante,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// A moldura comum: largura fixa e o toque com a tinta no próprio `Material`, que é quem pinta o
/// fundo (sob um `Container` opaco a tinta não apareceria).
class _Cartao extends StatelessWidget {
  const _Cartao({
    required this.cor,
    required this.aoTocar,
    required this.filhos,
  });

  final Color cor;
  final VoidCallback aoTocar;
  final List<Widget> filhos;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: _largura,
    child: Material(
      color: cor,
      borderRadius: BorderRadius.circular(Raios.padrao),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: aoTocar,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: filhos,
          ),
        ),
      ),
    ),
  );
}
