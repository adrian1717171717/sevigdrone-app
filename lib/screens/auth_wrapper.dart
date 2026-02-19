import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'animated_splash_view.dart';
import 'login_screen.dart';
import 'main_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Escuchamos los cambios en el AuthService
    final authService = Provider.of<AuthService>(context);

    // Si está cargando (verificando estado de auth inicial), mostramos el Splash
    if (authService.isLoading) {
      return const AnimatedSplashView();
    }

    // Si hay usuario autenticado, vamos a la pantalla principal
    if (authService.user != null) {
      return const MainScreen();
    }

    // Si no, mostramos el Login
    return const LoginScreen();
  }
}
