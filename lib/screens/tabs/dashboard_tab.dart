import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/preferences_service.dart';
import '../../models/news_model.dart'; // Importamos nuestro nuevo modelo


class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  List<String> _readNewsIds = [];
  
  @override
  void initState() {
    super.initState();
    _loadReadNews();
  }

  Future<void> _loadReadNews() async {
    final ids = await PreferencesService.getReadNewsIds();
    setState(() {
      _readNewsIds = ids;
    });
  }

  void _markAsRead(String id) {
    if (id.isNotEmpty && !_readNewsIds.contains(id)) {
      PreferencesService.markNewsAsRead(id);
      setState(() {
        _readNewsIds.add(id);
      });
    }
  }

  void _showNewsDetail(BuildContext context, NewsModel news) {
    _markAsRead(news.id);
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
                          placeholder: (context, url) => const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37))),
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

  @override
  Widget build(BuildContext context) {
    final goldColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text("COMUNICADOS", style: TextStyle(color: goldColor, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          centerTitle: true,
        ),
      ),
      body: _buildOfficialNews(goldColor),
    );
  }

  Widget _buildOfficialNews(Color goldColor) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('news').orderBy('date', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.docs.isEmpty) return const Center(child: Text("No hay comunicados oficiales.", style: TextStyle(color: Colors.grey)));

        final newsList = snapshot.data!.docs.map((doc) => NewsModel.fromFirestore(doc)).toList();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: newsList.length,
          itemBuilder: (context, index) {
            final newsItem = newsList[index];
            final isRead = _readNewsIds.contains(newsItem.id);

            return InkWell(
              onTap: () => _showNewsDetail(context, newsItem),
              child: Card(
                color: isRead ? const Color(0xFF161616) : const Color(0xFF1E1E1E),
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15), 
                  side: BorderSide(color: isRead ? Colors.transparent : goldColor.withOpacity(0.5))
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (newsItem.image != null && newsItem.image!.isNotEmpty)
                      Stack(
                        children: [
                          SizedBox(
                            height: 180,
                            width: double.infinity,
                            child: ColorFiltered(
                              colorFilter: isRead ? const ColorFilter.mode(Colors.grey, BlendMode.saturation) : const ColorFilter.mode(Colors.transparent, BlendMode.saturation),
                              child: CachedNetworkImage(
                                imageUrl: newsItem.image!,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                                errorWidget: (context, url, error) => const Icon(Icons.image_not_supported),
                              ),
                            ),
                          ),
                          if (!isRead)
                            Positioned(
                              top: 12, right: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: goldColor, borderRadius: BorderRadius.circular(12)),
                                child: const Text("NUEVO", style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ),
                        ],
                      ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("OFICIAL SEVIGDRONE", style: TextStyle(color: isRead ? Colors.grey : goldColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                          const SizedBox(height: 8),
                          Text(newsItem.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: isRead ? Colors.white70 : Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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
    );
  }
}
