import 'package:connactions_app/api/erro_da_api.dart';
import 'package:connactions_app/api/modelos/atividade.dart';
import 'package:connactions_app/api/modelos/ideia.dart';
import 'package:connactions_app/features/ideias/tela_do_backlog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../apoio/app_de_teste.dart';
import '../../apoio/fake_api.dart';

final eu = pessoaDoEu(euDeTeste());
final bia = pessoaDeTeste();

FakeApi apiCom({
  List<Ideia> ideias = const [],
  Atividade? aberta,
  Object? falhaAoListarIdeias,
  Object? falhaAoObterAberta,
}) => FakeApi(
  eu: euDeTeste(),
  turmas: [turmaDeTeste(totalDeMembros: 2)],
  membrosPor: {
    'turma-1': [membroDeTeste(eu, 1), membroDeTeste(bia, 2)],
  },
  abertaPor: {'turma-1': aberta},
  ideiasPor: {'turma-1': ideias},
  falhaAoListarIdeias: falhaAoListarIdeias,
  falhaAoObterAberta: falhaAoObterAberta,
);

/// Tela alta, para medir a ordem dos cartões; o puxar para atualizar pede o viewport padrão, porque
/// só dispara depois de arrastar 25% da altura da tela.
Future<void> abrirFeed(
  WidgetTester tester,
  FakeApi api, {
  Size tamanho = const Size(800, 2400),
}) async {
  tester.view.physicalSize = tamanho;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(appDeTeste(api: api));
  await tester.pumpAndSettle();
}

Finder cartao() => find.text('Backlog de ideias');

int leituras(FakeApi api) =>
    api.chamadas.where((c) => c == 'listarIdeias:turma-1').length;

void main() {
  testWidgets('fica depois do miolo e antes dos membros', (tester) async {
    await abrirFeed(
      tester,
      apiCom(
        ideias: [
          ideiaDeTeste(id: 'i3', titulo: 'Trilha', autor: bia),
          ideiaDeTeste(id: 'i2', titulo: 'Karaokê'),
          ideiaDeTeste(id: 'i1', titulo: 'Pizza'),
        ],
      ),
    );

    expect(cartao(), findsOneWidget);
    expect(find.text('Sugira novos rolês para a turma'), findsOneWidget);
    expect(find.text('2/5'), findsOneWidget);
    final vez = tester.getTopLeft(find.text('É a sua vez de propor!')).dy;
    final backlog = tester.getTopLeft(cartao()).dy;
    final membros = tester.getTopLeft(find.text('Convidar amigos')).dy;
    expect(vez, lessThan(backlog));
    expect(backlog, lessThan(membros));
  });

  testWidgets('sem número se a leitura das ideias falhou', (tester) async {
    await abrirFeed(
      tester,
      apiCom(falhaAoListarIdeias: const ErroDeRede('caiu')),
    );

    expect(cartao(), findsOneWidget);
    expect(find.textContaining('/5'), findsNothing);
  });

  testWidgets('aparece também com a rodada em erro', (tester) async {
    await abrirFeed(
      tester,
      apiCom(falhaAoObterAberta: const ErroDeRede('caiu')),
    );

    expect(find.text('Algo não deu certo'), findsOneWidget);
    expect(cartao(), findsOneWidget);
  });

  testWidgets('aparece com a atividade aberta', (tester) async {
    await abrirFeed(tester, apiCom(aberta: atividadeDeTeste(proponente: bia)));

    expect(find.text('Bia propôs a rodada 1'), findsOneWidget);
    expect(cartao(), findsOneWidget);
  });

  testWidgets('tocar abre o backlog', (tester) async {
    await abrirFeed(tester, apiCom());

    await tester.tap(cartao());
    await tester.pumpAndSettle();

    expect(find.byType(TelaDoBacklog), findsOneWidget);
  });

  testWidgets('puxar para baixo relê as ideias junto com o resto', (
    tester,
  ) async {
    final api = apiCom();
    await abrirFeed(tester, api, tamanho: const Size(800, 600));
    expect(leituras(api), 1);

    await tester.fling(find.byType(ListView).first, const Offset(0, 300), 1000);
    await tester.pumpAndSettle();

    expect(leituras(api), 2);
  });

  testWidgets('sem turma não há cartão', (tester) async {
    await tester.pumpWidget(appDeTeste(api: FakeApi(eu: euDeTeste())));
    await tester.pumpAndSettle();

    expect(cartao(), findsNothing);
  });
}
