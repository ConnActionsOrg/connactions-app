import 'dart:async';

import 'package:connactions_app/api/erro_da_api.dart';
import 'package:connactions_app/api/modelos/atividade.dart';
import 'package:connactions_app/api/modelos/foto_para_enviar.dart';
import 'package:connactions_app/api/modelos/proposta.dart';
import 'package:connactions_app/api/modelos/registro.dart';
import 'package:connactions_app/app/dependencias.dart';
import 'package:connactions_app/features/atividades/atividade_aberta.dart';
import 'package:connactions_app/features/diario/diario.dart';
import 'package:connactions_app/features/ideias/ideias.dart';
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

ProviderContainer montar(FakeApi api, {bool ouvirAberta = true}) {
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
  if (ouvirAberta) {
    container.listen(atividadeAbertaProvider('turma-1'), (_, _) {});
  }
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

  test('lancar com a ideia do backlog manda o backlog reler', () async {
    final api = FakeApi(
      eu: euDeTeste(),
      turmas: [turmaDeTeste(totalDeMembros: 2)],
      membrosPor: {
        'turma-1': [membroDeTeste(eu, 1), membroDeTeste(bia, 2)],
      },
      ideiasPor: {
        'turma-1': [ideiaDeTeste(id: 'i1', autor: bia)],
      },
    );
    final c = montar(api);
    c.listen(ideiasProvider('turma-1'), (_, _) {});
    await c.read(turmasProvider.future);
    await c.read(atividadeAbertaProvider('turma-1').future);
    expect((await c.read(ideiasProvider('turma-1').future)).single.id, 'i1');
    final leituras = api.chamadas.where((c) => c == 'listarIdeias:turma-1');

    await c
        .read(atividadeAbertaProvider('turma-1').notifier)
        .lancar(
          const Proposta(
            titulo: 'Piquenique',
            formato: FormatoDeAtividade.individual,
            publica: true,
            origemIdeiaId: 'i1',
          ),
        );

    expect(await c.read(ideiasProvider('turma-1').future), isEmpty);
    expect(leituras.length, 2);
  });

  test('lancar do zero não relê as ideias', () async {
    final api = apiComTurma();
    final c = montar(api);
    c.listen(ideiasProvider('turma-1'), (_, _) {});
    await c.read(turmasProvider.future);
    await c.read(atividadeAbertaProvider('turma-1').future);
    await c.read(ideiasProvider('turma-1').future);

    await c
        .read(atividadeAbertaProvider('turma-1').notifier)
        .lancar(
          const Proposta(
            titulo: 'Piquenique',
            formato: FormatoDeAtividade.individual,
            publica: true,
          ),
        );
    await Future<void>.delayed(Duration.zero);

    expect(api.chamadas.where((c) => c == 'listarIdeias:turma-1').length, 1);
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
    expect(
      c.read(diarioProvider('turma-1')).value!.itens.single.atividade.id,
      'ativ-1',
    );
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

  group('depois de uma recarga que falhou', () {
    // Deixa o erro da recarga junto da aberta que já estava, como depois de um "puxar para baixo"
    // sem rede, e devolve a rede antes da ação.
    Future<ProviderContainer> comRecargaFalha(FakeApi api) async {
      final c = montar(api);
      await c.read(turmasProvider.future);
      await c.read(atividadeAbertaProvider('turma-1').future);
      api.falhaAoObterAberta = const ErroDeRede('caiu');
      await expectLater(
        c.refresh(atividadeAbertaProvider('turma-1').future),
        throwsA(isA<ErroDeRede>()),
      );
      api.falhaAoObterAberta = null;
      return c;
    }

    test('lancar chama a API com a rede de volta', () async {
      final api = apiComTurma();
      final c = await comRecargaFalha(api);

      final a = await c
          .read(atividadeAbertaProvider('turma-1').notifier)
          .lancar(proposta);

      expect(api.chamadas.last, 'lancarAtividade:turma-1:Piquenique');
      expect(c.read(atividadeAbertaProvider('turma-1')).value?.id, a.id);
    });

    test('registrar chama a API com a rede de volta', () async {
      final api = apiComTurma(aberta: atividadeDeTeste());
      final c = await comRecargaFalha(api);

      final r = await c
          .read(atividadeAbertaProvider('turma-1').notifier)
          .registrar(fotoDeTeste(), 'Bolo');

      expect(api.chamadas.last, 'registrar:ativ-1:Bolo');
      expect(
        c.read(atividadeAbertaProvider('turma-1')).value!.registros.single.id,
        r.id,
      );
    });

    test('apagarRegistro chama a API com a rede de volta', () async {
      final api = apiComTurma(
        aberta: atividadeDeTeste(registros: [registroDeTeste(autor: eu)]),
      );
      final c = await comRecargaFalha(api);

      await c
          .read(atividadeAbertaProvider('turma-1').notifier)
          .apagarRegistro('reg-1');

      expect(api.chamadas.last, 'apagarRegistro:reg-1');
      expect(
        c.read(atividadeAbertaProvider('turma-1')).value!.registros,
        isEmpty,
      );
    });

    test('encerrar chama a API com a rede de volta', () async {
      final api = apiComTurma(aberta: atividadeDeTeste());
      final c = await comRecargaFalha(api);

      await c.read(atividadeAbertaProvider('turma-1').notifier).encerrar();

      expect(api.chamadas, contains('encerrarAtividade:ativ-1'));
      expect(c.read(atividadeAbertaProvider('turma-1')).value, isNull);
      expect(c.read(turmasProvider).value!.single.vezDe.id, bia.id);
    });
  });

  group('com a aberta mudando no meio da chamada', () {
    _ApiComGancho apiComAberta(Atividade aberta) => _ApiComGancho(
      eu: euDeTeste(),
      turmas: [turmaDeTeste(totalDeMembros: 2)],
      membrosPor: {
        'turma-1': [membroDeTeste(eu, 1), membroDeTeste(bia, 2)],
      },
      abertaPor: {'turma-1': aberta},
    );

    test(
      'encerrar entrega a vez à lista mesmo com a aberta descartada',
      () async {
        final api = apiComAberta(atividadeDeTeste());
        final c = montar(api, ouvirAberta: false);
        final ouvinte = c.listen(atividadeAbertaProvider('turma-1'), (_, _) {});
        await c.read(turmasProvider.future);
        await c.read(atividadeAbertaProvider('turma-1').future);
        api.duranteEncerrar = () async {
          ouvinte.close();
          await Future<void>.delayed(Duration.zero);
          // sem isto o teste passaria sem provar nada: a família tem de estar morta com o POST no ar
          expect(c.exists(atividadeAbertaProvider('turma-1')), isFalse);
        };

        await c.read(atividadeAbertaProvider('turma-1').notifier).encerrar();

        expect(c.read(turmasProvider).value!.single.vezDe.id, bia.id);
      },
    );

    test('registrar chama a API mesmo com a aberta descartada enquanto '
        'carregava', () async {
      final api = apiComAberta(atividadeDeTeste())
        ..segurarObterAberta = Completer<void>();
      final c = montar(api, ouvirAberta: false);
      final ouvinte = c.listen(atividadeAbertaProvider('turma-1'), (_, _) {});
      final registrando = c
          .read(atividadeAbertaProvider('turma-1').notifier)
          .registrar(fotoDeTeste(), 'Bolo');
      await Future<void>.delayed(Duration.zero);
      ouvinte.close();
      await Future<void>.delayed(Duration.zero);
      // sem isto o teste passaria sem provar nada: a família tem de estar morta durante a espera
      expect(c.exists(atividadeAbertaProvider('turma-1')), isFalse);

      api.segurarObterAberta!.complete();
      await registrando;

      expect(api.chamadas, contains('registrar:ativ-1:Bolo'));
    });

    test('registrar cuja resposta chega depois de encerrar não ressuscita a '
        'atividade', () async {
      final api = apiComAberta(atividadeDeTeste());
      final c = montar(api);
      await c.read(turmasProvider.future);
      await c.read(atividadeAbertaProvider('turma-1').future);
      final aberta = c.read(atividadeAbertaProvider('turma-1').notifier);
      api.depoisDeRegistrar = () => aberta.encerrar();

      await aberta.registrar(fotoDeTeste(), 'Bolo');

      expect(api.chamadas, contains('encerrarAtividade:ativ-1'));
      expect(c.read(atividadeAbertaProvider('turma-1')).value, isNull);
    });

    test('apagarRegistro cuja resposta chega depois de encerrar não ressuscita '
        'a atividade', () async {
      final api = apiComAberta(
        atividadeDeTeste(registros: [registroDeTeste(autor: eu)]),
      );
      final c = montar(api);
      await c.read(turmasProvider.future);
      await c.read(atividadeAbertaProvider('turma-1').future);
      final aberta = c.read(atividadeAbertaProvider('turma-1').notifier);
      api.depoisDeApagar = () => aberta.encerrar();

      await aberta.apagarRegistro('reg-1');

      expect(api.chamadas, contains('encerrarAtividade:ativ-1'));
      expect(c.read(atividadeAbertaProvider('turma-1')).value, isNull);
    });
  });
}

/// Deixa o teste mexer no mundo enquanto uma chamada está no ar: os ganchos rodam depois de a API
/// ter gravado (registrar, apagar) ou antes de gravar (encerrar), e antes de a resposta voltar.
class _ApiComGancho extends FakeApi {
  _ApiComGancho({super.eu, super.turmas, super.membrosPor, super.abertaPor});

  Future<void> Function()? duranteEncerrar;
  Future<void> Function()? depoisDeRegistrar;
  Future<void> Function()? depoisDeApagar;

  @override
  Future<Encerramento> encerrarAtividade(String atividadeId) async {
    await duranteEncerrar?.call();
    return super.encerrarAtividade(atividadeId);
  }

  @override
  Future<Registro> registrar(
    String atividadeId, {
    required FotoParaEnviar foto,
    String legenda = '',
  }) async {
    final registro = await super.registrar(
      atividadeId,
      foto: foto,
      legenda: legenda,
    );
    await depoisDeRegistrar?.call();
    return registro;
  }

  @override
  Future<void> apagarRegistro(String registroId) async {
    await super.apagarRegistro(registroId);
    await depoisDeApagar?.call();
  }
}
