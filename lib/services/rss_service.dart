import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

class RssService {
  final String _feedUrl = 'https://news.google.com/rss/search?q=drones+tecnologia&hl=es-419&gl=EC&ceid=EC:es-419';

  Future<List<Map<String, String>>> getNews() async {
    try {
      final response = await http.get(Uri.parse(_feedUrl));

      if (response.statusCode == 200) {
        final document = XmlDocument.parse(response.body);
        final items = document.findAllElements('item');

        return items.map((node) {
          String title = _getText(node, 'title');
          String link = _getText(node, 'link');
          String pubDate = _getText(node, 'pubDate');
          String description = _getText(node, 'description');

          // --- LÓGICA MEJORADA PARA EXTRAER IMAGEN ---
          // Google News a veces pone la imagen dentro de la descripción como HTML
          String imageUrl = _getImageUrl(node) ?? _findImageInDescription(description) ?? '';

          // Si falla, intentamos una imagen por defecto o placeholder si se desea
          // pero por ahora dejamos vacío para que la UI maneje el placeholder.

          // Limpieza del título
          if (title.contains(' - ')) {
            title = title.split(' - ')[0].trim();
          }

          // Limpieza de la descripción (quitamos etiquetas HTML para el texto resumen)
          String cleanBody = _stripHtml(description);

          return {
            'title': title,
            'link': link,
            'pubDate': pubDate,
            'image': imageUrl,
            'body': cleanBody, // Usamos una versión limpia para el texto
            'raw_description': description // Guardamos la original por si acaso
          };
        }).toList();
      } else {
        print("Error en la respuesta del servidor: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("Error al procesar el feed RSS: $e");
      return [];
    }
  }

  // --- HELPERS PARA UNA EXTRACCIÓN MÁS ROBUSTA ---

  String _getText(XmlElement node, String tag) {
    try {
      return node.findElements(tag).single.innerText;
    } catch (e) {
      return '';
    }
  }

  String? _getImageUrl(XmlElement node) {
    // 1. Prioridad: Etiqueta <media:content>
    final mediaContent = node.findElements('media:content').firstOrNull;
    if (mediaContent != null) {
      return mediaContent.getAttribute('url');
    }

    // 2. Segunda opción: Etiqueta <enclosure>
    final enclosure = node.findElements('enclosure').firstOrNull;
    if (enclosure != null && enclosure.getAttribute('type')?.startsWith('image/') == true) {
      return enclosure.getAttribute('url');
    }

    return null; 
  }

  String? _findImageInDescription(String description) {
    // 3. Último recurso: Buscar <img> en la descripción (común en Google News)
    // Buscamos src="URL"
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
