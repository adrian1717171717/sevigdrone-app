import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _readNewsKey = 'read_news_ids';

  // Obtener lista de IDs de noticias leídas
  static Future<List<String>> getReadNewsIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_readNewsKey) ?? [];
  }

  // Marcar una noticia como leída
  static Future<void> markNewsAsRead(String newsId) async {
    final prefs = await SharedPreferences.getInstance();
    final readIds = prefs.getStringList(_readNewsKey) ?? [];
    if (!readIds.contains(newsId)) {
      readIds.add(newsId);
      await prefs.setStringList(_readNewsKey, readIds);
    }
  }

  // Limpiar historial de noticias (opcional para desarrollo)
  static Future<void> clearReadNews() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_readNewsKey);
  }

  // --- MÉTODOS PARA CACHÉ DE NOTICIAS ---
  static const String _cachedNewsKey = 'cached_global_news';
  static const String _lastFetchDateKey = 'last_global_news_fetch_date';

  // Guardar noticias en caché (JSON string)
  static Future<void> setCachedNews(String newsJson) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cachedNewsKey, newsJson);
  }

  // Obtener noticias de caché
  static Future<String?> getCachedNews() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_cachedNewsKey);
  }

  // Guardar fecha de última actualización (formato yyyy-MM-dd)
  static Future<void> setLastNewsFetchDate(String dateStr) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastFetchDateKey, dateStr);
  }

  // Obtener fecha de última actualización
  static Future<String?> getLastNewsFetchDate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastFetchDateKey);
  }
}
