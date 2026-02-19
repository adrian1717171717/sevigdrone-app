import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String name;
  final String role;
  final String? gender;
  final List<String> purchasedCourses;
  final int totalFlightMinutes; // Nuevo campo

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.gender,
    required this.purchasedCourses,
    this.totalFlightMinutes = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role,
      'gender': gender,
      'purchased_courses': purchasedCourses,
      'total_flight_minutes': totalFlightMinutes,
    };
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>? ?? {};

    var coursesFromDb = data['purchased_courses'] as List<dynamic>?;
    List<String> courses = coursesFromDb?.map((courseId) => courseId.toString()).toList() ?? [];

    return UserModel(
      uid: data['uid'] ?? doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? 'Sin Nombre',
      role: data['role'] ?? 'user',
      gender: data['gender'] as String?,
      purchasedCourses: courses,
      totalFlightMinutes: data['total_flight_minutes'] ?? 0,
    );
  }
}
