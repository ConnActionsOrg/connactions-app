import 'package:connactions_app/api/modelos/atividade_da_comunidade.dart';
import 'package:connactions_app/app/dependencias.dart';
import 'package:connactions_app/design/widgets/avatar.dart';
import 'package:connactions_app/features/atividades/visualizador_de_fotos.dart';
import 'package:connactions_app/features/comunidade/cartao_da_comunidade.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../apoio/fake_api.dart';
import '../../apoio/montar.dart';

final agora = DateTime.utc(2026, 10, 6, 22);

/// O cartão sem turma ativa: só a leitura, sem providers além do que o visualizador não usa.
Future<void> montarCartao(
  WidgetTester tester,
  AtividadeDaComunidade atividade,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [apiProvider.overrideWithValue(FakeApi(eu: euDeTeste()))],
      child: montar(
        SingleChildScrollView(
          child: CartaoDaComunidade(
            atividade: atividade,
            agora: agora,
            turmaAtiva: null,
          ),
        ),
      ),
    ),
  );
}

Finder foto(int i, int de) => find.byWidgetPredicate(
  (w) => w is Semantics && w.properties.label == 'Ver foto $i de $de',
);

void main() {
  testWidgets('mostra a turma de origem, a conta e nenhuma pessoa', (
    tester,
  ) async {
    await montarCartao(
      tester,
      atividadeDaComunidadeDeTeste(
        regras: const ['Um jogo por pessoa', 'Sem celular'],
        inspiradas: 3,
      ),
    );

    expect(find.text('Turma Prova'), findsOneWidget);
    expect(find.text('há 2 dias'), findsOneWidget);
    expect(find.text('Em grupo'), findsOneWidget);
    expect(find.text('Noite de jogos'), findsOneWidget);
    expect(find.text('Cada um leva um jogo.'), findsOneWidget);
    expect(find.text('Um jogo por pessoa'), findsOneWidget);
    expect(find.text('Sem celular'), findsOneWidget);
    expect(find.text('3 turmas se inspiraram'), findsOneWidget);
    expect(find.byType(Avatar), findsNothing);
  });

  testWidgets('sem inspiradas, sem a linha da contagem', (tester) async {
    await montarCartao(tester, atividadeDaComunidadeDeTeste(inspiradas: 0));

    expect(find.textContaining('se inspir'), findsNothing);
  });

  testWidgets('sem turma ativa, sem as ações', (tester) async {
    await montarCartao(tester, atividadeDaComunidadeDeTeste());

    expect(find.textContaining('Salvar no backlog'), findsNothing);
    expect(find.text('Propor pro meu grupo'), findsNothing);
  });

  testWidgets('cada miniatura tem nome acessível e abre sem autor', (
    tester,
  ) async {
    await montarCartao(
      tester,
      atividadeDaComunidadeDeTeste(
        fotos: [
          fotoSemAutorDeTeste(id: 'a', legenda: 'Primeira'),
          fotoSemAutorDeTeste(id: 'b', legenda: 'Segunda'),
        ],
      ),
    );
    expect(foto(1, 2), findsOneWidget);
    expect(foto(2, 2), findsOneWidget);

    await tester.tap(foto(2, 2));
    await tester.pumpAndSettle();

    expect(find.byType(VisualizadorDeFotos), findsOneWidget);
    expect(find.text('2 / 2'), findsOneWidget);
    expect(find.text('Segunda'), findsOneWidget);
    expect(find.byType(Avatar), findsNothing);
  });
}
