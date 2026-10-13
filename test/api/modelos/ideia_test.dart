import 'package:connactions_app/api/modelos/atividade.dart';
import 'package:connactions_app/api/modelos/ideia.dart';
import 'package:flutter_test/flutter_test.dart';

const autorJson = {
  'id': 'p1',
  'handle': 'carol',
  'nome': 'Carol Souza',
  'foto_url': null,
};

Map<String, dynamic> ideiaJson({
  Object? formato,
  Object? origemAtividadeId,
  List<Object> regras = const [],
}) => {
  'id': 'i1',
  'titulo': 'Noite de pizza',
  'descricao': 'Cada um traz um recheio.',
  'regras': regras,
  'formato': formato,
  'origem_atividade_id': origemAtividadeId,
  'autor': autorJson,
  'criado_em': '2026-10-06T12:00:00Z',
};

void main() {
  test('Ideia.deJson lê a ideia digitada, sem formato nem origem', () {
    final i = Ideia.deJson(ideiaJson());
    expect(i.id, 'i1');
    expect(i.titulo, 'Noite de pizza');
    expect(i.descricao, 'Cada um traz um recheio.');
    expect(i.regras, isEmpty);
    expect(i.formato, isNull);
    expect(i.origemAtividadeId, isNull);
    expect(i.daComunidade, isFalse);
    expect(i.autor.nome, 'Carol Souza');
    expect(i.autor.primeiroNome, 'Carol');
    expect(i.criadoEm, DateTime.utc(2026, 10, 6, 12));
  });

  test('Ideia.deJson lê a salva da Comunidade: formato, regras e origem', () {
    final i = Ideia.deJson(
      ideiaJson(
        formato: 'grupo',
        origemAtividadeId: 'a9',
        regras: const ['Um recheio por pessoa'],
      ),
    );
    expect(i.formato, FormatoDeAtividade.grupo);
    expect(i.regras, ['Um recheio por pessoa']);
    expect(i.origemAtividadeId, 'a9');
    expect(i.daComunidade, isTrue);
  });
}
