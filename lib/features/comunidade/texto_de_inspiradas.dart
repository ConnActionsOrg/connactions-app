/// "1 turma se inspirou" ou "N turmas se inspiraram"; nada enquanto ninguém se inspirou.
String? textoDeInspiradas(int inspiradas) => switch (inspiradas) {
  <= 0 => null,
  1 => '1 turma se inspirou',
  final n => '$n turmas se inspiraram',
};
