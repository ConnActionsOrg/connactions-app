import 'package:connactions_app/api/erro_da_api.dart';
import 'package:connactions_app/api/modelos/atividade.dart';
import 'package:connactions_app/api/modelos/ideia.dart';
import 'package:connactions_app/api/modelos/pessoa.dart';
import 'package:connactions_app/features/atividades/tela_de_propor.dart';
import 'package:connactions_app/features/ideias/tela_de_nova_ideia.dart';
import 'package:connactions_app/features/ideias/tela_do_backlog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../apoio/app_de_teste.dart';
import '../../apoio/fake_api.dart';
import '../../apoio/navegar.dart';

final eu = pessoaDoEu(euDeTeste());
final bia = pessoaDeTeste();

FakeApi apiCom({
  List<Ideia> ideias = const [],
  Pessoa? vezDe,
  Atividade? aberta,
}) => FakeApi(
  eu: euDeTeste(),
  turmas: [turmaDeTeste(vezDe: vezDe, totalDeMembros: 2)],
  membrosPor: {
    'turma-1': [membroDeTeste(eu, 1), membroDeTeste(bia, 2)],
  },
  abertaPor: {'turma-1': aberta},
  ideiasPor: {'turma-1': ideias},
);

/// Numa tela alta: o viewport de teste (800×600) só constrói e só alcança o que cabe nele. O puxar
/// para atualizar pede o contrário: só dispara depois de arrastar 25% da altura da tela.
Future<void> abrirBacklog(
  WidgetTester tester,
  FakeApi api, {
  Size tamanho = const Size(800, 2400),
}) async {
  tester.view.physicalSize = tamanho;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(appDeTeste(api: api));
  await tester.pumpAndSettle();
  await irPara(tester, '/turmas/turma-1/ideias');
  expect(find.byType(TelaDoBacklog), findsOneWidget);
}

/// `FilledButton.icon` é uma subclasse privada: `byType` não a acha, então sobe do texto.
FilledButton botao(WidgetTester tester, String texto) =>
    tester.widget<FilledButton>(
      find
          .ancestor(
            of: find.text(texto),
            matching: find.byWidgetPredicate((w) => w is FilledButton),
          )
          .first,
    );

int leituras(FakeApi api) =>
    api.chamadas.where((c) => c == 'listarIdeias:turma-1').length;

List<Ideia> minhas(int n) => [
  for (var i = 1; i <= n; i++) ideiaDeTeste(id: 'i$i', titulo: 'Ideia $i'),
];

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));

  testWidgets('mostra o contador só com as minhas e as ideias da turma', (
    tester,
  ) async {
    await abrirBacklog(
      tester,
      apiCom(
        ideias: [
          ideiaDeTeste(
            id: 'i2',
            titulo: 'Trilha',
            autor: bia,
            origemAtividadeId: 'com-1',
            formato: FormatoDeAtividade.grupo,
          ),
          ideiaDeTeste(id: 'i1', titulo: 'Pizza'),
        ],
      ),
    );

    expect(find.text('Suas ideias: 1 de 5'), findsOneWidget);
    expect(
      find.text('Ideias que a turma guardou para não esquecer.'),
      findsOneWidget,
    );
    expect(find.text('Sua ideia'), findsOneWidget);
    expect(find.text('Sugerido por Bia'), findsOneWidget);
    expect(find.text('Da Comunidade'), findsOneWidget);
    expect(find.text('Em grupo'), findsOneWidget);
    expect(botao(tester, 'Nova ideia').onPressed, isNotNull);
  });

  testWidgets('"Apagar" só nas minhas, e pede confirmação', (tester) async {
    final api = apiCom(
      ideias: [
        ideiaDeTeste(id: 'i2', titulo: 'Trilha', autor: bia),
        ideiaDeTeste(id: 'i1', titulo: 'Pizza'),
      ],
    );
    await abrirBacklog(tester, api);
    expect(find.text('Apagar'), findsOneWidget);

    await tester.tap(find.text('Apagar'));
    await tester.pumpAndSettle();
    expect(find.text('Apagar esta ideia?'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(api.chamadas.any((c) => c.startsWith('apagarIdeia')), isFalse);
    expect(find.text('Pizza'), findsOneWidget);

    await tester.tap(find.text('Apagar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apagar').last);
    await tester.pumpAndSettle();

    expect(api.chamadas, contains('apagarIdeia:i1'));
    expect(find.text('Pizza'), findsNothing);
    expect(find.text('Trilha'), findsOneWidget);
    expect(find.text('Suas ideias: 0 de 5'), findsOneWidget);
  });

  testWidgets('apagar que volta 409 avisa com a mensagem da API e relê', (
    tester,
  ) async {
    final api = apiCom(
      ideias: [ideiaDeTeste(id: 'i1', titulo: 'Pizza')],
    );
    api.falhaAoApagarIdeia = const ErroDaApi(
      status: 409,
      codigo: 'ideia_indisponivel',
      mensagem: 'Essa ideia já foi usada ou apagada.',
    );
    await abrirBacklog(tester, api);
    expect(leituras(api), 1);

    await tester.tap(find.text('Apagar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apagar').last);
    await tester.pumpAndSettle();

    expect(find.text('Essa ideia já foi usada ou apagada.'), findsOneWidget);
    expect(leituras(api), 2);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('"Propor esta" só na minha vez e sem atividade aberta', (
    tester,
  ) async {
    final ideias = [
      ideiaDeTeste(id: 'i2', titulo: 'Trilha', autor: bia),
      ideiaDeTeste(id: 'i1', titulo: 'Pizza'),
    ];

    await abrirBacklog(tester, apiCom(ideias: ideias));
    // quem está na vez lança qualquer ideia da turma, a sua ou a dos outros
    expect(find.text('Propor esta'), findsNWidgets(2));
  });

  testWidgets('"Propor esta" some fora da vez', (tester) async {
    await abrirBacklog(
      tester,
      apiCom(
        ideias: [ideiaDeTeste(titulo: 'Pizza')],
        vezDe: bia,
      ),
    );
    expect(find.text('Pizza'), findsOneWidget);
    expect(find.text('Propor esta'), findsNothing);
  });

  testWidgets('"Propor esta" some com atividade aberta', (tester) async {
    await abrirBacklog(
      tester,
      apiCom(
        ideias: [ideiaDeTeste(titulo: 'Pizza')],
        aberta: atividadeDeTeste(),
      ),
    );
    expect(find.text('Pizza'), findsOneWidget);
    expect(find.text('Propor esta'), findsNothing);
  });

  testWidgets('"Propor esta" abre o Propor da turma', (tester) async {
    await abrirBacklog(tester, apiCom(ideias: [ideiaDeTeste()]));

    await tester.tap(find.text('Propor esta'));
    await tester.pumpAndSettle();

    expect(find.byType(TelaDePropor), findsOneWidget);
  });

  testWidgets('com 5/5, "Nova ideia" fica desligado e o texto muda', (
    tester,
  ) async {
    await abrirBacklog(tester, apiCom(ideias: minhas(5)));

    expect(find.text('Suas ideias: 5 de 5'), findsOneWidget);
    expect(find.text('Use ou apague uma para guardar outra.'), findsOneWidget);
    expect(botao(tester, 'Nova ideia').onPressed, isNull);
  });

  testWidgets('vazio: o convite para anotar a primeira ideia', (tester) async {
    await abrirBacklog(tester, apiCom());

    expect(find.text('Nenhuma ideia guardada'), findsOneWidget);
    expect(
      find.text('Anote aqui o que a turma quer fazer um dia.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Nova ideia'));
    await tester.pumpAndSettle();
    expect(find.byType(TelaDeNovaIdeia), findsOneWidget);
  });

  testWidgets('erro na primeira carga: tentar de novo traz a lista', (
    tester,
  ) async {
    final api = apiCom(
      ideias: [ideiaDeTeste(id: 'i1', titulo: 'Pizza')],
    );
    api.falhaAoListarIdeias = const ErroDeRede('caiu');
    await abrirBacklog(tester, api);
    expect(find.text('Algo não deu certo'), findsOneWidget);
    expect(
      find.text('Sem conexão com a API. Confira a rede e tente de novo.'),
      findsOneWidget,
    );

    api.falhaAoListarIdeias = null;
    await tester.tap(find.text('Tentar de novo'));
    await tester.pumpAndSettle();

    expect(find.text('Pizza'), findsOneWidget);
  });

  testWidgets('puxar para baixo relê as ideias', (tester) async {
    final api = apiCom(
      ideias: [ideiaDeTeste(id: 'i1', titulo: 'Pizza')],
    );
    await abrirBacklog(tester, api, tamanho: const Size(800, 600));
    expect(leituras(api), 1);

    await tester.fling(find.byType(ListView).first, const Offset(0, 300), 1000);
    await tester.pumpAndSettle();

    expect(leituras(api), 2);
  });

  testWidgets('o fundo da tela é a superfície do Stitch', (tester) async {
    await abrirBacklog(tester, apiCom());
    final scaffold = find.descendant(
      of: find.byType(TelaDoBacklog),
      matching: find.byType(Scaffold),
    );
    final cor =
        tester.widget<Scaffold>(scaffold).backgroundColor ??
        Theme.of(tester.element(scaffold)).scaffoldBackgroundColor;
    expect(cor, const Color(0xFFFDF9F2));
  });
}
