import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'main_screen.dart';

class AnimatedSplashView extends StatefulWidget {
  const AnimatedSplashView({super.key});

  @override
  State<AnimatedSplashView> createState() => _AnimatedSplashViewState();
}

class _AnimatedSplashViewState extends State<AnimatedSplashView> {
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    // Inicia la animación del logo
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _isAnimating = true);
      }
    });
  }

  // Eliminamos la navegación interna, ya que AuthWrapper se encarga de esto.


  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 1200), // Desvanecimiento del logo
          opacity: _isAnimating ? 0.0 : 1.0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 1500), // Despegue del logo
            curve: Curves.easeInOutCubic,
            transform: Matrix4.translationValues(0, _isAnimating ? -size.height / 3 : 0, 0),
            child: Image.asset('assets/images/logo.png', width: size.width * 0.5),
          ),
        ),
      ),
    );
  }
}
