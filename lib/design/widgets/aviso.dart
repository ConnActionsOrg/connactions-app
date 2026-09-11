import 'package:flutter/material.dart';

/// Aviso curto no rodapé. O visual vem do snackBarTheme; aqui só a chamada fica curta.
void mostrarAviso(BuildContext context, String texto) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(texto)));
}
