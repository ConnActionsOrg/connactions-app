/// Ajustes de build. A URL da API vem de `--dart-define=API_URL`; o padrão é o host da máquina
/// visto de dentro do emulador Android.
abstract final class Config {
  static const apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://10.0.2.2:8090/v1',
  );
}
