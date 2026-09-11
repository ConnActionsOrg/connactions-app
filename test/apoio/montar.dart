import 'package:connactions_app/design/tema.dart';
import 'package:flutter/material.dart';

/// Envolve um widget no tema real, dentro de um Scaffold: é como ele vive no app.
Widget montar(Widget filho) => MaterialApp(
  theme: temaClaro(),
  home: Scaffold(body: filho),
);
