import 'package:connactions_app/app/preferencias.dart';

/// Preferências que vivem só durante o teste. `valores` fica exposto para semear e afirmar.
class PreferenciasEmMemoria implements Preferencias {
  PreferenciasEmMemoria([Map<String, String>? iniciais])
    : valores = {...?iniciais};

  final Map<String, String> valores;

  @override
  String? ler(String chave) => valores[chave];

  @override
  Future<void> gravar(String chave, String valor) async =>
      valores[chave] = valor;

  @override
  Future<void> apagar(String chave) async => valores.remove(chave);
}
