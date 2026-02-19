import 'package:cloud_firestore/cloud_firestore.dart';

class CourseModel {
  final String id;
  final String title;
  final String subtitle; // Mantenemos por compatibilidad, pero usaremos description principalmente
  final String description;
  final dynamic price; // Puede ser String (viejo) o double (nuevo)
  final String? image; // Viejo
  final String? imageUrl; // Nuevo
  final String? instructor;

  CourseModel({
    required this.id,
    required this.title,
    this.subtitle = '',
    this.description = '',
    this.price,
    this.image,
    this.imageUrl,
    this.instructor,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'description': description,
      'price': price,
      'image': image,
      'imageUrl': imageUrl,
      'instructor': instructor,
    };
  }

  factory CourseModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>? ?? {};

    return CourseModel(
      id: doc.id,
      title: data['title'] ?? '',
      subtitle: data['subtitle'] ?? '',
      description: data['description'] ?? '',
      price: data['price'], // Dejamos que sea dinámico
      image: data['image'],
      imageUrl: data['imageUrl'] ?? data['image'], // Fallback al viejo
      instructor: data['instructor'],
    );
  }
}
