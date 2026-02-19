import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'repositories/course_repository.dart';
import 'repositories/news_repository.dart'; 
import 'screens/auth_wrapper.dart'; // Import AuthWrapper

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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
        theme: ThemeData(
          brightness: Brightness.dark,
          primaryColor: const Color(0xFFD4AF37), 
          colorScheme: const ColorScheme.dark().copyWith(
            primary: const Color(0xFFD4AF37),
            secondary: Colors.cyanAccent, 
          ),
          scaffoldBackgroundColor: const Color(0xFF121212),
          cardColor: const Color(0xFF1E1E1E),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.black,
            elevation: 0,
          ),
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}
