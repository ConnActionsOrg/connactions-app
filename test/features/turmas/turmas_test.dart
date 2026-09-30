import 'dart:async';

import 'package:connactions_app/api/erro_da_api.dart';
import 'package:connactions_app/app/dependencias.dart';
import 'package:connactions_app/features/turmas/detalhe_da_turma.dart';
import 'package:connactions_app/features/turmas/turma_ativa.dart';
import 'package:connactions_app/features/turmas/turmas.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../apoio/autenticador_falso.dart';
import '../../apoio/compartilhador_falso.dart';
import '../../apoio/fake_api.dart';
import '../../apoio/preferencias_em_memoria.dart';
import '../../apoio/seletor_de_foto_falso.dart';

ProviderContainer montar({
  FakeApi? api,
  PreferenciasEmMemoria? preferencias,
  AutenticadorFalso? autenticador,
}) {
  final container = ProviderContainer.test(
    overrides: [
      autenticadorProvider.overrideWithValue(
        autenticador ?? AutenticadorFalso(conta: contaDeTeste),
      ),
      apiProvider.overrideWithValue(api ?? FakeApi(eu: euDeTeste())),
      preferenciasProvider.overrideWithValue(
        preferencias ?? PreferenciasEmMemoria(),
      ),
      compartilhadorProvider.overrideWithValue(CompartilhadorFalso()),
      seletorDeFotoProvider.overrideWithValue(SeletorDeFotoFalso()),
    ],
  );
  // sem ouvinte o Riverpod pausa a cadeia conta → perfil → turmas e o .future nunca resolve
  container.listen(turmasProvider, (_, _) {});
  container.listen(turmaAtivaProvider, (_, _) {});
  return container;
}

List<String> idsDe(ProviderContainer c) =>
    (c.read(turmasProvider).value ?? []).map((t) => t.id).toList();

void main() {
  test('lista as turmas depois de garantir o perfil', () async {
    final api = FakeApi(eu: euDeTeste(), turmas: [turmaDeTeste()]);
    final c = montar(api: api);

    final turmas = await c.read(turmasProvider.future);

    expect(turmas.single.id, 'turma-1');
    expect(api.chamadas, ['obterEu', 'listarTurmas']);
  });

  test('deslogado devolve lista vazia sem chamar a API', () async {
    final api = FakeApi();
    final c = montar(api: api, autenticador: AutenticadorFalso());

    expect(await c.read(turmasProvider.future), isEmpty);
    expect(api.chamadas, isEmpty);
    expect(c.read(turmaAtivaProvider), isNull);
  });

  test('sem id salvo a ativa é a primeira', () async {
    final c = montar(
      api: FakeApi(
        eu: euDeTeste(),
        turmas: [
          turmaDeTeste(id: 'turma-1'),
          turmaDeTeste(id: 'turma-2'),
        ],
      ),
    );
    await c.read(turmasProvider.future);
    expect(c.read(turmaAtivaProvider)?.id, 'turma-1');
  });

  test('com id salvo, a ativa é a escolhida', () async {
    final c = montar(
      api: FakeApi(
        eu: euDeTeste(),
        turmas: [
          turmaDeTeste(id: 'turma-1'),
          turmaDeTeste(id: 'turma-2', nome: 'Cozinha & Prosa'),
        ],
      ),
      preferencias: PreferenciasEmMemoria({'turma_ativa_id': 'turma-2'}),
    );
    await c.read(turmasProvider.future);
    expect(c.read(turmaAtivaProvider)?.nome, 'Cozinha & Prosa');
  });

  test('id órfão cai na primeira, sem gravar nada', () async {
    final prefs = PreferenciasEmMemoria({'turma_ativa_id': 'turma-99'});
    final c = montar(
      api: FakeApi(eu: euDeTeste(), turmas: [turmaDeTeste()]),
      preferencias: prefs,
    );
    await c.read(turmasProvider.future);

    expect(c.read(turmaAtivaProvider)?.id, 'turma-1');
    expect(prefs.valores['turma_ativa_id'], 'turma-99');
  });

  test('definir troca a ativa e persiste', () async {
    final prefs = PreferenciasEmMemoria();
    final c = montar(
      api: FakeApi(
        eu: euDeTeste(),
        turmas: [
          turmaDeTeste(id: 'turma-1'),
          turmaDeTeste(id: 'turma-2'),
        ],
      ),
      preferencias: prefs,
    );
    await c.read(turmasProvider.future);

    await c.read(turmaAtivaIdProvider.notifier).definir('turma-2');

    expect(c.read(turmaAtivaProvider)?.id, 'turma-2');
    expect(prefs.valores['turma_ativa_id'], 'turma-2');
  });

  test('criar põe na lista e torna ativa', () async {
    final api = FakeApi(
      eu: euDeTeste(),
      turmas: [turmaDeTeste(id: 'turma-1')],
    );
    final prefs = PreferenciasEmMemoria();
    final c = montar(api: api, preferencias: prefs);
    await c.read(turmasProvider.future);

    final nova = await c
        .read(turmasProvider.notifier)
        .criar(nome: 'Rolê da Firma', emoji: '🍕');

    expect(idsDe(c), ['turma-1', nova.id]);
    expect(c.read(turmaAtivaProvider)?.id, nova.id);
    expect(prefs.valores['turma_ativa_id'], nova.id);
    expect(api.chamadas.last, 'criarTurma:Rolê da Firma:🍕');
  });

  test('criar espera a lista assentar antes de gravar', () async {
    final api = FakeApi(
      eu: euDeTeste(),
      turmas: [turmaDeTeste(id: 'turma-1')],
    )..segurarListarTurmas = Completer<void>();
    final c = montar(api: api);

    final futuro = c
        .read(turmasProvider.notifier)
        .criar(nome: 'Nova', emoji: '🍕');
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(api.chamadas, isNot(contains('criarTurma:Nova:🍕')));

    api.segurarListarTurmas!.complete();
    final turma = await futuro;

    expect(
      api.chamadas.indexOf('listarTurmas'),
      lessThan(api.chamadas.indexOf('criarTurma:Nova:🍕')),
    );
    expect(idsDe(c), contains(turma.id));
    expect(c.read(turmaAtivaProvider)?.id, turma.id);
  });

  test('entrar põe na lista sem duplicar e torna ativa', () async {
    final convite = turmaDeTeste(
      id: 'turma-2',
      nome: 'Cozinha & Prosa',
      codigoConvite: 'WXYZ6789',
      vezDe: pessoaDeTeste(),
      totalDeMembros: 3,
    );
    final api = FakeApi(
      eu: euDeTeste(),
      turmas: [turmaDeTeste(id: 'turma-1')],
      convites: {'WXYZ6789': convite},
    );
    final c = montar(api: api);
    await c.read(turmasProvider.future);

    final turma = await c.read(turmasProvider.notifier).entrar('wxyz 6789');
    expect(turma.id, 'turma-2');
    expect(turma.totalDeMembros, 4);
    expect(idsDe(c), ['turma-1', 'turma-2']);
    expect(c.read(turmaAtivaProvider)?.id, 'turma-2');

    await c.read(turmasProvider.notifier).entrar('WXYZ6789'); // já sou membro
    expect(idsDe(c), ['turma-1', 'turma-2']);
  });

  test('sair tira da lista e a ativa cai na primeira', () async {
    final prefs = PreferenciasEmMemoria({'turma_ativa_id': 'turma-2'});
    final api = FakeApi(
      eu: euDeTeste(),
      turmas: [
        turmaDeTeste(id: 'turma-1'),
        turmaDeTeste(id: 'turma-2'),
      ],
    );
    final c = montar(api: api, preferencias: prefs);
    await c.read(turmasProvider.future);
    expect(c.read(turmaAtivaProvider)?.id, 'turma-2');

    await c.read(turmasProvider.notifier).sair('turma-2');

    expect(idsDe(c), ['turma-1']);
    expect(c.read(turmaAtivaProvider)?.id, 'turma-1');
    expect(api.chamadas.last, 'sairDaTurma:turma-2');
  });

  test('sair de turma de outra pessoa é sem_acesso', () async {
    final api = FakeApi(
      eu: euDeTeste(),
      turmas: [turmaDeTeste(id: 'turma-1')],
      convites: {
        'WXYZ6789': turmaDeTeste(
          id: 'turma-2',
          codigoConvite: 'WXYZ6789',
          vezDe: pessoaDeTeste(),
        ),
      },
    );
    final c = montar(api: api);
    await c.read(turmasProvider.future);

    await expectLater(
      c.read(turmasProvider.notifier).sair('turma-2'),
      throwsA(isA<ErroDaApi>().having((e) => e.semAcesso, 'semAcesso', isTrue)),
    );
    expect(idsDe(c), ['turma-1']);
  });

  test('regenerar substitui a turma na lista', () async {
    final api = FakeApi(
      eu: euDeTeste(),
      turmas: [turmaDeTeste(id: 'turma-1', codigoConvite: 'ABCD2345')],
    );
    final c = montar(api: api);
    await c.read(turmasProvider.future);

    final nova = await c
        .read(turmasProvider.notifier)
        .regenerarConvite('turma-1');

    expect(nova.codigoConvite, isNot('ABCD2345'));
    expect(
      c.read(turmasProvider).value?.single.codigoConvite,
      nova.codigoConvite,
    );
    expect(c.read(turmaAtivaProvider)?.codigoConvite, nova.codigoConvite);
  });

  test('falha ao listar vira erro e não é repetida sozinha', () async {
    final api = FakeApi(
      eu: euDeTeste(),
      falhaAoListarTurmas: const ErroDeRede('caiu'),
    );
    final c = montar(api: api);

    await expectLater(
      c.read(turmasProvider.future),
      throwsA(isA<ErroDeRede>()),
    );

    expect(api.chamadas.where((c) => c == 'listarTurmas').length, 1);
    expect(c.read(turmaAtivaProvider), isNull);
  });

  test('o detalhe da turma vem da API por id', () async {
    final api = FakeApi(
      eu: euDeTeste(),
      turmas: [turmaDeTeste(id: 'turma-1')],
      membrosPor: {
        'turma-1': [
          membroDeTeste(pessoaDoEu(euDeTeste()), 1),
          membroDeTeste(pessoaDeTeste(), 2),
        ],
      },
    );
    final c = montar(api: api);
    // sem isto, a cadeia turmasProvider->perfilAtualProvider (disparada dentro de montar())
    // ainda está em andamento e pode intercalar um "obterEu" antes do obterTurma abaixo.
    await c.read(turmasProvider.future);
    c.listen(turmaDetalheProvider('turma-1'), (_, _) {});

    final detalhe = await c.read(turmaDetalheProvider('turma-1').future);

    expect(detalhe.membros.map((m) => m.pessoa.handle).toList(), [
      'marina.d',
      'bia',
    ]);
    expect(api.chamadas.last, 'obterTurma:turma-1');
  });

  test('embaralhar grava o detalhe devolvido', () async {
    final eu = pessoaDoEu(euDeTeste());
    final bia = pessoaDeTeste();
    final api = FakeApi(
      eu: euDeTeste(),
      turmas: [turmaDeTeste(totalDeMembros: 2)],
      membrosPor: {
        'turma-1': [membroDeTeste(eu, 1), membroDeTeste(bia, 2)],
      },
    );
    final c = montar(api: api);
    // sem isto a cadeia turmas → perfil ainda pode registrar 'listarTurmas' depois da chamada afirmada
    await c.read(turmasProvider.future);
    c.listen(turmaDetalheProvider('turma-1'), (_, _) {});
    await c.read(turmaDetalheProvider('turma-1').future);

    await c.read(turmaDetalheProvider('turma-1').notifier).embaralhar();

    final membros = c.read(turmaDetalheProvider('turma-1')).value!.membros;
    expect(membros.map((m) => m.pessoa.id), [bia.id, eu.id]);
    expect(api.chamadas.last, 'embaralharOrdem:turma-1');
  });

  test('criar depois de recarga que falhou chama a API', () async {
    final api = FakeApi(
      eu: euDeTeste(),
      turmas: [turmaDeTeste(id: 'turma-1')],
    );
    final c = montar(api: api);
    await c.read(turmasProvider.future);
    // o erro da recarga sem rede fica junto da lista que já estava; a rede volta antes da ação
    api.falhaAoListarTurmas = const ErroDeRede('caiu');
    await expectLater(
      c.refresh(turmasProvider.future),
      throwsA(isA<ErroDeRede>()),
    );
    api.falhaAoListarTurmas = null;

    final nova = await c
        .read(turmasProvider.notifier)
        .criar(nome: 'Rolê da Firma', emoji: '🍕');

    expect(api.chamadas.last, 'criarTurma:Rolê da Firma:🍕');
    expect(idsDe(c), ['turma-1', nova.id]);
  });

  test('embaralhar depois de recarga que falhou chama a API', () async {
    final eu = pessoaDoEu(euDeTeste());
    final bia = pessoaDeTeste();
    final api = FakeApi(
      eu: euDeTeste(),
      turmas: [turmaDeTeste(totalDeMembros: 2)],
      membrosPor: {
        'turma-1': [membroDeTeste(eu, 1), membroDeTeste(bia, 2)],
      },
    );
    final c = montar(api: api);
    await c.read(turmasProvider.future);
    c.listen(turmaDetalheProvider('turma-1'), (_, _) {});
    await c.read(turmaDetalheProvider('turma-1').future);
    api.falhaAoObterTurma = const ErroDeRede('caiu');
    await expectLater(
      c.refresh(turmaDetalheProvider('turma-1').future),
      throwsA(isA<ErroDeRede>()),
    );
    api.falhaAoObterTurma = null;

    await c.read(turmaDetalheProvider('turma-1').notifier).embaralhar();

    expect(api.chamadas.last, 'embaralharOrdem:turma-1');
    final membros = c.read(turmaDetalheProvider('turma-1')).value!.membros;
    expect(membros.map((m) => m.pessoa.id), [bia.id, eu.id]);
  });
}
