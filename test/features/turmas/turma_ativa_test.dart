import 'package:connactions_app/features/turmas/turma_ativa.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../apoio/fake_api.dart';

void main() {
  final primeira = turmaDeTeste(id: 'turma-1');
  final segunda = turmaDeTeste(
    id: 'turma-2',
    nome: 'Cozinha & Prosa',
    emoji: '☕',
  );

  test('sem turmas não há ativa', () {
    expect(turmaAtiva(null, 'turma-1'), isNull);
    expect(turmaAtiva([], 'turma-1'), isNull);
  });

  test('o id salvo vence', () {
    expect(turmaAtiva([primeira, segunda], 'turma-2')?.id, 'turma-2');
  });

  test('id órfão ou ausente cai na primeira', () {
    expect(turmaAtiva([primeira, segunda], 'turma-99')?.id, 'turma-1');
    expect(turmaAtiva([primeira, segunda], null)?.id, 'turma-1');
  });
}
