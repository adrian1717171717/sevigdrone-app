import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

// AuthService ahora es un ChangeNotifier
class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? _userModel;
  UserModel? get user => _userModel;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  AuthService() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? user) async {
    // Artificial delay to ensure splash screen is seen (and valid token refresh)
    await Future.delayed(const Duration(seconds: 2));

    if (user != null) {
      // Si el usuario inicia sesión, vamos a Firestore a buscar su perfil completo
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        _userModel = UserModel.fromFirestore(userDoc);
      } else {
        _userModel = null; // O manejar un caso donde el usuario de Auth no está en Firestore
      }
    } else {
      _userModel = null;
    }
    _isLoading = false;
    // Notificamos a los oyentes (la UI) que el estado del usuario ha cambiado
    notifyListeners();
  }

  Future<void> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      // Re-lanzamos el error para que la UI pueda mostrarlo
      throw e;
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required String gender,
  }) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      UserModel newUser = UserModel(
        uid: userCredential.user!.uid,
        email: email,
        name: name.toUpperCase(),
        role: 'user',
        gender: gender,
        purchasedCourses: [],
      );

      // Guardamos el nuevo usuario en Firestore
      await _firestore.collection('users').doc(newUser.uid).set({
        'uid': newUser.uid,
        'email': newUser.email,
        'name': newUser.name,
        'gender': newUser.gender,
        'role': newUser.role,
        'createdAt': FieldValue.serverTimestamp(),
        'purchased_courses': newUser.purchasedCourses,
      });

    } catch (e) {
      throw e;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Método para activar/desactivar curso (Solo para Admin/Testing)
  Future<void> toggleCoursePurchase(String courseId, bool isPurchased) async {
    if (_userModel == null) return;
    
    // Security check: Only admins can toggle courses
    if (_userModel!.role != 'admin') {
      print("Security Warning: Unauthorized attempt to toggle course by user ${_userModel!.uid}");
      return;
    }

    try {
      if (isPurchased) {
        // Agregar a comprados
        if (!_userModel!.purchasedCourses.contains(courseId)) {
          _userModel!.purchasedCourses.add(courseId);
        }
      } else {
        // Remover de comprados
        _userModel!.purchasedCourses.remove(courseId);
      }

      // Actualizar Firestore
      await _firestore.collection('users').doc(_userModel!.uid).update({
        'purchased_courses': _userModel!.purchasedCourses,
      });

      // Notificar a la UI
      notifyListeners();
    } catch (e) {
      print("Error toggling course: $e");
      throw e;
    }
  }

  Future<void> markResourceOpened(String resourceId) async {
    if (_userModel == null) return;
    if (!_userModel!.openedResources.contains(resourceId)) {
      _userModel!.openedResources.add(resourceId);
      await _firestore.collection('users').doc(_userModel!.uid).update({
        'opened_resources': _userModel!.openedResources,
      });
      notifyListeners();
    }
  }
}
