import 'package:connactions_app/api/erro_da_api.dart';
import 'package:connactions_app/api/modelos/atividade.dart';
import 'package:connactions_app/api/modelos/atividade_da_comunidade.dart';
import 'package:connactions_app/api/modelos/ideia.dart';
import 'package:connactions_app/api/modelos/proposta.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_api.dart';

final eu = pessoaDoEu(euDeTeste());
final bia = pessoaDeTeste();

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

Matcher erroCom(String codigo) =>
    throwsA(isA<ErroDaApi>().having((e) => e.codigo, 'codigo', codigo));

void main() {
  test('o teto é de 5 livres por autor, sem contar as dos outros', () async {
    final api = apiCom(
      ideias: [ideiaDeTeste(id: 'da-bia', autor: bia)],
    );
    for (var i = 1; i <= 5; i++) {
      await api.criarIdeia('turma-1', titulo: 'Ideia $i');
    }

    await expectLater(
      api.criarIdeia('turma-1', titulo: 'A sexta'),
      erroCom('backlog_cheio'),
    );
    final lista = await api.listarIdeias('turma-1');
    expect(lista.length, 6);
    expect(lista.first.titulo, 'Ideia 5');
    expect(lista.first.autor.id, eu.id);
    expect(api.chamadas.last, 'listarIdeias:turma-1');
  });

  test('salvar da Comunidade copia o conteúdo e grava a origem', () async {
    final api = apiCom(
      comunidade: [
        atividadeDaComunidadeDeTeste(
          regras: const ['Um jogo por pessoa'],
          formato: FormatoDeAtividade.individual,
        ),
      ],
    );

    final salva = await api.salvarDaComunidade('com-1', turmaId: 'turma-1');

    expect(salva.titulo, 'Noite de jogos');
    expect(salva.descricao, 'Cada um leva um jogo.');
    expect(salva.regras, ['Um jogo por pessoa']);
    expect(salva.formato, FormatoDeAtividade.individual);
    expect(salva.origemAtividadeId, 'com-1');
    expect(salva.autor.id, eu.id);
    expect((await api.listarIdeias('turma-1')).single.id, salva.id);
    expect(api.chamadas, contains('salvarDaComunidade:com-1:turma-1'));
  });

  test('a duplicata é recusada antes de olhar o teto', () async {
    final api = apiCom(comunidade: [atividadeDaComunidadeDeTeste()]);
    await api.salvarDaComunidade('com-1', turmaId: 'turma-1');
    for (var i = 1; i <= 4; i++) {
      await api.criarIdeia('turma-1', titulo: 'Ideia $i');
    }

    await expectLater(
      api.salvarDaComunidade('com-1', turmaId: 'turma-1'),
      erroCom('ja_no_backlog'),
    );
  });

  test('salvar recusa atividade desconhecida e turma alheia', () async {
    final api = apiCom(comunidade: [atividadeDaComunidadeDeTeste()]);

    await expectLater(
      api.salvarDaComunidade('nao-existe', turmaId: 'turma-1'),
      erroCom('nao_encontrado'),
    );
    await expectLater(
      api.salvarDaComunidade('com-1', turmaId: 'turma-x'),
      erroCom('nao_encontrado'),
    );
  });

  test('só o autor apaga, e a apagada sai da lista', () async {
    final api = apiCom(
      ideias: [
        ideiaDeTeste(id: 'minha'),
        ideiaDeTeste(id: 'da-bia', autor: bia),
      ],
    );

    await expectLater(api.apagarIdeia('da-bia'), erroCom('sem_acesso'));
    await expectLater(api.apagarIdeia('nao-existe'), erroCom('nao_encontrado'));
    await api.apagarIdeia('minha');

    expect((await api.listarIdeias('turma-1')).map((i) => i.id), ['da-bia']);
  });

  test('lançar com a ideia a consome e guarda a proposta', () async {
    final api = apiCom(ideias: [ideiaDeTeste(id: 'i1')]);

    await api.lancarAtividade(
      'turma-1',
      const Proposta(
        titulo: 'Pizza',
        formato: FormatoDeAtividade.grupo,
        publica: true,
        origemIdeiaId: 'i1',
      ),
    );

    expect(api.ultimaProposta?.origemIdeiaId, 'i1');
    expect(await api.listarIdeias('turma-1'), isEmpty);
  });

  test('lançar com ideia que sumiu dá ideia_indisponivel', () async {
    final api = apiCom();

    await expectLater(
      api.lancarAtividade(
        'turma-1',
        const Proposta(
          titulo: 'Pizza',
          formato: FormatoDeAtividade.grupo,
          publica: true,
          origemIdeiaId: 'sumiu',
        ),
      ),
      erroCom('ideia_indisponivel'),
    );
    expect(api.abertaPor['turma-1'], isNull);
  });

  test('lançar com atividade fora da Comunidade dá 422', () async {
    final api = apiCom(comunidade: [atividadeDaComunidadeDeTeste()]);

    await expectLater(
      api.lancarAtividade(
        'turma-1',
        const Proposta(
          titulo: 'Pizza',
          formato: FormatoDeAtividade.grupo,
          publica: true,
          origemAtividadeId: 'sumiu',
        ),
      ),
      erroCom('dados_invalidos'),
    );
    await api.lancarAtividade(
      'turma-1',
      const Proposta(
        titulo: 'Pizza',
        formato: FormatoDeAtividade.grupo,
        publica: true,
        origemAtividadeId: 'com-1',
      ),
    );
    expect(api.ultimaProposta?.origemAtividadeId, 'com-1');
  });

  test('listarComunidade pagina pelo índice, como o Diário', () async {
    final api = apiCom(
      comunidade: [
        for (var i = 1; i <= 3; i++) atividadeDaComunidadeDeTeste(id: 'com-$i'),
      ],
    );

    final primeira = await api.listarComunidade(limite: 2);
    expect(primeira.itens.map((a) => a.id), ['com-1', 'com-2']);
    expect(primeira.proximo, '2');

    final segunda = await api.listarComunidade(
      apos: primeira.proximo,
      limite: 2,
    );
    expect(segunda.itens.map((a) => a.id), ['com-3']);
    expect(segunda.proximo, isNull);
    expect(api.chamadas, ['listarComunidade:', 'listarComunidade:2']);
  });
}
