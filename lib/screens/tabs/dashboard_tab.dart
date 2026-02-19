import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/rss_service.dart';
import '../../models/news_model.dart'; // Importamos nuestro nuevo modelo


class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  final RssService _rssService = RssService();
  late Future<List<Map<String, String>>> _globalNewsFuture;
  
  // Lista de imágenes de drones para rotar
  final List<String> _droneImages = [
    "https://images.unsplash.com/photo-1506947411487-a56738267384?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80",
    "https://images.unsplash.com/photo-1527977966376-1c8408f9f108?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80",
    "https://images.unsplash.com/photo-1473968512647-3e447244af8f?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80",
    "https://images.unsplash.com/photo-1579829366248-26e6d1c828e1?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80",
    "https://images.unsplash.com/photo-1508614589041-895b8c9d7b18?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80",
    "https://images.unsplash.com/photo-1487887235947-a955ef187fcc?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80",
  ];

  @override
  void initState() {
    super.initState();
    _globalNewsFuture = _rssService.getNews();
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("No se pudo abrir $urlString")));
    }
  }

  void _showNewsDetail(BuildContext context, NewsModel news) { // Ahora recibe un objeto NewsModel
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121212),
      builder: (context) {
        return DraggableScrollableSheet(
            initialChildSize: 0.9,
            minChildSize: 0.5,
            maxChildSize: 1.0,
            expand: false,
            builder: (_, controller) {
              return Column(
                children: [
                   if (news.image != null && news.image!.isNotEmpty)
                    SizedBox(
                        height: 250,
                        width: double.infinity,
                        child: CachedNetworkImage(
                          imageUrl: news.image!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) => const Icon(Icons.image_not_supported, color: Colors.grey, size: 60),
                        ),
                      ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ListView(
                        controller: controller,
                        children: [
                          Text(news.title, style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 24, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          Text(news.body, style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.5)),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () => _launchWhatsApp(news.title),
                            icon: const Icon(Icons.chat_bubble_outline),
                            label: const Text("Consultar sobre esta promoción"),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            });
      },
    );
  }

  Future<void> _launchWhatsApp(String promoTitle) async {
    const String phone = "593983123356";
    final String message = "Hola SEVIGDRONE, estoy interesado en la promoción: *$promoTitle*";
    final Uri url = Uri.parse("https://wa.me/$phone?text=${Uri.encodeComponent(message)}");
     if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No se pudo abrir WhatsApp.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final goldColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: Text(
                  "Anuncios y Promociones", 
                  style: TextStyle(color: goldColor, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // --- CARRUSEL DE PROMOCIONES ---
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('news').orderBy('date', descending: true).limit(5).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
                if (snapshot.data!.docs.isEmpty) return const SizedBox(height: 200, child: Center(child: Text("No hay anuncios.", style: TextStyle(color: Colors.grey))));

                // Convertimos los documentos de Firestore en una lista de NewsModel
                final newsList = snapshot.data!.docs.map((doc) => NewsModel.fromFirestore(doc)).toList();

                return SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: newsList.length,
                    itemBuilder: (context, index) {
                      final newsItem = newsList[index];

                      return InkWell(
                        onTap: () => _showNewsDetail(context, newsItem), 
                        borderRadius: BorderRadius.circular(15),
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.8,
                          margin: EdgeInsets.only(right: index == newsList.length - 1 ? 0 : 16),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [BoxShadow(color: goldColor.withOpacity(0.2), blurRadius: 10)],
                              image: newsItem.image != null && newsItem.image!.isNotEmpty
                                  ? DecorationImage(image: CachedNetworkImageProvider(newsItem.image!), fit: BoxFit.cover, colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.5), BlendMode.darken))
                                  : null,
                              gradient: newsItem.image == null || newsItem.image!.isEmpty ? LinearGradient(colors: [goldColor, Colors.orange[800]!]) : null
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: goldColor, borderRadius: BorderRadius.circular(5)),
                                    child: const Text("OFICIAL SEVIGDRONE", style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold))
                                ),
                                const SizedBox(height: 8),
                                Text(newsItem.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.black, blurRadius: 4)]))
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),

            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Text(
                  "Actualidad Mundial Drone 🌎", 
                  style: TextStyle(color: goldColor, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            // --- NOTICIAS AUTOMÁTICAS (RSS) ---
            FutureBuilder<List<Map<String, String>>>(
              future: _globalNewsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
                if (!snapshot.hasData || snapshot.data!.isEmpty) return const Padding(padding: EdgeInsets.all(16), child: Text("No se pudo cargar las noticias globales.", style: TextStyle(color: Colors.grey)));

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: snapshot.data!.length > 6 ? 6 : snapshot.data!.length, 
                  itemBuilder: (context, index) {
                    var item = snapshot.data![index];
                    String imgUrl = item['image'] ?? "";

                    return Card(
                      color: const Color(0xFF1E1E1E),
                      margin: const EdgeInsets.only(bottom: 16),
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 4,
                      child: InkWell(
                        onTap: () {
                          if (item['link'] != null) _launchURL(item['link']!);
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                              SizedBox(
                                height: 180,
                                width: double.infinity,
                                child: CachedNetworkImage(
                                  imageUrl: imgUrl.isNotEmpty 
                                      ? imgUrl 
                                      : _droneImages[(index + DateTime.now().day) % _droneImages.length], 
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(color: Colors.black, child: const Center(child: CircularProgressIndicator(color: Colors.white24))),
                                  errorWidget: (context, url, error) => CachedNetworkImage(
                                    imageUrl: _droneImages[(index + DateTime.now().day) % _droneImages.length],
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      item['title'] ?? "",
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.language, size: 14, color: goldColor),
                                      const SizedBox(width: 6),
                                      const Text("Fuente: Planet Drones", style: TextStyle(color: Colors.grey, fontSize: 12)),
                                      const Spacer(),
                                      const Text("Leer más", style: TextStyle(color: Colors.grey, fontSize: 12)),
                                      const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}
