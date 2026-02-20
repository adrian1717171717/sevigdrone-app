import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Importamos las pestañas (Crearemos los archivos faltantes en el siguiente paso)
import 'tabs/dashboard_tab.dart';
import 'tabs/flight_conditions_tab.dart'; // <--- NUEVA
import 'tabs/courses_tab.dart';
import 'tabs/hangar_tab.dart';
import 'tabs/profile_tab.dart'; 
import 'tabs/admin_tab.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  bool _isAdmin = false;
  bool _loadingRole = true;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  void _checkUserRole() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (userDoc.exists && userDoc.get('role') == 'admin') {
          setState(() => _isAdmin = true);
        }
      } catch (e) {
        print("Error verificando rol: $e");
      }
    }
    setState(() => _loadingRole = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingRole) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37))));
    }

    // --- LISTA DE PESTAÑAS ---
    List<Widget> pages = [
      const CoursesTab(),        // 0: Cursos (Academia) -> Pantalla Inicial
      const DashboardTab(),      // 1: Noticias
      const FlightConditionsTab(), // 2: Condiciones (Clima)
      const HangarTab(),         // 3: Hangar (Flota)
      const ProfileTab(),        // 4: Perfil
    ];

    // --- LISTA DE BOTONES ---
    List<BottomNavigationBarItem> navItems = [
      const BottomNavigationBarItem(icon: Icon(Icons.school_outlined), activeIcon: Icon(Icons.school), label: "Academia"),
      const BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: "Noticias"),
      const BottomNavigationBarItem(icon: Icon(Icons.cloud_outlined), activeIcon: Icon(Icons.cloud), label: "Clima"),
      const BottomNavigationBarItem(icon: Icon(Icons.flight_takeoff), activeIcon: Icon(Icons.flight), label: "Hangar"),
      const BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: "Perfil"),
    ];

    // Si es ADMIN, añadimos la 5ta pestaña al final
    if (_isAdmin) {
      pages.add(const AdminTab());
      navItems.add(const BottomNavigationBarItem(
          icon: Icon(Icons.admin_panel_settings_outlined),
          activeIcon: Icon(Icons.admin_panel_settings),
          label: "Admin"
      ));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("SEVIGDRONE"),
        centerTitle: true,
        // Quitamos el botón de salir del AppBar porque ahora estará en Perfil
        automaticallyImplyLeading: false,
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        selectedItemColor: const Color(0xFFD4AF37), // Dorado
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed, // Importante para más de 3 items
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: navItems,
      ),
    );
  }
}