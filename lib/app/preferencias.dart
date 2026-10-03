import 'package:shared_preferences/shared_preferences.dart';

/// Chaves que o app guarda no aparelho. A lista fecha o allowList do shared_preferences.
abstract final class ChaveDePreferencia {
  static const turmaAtivaId = 'turma_ativa_id';

  /// `'true'` depois que o app perguntou pela permissão, ou a achou já concedida: daí em diante
  /// quem cobra é o Perfil, e não o Feed.
  static const notificacoesPerguntadas = 'notificacoes_perguntadas';
  static const todas = <String>{turmaAtivaId, notificacoesPerguntadas};
}

/// O que o app guarda no aparelho entre aberturas. Leitura síncrona: a implementação real
/// carrega tudo antes do runApp.
abstract class Preferencias {
  String? ler(String chave);
  Future<void> gravar(String chave, String valor);
  Future<void> apagar(String chave);
}

class PreferenciasDoAparelho implements Preferencias {
  PreferenciasDoAparelho._(this._cache);

  final SharedPreferencesWithCache _cache;

  static Future<PreferenciasDoAparelho> abrir() async =>
      PreferenciasDoAparelho._(
        await SharedPreferencesWithCache.create(
          cacheOptions: const SharedPreferencesWithCacheOptions(
            allowList: ChaveDePreferencia.todas,
          ),
        ),
      );

  @override
  String? ler(String chave) => _cache.getString(chave);

  @override
  Future<void> gravar(String chave, String valor) =>
      _cache.setString(chave, valor);

  @override
  Future<void> apagar(String chave) => _cache.remove(chave);
}
