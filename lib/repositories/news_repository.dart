import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/news_model.dart';

class NewsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionPath = 'news';

  Stream<List<NewsModel>> getNewsStream() {
    return _firestore
        .collection(_collectionPath)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => NewsModel.fromFirestore(doc)).toList();
    });
  }

  Future<void> addNews(Map<String, dynamic> data) async {
    await _firestore.collection(_collectionPath).add(data);
  }

  Future<void> updateNews(String id, Map<String, dynamic> data) async {
    await _firestore.collection(_collectionPath).doc(id).update(data);
  }

  Future<void> deleteNews(String id) async {
    await _firestore.collection(_collectionPath).doc(id).delete();
  }
}
