import 'dart:async';

import 'package:connactions_app/api/erro_da_api.dart';
import 'package:connactions_app/api/modelos/atividade.dart';
import 'package:connactions_app/api/modelos/pagina_do_diario.dart';
import 'package:connactions_app/design/widgets/etiqueta.dart';
import 'package:connactions_app/features/atividades/visualizador_de_fotos.dart';
import 'package:connactions_app/features/diario/cartao_da_capa.dart';
import 'package:connactions_app/features/diario/cartao_do_diario.dart';
import 'package:connactions_app/features/diario/tela_do_diario.dart';
import 'package:connactions_app/features/turmas/seletor_de_turma.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import '../../apoio/app_de_teste.dart';
import '../../apoio/fake_api.dart';

/// Segura `listarDiario` até o teste liberar e conta os pedidos que chegaram, presos ou não.
class _ApiComDiarioSegurado extends FakeApi {
  _ApiComDiarioSegurado({super.eu, super.turmas, super.diarioPor});

  Completer<void>? segurarListarDiario;
  var pedidos = 0;

  @override
  Future<PaginaDoDiario> listarDiario(
    String turmaId, {
    String? apos,
    int limite = 20,
  }) async {
    pedidos++;
    await segurarListarDiario?.future;
    return super.listarDiario(turmaId, apos: apos, limite: limite);
  }
}

/// Mais que uma página (20): a 21ª e a 22ª só chegam pelo "Carregar mais".
List<Atividade> _encerradas(int quantas) => [
  for (var i = 1; i <= quantas; i++)
    atividadeDeTeste(
      id: 'a$i',
      titulo: 'Atividade $i',
      encerradaEm: DateTime.utc(2026, 10, 1).subtract(Duration(days: i)),
    ),
];

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));

  final agora = DateTime.utc(2026, 10, 20, 12);
  final eu = pessoaDoEu(euDeTeste());
  final bia = pessoaDeTeste();

  Future<void> abrirDiario(WidgetTester tester, FakeApi api) async {
    await tester.pumpWidget(appDeTeste(api: api, agora: agora));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Diário'));
    await tester.pumpAndSettle();
  }

  // O Feed continua montado na outra aba do IndexedStack: o Scrollable tem de ser o do Diário.
  Finder listaDoDiario() => find
      .descendant(
        of: find.byType(TelaDoDiario),
        matching: find.byType(Scrollable),
      )
      .first;

  // A tela de teste (800×600) mostra um cartão só, e os finders ignoram o que fica fora dela.
  void telaAlta(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  // Depois de paginar, o botão (se ainda existisse) ficaria depois do último cartão, longe da tela:
  // a lista nem o constrói. Sem rolar até lá, o "não existe" passaria mesmo com o botão sobrando.
  Future<void> conferirFimSemBotao(WidgetTester tester) async {
    await tester.scrollUntilVisible(
      find.text('Atividade 22'),
      300,
      scrollable: listaDoDiario(),
    );
    expect(find.text('Carregar mais', skipOffstage: false), findsNothing);
  }

  testWidgets('sem turma, o vazio de sempre e nenhuma pílula', (tester) async {
    await abrirDiario(tester, FakeApi(eu: euDeTeste()));
    expect(find.text('O diário começa vazio'), findsOneWidget);
    expect(find.byType(SeletorDeTurma), findsNothing);
  });

  testWidgets('com turma, a pílula e o vazio daquela turma', (tester) async {
    await abrirDiario(
      tester,
      FakeApi(eu: euDeTeste(), turmas: [turmaDeTeste()]),
    );
    expect(find.byType(SeletorDeTurma), findsOneWidget);
    expect(find.text('O diário da turma começa vazio'), findsOneWidget);
    expect(
      find.text(
        'As atividades encerradas de 🌿 Turma do Domingo vão aparecer aqui.',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'lista as encerradas com título, formato, proponente, data e fotos',
    (tester) async {
      telaAlta(tester);
      await abrirDiario(
        tester,
        FakeApi(
          eu: euDeTeste(),
          turmas: [turmaDeTeste()],
          diarioPor: {
            'turma-1': [
              atividadeDeTeste(
                id: 'a2',
                numero: 2,
                titulo: 'Campeonato Amador de Boliche',
                formato: FormatoDeAtividade.grupo,
                proponente: bia,
                descricao: 'Ninguém acertou um strike de primeira.',
                encerradaEm: DateTime.utc(2026, 10, 15, 22),
                registros: [
                  registroDeTeste(id: 'r1', autor: bia),
                  registroDeTeste(id: 'r2', autor: bia),
                ],
              ),
              atividadeDeTeste(
                id: 'a1',
                numero: 1,
                titulo: 'Desenhe um Amigo',
                proponente: eu,
                descricao: '',
                encerradaEm: DateTime.utc(2026, 9, 28, 22),
                registros: const [],
              ),
            ],
          },
        ),
      );

      expect(find.text('Campeonato Amador de Boliche'), findsOneWidget);
      expect(find.text('Em grupo'), findsOneWidget);
      expect(find.textContaining('Proposta por Bia'), findsOneWidget);
      expect(find.textContaining('15 de outubro'), findsOneWidget);
      expect(
        find.text('Ninguém acertou um strike de primeira.'),
        findsOneWidget,
      );
      // a contagem do cartão; a da capa (total da turma) é outra, e também diz '2 fotos'
      expect(
        find.descendant(
          of: find.byType(CartaoDoDiario),
          matching: find.text('2 fotos'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(CartaoDaCapa),
          matching: find.text('2 fotos'),
        ),
        findsOneWidget,
      );
      expect(find.text('Desenhe um Amigo'), findsOneWidget);
      expect(find.textContaining('Proposta por Marina'), findsOneWidget);
      expect(find.text('Sem fotos'), findsOneWidget);
      expect(find.text('Carregar mais'), findsNothing);
      expect(find.text('O diário da turma começa vazio'), findsNothing);
    },
  );

  testWidgets('tocar numa miniatura abre o visualizador sem apagar', (
    tester,
  ) async {
    telaAlta(tester); // a capa empurra o cartão para baixo da tela de teste
    await abrirDiario(
      tester,
      FakeApi(
        eu: euDeTeste(),
        turmas: [turmaDeTeste()],
        diarioPor: {
          'turma-1': [
            atividadeDeTeste(
              encerradaEm: DateTime.utc(2026, 10, 15),
              registros: [registroDeTeste(autor: eu, legenda: 'Minha')],
            ),
          ],
        },
      ),
    );
    await tester.tap(
      find
          .descendant(
            of: find.byType(CartaoDoDiario),
            matching: find.byType(Image),
          )
          .first,
    );
    await tester.pumpAndSettle();
    expect(find.byType(VisualizadorDeFotos), findsOneWidget);
    expect(find.byTooltip('Apagar'), findsNothing); // a memória congela
  });

  testWidgets('carregar mais pede a página seguinte e some no fim', (
    tester,
  ) async {
    final api = FakeApi(
      eu: euDeTeste(),
      turmas: [turmaDeTeste()],
      diarioPor: {'turma-1': _encerradas(22)},
    );
    await abrirDiario(tester, api);
    expect(find.byType(CartaoDoDiario), findsWidgets);
    final lista = listaDoDiario();

    await tester.scrollUntilVisible(
      find.text('Carregar mais'),
      300,
      scrollable: lista,
    );
    await tester.tap(find.text('Carregar mais'));
    await tester.pumpAndSettle();

    expect(api.chamadas.last, 'listarDiario:turma-1:20');
    await tester.scrollUntilVisible(
      find.text('Atividade 22'),
      300,
      scrollable: lista,
    );
    expect(find.text('Atividade 22'), findsOneWidget);
    // o botão ficaria logo abaixo, fora da área visível
    expect(find.text('Carregar mais', skipOffstage: false), findsNothing);
  });

  testWidgets('erro mostra tentar de novo e recupera', (tester) async {
    final api = FakeApi(
      eu: euDeTeste(),
      turmas: [turmaDeTeste()],
      falhaAoListarDiario: const ErroDeRede('caiu'),
    );
    await abrirDiario(tester, api);
    expect(
      find.text('Sem conexão com a API. Confira a rede e tente de novo.'),
      findsOneWidget,
    );
    api.falhaAoListarDiario = null;
    await tester.tap(find.text('Tentar de novo'));
    await tester.pumpAndSettle();
    expect(find.text('O diário da turma começa vazio'), findsOneWidget);
  });

  testWidgets(
    'enquanto a primeira página não chega, só o progresso sob a pílula',
    (tester) async {
      final api = _ApiComDiarioSegurado(
        eu: euDeTeste(),
        turmas: [turmaDeTeste()],
      );
      final segurar = api.segurarListarDiario = Completer<void>();
      await tester.pumpWidget(appDeTeste(api: api, agora: agora));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Diário'));
      // sem pumpAndSettle: a leitura está presa e o indicador gira para sempre
      for (var i = 0; i < 20; i++) {
        await tester.pump();
      }

      expect(find.byType(SeletorDeTurma), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('O diário da turma começa vazio'), findsNothing);

      segurar.complete();
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('O diário da turma começa vazio'), findsOneWidget);
    },
  );

  testWidgets(
    'carregar mais mostra o progresso e não pede de novo enquanto espera',
    (tester) async {
      final api = _ApiComDiarioSegurado(
        eu: euDeTeste(),
        turmas: [turmaDeTeste()],
        diarioPor: {'turma-1': _encerradas(22)},
      );
      await abrirDiario(tester, api);
      await tester.scrollUntilVisible(
        find.text('Carregar mais'),
        300,
        scrollable: listaDoDiario(),
      );
      final pedidosAntes = api.pedidos;
      final segurar = api.segurarListarDiario = Completer<void>();

      await tester.tap(find.text('Carregar mais'));
      await tester.pump();
      expect(find.text('Carregar mais', skipOffstage: false), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // o botão está desabilitado: tocar de novo não dispara outro pedido
      await tester.tap(find.byType(TextButton));
      await tester.pump();
      expect(api.pedidos, pedidosAntes + 1);

      segurar.complete();
      await tester.pumpAndSettle();
      expect(api.pedidos, pedidosAntes + 1);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      await conferirFimSemBotao(tester);
    },
  );

  testWidgets('falha ao carregar mais avisa, devolve o botão e mantém a lista', (
    tester,
  ) async {
    final api = FakeApi(
      eu: euDeTeste(),
      turmas: [turmaDeTeste()],
      diarioPor: {'turma-1': _encerradas(22)},
    );
    await abrirDiario(tester, api);
    await tester.scrollUntilVisible(
      find.text('Carregar mais'),
      300,
      scrollable: listaDoDiario(),
    );

    api.falhaAoListarDiario = const ErroDeRede('caiu');
    await tester.tap(find.text('Carregar mais'));
    await tester.pumpAndSettle();

    expect(
      find.text('Sem conexão com a API. Confira a rede e tente de novo.'),
      findsOneWidget,
    );
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Carregar mais'), findsOneWidget);
    // o erro de tela cheia é só da primeira página: a lista carregada fica
    expect(find.text('Algo não deu certo'), findsNothing);
    expect(find.byType(CartaoDoDiario), findsWidgets);

    // o aviso sai sozinho (4 s e a animação de saída) e a mesma tentativa passa quando a rede volta
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(
      find.text('Sem conexão com a API. Confira a rede e tente de novo.'),
      findsNothing,
    );
    api.falhaAoListarDiario = null;
    await tester.tap(find.text('Carregar mais'));
    await tester.pumpAndSettle();
    await conferirFimSemBotao(tester);
  });

  testWidgets('puxar para baixo recarrega a primeira página', (tester) async {
    final api = FakeApi(
      eu: euDeTeste(),
      turmas: [turmaDeTeste()],
      diarioPor: {
        'turma-1': [
          atividadeDeTeste(
            id: 'a1',
            titulo: 'Já estava lá',
            encerradaEm: DateTime.utc(2026, 10, 10),
          ),
        ],
      },
    );
    await abrirDiario(tester, api);
    expect(find.text('Recém-encerrada'), findsNothing);
    api.diarioPor['turma-1']!.insert(
      0,
      atividadeDeTeste(
        id: 'a2',
        titulo: 'Recém-encerrada',
        encerradaEm: DateTime.utc(2026, 10, 18),
      ),
    );

    await tester.fling(listaDoDiario(), const Offset(0, 300), 1000);
    await tester.pumpAndSettle();

    expect(find.text('Recém-encerrada'), findsOneWidget);
    final leituras = api.chamadas.where((c) => c == 'listarDiario:turma-1:');
    expect(leituras, hasLength(2));
  });

  testWidgets('recarga que falha avisa, e o carregar mais segue paginando '
      'quando a rede volta', (tester) async {
    final api = FakeApi(
      eu: euDeTeste(),
      turmas: [turmaDeTeste()],
      diarioPor: {'turma-1': _encerradas(22)},
    );
    await abrirDiario(tester, api);

    api.falhaAoListarDiario = const ErroDeRede('caiu');
    await tester.fling(listaDoDiario(), const Offset(0, 300), 1000);
    await tester.pumpAndSettle();

    expect(
      find.text('Sem conexão com a API. Confira a rede e tente de novo.'),
      findsOneWidget,
    );
    // a lista carregada fica, sem o erro de tela cheia
    expect(find.text('Atividade 1'), findsOneWidget);
    expect(find.text('Algo não deu certo'), findsNothing);

    // o aviso sai sozinho; com a rede de volta o botão pede a página seguinte à que já estava
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    api.falhaAoListarDiario = null;
    await tester.scrollUntilVisible(
      find.text('Carregar mais'),
      300,
      scrollable: listaDoDiario(),
    );
    await tester.tap(find.text('Carregar mais'));
    await tester.pumpAndSettle();

    expect(api.chamadas.last, 'listarDiario:turma-1:20');
    await conferirFimSemBotao(tester);
    expect(find.text('Atividade 22'), findsOneWidget);
  });

  testWidgets('o formato é etiqueta sálvia e a descrição é citação em itálico, '
      'só quando existe', (tester) async {
    telaAlta(tester);
    await abrirDiario(
      tester,
      FakeApi(
        eu: euDeTeste(),
        turmas: [turmaDeTeste()],
        diarioPor: {
          'turma-1': [
            atividadeDeTeste(
              id: 'a2',
              titulo: 'Com descrição',
              descricao: 'Uma frase para lembrar.',
              encerradaEm: DateTime.utc(2026, 10, 15, 22),
            ),
            atividadeDeTeste(
              id: 'a1',
              titulo: 'Sem descrição',
              descricao: '',
              encerradaEm: DateTime.utc(2026, 10, 14, 22),
            ),
          ],
        },
      ),
    );

    final etiquetas = tester.widgetList<Etiqueta>(find.byType(Etiqueta));
    expect(etiquetas, hasLength(2));
    expect(etiquetas.every((e) => e.tom == TomDaEtiqueta.salvia), isTrue);

    final citacao = tester.widget<Text>(find.text('Uma frase para lembrar.'));
    expect(citacao.style?.fontStyle, FontStyle.italic);
    // a segunda não tem descrição: nenhum outro texto em itálico, nenhuma caixa vazia
    expect(
      find.byWidgetPredicate(
        (w) => w is Text && w.style?.fontStyle == FontStyle.italic,
      ),
      findsOneWidget,
    );
  });

  testWidgets('cada foto é uma miniatura e a contagem concorda no singular e '
      'no plural', (tester) async {
    telaAlta(tester);
    await abrirDiario(
      tester,
      FakeApi(
        eu: euDeTeste(),
        turmas: [turmaDeTeste()],
        diarioPor: {
          'turma-1': [
            atividadeDeTeste(
              id: 'a3',
              titulo: 'Com três',
              descricao: '',
              encerradaEm: DateTime.utc(2026, 10, 15),
              registros: [
                for (var i = 1; i <= 3; i++)
                  registroDeTeste(id: 'r$i', autor: bia),
              ],
            ),
            atividadeDeTeste(
              id: 'a2',
              titulo: 'Com uma',
              descricao: '',
              encerradaEm: DateTime.utc(2026, 10, 14),
              registros: [registroDeTeste(id: 'r4', autor: bia)],
            ),
            atividadeDeTeste(
              id: 'a1',
              titulo: 'Com nenhuma',
              descricao: '',
              encerradaEm: DateTime.utc(2026, 10, 13),
            ),
          ],
        },
      ),
    );

    int miniaturasDe(String titulo) => find
        .descendant(
          of: find.ancestor(
            of: find.text(titulo),
            matching: find.byType(CartaoDoDiario),
          ),
          matching: find.byType(Image),
        )
        .evaluate()
        .length;

    expect(find.text('3 fotos'), findsOneWidget);
    expect(find.text('1 foto'), findsOneWidget);
    expect(find.text('Sem fotos'), findsOneWidget);
    expect(miniaturasDe('Com três'), 3);
    expect(miniaturasDe('Com uma'), 1);
    expect(miniaturasDe('Com nenhuma'), 0);
  });

  testWidgets('tocar na segunda miniatura abre o visualizador nela, com a hora '
      'do relógio do app', (tester) async {
    telaAlta(tester); // a capa empurra o cartão para baixo da tela de teste
    await abrirDiario(
      tester,
      FakeApi(
        eu: euDeTeste(),
        turmas: [turmaDeTeste()],
        diarioPor: {
          'turma-1': [
            atividadeDeTeste(
              encerradaEm: DateTime.utc(2026, 10, 15),
              registros: [
                registroDeTeste(id: 'r1', autor: bia, legenda: 'Primeira'),
                registroDeTeste(
                  id: 'r2',
                  autor: eu,
                  legenda: 'Segunda',
                  criadoEm: agora.subtract(const Duration(hours: 2)),
                ),
              ],
            ),
          ],
        },
      ),
    );

    await tester.tap(
      find
          .descendant(
            of: find.byType(CartaoDoDiario),
            matching: find.byType(Image),
          )
          .at(1),
    );
    await tester.pumpAndSettle();

    expect(find.text('2 / 2'), findsOneWidget);
    expect(find.text('Segunda · há 2 h'), findsOneWidget);
  });

  testWidgets('a linha de autoria tem o primeiro nome e a data do fuso do '
      'aparelho, não a de UTC', (tester) async {
    // 01:00 UTC ainda é o dia anterior onde o fuso é negativo (Brasil); em UTC os dois coincidem
    final encerradaEm = DateTime.utc(2026, 10, 16, 1);
    await abrirDiario(
      tester,
      FakeApi(
        eu: euDeTeste(),
        turmas: [turmaDeTeste()],
        diarioPor: {
          'turma-1': [
            atividadeDeTeste(proponente: eu, encerradaEm: encerradaEm),
          ],
        },
      ),
    );

    final esperada = DateFormat(
      "d 'de' MMMM",
      'pt_BR',
    ).format(encerradaEm.toLocal());
    expect(find.text('Proposta por Marina · $esperada'), findsOneWidget);
  });
}
