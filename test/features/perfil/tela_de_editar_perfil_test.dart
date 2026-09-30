import 'dart:async';

import 'package:connactions_app/api/erro_da_api.dart';
import 'package:connactions_app/api/modelos/eu.dart';
import 'package:connactions_app/api/modelos/foto_para_enviar.dart';
import 'package:connactions_app/app/seletor_de_foto.dart';
import 'package:connactions_app/design/widgets/avatar.dart';
import 'package:connactions_app/features/perfil/tela_de_editar_perfil.dart';
import 'package:connactions_app/features/perfil/tela_do_perfil.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../apoio/app_de_teste.dart';
import '../../apoio/fake_api.dart';
import '../../apoio/seletor_de_foto_falso.dart';

Future<void> abrirEdicao(
  WidgetTester tester,
  FakeApi api, {
  SeletorDeFoto? seletor,
}) async {
  await tester.pumpWidget(appDeTeste(api: api, seletorDeFoto: seletor));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Perfil'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Editar perfil'));
  await tester.pumpAndSettle();
  expect(find.byType(TelaDeEditarPerfil), findsOneWidget);
}

Finder campo(String rotulo) => find.widgetWithText(TextField, rotulo);

String textoDo(WidgetTester tester, String rotulo) =>
    tester.widget<TextField>(campo(rotulo)).controller!.text;

FilledButton botaoSalvar(WidgetTester tester) =>
    tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Salvar'));

/// O Salvar fica no fim do ListView, abaixo da dobra no viewport de teste.
Future<void> tocarEmSalvar(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Salvar'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Salvar'));
}

void main() {
  testWidgets('abre com os valores atuais e Salvar desabilitado', (
    tester,
  ) async {
    await abrirEdicao(
      tester,
      FakeApi(
        eu: euDeTeste(nome: 'Marina Duarte', handle: 'marina.d', bio: 'Oi'),
      ),
    );

    expect(textoDo(tester, 'Nome'), 'Marina Duarte');
    expect(textoDo(tester, '@handle'), 'marina.d');
    expect(textoDo(tester, 'Bio'), 'Oi');
    expect(botaoSalvar(tester).onPressed, isNull);
  });

  testWidgets('salva só o que mudou, volta ao Perfil e avisa', (tester) async {
    final api = FakeApi(eu: euDeTeste());
    await abrirEdicao(tester, api);

    await tester.enterText(campo('Nome'), 'Marina D.');
    await tester.pump();
    expect(botaoSalvar(tester).onPressed, isNotNull);

    await tocarEmSalvar(tester);
    await tester.pumpAndSettle();

    expect(api.chamadas.last, 'atualizarEu:{"nome":"Marina D."}');
    expect(find.byType(TelaDeEditarPerfil), findsNothing);
    expect(find.byType(TelaDoPerfil), findsOneWidget);
    expect(find.text('Marina D.'), findsOneWidget);
    expect(find.text('Perfil atualizado'), findsOneWidget);

    // o SnackBar arma um Timer de 4s; deixá-lo pendente reprova o teste no teardown
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('handle digitado em maiúsculas vira minúsculas', (tester) async {
    final api = FakeApi(eu: euDeTeste());
    await abrirEdicao(tester, api);

    await tester.enterText(campo('@handle'), 'Marina.DD');
    await tester.pump();
    expect(textoDo(tester, '@handle'), 'marina.dd');

    await tocarEmSalvar(tester);
    await tester.pumpAndSettle();
    expect(api.chamadas.last, 'atualizarEu:{"handle":"marina.dd"}');

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('handle em uso vira erro no campo e a tela fica', (tester) async {
    final api = FakeApi(
      eu: euDeTeste(),
      falhaAoAtualizar: const ErroDaApi(
        status: 422,
        codigo: 'handle_em_uso',
        mensagem: 'Esse @handle já é de outra pessoa.',
      ),
    );
    await abrirEdicao(tester, api);

    await tester.enterText(campo('@handle'), 'outra.pessoa');
    await tester.pump();
    await tocarEmSalvar(tester);
    await tester.pumpAndSettle();

    expect(find.text('Esse @handle já é de outra pessoa.'), findsOneWidget);
    expect(find.byType(TelaDeEditarPerfil), findsOneWidget);
    expect(textoDo(tester, '@handle'), 'outra.pessoa');
  });

  testWidgets('falha de rede avisa e mantém o rascunho', (tester) async {
    final api = FakeApi(
      eu: euDeTeste(),
      falhaAoAtualizar: const ErroDeRede('caiu'),
    );
    await abrirEdicao(tester, api);

    await tester.enterText(campo('Bio'), 'Colecionando risadas');
    await tester.pump();
    await tocarEmSalvar(tester);
    await tester.pumpAndSettle();

    expect(
      find.text('Sem conexão com a API. Confira a rede e tente de novo.'),
      findsOneWidget,
    );
    expect(textoDo(tester, 'Bio'), 'Colecionando risadas');

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('Salvar exige nome e handle com três ou mais caracteres', (
    tester,
  ) async {
    await abrirEdicao(tester, FakeApi(eu: euDeTeste()));

    await tester.enterText(campo('Nome'), '   ');
    await tester.pump();
    expect(botaoSalvar(tester).onPressed, isNull);

    await tester.enterText(campo('Nome'), 'Marina Duarte');
    await tester.enterText(campo('@handle'), 'ab');
    await tester.pump();
    expect(botaoSalvar(tester).onPressed, isNull);
  });

  testWidgets('o fundo da tela é a superfície do Stitch', (tester) async {
    await abrirEdicao(tester, FakeApi(eu: euDeTeste()));
    final scaffold = find.descendant(
      of: find.byType(TelaDeEditarPerfil),
      matching: find.byType(Scaffold),
    );
    final cor =
        tester.widget<Scaffold>(scaffold).backgroundColor ??
        Theme.of(tester.element(scaffold)).scaffoldBackgroundColor;
    expect(cor, const Color(0xFFFDF9F2));
  });

  testWidgets('trocar foto passa pela folha, pelo seletor e pela API', (
    tester,
  ) async {
    final api = FakeApi(eu: euDeTeste());
    final seletor = SeletorDeFotoFalso(foto: fotoDeTeste(nome: 'eu.jpg'));
    await abrirEdicao(tester, api, seletor: seletor);

    await tester.tap(find.text('Trocar foto'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tirar foto'));
    await tester.pumpAndSettle();

    expect(seletor.origens, [OrigemDaFoto.camera]);
    expect(api.chamadas.last, 'trocarFoto:eu.jpg');
    final avatar = tester.widget<Avatar>(find.byType(Avatar).first);
    expect(avatar.fotoUrl, 'http://midia.local/midia/perfis/eu.jpg');
    expect(find.text('Foto atualizada'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('cancelar o seletor não chama a API', (tester) async {
    final api = FakeApi(eu: euDeTeste());
    final seletor = SeletorDeFotoFalso();
    await abrirEdicao(tester, api, seletor: seletor);
    await tester.tap(find.text('Trocar foto'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Escolher da galeria'));
    await tester.pumpAndSettle();
    expect(seletor.origens, [OrigemDaFoto.galeria]);
    expect(api.chamadas.where((c) => c.startsWith('trocarFoto')), isEmpty);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('foto recusada vira aviso', (tester) async {
    final api = FakeApi(eu: euDeTeste())
      ..falhaAoTrocarFoto = const ErroDaApi(
        status: 422,
        codigo: 'foto_invalida',
        mensagem: 'Envie uma foto JPEG ou PNG de até 10 MB.',
      );
    await abrirEdicao(
      tester,
      api,
      seletor: SeletorDeFotoFalso(foto: fotoDeTeste()),
    );
    await tester.tap(find.text('Trocar foto'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tirar foto'));
    await tester.pumpAndSettle();
    expect(
      find.text('Envie uma foto JPEG ou PNG de até 10 MB.'),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets(
    'seletor que lança (sem câmera, permissão negada) avisa e não chama a API',
    (tester) async {
      final api = FakeApi(eu: euDeTeste());
      await abrirEdicao(tester, api, seletor: _SeletorQueLanca());

      await tester.tap(find.text('Trocar foto'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tirar foto'));
      await tester.pumpAndSettle();

      expect(find.text('Algo deu errado. Tente de novo.'), findsOneWidget);
      expect(api.chamadas.where((c) => c.startsWith('trocarFoto')), isEmpty);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'enquanto envia, o anel cobre o avatar e o botão não abre outra folha',
    (tester) async {
      final api = _ApiQueSegura(eu: euDeTeste());
      final seletor = SeletorDeFotoFalso(foto: fotoDeTeste(nome: 'eu.jpg'));
      await abrirEdicao(tester, api, seletor: seletor);
      final anel = find.descendant(
        of: find.byType(TelaDeEditarPerfil),
        matching: find.byType(CircularProgressIndicator),
      );
      expect(anel, findsNothing);

      await tester.tap(find.text('Trocar foto'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tirar foto'));
      // sem pumpAndSettle: o anel anima para sempre
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(anel, findsOneWidget);

      await tester.tap(find.text('Trocar foto'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Tirar foto'), findsNothing);
      expect(seletor.origens, [OrigemDaFoto.camera]);

      api.liberar.complete();
      await tester.pumpAndSettle();
      expect(anel, findsNothing);
      expect(find.text('Foto atualizada'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    },
  );
}

/// Sem câmera ou com a permissão negada o plugin lança em vez de devolver null.
class _SeletorQueLanca implements SeletorDeFoto {
  @override
  Future<FotoParaEnviar?> escolher(OrigemDaFoto origem) =>
      Future.error(PlatformException(code: 'camera_access_denied'));
}

/// Prende o envio da foto até o teste liberar: prova o estado de "enviando" sem depender de tempo.
class _ApiQueSegura extends FakeApi {
  _ApiQueSegura({super.eu});

  final liberar = Completer<void>();

  @override
  Future<Eu> trocarFoto(FotoParaEnviar foto) async {
    await liberar.future;
    return super.trocarFoto(foto);
  }
}
