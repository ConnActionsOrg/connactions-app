import 'package:connactions_app/api/modelos/atividade.dart';
import 'package:connactions_app/api/modelos/pagina_do_diario.dart';
import 'package:connactions_app/api/modelos/registro.dart';
import 'package:flutter_test/flutter_test.dart';

const pessoaJson = {
  'id': 'p1',
  'handle': 'bia',
  'nome': 'Bia Souza',
  'foto_url': null,
};

const registroJson = {
  'id': 'r1',
  'autor': pessoaJson,
  'foto_url': 'http://midia.local/registros/a.jpg',
  'miniatura_url': 'http://midia.local/registros/a.min.jpg',
  'legenda': 'Bolo de milho',
  'criado_em': '2026-09-29T15:00:00Z',
};

Map<String, dynamic> atividadeJson({
  Object? prazo = '2026-10-02T02:59:59Z',
  Object? encerradaEm,
  List<Object> registros = const [registroJson],
}) => {
  'id': 'a1',
  'turma_id': 'turma-1',
  'numero': 3,
  'proponente': pessoaJson,
  'titulo': 'Piquenique',
  'descricao': 'Cada um leva algo amarelo.',
  'regras': ['Um item por pessoa', 'Foto ao ar livre'],
  'formato': 'individual',
  'publica': true,
  'prazo': prazo,
  'lancada_em': '2026-09-29T12:00:00Z',
  'encerrada_em': encerradaEm,
  'registros': registros,
};

void main() {
  test('deJson lê tudo, inclusive prazo e registros', () {
    final a = Atividade.deJson(atividadeJson());
    expect(a.id, 'a1');
    expect(a.turmaId, 'turma-1');
    expect(a.numero, 3);
    expect(a.proponente.nome, 'Bia Souza');
    expect(a.regras, ['Um item por pessoa', 'Foto ao ar livre']);
    expect(a.formato, FormatoDeAtividade.individual);
    expect(a.publica, isTrue);
    expect(a.prazo, DateTime.utc(2026, 10, 2, 2, 59, 59));
    expect(a.lancadaEm, DateTime.utc(2026, 9, 29, 12));
    expect(a.encerradaEm, isNull);
    expect(a.aberta, isTrue);
    expect(a.registros.single.legenda, 'Bolo de milho');
    expect(a.registros.single.autor.id, 'p1');
  });

  test('sem prazo e encerrada', () {
    final a = Atividade.deJson(
      atividadeJson(
        prazo: null,
        encerradaEm: '2026-09-30T10:00:00Z',
        registros: const [],
      ),
    );
    expect(a.prazo, isNull);
    expect(a.encerradaEm, DateTime.utc(2026, 9, 30, 10));
    expect(a.aberta, isFalse);
    expect(a.registros, isEmpty);
  });

  test('prazoVenceu compara com o agora dado', () {
    final a = Atividade.deJson(atividadeJson());
    expect(a.prazoVenceu(DateTime.utc(2026, 10, 1)), isFalse);
    expect(a.prazoVenceu(DateTime.utc(2026, 10, 2, 2, 59, 59)), isTrue);
    expect(a.prazoVenceu(DateTime.utc(2026, 10, 3)), isTrue);
    final semPrazo = Atividade.deJson(atividadeJson(prazo: null));
    expect(semPrazo.prazoVenceu(DateTime.utc(2030)), isFalse);
  });

  test('registroDe acha o meu e copyWith troca só o pedido', () {
    final a = Atividade.deJson(atividadeJson());
    expect(a.registroDe('p1')?.id, 'r1');
    expect(a.registroDe('outro'), isNull);
    final sem = a.copyWith(registros: const []);
    expect(sem.registros, isEmpty);
    expect(sem.titulo, a.titulo);
    final fechada = a.copyWith(encerradaEm: DateTime.utc(2026, 9, 30));
    expect(fechada.aberta, isFalse);
    expect(fechada.registros.length, 1);
  });

  test('formato desconhecido estoura, rótulos são os das etiquetas', () {
    expect(() => FormatoDeAtividade.deJson('dupla'), throwsArgumentError);
    expect(FormatoDeAtividade.grupo.rotulo, 'Em grupo');
    expect(FormatoDeAtividade.individual.rotulo, 'Individual');
  });

  test('Registro.deJson', () {
    final r = Registro.deJson(registroJson);
    expect(r.fotoUrl, endsWith('a.jpg'));
    expect(r.miniaturaUrl, endsWith('a.min.jpg'));
    expect(r.criadoEm, DateTime.utc(2026, 9, 29, 15));
  });

  test('PaginaDoDiario.deJson com e sem próximo', () {
    final p = PaginaDoDiario.deJson({
      'itens': [atividadeJson(encerradaEm: '2026-09-30T10:00:00Z')],
      'proximo': 'abc',
    });
    expect(p.itens.single.id, 'a1');
    expect(p.proximo, 'abc');
    final fim = PaginaDoDiario.deJson({'itens': <Object>[], 'proximo': null});
    expect(fim.itens, isEmpty);
    expect(fim.proximo, isNull);
  });
}
