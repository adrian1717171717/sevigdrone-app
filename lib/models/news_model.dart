import 'package:cloud_firestore/cloud_firestore.dart';

class NewsModel {
  final String id;
  final String title;
  final String body;
  final String? image;
  final String? author;
  final String? url;
  final Timestamp date;

  NewsModel({
    required this.id,
    required this.title,
    required this.body,
    this.image,
    this.author,
    this.url,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'image': image,
      'author': author,
      'url': url,
      'date': date,
    };
  }

  factory NewsModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>? ?? {};
    return NewsModel(
      id: doc.id,
      title: data['title'] ?? 'Sin Título',
      body: data['body'] ?? '',
      image: data['image'] as String?,
      author: data['author'] as String?,
      url: data['url'] as String?,
      date: data['date'] as Timestamp? ?? Timestamp.now(),
    );
  }
}
