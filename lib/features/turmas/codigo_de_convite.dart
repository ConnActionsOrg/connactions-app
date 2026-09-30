import 'package:flutter/services.dart';

/// Sem 0/O/1/I, como na API: o código é dito em voz alta e digitado no celular do amigo.
const alfabetoDoCodigo = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
const tamanhoDoCodigo = 8;

/// Maiúsculas, sem espaço nenhum: o que veio colado do WhatsApp vira o que a API espera.
String normalizarCodigo(String bruto) =>
    bruto.toUpperCase().replaceAll(RegExp(r'\s+'), '');

bool codigoCompleto(String codigo) =>
    codigo.length == tamanhoDoCodigo &&
    codigo.split('').every(alfabetoDoCodigo.contains);

/// Formatador do campo: maiúsculas, só o alfabeto do código, até oito caracteres. Colar a
/// mensagem do convite (o WhatsApp copia a mensagem inteira) passa de oito: aí vale o código
/// escrito nela, e não as primeiras letras de "Vem pra turma".
class FormatadorDeCodigo extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue anterior,
    TextEditingValue novo,
  ) {
    final limpo = normalizarCodigo(
      novo.text,
    ).split('').where(alfabetoDoCodigo.contains).join();
    final codigo = limpo.length <= tamanhoDoCodigo
        ? limpo
        : _codigoEscritoEm(novo.text) ?? limpo.substring(0, tamanhoDoCodigo);
    return TextEditingValue(
      text: codigo,
      selection: TextSelection.collapsed(offset: codigo.length),
    );
  }
}

/// A última palavra que é um código completo: o convite termina no código, e o nome da turma,
/// antes dele, pode ter uma palavra de oito letras do alfabeto.
String? _codigoEscritoEm(String texto) => RegExp(r'[A-Za-z0-9]+')
    .allMatches(texto)
    .map((m) => m[0]!.toUpperCase())
    .where(codigoCompleto)
    .lastOrNull;
