import 'dart:async';

import 'package:connactions_app/api/erro_da_api.dart';
import 'package:connactions_app/api/modelos/atividade.dart';
import 'package:connactions_app/api/modelos/foto_para_enviar.dart';
import 'package:connactions_app/app/seletor_de_foto.dart';
import 'package:connactions_app/features/atividades/atividade_aberta.dart';
import 'package:connactions_app/features/atividades/tela_de_novo_registro.dart';
import 'package:connactions_app/features/feed/tela_do_feed.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../apoio/app_de_teste.dart';
import '../../apoio/fake_api.dart';
import '../../apoio/seletor_de_foto_falso.dart';

/// Bytes que nenhum decodificador reconhece: a prévia cai sempre no mesmo fundo neutro de 200 px,
/// e o "Postar" fica dentro dos 800x600. Os de `fotoDeTeste()` começam como um JPEG, e o motor
/// imprime `Shell: Unsupported marker type` a cada vez que a tela abre; uma imagem que decodifica
/// mudaria a altura da prévia conforme o `ImageCache` de um teste anterior.
final fotoIlegivel = FotoParaEnviar(
  bytes: Uint8List.fromList(const [1, 2, 3, 4]),
  nome: 'foto.jpg',
);

Future<void> abrir(WidgetTester tester, FakeApi api) async {
  await tester.pumpWidget(appDeTeste(api: api));
  await tester.pumpAndSettle();
  // um contexto de dentro do roteador: o de AppConnactions fica acima do Navigator
  final contexto = tester.element(find.byType(TelaDoFeed));
  Navigator.of(contexto, rootNavigator: true).push<void>(
    MaterialPageRoute(
      builder: (_) =>
          TelaDeNovoRegistro(turmaId: 'turma-1', foto: fotoIlegivel),
    ),
  );
  await tester.pumpAndSettle();
  expect(find.byType(TelaDeNovoRegistro), findsOneWidget);
}

FakeApi apiComAberta({
  FormatoDeAtividade formato = FormatoDeAtividade.individual,
}) => FakeApi(
  eu: euDeTeste(),
  turmas: [turmaDeTeste()],
  abertaPor: {'turma-1': atividadeDeTeste(formato: formato)},
);

void main() {
  testWidgets('mostra a prévia, posta com a legenda e volta com aviso', (
    tester,
  ) async {
    final api = apiComAberta();
    await abrir(tester, api);
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('Novo registro'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'Legenda (opcional)'),
      'Bolo de milho',
    );
    await tester.tap(find.text('Postar'));
    await tester.pumpAndSettle();

    expect(api.chamadas.last, 'registrar:ativ-1:Bolo de milho');
    expect(api.abertaPor['turma-1']!.registros.single.legenda, 'Bolo de milho');
    expect(find.byType(TelaDeNovoRegistro), findsNothing);
    expect(find.text('Registro postado!'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('409 avisa, recarrega e volta', (tester) async {
    final api = apiComAberta()
      ..falhaAoRegistrar = const ErroDaApi(
        status: 409,
        codigo: 'ja_registrou',
        mensagem: 'Você já postou o seu registro. Apague-o para postar outro.',
      );
    await abrir(tester, api);
    final leituras = api.chamadas
        .where((c) => c.startsWith('obterAtividadeAberta'))
        .length;

    await tester.tap(find.text('Postar'));
    await tester.pumpAndSettle();

    expect(find.byType(TelaDeNovoRegistro), findsNothing);
    expect(
      find.text('Você já postou o seu registro. Apague-o para postar outro.'),
      findsOneWidget,
    );
    expect(
      api.chamadas.where((c) => c.startsWith('obterAtividadeAberta')).length,
      greaterThan(leituras),
    );
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets(
    '422 (legenda com emoji além do teto em runes) avisa e a tela fica',
    (tester) async {
      final api = apiComAberta()
        ..falhaAoRegistrar = const ErroDaApi(
          status: 422,
          codigo: 'dados_invalidos',
          mensagem: 'A legenda pode ter até 200 caracteres.',
        );
      await abrir(tester, api);

      await tester.tap(find.text('Postar'));
      await tester.pumpAndSettle();

      expect(find.byType(TelaDeNovoRegistro), findsOneWidget);
      expect(
        find.text('A legenda pode ter até 200 caracteres.'),
        findsOneWidget,
      );
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    },
  );

  testWidgets('sem conexão avisa e a tela fica com o botão de volta', (
    tester,
  ) async {
    final api = apiComAberta()..falhaAoRegistrar = const ErroDeRede('sem rede');
    await abrir(tester, api);

    await tester.tap(find.text('Postar'));
    await tester.pumpAndSettle();

    expect(find.byType(TelaDeNovoRegistro), findsOneWidget);
    expect(
      find.text('Sem conexão com a API. Confira a rede e tente de novo.'),
      findsOneWidget,
    );
    expect(find.text('Postar'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets(
    'enquanto posta, o botão mostra o progresso e não dispara de novo',
    (tester) async {
      final api = apiComAberta();
      await abrir(tester, api);
      // a leitura da aberta pendura, e com ela o registrar, que a espera antes de chamar a API
      // (só depois de abrir: o Feed por baixo também a lê e não assentaria)
      final segurar = api.segurarObterAberta = Completer<void>();
      ProviderScope.containerOf(
        tester.element(find.byType(TelaDeNovoRegistro)),
      ).invalidate(atividadeAbertaProvider('turma-1'));
      await tester.pump();

      await tester.tap(find.text('Postar'));
      await tester.pump();

      final tela = find.byType(TelaDeNovoRegistro);
      expect(
        find.descendant(
          of: tela,
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
      expect(find.text('Postar'), findsNothing);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      await tester.tap(find.byType(FilledButton), warnIfMissed: false);

      segurar.complete();
      await tester.pumpAndSettle();

      expect(
        api.chamadas.where((c) => c.startsWith('registrar:')),
        hasLength(1),
      );
      expect(tela, findsNothing);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    },
  );

  testWidgets('posta a legenda sem os espaços das pontas', (tester) async {
    final api = apiComAberta();
    await abrir(tester, api);

    await tester.enterText(
      find.widgetWithText(TextField, 'Legenda (opcional)'),
      '  Bolo de milho  ',
    );
    await tester.tap(find.text('Postar'));
    await tester.pumpAndSettle();

    expect(api.chamadas.last, 'registrar:ativ-1:Bolo de milho');
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('a legenda para em 200 caracteres', (tester) async {
    await abrir(tester, apiComAberta());
    final campo = find.widgetWithText(TextField, 'Legenda (opcional)');

    await tester.enterText(campo, 'a' * 201);

    expect(tester.widget<TextField>(campo).controller!.text, hasLength(200));
  });

  testWidgets('foto que não decodifica vira o fundo neutro, sem exceção', (
    tester,
  ) async {
    await abrir(tester, apiComAberta());

    expect(find.byIcon(Symbols.image), findsOneWidget);
  });

  group('abrirNovoRegistro', () {
    /// Um botão chama `abrirNovoRegistro` com o contexto e o ref dele, como o Feed fará, e é tocado.
    Future<void> tocarEmNovaFoto(
      WidgetTester tester,
      SeletorDeFoto seletor,
    ) async {
      await tester.pumpWidget(
        appDeTeste(api: apiComAberta(), seletorDeFoto: seletor),
      );
      await tester.pumpAndSettle();
      final contexto = tester.element(find.byType(TelaDoFeed));
      Navigator.of(contexto, rootNavigator: true).push<void>(
        MaterialPageRoute(
          builder: (_) => Consumer(
            builder: (context, ref, _) => Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () =>
                      abrirNovoRegistro(context, ref, turmaId: 'turma-1'),
                  child: const Text('Nova foto'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nova foto'));
      await tester.pumpAndSettle();
      expect(find.text('Tirar foto'), findsOneWidget);
    }

    testWidgets(
      'fechar a folha sem escolher não chama o seletor nem abre a tela',
      (tester) async {
        final seletor = SeletorDeFotoFalso(foto: fotoIlegivel);
        await tocarEmNovaFoto(tester, seletor);

        await tester.tapAt(const Offset(10, 10)); // fora da folha
        await tester.pumpAndSettle();

        expect(seletor.origens, isEmpty);
        expect(find.byType(TelaDeNovoRegistro), findsNothing);
      },
    );

    testWidgets('cancelar no seletor do aparelho não abre a tela nem avisa', (
      tester,
    ) async {
      final seletor = SeletorDeFotoFalso();
      await tocarEmNovaFoto(tester, seletor);

      await tester.tap(find.text('Tirar foto'));
      await tester.pumpAndSettle();

      expect(seletor.origens, [OrigemDaFoto.camera]);
      expect(find.byType(TelaDeNovoRegistro), findsNothing);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('foto escolhida abre a tela com a turma e a foto', (
      tester,
    ) async {
      final seletor = SeletorDeFotoFalso(foto: fotoIlegivel);
      await tocarEmNovaFoto(tester, seletor);

      await tester.tap(find.text('Escolher da galeria'));
      await tester.pumpAndSettle();

      expect(seletor.origens, [OrigemDaFoto.galeria]);
      final tela = tester.widget<TelaDeNovoRegistro>(
        find.byType(TelaDeNovoRegistro),
      );
      expect(tela.turmaId, 'turma-1');
      expect(tela.foto, same(fotoIlegivel));
      final previa =
          tester.widget<Image>(find.byType(Image)).image as MemoryImage;
      expect(previa.bytes, same(fotoIlegivel.bytes));
    });

    testWidgets(
      'seletor que lança (sem câmera, permissão negada) avisa e não abre a tela',
      (tester) async {
        await tocarEmNovaFoto(tester, _SeletorQueLanca());

        await tester.tap(find.text('Tirar foto'));
        await tester.pumpAndSettle();

        expect(find.byType(TelaDeNovoRegistro), findsNothing);
        expect(find.text('Algo deu errado. Tente de novo.'), findsOneWidget);
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();
      },
    );
  });
}

/// Sem câmera ou com a permissão negada o plugin lança em vez de devolver null.
class _SeletorQueLanca implements SeletorDeFoto {
  @override
  Future<FotoParaEnviar?> escolher(OrigemDaFoto origem) =>
      Future.error(PlatformException(code: 'camera_access_denied'));
}
