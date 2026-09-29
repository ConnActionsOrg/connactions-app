import 'dart:async';

import 'package:connactions_app/api/erro_da_api.dart';
import 'package:connactions_app/api/modelos/atividade.dart';
import 'package:connactions_app/api/modelos/proposta.dart';
import 'package:connactions_app/app/dependencias.dart';
import 'package:connactions_app/features/atividades/atividade_aberta.dart';
import 'package:connactions_app/features/diario/diario.dart';
import 'package:connactions_app/features/turmas/turmas.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../apoio/autenticador_falso.dart';
import '../../apoio/compartilhador_falso.dart';
import '../../apoio/fake_api.dart';
import '../../apoio/preferencias_em_memoria.dart';
import '../../apoio/seletor_de_foto_falso.dart';

final eu = pessoaDoEu(euDeTeste());
final bia = pessoaDeTeste();

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
  // sem ouvinte o Riverpod pausa a cadeia e o .future nunca resolve
  container.listen(turmasProvider, (_, _) {});
  container.listen(atividadeAbertaProvider('turma-1'), (_, _) {});
  return container;
}

FakeApi apiComTurma({Atividade? aberta}) => FakeApi(
  eu: euDeTeste(),
  turmas: [turmaDeTeste(totalDeMembros: 2)],
  membrosPor: {
    'turma-1': [membroDeTeste(eu, 1), membroDeTeste(bia, 2)],
  },
  abertaPor: {'turma-1': aberta},
);

const proposta = Proposta(
  titulo: 'Piquenique',
  formato: FormatoDeAtividade.individual,
  publica: true,
);

void main() {
  test('lê a aberta da turma (ou nada)', () async {
    final c = montar(apiComTurma());
    expect(await c.read(atividadeAbertaProvider('turma-1').future), isNull);

    final c2 = montar(apiComTurma(aberta: atividadeDeTeste()));
    final a = await c2.read(atividadeAbertaProvider('turma-1').future);
    expect(a?.id, 'ativ-1');
  });

  test('lancar grava a atividade devolvida', () async {
    final api = apiComTurma();
    final c = montar(api);
    // sem isto a cadeia turmas → perfil ainda pode registrar 'listarTurmas' depois da chamada afirmada
    await c.read(turmasProvider.future);
    await c.read(atividadeAbertaProvider('turma-1').future);

    final a = await c
        .read(atividadeAbertaProvider('turma-1').notifier)
        .lancar(proposta);

    expect(c.read(atividadeAbertaProvider('turma-1')).value?.id, a.id);
    expect(api.chamadas.last, 'lancarAtividade:turma-1:Piquenique');
  });

  test('lancar espera o build assentar antes de gravar', () async {
    final api = apiComTurma()..segurarObterAberta = Completer<void>();
    final c = montar(api);

    final futuro = c
        .read(atividadeAbertaProvider('turma-1').notifier)
        .lancar(proposta);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(api.chamadas, isNot(contains('lancarAtividade:turma-1:Piquenique')));

    api.segurarObterAberta!.complete();
    final a = await futuro;

    expect(
      api.chamadas.indexOf('obterAtividadeAberta:turma-1'),
      lessThan(api.chamadas.indexOf('lancarAtividade:turma-1:Piquenique')),
    );
    expect(c.read(atividadeAbertaProvider('turma-1')).value?.id, a.id);
  });

  test('encerrar zera a aberta, troca a turma e invalida o diário', () async {
    final api = apiComTurma(aberta: atividadeDeTeste());
    final c = montar(api);
    c.listen(diarioProvider('turma-1'), (_, _) {});
    await c.read(turmasProvider.future);
    await c.read(atividadeAbertaProvider('turma-1').future);
    await c.read(diarioProvider('turma-1').future);
    final leiturasDoDiario = api.chamadas
        .where((c) => c.startsWith('listarDiario'))
        .length;

    final e = await c
        .read(atividadeAbertaProvider('turma-1').notifier)
        .encerrar();

    expect(e.turma.vezDe.id, bia.id);
    expect(c.read(atividadeAbertaProvider('turma-1')).value, isNull);
    expect(c.read(turmasProvider).value!.single.vezDe.id, bia.id);
    await c.read(diarioProvider('turma-1').future);
    expect(
      api.chamadas.where((c) => c.startsWith('listarDiario')).length,
      leiturasDoDiario + 1,
    );
    expect(c.read(diarioProvider('turma-1')).value!.itens.single.id, 'ativ-1');
  });

  test('registrar acrescenta e apagar remove', () async {
    final api = apiComTurma(aberta: atividadeDeTeste());
    final c = montar(api);
    // sem isto a cadeia turmas → perfil ainda pode registrar 'listarTurmas' depois da chamada afirmada
    await c.read(turmasProvider.future);
    await c.read(atividadeAbertaProvider('turma-1').future);

    final r = await c
        .read(atividadeAbertaProvider('turma-1').notifier)
        .registrar(fotoDeTeste(), 'Bolo');
    expect(
      c.read(atividadeAbertaProvider('turma-1')).value!.registros.single.id,
      r.id,
    );
    expect(api.chamadas.last, 'registrar:ativ-1:Bolo');

    await c
        .read(atividadeAbertaProvider('turma-1').notifier)
        .apagarRegistro(r.id);
    expect(
      c.read(atividadeAbertaProvider('turma-1')).value!.registros,
      isEmpty,
    );
    expect(api.chamadas.last, 'apagarRegistro:${r.id}');
  });

  test('erro da API sobe para quem chamou e o estado fica', () async {
    final api = apiComTurma(aberta: atividadeDeTeste())
      ..falhaAoRegistrar = const ErroDaApi(
        status: 409,
        codigo: 'ja_registrou',
        mensagem: 'Você já postou.',
      );
    final c = montar(api);
    await c.read(atividadeAbertaProvider('turma-1').future);

    await expectLater(
      c
          .read(atividadeAbertaProvider('turma-1').notifier)
          .registrar(fotoDeTeste(), ''),
      throwsA(isA<ErroDaApi>().having((e) => e.conflito, 'conflito', isTrue)),
    );
    expect(c.read(atividadeAbertaProvider('turma-1')).value?.id, 'ativ-1');
  });
}
