import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design/tema.dart';
import 'roteador.dart';

class AppConnactions extends ConsumerWidget {
  const AppConnactions({super.key});

  static final _tema = temaClaro();

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
    title: 'ConnActions',
    theme: _tema,
    routerConfig: ref.watch(roteadorProvider),
    locale: const Locale('pt', 'BR'),
    supportedLocales: const [Locale('pt', 'BR')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
  );
}
