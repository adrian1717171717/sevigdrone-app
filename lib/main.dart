import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/auth_service.dart';
import 'repositories/course_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'repositories/news_repository.dart'; 
import 'screens/auth_wrapper.dart'; 
import 'app_theme.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
  
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthService()),
        Provider(create: (context) => CourseRepository()),
        Provider(create: (context) => NewsRepository()), 
      ],
      child: MaterialApp(
        title: 'Sevigdrone',
        debugShowCheckedModeBanner: false, 
        theme: AppTheme.themeData,
        home: const AuthWrapper(),
      ),
    );
  }
}
