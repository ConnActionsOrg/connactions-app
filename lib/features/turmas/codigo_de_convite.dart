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

/// Formatador do campo: maiúsculas, só o alfabeto do código, até oito caracteres.
class FormatadorDeCodigo extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue anterior,
    TextEditingValue novo,
  ) {
    final limpo = normalizarCodigo(
      novo.text,
    ).split('').where(alfabetoDoCodigo.contains).take(tamanhoDoCodigo).join();
    return TextEditingValue(
      text: limpo,
      selection: TextSelection.collapsed(offset: limpo.length),
    );
  }
}
