import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  // Selecciona una imagen de la galería
  Future<File?> pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) {
      return File(pickedFile.path);
    } 
    return null;
  }

  // Sube la imagen y devuelve la URL de descarga
  Future<String?> uploadImage(File image, {required String path}) async {
    try {
      final ref = _storage.ref(path).child('${DateTime.now().toIso8601String()}.jpg');
      await ref.putFile(image);
      return await ref.getDownloadURL();
    } catch (e) {
      print("Error al subir la imagen: $e");
      return null;
    }
  }
}
