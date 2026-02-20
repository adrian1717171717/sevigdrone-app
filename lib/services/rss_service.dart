import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'package:metadata_fetch/metadata_fetch.dart';
import 'package:intl/intl.dart';
import 'preferences_service.dart';

class RssService {
  final String _feedUrl = 'https://news.google.com/rss/search?q=drones+tecnologia&hl=es-419&gl=EC&ceid=EC:es-419';

  Future<List<Map<String, String>>> getNews() async {
    try {
      // 1. Revisar caché de hoy
      final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final String? lastFetch = await PreferencesService.getLastNewsFetchDate();
      
      if (lastFetch == today) {
        // Retornar datos de caché si son de hoy
        final String? cachedJson = await PreferencesService.getCachedNews();
        if (cachedJson != null && cachedJson.isNotEmpty) {
          final List<dynamic> decoded = jsonDecode(cachedJson);
          return decoded.map((item) => Map<String, String>.from(item as Map)).toList();
        }
      }

      // 2. Si no hay caché válido, buscar desde la red
      final response = await http.get(Uri.parse(_feedUrl));

      if (response.statusCode == 200) {
        final document = XmlDocument.parse(response.body);
        final items = document.findAllElements('item').take(6); // Limitamos a 6 para no demorar extrayendo metadata

        List<Map<String, String>> fetchedNews = [];
        
        for (var node in items) {
          String title = _getText(node, 'title');
          String link = _getText(node, 'link');
          String pubDate = _getText(node, 'pubDate');
          String description = _getText(node, 'description');

          // Limpieza de título e body básico
          if (title.contains(' - ')) {
            title = title.split(' - ')[0].trim();
          }
          String cleanBody = _stripHtml(description);

          // 3. Extraer imagen
          String imageUrl = '';
          
          // Primero tratar de obtener con Open Graph (MetadataFetch)
          if (link.isNotEmpty) {
            try {
              var data = await MetadataFetch.extract(link);
              if (data != null && data.image != null && data.image!.isNotEmpty) {
                imageUrl = data.image!;
              }
            } catch (e) {
              print('Error extrayendo metadata para $link: $e');
            }
          }

          // Si falla Open Graph, intentar los fallbacks anteriores
          if (imageUrl.isEmpty) {
             imageUrl = _getImageUrl(node) ?? _findImageInDescription(description) ?? '';
          }

          fetchedNews.add({
            'title': title,
            'link': link,
            'pubDate': pubDate,
            'image': imageUrl,
            'body': cleanBody,
            'raw_description': description
          });
        }

        // 4. Guardar en caché
        await PreferencesService.setCachedNews(jsonEncode(fetchedNews));
        await PreferencesService.setLastNewsFetchDate(today);

        return fetchedNews;
      } else {
        print("Error en la respuesta del servidor: ${response.statusCode}");
        return _fallbackToCache();
      }
    } catch (e) {
      print("Error al procesar el feed RSS: $e");
      return _fallbackToCache();
    }
  }

  Future<List<Map<String, String>>> _fallbackToCache() async {
    try {
      final String? cachedJson = await PreferencesService.getCachedNews();
      if (cachedJson != null && cachedJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(cachedJson);
        return decoded.map((item) => Map<String, String>.from(item as Map)).toList();
      }
    } catch(e) {
      print("Error leyendo caché de seguridad: $e");
    }
    return [];
  }

  // --- HELPERS ---

  String _getText(XmlElement node, String tag) {
    try {
      return node.findElements(tag).single.innerText;
    } catch (e) {
      return '';
    }
  }

  String? _getImageUrl(XmlElement node) {
    final mediaContent = node.findElements('media:content').firstOrNull;
    if (mediaContent != null) {
      return mediaContent.getAttribute('url');
    }
    final enclosure = node.findElements('enclosure').firstOrNull;
    if (enclosure != null && enclosure.getAttribute('type')?.startsWith('image/') == true) {
      return enclosure.getAttribute('url');
    }
    return null; 
  }

  String? _findImageInDescription(String description) {
    final imageMatch = RegExp(r'src="([^"]+)"').firstMatch(description);
    if (imageMatch != null) {
      return imageMatch.group(1);
    }
    return null;
  }

  String _stripHtml(String htmlString) {
    return htmlString.replaceAll(RegExp(r'<[^>]*>'), '');
  }
}
