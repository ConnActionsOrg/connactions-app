import 'package:connactions_app/app/dependencias.dart';
import 'package:connactions_app/features/comunidade/comunidade.dart';
import 'package:connactions_app/features/turmas/turmas.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../apoio/autenticador_falso.dart';
import '../../apoio/compartilhador_falso.dart';
import '../../apoio/fake_api.dart';
import '../../apoio/preferencias_em_memoria.dart';
import '../../apoio/seletor_de_foto_falso.dart';

ProviderContainer montar(FakeApi api) {
  final container = ProviderContainer.test(
    overrides: [
      autenticadorProvider.overrideWithValue(
        AutenticadorFalso(conta: contaDeTeste),
      ),
      apiProvider.overrideWithValue(api),
      preferenciasProvider.overrideWithValue(PreferenciasEmMemoria()),
      compartilhadorProvider.overrideWithValue(CompartilhadorFalso()),
      seletorDeFotoProvider.overrideWithValue(SeletorDeFotoFalso()),
    ],
  );
  // sem ouvinte o Riverpod pausa a cadeia conta → perfil → turmas e o .future nunca resolve
  container.listen(turmasProvider, (_, _) {});
  container.listen(comunidadeProvider, (_, _) {});
  return container;
}

FakeApi apiCom({int quantas = 3}) => FakeApi(
  eu: euDeTeste(),
  turmas: [turmaDeTeste()],
  convites: {
    'ZZZZ2345': turmaDeTeste(
      id: 'turma-2',
      nome: 'Outra turma',
      codigoConvite: 'ZZZZ2345',
      criadorId: 'outra-pessoa',
      vezDe: pessoaDeTeste(),
    ),
  },
  comunidade: [
    for (var i = 1; i <= quantas; i++)
      atividadeDaComunidadeDeTeste(id: 'com-$i'),
  ],
);

int leituras(FakeApi api) =>
    api.chamadas.where((c) => c.startsWith('listarComunidade')).length;

/// Dá aos rebuilds agendados a chance de rodar antes de afirmar que NÃO houve releitura.
Future<void> aguardarRebuilds() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  test('espera o perfil e as turmas antes da primeira página', () async {
    final api = apiCom(quantas: 25);
    final c = montar(api);

    final pagina = await c.read(comunidadeProvider.future);

    expect(pagina.itens.length, 20);
    expect(pagina.proximo, '20');
    expect(api.chamadas, ['obterEu', 'listarTurmas', 'listarComunidade:']);
  });

  test('carregarMais concatena até o fim e depois não chama a API', () async {
    final api = apiCom(quantas: 25);
    final c = montar(api);
    await c.read(comunidadeProvider.future);
    final notifier = c.read(comunidadeProvider.notifier);

    await notifier.carregarMais();
    final tudo = c.read(comunidadeProvider).value!;
    expect(tudo.itens.length, 25);
    expect(tudo.itens.first.id, 'com-1');
    expect(tudo.itens.last.id, 'com-25');
    expect(tudo.proximo, isNull);
    expect(api.chamadas.last, 'listarComunidade:20');

    await notifier.carregarMais();
    expect(leituras(api), 2);
  });

  test('relê quando eu entro numa turma, que deixa de ser "outra"', () async {
    final api = apiCom();
    final c = montar(api);
    await c.read(comunidadeProvider.future);
    expect(leituras(api), 1);

    await c.read(turmasProvider.notifier).entrar('ZZZZ2345');
    await c.read(comunidadeProvider.future);

    expect(leituras(api), 2);
  });

  test('relê quando eu saio de uma turma', () async {
    final api = apiCom();
    final c = montar(api);
    await c.read(comunidadeProvider.future);

    await c.read(turmasProvider.notifier).sair('turma-1');
    await c.read(comunidadeProvider.future);

    expect(leituras(api), 2);
  });

  test('não relê quando só a vez anda ou o convite muda', () async {
    final api = apiCom();
    final c = montar(api);
    await c.read(comunidadeProvider.future);
    final turma = c.read(turmasProvider).value!.single;

    c
        .read(turmasProvider.notifier)
        .substituir(
          turma.copyWith(vezDe: pessoaDeTeste(), codigoConvite: 'NOVO2345'),
        );
    await aguardarRebuilds();

    expect(leituras(api), 1);
  });

  test('não relê quando a lista de turmas é recarregada igual', () async {
    final api = apiCom();
    final c = montar(api);
    await c.read(comunidadeProvider.future);

    c.invalidate(turmasProvider);
    await c.read(turmasProvider.future);
    await aguardarRebuilds();

    expect(api.chamadas.where((c) => c == 'listarTurmas').length, 2);
    expect(leituras(api), 1);
  });
}
