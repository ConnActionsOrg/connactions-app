import 'dart:async';
import 'dart:typed_data';

import 'package:connactions_app/api/erro_da_api.dart';
import 'package:connactions_app/api/modelos/atividade.dart';
import 'package:connactions_app/api/modelos/foto_para_enviar.dart';
import 'package:connactions_app/api/modelos/pessoa.dart';
import 'package:connactions_app/api/modelos/registro.dart';
import 'package:connactions_app/app/seletor_de_foto.dart';
import 'package:connactions_app/features/atividades/cartao_de_registro.dart';
import 'package:connactions_app/features/atividades/tela_de_novo_registro.dart';
import 'package:connactions_app/features/atividades/visualizador_de_fotos.dart';
import 'package:connactions_app/features/feed/tela_do_feed.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../apoio/app_de_teste.dart';
import '../../apoio/fake_api.dart';
import '../../apoio/seletor_de_foto_falso.dart';

final eu = pessoaDoEu(euDeTeste());
final bia = pessoaDeTeste();
final agora = DateTime.utc(2026, 9, 29, 12);

/// Bytes que nenhum decodificador reconhece: a prévia da tela de novo registro cai no fundo neutro
/// em vez de o motor imprimir `Unsupported marker type` a cada abertura (os de `fotoDeTeste()`
/// começam como um JPEG).
final fotoIlegivel = FotoParaEnviar(
  bytes: Uint8List.fromList(const [1, 2, 3, 4]),
  nome: 'foto.jpg',
);

FakeApi apiCom({
  Atividade? aberta,
  Pessoa? vezDe,
  bool soEu = false,
  Object? falhaAoObterAberta,
  Object? falhaAoEncerrar,
  Object? falhaAoApagarRegistro,
}) => FakeApi(
  eu: euDeTeste(),
  turmas: [turmaDeTeste(vezDe: vezDe, totalDeMembros: soEu ? 1 : 2)],
  membrosPor: {
    'turma-1': soEu
        ? [membroDeTeste(eu, 1)]
        : [membroDeTeste(eu, 1), membroDeTeste(bia, 2)],
  },
  abertaPor: {'turma-1': aberta},
  falhaAoObterAberta: falhaAoObterAberta,
  falhaAoEncerrar: falhaAoEncerrar,
  falhaAoApagarRegistro: falhaAoApagarRegistro,
);

Future<void> abrirFeed(
  WidgetTester tester,
  FakeApi api, {
  SeletorDeFotoFalso? seletor,
}) async {
  await tester.pumpWidget(
    appDeTeste(api: api, agora: agora, seletorDeFoto: seletor),
  );
  await tester.pumpAndSettle();
  expect(find.byType(TelaDoFeed), findsOneWidget);
}

/// O Feed é mais alto que o viewport de teste: rola até o alvo antes de tocar.
Future<void> rolarAte(WidgetTester tester, Finder alvo) async {
  await tester.scrollUntilVisible(
    alvo,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

List<Registro> registrosDe(Pessoa autor, int n) => [
  for (var i = 1; i <= n; i++)
    registroDeTeste(id: 'reg-$i', autor: autor, legenda: 'Foto $i'),
];

int leiturasDaAberta(FakeApi api) =>
    api.chamadas.where((c) => c.startsWith('obterAtividadeAberta')).length;

void main() {
  testWidgets(
    'faixa, etiquetas, título, descrição, regras e o botão de registro',
    (tester) async {
      await abrirFeed(
        tester,
        apiCom(
          vezDe: bia,
          aberta: atividadeDeTeste(
            proponente: bia,
            prazo: agora.add(const Duration(days: 1, hours: 4)),
            regras: const ['Um item amarelo por pessoa', 'Foto ao ar livre'],
          ),
        ),
      );

      expect(find.text('Bia propôs a rodada 1'), findsOneWidget);
      expect(find.text('há 2 h'), findsOneWidget);
      expect(find.text('Individual'), findsOneWidget);
      expect(find.text('1 dia e 4 horas'), findsOneWidget);
      expect(find.text('Pública'), findsOneWidget);
      expect(
        find.text('Piquenique Temático de Comidas Amarelas'),
        findsOneWidget,
      );
      // o ListView só infla o que cabe no viewport de teste: rola até cada bloco antes de afirmar
      await rolarAte(tester, find.text('Foto ao ar livre'));
      expect(find.textContaining('totalmente amarelo'), findsOneWidget);
      expect(find.text('Um item amarelo por pessoa'), findsOneWidget);
      await rolarAte(tester, find.text('Ninguém ainda'));
      expect(find.text('Quem já fez até agora'), findsOneWidget);
      await rolarAte(tester, find.text('Adicionar meu registro'));
      expect(
        find.text('As fotos desta atividade ficam visíveis na Comunidade.'),
        findsOneWidget,
      );
      // não sou a proponente
      expect(find.text('Encerrar atividade'), findsNothing);
      expect(find.text('É a vez de Bia propor'), findsNothing);
    },
  );

  testWidgets(
    'sem prazo é "Sem pressa"; privada não tem etiqueta nem consentimento',
    (tester) async {
      await abrirFeed(
        tester,
        apiCom(
          aberta: atividadeDeTeste(
            publica: false,
            regras: const [],
            descricao: '',
          ),
        ),
      );
      expect(find.text('Sem pressa'), findsOneWidget);
      expect(find.text('Pública'), findsNothing);
      expect(find.text('Você propôs a rodada 1'), findsOneWidget);
      await rolarAte(tester, find.text('Adicionar meu registro'));
      expect(
        find.text('As fotos desta atividade ficam visíveis na Comunidade.'),
        findsNothing,
      );
    },
  );

  testWidgets('prazo vencido', (tester) async {
    await abrirFeed(
      tester,
      apiCom(
        aberta: atividadeDeTeste(
          prazo: agora.subtract(const Duration(hours: 1)),
        ),
      ),
    );
    expect(find.text('Prazo venceu'), findsOneWidget);
  });

  testWidgets('individual: já postei → linha, etiqueta Seu e contagem', (
    tester,
  ) async {
    await abrirFeed(
      tester,
      apiCom(
        aberta: atividadeDeTeste(
          registros: [registroDeTeste(autor: eu, legenda: 'Meu bolo')],
        ),
      ),
    );
    await rolarAte(tester, find.text('Você já postou o seu registro.'));
    expect(find.text('1 postado'), findsOneWidget);
    expect(find.text('Seu'), findsOneWidget);
    expect(find.text('Meu bolo'), findsOneWidget);
    expect(find.text('Adicionar meu registro'), findsNothing);
  });

  testWidgets('grupo como proponente: contador, e em 10 o botão some', (
    tester,
  ) async {
    await abrirFeed(
      tester,
      apiCom(
        aberta: atividadeDeTeste(
          formato: FormatoDeAtividade.grupo,
          registros: registrosDe(eu, 9),
        ),
      ),
    );
    expect(find.text('Em grupo'), findsOneWidget);
    await rolarAte(tester, find.text('Adicionar foto (9/10)'));
    expect(find.text('9 postados'), findsOneWidget);

    await abrirFeed(
      tester,
      apiCom(
        aberta: atividadeDeTeste(
          formato: FormatoDeAtividade.grupo,
          registros: registrosDe(eu, 10),
        ),
      ),
    );
    await rolarAte(tester, find.text('Esta atividade já tem as 10 fotos.'));
    expect(find.textContaining('Adicionar foto'), findsNothing);
  });

  testWidgets('grupo como membro: só a linha', (tester) async {
    await abrirFeed(
      tester,
      apiCom(
        vezDe: bia,
        aberta: atividadeDeTeste(
          proponente: bia,
          formato: FormatoDeAtividade.grupo,
        ),
      ),
    );
    await rolarAte(
      tester,
      find.text('Só quem propôs posta as fotos desta atividade.'),
    );
    expect(find.textContaining('Adicionar'), findsNothing);
  });

  testWidgets('proponente encerra: diálogo, API, vez avança e aviso', (
    tester,
  ) async {
    final api = apiCom(aberta: atividadeDeTeste());
    await abrirFeed(tester, api);
    await rolarAte(tester, find.text('Encerrar atividade'));

    await tester.tap(find.text('Encerrar atividade'));
    await tester.pumpAndSettle();
    expect(find.text('Encerrar atividade?'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(api.chamadas, isNot(contains('encerrarAtividade:ativ-1')));

    await tester.tap(find.text('Encerrar atividade'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Encerrar'));
    await tester.pumpAndSettle();

    expect(api.chamadas, contains('encerrarAtividade:ativ-1'));
    expect(find.text('É a vez de Bia propor'), findsOneWidget);
    expect(find.text('Piquenique Temático de Comidas Amarelas'), findsNothing);
    expect(
      find.text('Atividade encerrada. Agora é a vez de Bia.'),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('turma de um membro só: encerrar devolve a vez a mim', (
    tester,
  ) async {
    await abrirFeed(tester, apiCom(aberta: atividadeDeTeste(), soEu: true));
    await rolarAte(tester, find.text('Encerrar atividade'));
    await tester.tap(find.text('Encerrar atividade'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Encerrar'));
    await tester.pumpAndSettle();

    expect(find.text('É a sua vez de propor!'), findsOneWidget);
    expect(find.text('Propor atividade'), findsOneWidget);
    expect(
      find.text('Atividade encerrada. Agora é a sua vez!'),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('409 ao encerrar avisa e recarrega', (tester) async {
    final api = apiCom(
      aberta: atividadeDeTeste(),
      falhaAoEncerrar: const ErroDaApi(
        status: 409,
        codigo: 'atividade_encerrada',
        mensagem: 'Esta atividade já foi encerrada.',
      ),
    );
    await abrirFeed(tester, api);
    final leituras = leiturasDaAberta(api);
    await rolarAte(tester, find.text('Encerrar atividade'));
    await tester.tap(find.text('Encerrar atividade'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Encerrar'));
    await tester.pumpAndSettle();

    expect(find.text('Esta atividade já foi encerrada.'), findsOneWidget);
    expect(leiturasDaAberta(api), greaterThan(leituras));
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('erro ao carregar a aberta mostra tentar de novo e recupera', (
    tester,
  ) async {
    final api = apiCom(
      aberta: atividadeDeTeste(),
      falhaAoObterAberta: const ErroDeRede('caiu'),
    );
    await abrirFeed(tester, api);
    expect(
      find.text('Sem conexão com a API. Confira a rede e tente de novo.'),
      findsOneWidget,
    );
    expect(find.text('Piquenique Temático de Comidas Amarelas'), findsNothing);

    api.falhaAoObterAberta = null;
    await tester.tap(find.text('Tentar de novo'));
    await tester.pumpAndSettle();
    expect(
      find.text('Piquenique Temático de Comidas Amarelas'),
      findsOneWidget,
    );
  });

  testWidgets('tocar numa miniatura abre o visualizador', (tester) async {
    await abrirFeed(
      tester,
      apiCom(
        aberta: atividadeDeTeste(registros: [registroDeTeste(autor: bia)]),
      ),
    );
    await rolarAte(tester, find.byType(CartaoDeRegistro));
    await tester.tap(find.byType(CartaoDeRegistro));
    await tester.pumpAndSettle();
    expect(find.byType(VisualizadorDeFotos), findsOneWidget);
    expect(find.text('1 / 1'), findsOneWidget);
  });

  testWidgets(
    '"Adicionar meu registro" abre a folha, o seletor e a tela de novo registro',
    (tester) async {
      final seletor = SeletorDeFotoFalso(foto: fotoIlegivel);
      await abrirFeed(
        tester,
        apiCom(aberta: atividadeDeTeste()),
        seletor: seletor,
      );
      await rolarAte(tester, find.text('Adicionar meu registro'));
      await tester.tap(find.text('Adicionar meu registro'));
      await tester.pumpAndSettle();
      expect(find.text('Tirar foto'), findsOneWidget);

      await tester.tap(find.text('Escolher da galeria'));
      await tester.pumpAndSettle();
      expect(seletor.origens, [OrigemDaFoto.galeria]);
      expect(find.byType(TelaDeNovoRegistro), findsOneWidget);
    },
  );

  testWidgets('cancelar o seletor não abre nada', (tester) async {
    await abrirFeed(
      tester,
      apiCom(aberta: atividadeDeTeste()),
      seletor: SeletorDeFotoFalso(),
    );
    await rolarAte(tester, find.text('Adicionar meu registro'));
    await tester.tap(find.text('Adicionar meu registro'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tirar foto'));
    await tester.pumpAndSettle();
    expect(find.byType(TelaDeNovoRegistro), findsNothing);
    expect(find.byType(TelaDoFeed), findsOneWidget);
  });

  testWidgets(
    'carregando a aberta: progresso no lugar do texto e sem o botão',
    (tester) async {
      final api = apiCom();
      final segurar = api.segurarObterAberta = Completer<void>();
      await tester.pumpWidget(appDeTeste(api: api, agora: agora));
      // sem pumpAndSettle: a leitura está presa e o indicador gira para sempre
      for (var i = 0; i < 20; i++) {
        await tester.pump();
      }
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('É a sua vez de propor!'), findsOneWidget);
      expect(find.text('Propor atividade'), findsNothing);

      segurar.complete();
      await tester.pumpAndSettle();
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.text('Propor atividade'), findsOneWidget);
    },
  );

  testWidgets('puxar para baixo recarrega as turmas e a atividade aberta', (
    tester,
  ) async {
    // sem atividade a lista é mais curta que a tela: é quando o puxar é a única forma de saber
    // que a pessoa da vez já lançou
    final api = apiCom(vezDe: bia);
    await abrirFeed(tester, api);
    int turmas() => api.chamadas.where((c) => c == 'listarTurmas').length;
    final turmasAntes = turmas();
    final leiturasAntes = leiturasDaAberta(api);

    api.abertaPor['turma-1'] = atividadeDeTeste(proponente: bia);
    await tester.fling(find.byType(ListView).first, const Offset(0, 300), 1000);
    await tester.pumpAndSettle();

    expect(turmas(), turmasAntes + 1);
    expect(leiturasDaAberta(api), leiturasAntes + 1);
    expect(find.text('Bia propôs a rodada 1'), findsOneWidget);
    expect(find.text('É a vez de Bia propor'), findsNothing);
  });

  group('apagar registro pelo visualizador', () {
    Future<void> abrirVisualizador(WidgetTester tester, FakeApi api) async {
      await abrirFeed(tester, api);
      await rolarAte(tester, find.byType(CartaoDeRegistro));
      await tester.tap(find.byType(CartaoDeRegistro));
      await tester.pumpAndSettle();
      expect(find.byType(VisualizadorDeFotos), findsOneWidget);
    }

    Future<void> apagarPeloVisualizador(WidgetTester tester) async {
      await tester.tap(find.byTooltip('Apagar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apagar').last);
      await tester.pumpAndSettle();
    }

    testWidgets('o meu sai da atividade e o botão de postar volta', (
      tester,
    ) async {
      final api = apiCom(
        aberta: atividadeDeTeste(registros: [registroDeTeste(autor: eu)]),
      );
      await abrirVisualizador(tester, api);

      await apagarPeloVisualizador(tester);

      expect(api.chamadas, contains('apagarRegistro:reg-1'));
      expect(find.byType(VisualizadorDeFotos), findsNothing);
      expect(find.byType(CartaoDeRegistro), findsNothing);
      await rolarAte(tester, find.text('Adicionar meu registro'));
      expect(find.text('Ninguém ainda'), findsOneWidget);
      expect(find.text('Você já postou o seu registro.'), findsNothing);
    });

    testWidgets('o de outra pessoa não tem "Apagar"', (tester) async {
      final api = apiCom(
        aberta: atividadeDeTeste(registros: [registroDeTeste(autor: bia)]),
      );
      await abrirVisualizador(tester, api);

      expect(find.byTooltip('Apagar'), findsNothing);
    });

    testWidgets('409 avisa e o Feed relê a aberta quando o visualizador fecha', (
      tester,
    ) async {
      final api = apiCom(
        aberta: atividadeDeTeste(registros: [registroDeTeste(autor: eu)]),
        falhaAoApagarRegistro: const ErroDaApi(
          status: 409,
          codigo: 'atividade_encerrada',
          mensagem: 'Esta atividade já foi encerrada.',
        ),
      );
      await abrirVisualizador(tester, api);
      final leituras = leiturasDaAberta(api);
      api.abertaPor['turma-1'] = null; // encerrada em outro aparelho

      await apagarPeloVisualizador(tester);

      expect(find.text('Esta atividade já foi encerrada.'), findsOneWidget);
      expect(find.byType(VisualizadorDeFotos), findsOneWidget);
      // com o visualizador por cima o Feed está com o ouvinte pausado: a releitura só acontece ao fechar
      await tester.tap(find.byTooltip('Fechar'));
      await tester.pumpAndSettle();

      expect(leiturasDaAberta(api), greaterThan(leituras));
      expect(
        find.text('Piquenique Temático de Comidas Amarelas'),
        findsNothing,
      );
      expect(find.text('É a sua vez de propor!'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });

    testWidgets('recusa que não é conflito avisa e não relê a aberta', (
      tester,
    ) async {
      final api = apiCom(
        aberta: atividadeDeTeste(registros: [registroDeTeste(autor: eu)]),
        falhaAoApagarRegistro: const ErroDaApi(
          status: 403,
          codigo: 'sem_acesso',
          mensagem: 'Só quem postou pode apagar.',
        ),
      );
      await abrirVisualizador(tester, api);
      final leituras = leiturasDaAberta(api);

      await apagarPeloVisualizador(tester);

      expect(find.text('Só quem postou pode apagar.'), findsOneWidget);
      await tester.tap(find.byTooltip('Fechar'));
      await tester.pumpAndSettle();
      expect(leiturasDaAberta(api), leituras);
      expect(find.byType(CartaoDeRegistro), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });
  });

  group('encerrar que falha', () {
    Future<void> encerrarPelaTela(WidgetTester tester) async {
      await rolarAte(tester, find.text('Encerrar atividade'));
      await tester.tap(find.text('Encerrar atividade'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Encerrar'));
      await tester.pumpAndSettle();
    }

    testWidgets('sem conexão avisa e a atividade continua', (tester) async {
      final api = apiCom(
        aberta: atividadeDeTeste(),
        falhaAoEncerrar: const ErroDeRede('caiu'),
      );
      await abrirFeed(tester, api);

      await encerrarPelaTela(tester);

      expect(
        find.text('Sem conexão com a API. Confira a rede e tente de novo.'),
        findsOneWidget,
      );
      expect(
        find.text('Piquenique Temático de Comidas Amarelas'),
        findsOneWidget,
      );
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });

    testWidgets('recusa que não é conflito avisa sem recarregar', (
      tester,
    ) async {
      final api = apiCom(
        aberta: atividadeDeTeste(),
        falhaAoEncerrar: const ErroDaApi(
          status: 403,
          codigo: 'sem_acesso',
          mensagem: 'Só quem propôs pode encerrar.',
        ),
      );
      await abrirFeed(tester, api);
      final leituras = leiturasDaAberta(api);

      await encerrarPelaTela(tester);

      expect(find.text('Só quem propôs pode encerrar.'), findsOneWidget);
      expect(leiturasDaAberta(api), leituras);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });
  });
}
