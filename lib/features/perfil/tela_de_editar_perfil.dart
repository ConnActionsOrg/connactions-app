import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/erro_da_api.dart';
import '../../api/mensagens.dart';
import '../../api/modelos/alteracoes_do_eu.dart';
import '../../api/modelos/eu.dart';
import '../../app/sessao.dart';
import '../../design/medidas.dart';
import '../../design/widgets/aviso.dart';
import '../../design/widgets/cabecalho.dart';

/// Nome, @handle e bio. Manda só o que mudou; handle em uso vira erro no campo, não aviso.
class TelaDeEditarPerfil extends ConsumerStatefulWidget {
  const TelaDeEditarPerfil({super.key});

  @override
  ConsumerState<TelaDeEditarPerfil> createState() => _TelaDeEditarPerfilState();
}

class _TelaDeEditarPerfilState extends ConsumerState<TelaDeEditarPerfil> {
  late final Eu _original;
  late final TextEditingController _nome;
  late final TextEditingController _handle;
  late final TextEditingController _bio;
  String? _erroDoHandle;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    // só se chega aqui pelo Perfil já carregado, então o valor existe
    _original = ref.read(perfilAtualProvider).value!;
    _nome = TextEditingController(text: _original.nome);
    _handle = TextEditingController(text: _original.handle);
    _bio = TextEditingController(text: _original.bio);
  }

  @override
  void dispose() {
    _nome.dispose();
    _handle.dispose();
    _bio.dispose();
    super.dispose();
  }

  AlteracoesDoEu get _alteracoes {
    final nome = _nome.text.trim();
    final handle = _handle.text.trim();
    final bio = _bio.text.trim();
    return AlteracoesDoEu(
      nome: nome != _original.nome ? nome : null,
      handle: handle != _original.handle ? handle : null,
      bio: bio != _original.bio ? bio : null,
    );
  }

  bool get _podeSalvar =>
      !_salvando &&
      !_alteracoes.vazia &&
      _nome.text.trim().isNotEmpty &&
      _handle.text.trim().length >= 3;

  Future<void> _salvar() async {
    setState(() {
      _salvando = true;
      _erroDoHandle = null;
    });
    // capturado antes de navegar: o aviso aparece no Perfil, não nesta tela que vai fechar
    final mensageiro = ScaffoldMessenger.of(context);
    try {
      await ref.read(perfilAtualProvider.notifier).atualizar(_alteracoes);
      if (!mounted) return;
      context.pop();
      mensageiro.showSnackBar(
        const SnackBar(content: Text('Perfil atualizado')),
      );
    } on ErroDaApi catch (e) {
      if (!mounted) return;
      if (e.handleEmUso) {
        setState(() => _erroDoHandle = e.mensagem);
      } else {
        mostrarAviso(context, e.mensagem);
      }
    } catch (e) {
      if (mounted) mostrarAviso(context, mensagemDoErro(e));
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const Cabecalho(titulo: 'Editar perfil'),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(
        Espacos.margemDaTela,
        Espacos.md,
        Espacos.margemDaTela,
        Espacos.xl,
      ),
      children: [
        TextField(
          controller: _nome,
          maxLength: 80,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Nome'),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: Espacos.md),
        TextField(
          controller: _handle,
          maxLength: 20,
          autocorrect: false,
          enableSuggestions: false,
          inputFormatters: [
            const _Minusculas(),
            FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9._]')),
          ],
          decoration: InputDecoration(
            labelText: '@handle',
            prefixText: '@',
            helperText:
                '3 a 20 caracteres: letras minúsculas, números, ponto e sublinhado',
            errorText: _erroDoHandle,
          ),
          onChanged: (_) => setState(() => _erroDoHandle = null),
        ),
        const SizedBox(height: Espacos.md),
        TextField(
          controller: _bio,
          maxLength: 200,
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Bio',
            hintText: 'Uma frase sobre você',
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: Espacos.xl),
        FilledButton(
          onPressed: _podeSalvar ? _salvar : null,
          child: _salvando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Salvar'),
        ),
      ],
    ),
  );
}

/// Antes do filtro de caracteres: "Marina.D" vira "marina.d" em vez de perder o M.
class _Minusculas extends TextInputFormatter {
  const _Minusculas();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue anterior,
    TextEditingValue novo,
  ) => novo.copyWith(text: novo.text.toLowerCase());
}
