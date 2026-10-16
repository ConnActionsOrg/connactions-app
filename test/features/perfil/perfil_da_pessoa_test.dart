import 'dart:async';

import 'package:connactions_app/api/erro_da_api.dart';
import 'package:connactions_app/features/perfil/perfil_da_pessoa.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../apoio/container_de_teste.dart';
import '../../apoio/erros_sem_dono.dart';
import '../../apoio/fake_api.dart';

final eu = pessoaDoEu(euDeTeste());
final daBia = atividadesFeitasProvider('pessoa-bia');

/// A Bia é minha conexão e tem [quantas] atividades feitas, todas públicas.
FakeApi apiCom(int quantas) => FakeApi(
  eu: euDeTeste(),
  turmas: [turmaDeTeste()],
  usuarios: [usuarioDeTeste(turmas: 3)],
  conexoes: [(eu.id, 'pessoa-bia')],
  feitasPor: {
    'pessoa-bia': [for (var i = 1; i <= quantas; i++) feitaDeTeste(id: 'f$i')],
  },
);

/// As famílias são autoDispose: sem ouvinte o provider seria descartado entre uma leitura e outra.
ProviderContainer montar(FakeApi api) {
  final c = containerDeTeste(api);
  c.listen(daBia, (_, _) {});
  return c;
}

Future<void> ticks() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  test('o perfil vem da API pelo id, com os três contadores', () async {
    final api = apiCom(2);
    final c = containerDeTeste(api);
    c.listen(perfilDaPessoaProvider('pessoa-bia'), (_, _) {});

    final perfil = await c.read(perfilDaPessoaProvider('pessoa-bia').future);

    expect(perfil.nome, 'Bia Souza');
    expect([perfil.turmas, perfil.atividades, perfil.conexoes], [3, 2, 1]);
    expect(api.chamadas, ['obterPerfil:pessoa-bia']);
  });

  test('a falha do perfil vira erro e não é repetida sozinha', () async {
    final api = apiCom(0)..falhaAoObterPerfil = const ErroDeRede('caiu');
    final c = containerDeTeste(api);
    c.listen(perfilDaPessoaProvider('pessoa-bia'), (_, _) {});

    await expectLater(
      c.read(perfilDaPessoaProvider('pessoa-bia').future),
      throwsA(isA<ErroDeRede>()),
    );
    // o retry padrão do Riverpod 3 tentaria de novo em 200 ms
    await Future<void>.delayed(const Duration(milliseconds: 500));
    expect(api.chamadas, ['obterPerfil:pessoa-bia']);
  });

  test('a primeira página e o carregar mais até o fim', () async {
    final api = apiCom(25);
    final c = montar(api);

    final primeira = await c.read(daBia.future);
    expect(primeira.itens, hasLength(20));
    expect(primeira.proximo, '20');

    await c.read(daBia.notifier).carregarMais();
    final tudo = c.read(daBia).value!;
    expect(tudo.itens.map((a) => a.id), [for (var i = 1; i <= 25; i++) 'f$i']);
    expect(tudo.proximo, isNull);
    expect(api.chamadas.last, 'listarAtividadesFeitas:pessoa-bia:20');

    await c.read(daBia.notifier).carregarMais(); // no fim, não chama
    expect(
      api.chamadas.where((x) => x.startsWith('listarAtividadesFeitas')),
      hasLength(2),
    );
  });

  test(
    'o carregar mais que recebe 403 mantém o que já estava e sobe o erro',
    () async {
      final api = apiCom(25);
      final c = montar(api);
      await c.read(daBia.future);
      // a Bia desligou a visibilidade enquanto eu lia a primeira página
      api.usuarios['pessoa-bia']!.atividadesVisiveis = false;

      await expectLater(
        c.read(daBia.notifier).carregarMais(),
        throwsA(
          isA<ErroDaApi>().having(
            (e) => e.mensagem,
            'mensagem',
            'Essas atividades não estão visíveis.',
          ),
        ),
      );

      final estado = c.read(daBia);
      expect(estado.hasError, isFalse);
      expect(estado.value!.itens, hasLength(20));
      expect(estado.value!.proximo, '20');
    },
  );

  test(
    'o carregar mais depois de uma recarga que falhou pagina a partir do que já estava',
    () async {
      final api = apiCom(25);
      final c = montar(api);
      await c.read(daBia.future);
      api.falhaAoListarAtividadesFeitas = const ErroDeRede('caiu');
      await expectLater(c.refresh(daBia.future), throwsA(isA<ErroDeRede>()));
      api.falhaAoListarAtividadesFeitas = null;

      await c.read(daBia.notifier).carregarMais();

      expect(c.read(daBia).value!.itens, hasLength(25));
      expect(api.chamadas.last, 'listarAtividadesFeitas:pessoa-bia:20');
    },
  );

  test('o carregar mais com a tela fechada no meio termina sem erro', () async {
    final api = apiCom(25);
    final c = containerDeTeste(api);
    final tela = c.listen(daBia, (_, _) {});
    await c.read(daBia.future);
    final segurar = api.segurarListarAtividadesFeitas = Completer<void>();

    final futuro = c.read(daBia.notifier).carregarMais();
    await ticks();
    tela.close();
    await ticks();
    segurar.complete();

    expect(await erroDe(futuro), isNull);
    expect(api.chamadas.last, 'listarAtividadesFeitas:pessoa-bia:20');
  });
}
