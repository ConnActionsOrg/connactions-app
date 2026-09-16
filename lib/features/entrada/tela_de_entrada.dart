import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app/autenticador.dart';
import '../../app/dependencias.dart';
import '../../design/cores.dart';
import '../../design/medidas.dart';
import '../../design/tipografia.dart';
import '../../design/widgets/aviso.dart';
import '../../design/widgets/marca.dart';

/// Login. Não navega: quando a conta entra, o roteador redireciona sozinho.
class TelaDeEntrada extends ConsumerStatefulWidget {
  const TelaDeEntrada({super.key});

  @override
  ConsumerState<TelaDeEntrada> createState() => _TelaDeEntradaState();
}

class _TelaDeEntradaState extends ConsumerState<TelaDeEntrada> {
  bool _entrando = false;

  Future<void> _entrar() async {
    setState(() => _entrando = true);
    try {
      await ref.read(autenticadorProvider).entrarComGoogle();
    } on ErroDeLogin catch (e) {
      if (!e.cancelado && mounted) mostrarAviso(context, e.mensagem);
    } catch (_) {
      if (mounted) mostrarAviso(context, 'Não consegui entrar. Tente de novo.');
    } finally {
      if (mounted) setState(() => _entrando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    final tipografia = Tipografia.de(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Espacos.margemDaTela),
          child: Column(
            children: [
              const Spacer(flex: 3),
              const Marca(tamanho: 96),
              const SizedBox(height: Espacos.lg),
              Text(
                'ConnActions',
                style: tipografia.displayGrande.copyWith(color: cores.primaria),
              ),
              const SizedBox(height: Espacos.sm),
              Text(
                'Propor, viver e guardar momentos com quem você gosta.',
                style: tipografia.corpoGrande.copyWith(
                  color: cores.sobreSuperficieVariante,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 4),
              FilledButton.icon(
                onPressed: _entrando ? null : _entrar,
                icon: _entrando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Symbols.login),
                label: Text(_entrando ? 'Entrando…' : 'Entrar com Google'),
              ),
              const SizedBox(height: Espacos.md),
              Text(
                'Turmas por convite. Sem cadastro, sem senha.',
                style: tipografia.corpoPequeno.copyWith(
                  color: cores.sobreSuperficieVariante,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Espacos.lg),
            ],
          ),
        ),
      ),
    );
  }
}
