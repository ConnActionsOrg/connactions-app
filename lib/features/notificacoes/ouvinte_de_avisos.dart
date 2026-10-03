import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/dependencias.dart';
import '../../app/notificador.dart';
import '../../app/roteador.dart';
import '../../design/widgets/aviso.dart';
import '../atividades/atividade_aberta.dart';
import '../diario/diario.dart';
import '../turmas/turma_ativa.dart';

/// Mora no `builder` do MaterialApp.router: abaixo do ScaffoldMessenger, que mostra o aviso, e
/// acima das rotas, que o toque troca.
class OuvinteDeAvisos extends ConsumerStatefulWidget {
  const OuvinteDeAvisos({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<OuvinteDeAvisos> createState() => _OuvinteDeAvisosState();
}

class _OuvinteDeAvisosState extends ConsumerState<OuvinteDeAvisos> {
  late final List<StreamSubscription<Aviso>> _assinaturas;

  @override
  void initState() {
    super.initState();
    final notificador = ref.read(notificadorProvider);
    _assinaturas = [
      notificador.tocados.listen((aviso) => abrirAviso(ref, aviso)),
      notificador.recebidosComAppAberto.listen(_mostrar),
    ];
    unawaited(_abrirOToqueDoInicio(notificador));
  }

  Future<void> _abrirOToqueDoInicio(Notificador notificador) async {
    final aviso = await notificador.tocadoAoAbrir();
    if (aviso != null && mounted) await abrirAviso(ref, aviso);
  }

  void _mostrar(Aviso aviso) {
    mostrarAviso(context, '${aviso.titulo}\n${aviso.corpo}');
    _reler(ref, aviso.turmaId);
  }

  @override
  void dispose() {
    for (final assinatura in _assinaturas) {
      unawaited(assinatura.cancel());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// A frio a sessão ainda pode estar carregando: o redirect termina a viagem, no Feed ou, sem
/// ninguém logado, na entrada.
Future<void> abrirAviso(WidgetRef ref, Aviso aviso) async {
  final roteador = ref.read(roteadorProvider);
  final turmaAtiva = ref.read(turmaAtivaIdProvider.notifier);
  _reler(ref, aviso.turmaId);
  try {
    await turmaAtiva.definir(aviso.turmaId);
  } catch (_) {
    // o state já mudou antes da gravação: só a próxima abertura a frio perde a escolha
  }
  roteador.go('/feed');
}

void _reler(WidgetRef ref, String turmaId) {
  invalidarRodada(ref.invalidate, turmaId);
  ref.invalidate(diarioProvider(turmaId));
}
