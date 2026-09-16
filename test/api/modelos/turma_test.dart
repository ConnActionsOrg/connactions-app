import 'package:connactions_app/api/modelos/pessoa.dart';
import 'package:connactions_app/api/modelos/turma.dart';
import 'package:flutter_test/flutter_test.dart';

const turmaJson = {
  'id': 't1',
  'nome': 'Turma do Domingo',
  'emoji': '🌿',
  'codigo_convite': 'ABCD2345',
  'criador_id': 'u1',
  'vez_de': {
    'id': 'u1',
    'handle': 'ana.lima',
    'nome': 'Ana Lima',
    'foto_url': null,
  },
  'total_de_membros': 2,
  'criado_em': '2026-09-15T12:00:00-03:00',
};

void main() {
  test('Turma.deJson lê o contrato da API', () {
    final turma = Turma.deJson(turmaJson);
    expect(turma.nome, 'Turma do Domingo');
    expect(turma.emoji, '🌿');
    expect(turma.codigoConvite, 'ABCD2345');
    expect(turma.criadorId, 'u1');
    expect(turma.vezDe.handle, 'ana.lima');
    expect(turma.vezDe.fotoUrl, isNull);
    expect(turma.totalDeMembros, 2);
    expect(turma.criadoEm.toUtc(), DateTime.utc(2026, 9, 15, 15));
  });

  test('copyWith troca só o que foi pedido', () {
    final turma = Turma.deJson(turmaJson);
    final nova = turma.copyWith(codigoConvite: 'WXYZ6789', totalDeMembros: 3);
    expect(nova.codigoConvite, 'WXYZ6789');
    expect(nova.totalDeMembros, 3);
    expect(nova.nome, 'Turma do Domingo');
    expect(nova.vezDe.id, 'u1');
  });

  test('membrosPorExtenso concorda em número', () {
    final turma = Turma.deJson(turmaJson);
    expect(turma.copyWith(totalDeMembros: 1).membrosPorExtenso, '1 membro');
    expect(turma.membrosPorExtenso, '2 membros');
  });

  test('primeiroNome vai até o primeiro espaço', () {
    expect(Turma.deJson(turmaJson).vezDe.primeiroNome, 'Ana');
    const solto = {
      'id': 'x',
      'handle': 'x',
      'nome': '  Bia ',
      'foto_url': null,
    };
    expect(Pessoa.deJson(solto).primeiroNome, 'Bia');
  });

  test('TurmaDetalhe.deJson lê a turma e os membros', () {
    final detalhe = TurmaDetalhe.deJson({
      ...turmaJson,
      'membros': [
        {
          'id': 'u1',
          'handle': 'ana.lima',
          'nome': 'Ana Lima',
          'foto_url': null,
          'ordem': 1,
          'entrou_em': '2026-09-15T12:00:00Z',
        },
        {
          'id': 'u2',
          'handle': 'bia',
          'nome': 'Bia Souza',
          'foto_url': 'https://exemplo.com/bia.jpg',
          'ordem': 2,
          'entrou_em': '2026-09-15T13:00:00Z',
        },
      ],
    });
    expect(detalhe.turma.id, 't1');
    expect(detalhe.membros.length, 2);
    expect(detalhe.membros[1].pessoa.nome, 'Bia Souza');
    expect(detalhe.membros[1].pessoa.fotoUrl, 'https://exemplo.com/bia.jpg');
    expect(detalhe.membros[1].ordem, 2);
    expect(detalhe.membros[0].entrouEm, DateTime.utc(2026, 9, 15, 12));
  });
}
