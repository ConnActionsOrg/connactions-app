import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/dependencias.dart';
import '../../app/sessao.dart';

/// Cadastra este aparelho para a conta logada, depois do perfil (o `PUT /dispositivos` exige o
/// `POST /eu` feito), e de novo a cada token que o Firebase renovar. Falha não derruba nada: a
/// próxima abertura do app tenta outra vez. Fica vivo por um `ref.listen` em `AppConnactions`.
final registroDoAparelhoProvider = FutureProvider<void>((ref) async {
  // só o id: editar o perfil não é motivo para cadastrar de novo
  final euId = ref.watch(
    perfilAtualProvider.select((perfil) => perfil.value?.id),
  );
  if (euId == null) return;
  final notificador = ref.watch(notificadorProvider);
  final api = ref.watch(apiProvider);

  Future<void> cadastrar(String token) async {
    try {
      await api.registrarDispositivo(token: token, plataforma: 'android');
    } catch (_) {
      // engolida de propósito: sem cadastro o app segue, só não recebe aviso
    }
  }

  // a troca de conta reconstrói este provider e cancela a assinatura: o token renovado depois
  // de sair não volta para a conta que saiu
  final renovacoes = notificador.tokensNovos.listen(cadastrar);
  ref.onDispose(renovacoes.cancel);
  try {
    final token = await notificador.token();
    if (token != null) await cadastrar(token);
  } catch (_) {
    // o Firebase sem rede não dá token; a próxima abertura tenta de novo
  }
}, retry: (_, _) => null);
