import 'package:connactions_app/api/erro_da_api.dart';
import 'package:connactions_app/api/modelos/atividade_da_comunidade.dart';
import 'package:connactions_app/api/modelos/ideia.dart';
import 'package:connactions_app/app/dependencias.dart';
import 'package:connactions_app/features/ideias/ideias.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../apoio/fake_api.dart';

final eu = pessoaDoEu(euDeTeste());
final bia = pessoaDeTeste();

ProviderContainer montar(FakeApi api) {
  final container = ProviderContainer.test(
    overrides: [apiProvider.overrideWithValue(api)],
  );
  // sem ouvinte o Riverpod pausa o provider e o .future nunca resolve
  container.listen(ideiasProvider('turma-1'), (_, _) {});
  return container;
}

FakeApi apiCom({
  List<Ideia> ideias = const [],
  List<AtividadeDaComunidade> comunidade = const [],
}) => FakeApi(
  eu: euDeTeste(),
  turmas: [turmaDeTeste(totalDeMembros: 2)],
  membrosPor: {
    'turma-1': [membroDeTeste(eu, 1), membroDeTeste(bia, 2)],
  },
  ideiasPor: {'turma-1': ideias},
  comunidade: comunidade,
);

List<String> titulos(ProviderContainer c) =>
    c.read(ideiasProvider('turma-1')).value!.map((i) => i.titulo).toList();

void main() {
  test('lê as ideias livres da turma', () async {
    final api = apiCom(
      ideias: [
        ideiaDeTeste(id: 'i2', titulo: 'Trilha', autor: bia),
        ideiaDeTeste(id: 'i1', titulo: 'Pizza'),
      ],
    );
    final c = montar(api);

    final lista = await c.read(ideiasProvider('turma-1').future);

    expect(lista.map((i) => i.titulo), ['Trilha', 'Pizza']);
    expect(api.chamadas, ['listarIdeias:turma-1']);
  });

  test('criar põe a nova no topo e apagar a tira', () async {
    final api = apiCom(
      ideias: [ideiaDeTeste(id: 'i1', titulo: 'Pizza')],
    );
    final c = montar(api);
    await c.read(ideiasProvider('turma-1').future);
    final notifier = c.read(ideiasProvider('turma-1').notifier);

    final nova = await notifier.criar(titulo: 'Trilha', descricao: 'No morro');

    expect(nova.descricao, 'No morro');
    expect(titulos(c), ['Trilha', 'Pizza']);
    expect(api.chamadas.last, 'criarIdeia:turma-1:Trilha');

    await notifier.apagar('i1');

    expect(titulos(c), ['Trilha']);
    expect(api.chamadas.last, 'apagarIdeia:i1');
  });

  test('salvar da Comunidade põe a ideia copiada no topo', () async {
    final api = apiCom(
      ideias: [ideiaDeTeste(id: 'i1', titulo: 'Pizza')],
      comunidade: [atividadeDaComunidadeDeTeste()],
    );
    final c = montar(api);
    await c.read(ideiasProvider('turma-1').future);

    final salva = await c
        .read(ideiasProvider('turma-1').notifier)
        .salvarDaComunidade('com-1');

    expect(salva.origemAtividadeId, 'com-1');
    expect(titulos(c), ['Noite de jogos', 'Pizza']);
    expect(api.chamadas.last, 'salvarDaComunidade:com-1:turma-1');
  });

  test('erro da API sobe e a lista não muda', () async {
    final api = apiCom(
      ideias: [ideiaDeTeste(id: 'i1', titulo: 'Pizza')],
    );
    final c = montar(api);
    await c.read(ideiasProvider('turma-1').future);
    final notifier = c.read(ideiasProvider('turma-1').notifier);

    api.falhaAoCriarIdeia = const ErroDaApi(
      status: 409,
      codigo: 'backlog_cheio',
      mensagem: 'cheio',
    );
    await expectLater(
      notifier.criar(titulo: 'Trilha'),
      throwsA(isA<ErroDaApi>().having((e) => e.backlogCheio, 'cheio', isTrue)),
    );

    api.falhaAoApagarIdeia = const ErroDaApi(
      status: 409,
      codigo: 'ideia_indisponivel',
      mensagem: 'usada',
    );
    await expectLater(notifier.apagar('i1'), throwsA(isA<ErroDaApi>()));

    expect(titulos(c), ['Pizza']);
  });

  test('minhasLivres conta só as minhas e guardada olha a origem', () {
    final lista = [
      ideiaDeTeste(id: 'a', origemAtividadeId: 'com-1'),
      ideiaDeTeste(id: 'b', autor: bia),
      ideiaDeTeste(id: 'c'),
    ];

    expect(minhasLivres(lista, eu.id), 2);
    expect(minhasLivres(lista, bia.id), 1);
    expect(minhasLivres(const [], eu.id), 0);
    expect(guardada(lista, 'com-1'), isTrue);
    expect(guardada(lista, 'com-2'), isFalse);
    expect(tetoDeIdeias, 5);
  });
}
