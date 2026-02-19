import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/course_model.dart';

class CourseRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionPath = 'courses';

  // Obtiene un Stream de la lista de cursos
  Stream<List<CourseModel>> getCoursesStream() {
    return _firestore
        .collection(_collectionPath)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => CourseModel.fromFirestore(doc)).toList();
    });
  }

  // Añade un nuevo curso
  Future<void> addCourse(CourseModel course) async {
    DocumentReference docRef;
    if (course.id.isEmpty) {
      docRef = _firestore.collection(_collectionPath).doc(); // Genera ID automático
    } else {
      docRef = _firestore.collection(_collectionPath).doc(course.id);
    }
    
    // Aseguramos que el ID esté en el documento
    final data = course.toMap();
    data['id'] = docRef.id;
    
    await docRef.set(data);
  }

  // Actualiza un curso existente
  Future<void> updateCourse(CourseModel course) async {
    await _firestore.collection(_collectionPath).doc(course.id).update(course.toMap());
  }

  // Borra un curso
  Future<void> deleteCourse(String courseId) async {
    await _firestore.collection(_collectionPath).doc(courseId).delete();
  }

  // --- Métodos para los recursos (subcolección) ---

  Stream<QuerySnapshot> getCourseContentStream(String courseId) {
      return _firestore.collection(_collectionPath).doc(courseId).collection('content').orderBy('createdAt').snapshots();
  }

  Future<void> addResource(String courseId, Map<String, dynamic> resourceData) async {
      await _firestore.collection(_collectionPath).doc(courseId).collection('content').add(resourceData);
  }

  Future<void> deleteResource(String courseId, String resourceId) async {
      await _firestore.collection(_collectionPath).doc(courseId).collection('content').doc(resourceId).delete();
  }
}
