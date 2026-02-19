import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../about_screen.dart'; // Asegúrate de que este import exista

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  String _formatFlightTime(int totalMinutes) {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    return "${hours}h ${minutes}m";
  }

  // --- LÓGICA DE CAMBIO DE CONTRASEÑA ---
  void _showPasswordResetDialog(BuildContext context, String email) {
    if (email.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E), // Fondo oscuro
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            const Icon(Icons.lock_reset, color: Color(0xFFD4AF37)),
            const SizedBox(width: 10),
            const Text("Seguridad", style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Por protocolos de seguridad, enviaremos un enlace de restablecimiento a tu correo registrado:",
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[800]!),
              ),
              child: Row(
                children: [
                  const Icon(Icons.email, color: Colors.grey, size: 16),
                  const SizedBox(width: 10),
                  Expanded(child: Text(email, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                ],
              ),
            ),
            const SizedBox(height: 15),
            const Text("¿Deseas continuar?", style: TextStyle(color: Colors.white70)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              foregroundColor: Colors.black,
            ),
            onPressed: () async {
              Navigator.pop(context); // Cierra el diálogo
              _sendEmail(context, email);
            },
            child: const Text("ENVIAR CORREO"),
          ),
        ],
      ),
    );
  }

  Future<void> _sendEmail(BuildContext context, String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 10),
                Expanded(child: Text("Correo enviado. Revisa tu bandeja (y Spam).")),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final goldColor = Theme.of(context).primaryColor;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
      builder: (context, snapshot) {
        String name = "Cargando...";
        String gender = "Cadete";
        String email = user?.email ?? "";
        Map<String, dynamic> data = {};

        if (snapshot.hasData && snapshot.data!.exists) {
          data = snapshot.data!.data() as Map<String, dynamic>;
          name = data['name'] ?? "Sin Nombre";
          gender = data['gender'] ?? "Cadete";
        }

        return SingleChildScrollView( // Scroll por si la pantalla es pequeña
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // AVATAR
              CircleAvatar(
                radius: 50,
                backgroundColor: goldColor.withOpacity(0.2),
                child: Icon(
                  gender == "Femenino" ? Icons.face_3 : Icons.face,
                  size: 60,
                  color: goldColor,
                ),
              ),
              const SizedBox(height: 20),

              // INFO USUARIO
              Text(name, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              Text(email, style: TextStyle(color: Colors.grey[400], fontSize: 16)),
              const SizedBox(height: 5),
              Chip(
                label: Text(gender.toUpperCase()),
                backgroundColor: const Color(0xFF1E1E1E),
                labelStyle: TextStyle(color: goldColor, fontSize: 10, fontWeight: FontWeight.bold),
                side: BorderSide.none,
              ),

              const SizedBox(height: 20),

              // --- HORAS DE VUELO ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: goldColor.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Text("HORAS TOTALES DE VUELO", style: TextStyle(color: Colors.grey[400], fontSize: 10, letterSpacing: 2)),
                    const SizedBox(height: 5),
                    Text(
                      _formatFlightTime(data['total_flight_minutes'] ?? 0),
                      style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // --- BOTONES DE MENÚ ---

              // 1. Sobre SEVIGDRONE
              _buildOptionTile(
                  context,
                  icon: Icons.business,
                  title: "Sobre SEVIGDRONE",
                  subtitle: "Misión, Visión y Equipo",
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutScreen()));
                  }
              ),

              const SizedBox(height: 10),

              // 2. Cambiar Contraseña (AHORA FUNCIONAL)
              _buildOptionTile(
                  context,
                  icon: Icons.lock_reset,
                  title: "Cambiar Contraseña",
                  subtitle: "Enlace de recuperación seguro",
                  onTap: () => _showPasswordResetDialog(context, email)
              ),

              const SizedBox(height: 10),

              // 3. Cerrar Sesión
              _buildOptionTile(
                  context,
                  icon: Icons.logout,
                  title: "Cerrar Sesión",
                  color: Colors.redAccent,
                  onTap: () async {
                    await FirebaseAuth.instance.signOut();
                  }
              ),

              const SizedBox(height: 30),
              Text("SEVIGDRONE v1.0", style: TextStyle(color: Colors.grey[800], fontSize: 10)),
            ],
          ),
        );
      },
    );
  }

  // WIDGET AUXILIAR PARA DISEÑO DE BOTONES
  Widget _buildOptionTile(BuildContext context, {required IconData icon, required String title, String? subtitle, required VoidCallback onTap, Color? color}) {
    Color baseColor = color ?? Theme.of(context).primaryColor;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[900]!),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: baseColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: baseColor),
        ),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)) : null,
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 14),
        onTap: onTap,
      ),
    );
  }
}
