import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
const AboutScreen({super.key});

// FUNCIÓN CORREGIDA Y MEJORADA
Future<void> _launchURL(String urlString) async {
final Uri url = Uri.parse(urlString);
try {
// Intentamos abrir en modo "Aplicación Externa" (fuerza abrir WhatsApp/Gmail)
if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
throw 'No se pudo abrir $urlString';
}
} catch (e) {
print("Error abriendo link: $e");
}
}

@override
Widget build(BuildContext context) {
final goldColor = Theme.of(context).primaryColor;

return Scaffold(
appBar: AppBar(title: const Text("NOSOTROS")),
body: SingleChildScrollView(
padding: const EdgeInsets.all(20),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
// LOGO
Center(
child: Column(
children: [
Icon(Icons.shield, size: 80, color: goldColor),
const SizedBox(height: 10),
Text("SEVIGDRONE S.A.S", style: TextStyle(color: goldColor, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2)),
const Text('"Elevando Sueños, Conquistando Cielos"', style: TextStyle(color: Colors.white70, fontStyle: FontStyle.italic)),
],
),
),
const SizedBox(height: 30),

// INFO
_buildInfoCard(context, "MISIÓN", "Formar operadores de sistemas de aeronaves no tripuladas en modalidad básica y especialidad ISR... entregando especialistas de élite."),
_buildInfoCard(context, "VISIÓN 2030", "Consolidarse como un centro de instrucción líder y referente en América Latina en la formación técnica de tripulaciones remotas."),

const SizedBox(height: 30),
Text("NUESTRO LIDERAZGO", style: TextStyle(color: goldColor, fontSize: 18, fontWeight: FontWeight.bold)),
const Divider(color: Colors.grey),

_buildTeamMember("Ing. Anabel S. Guamán A.", "Gerente General / Instructor"),
_buildTeamMember("Sr. Segundo V. Guamán C.", "Presidente"),
_buildTeamMember("Mgtr. Segundo V. Guamán A.", "Accionista / Instructor"),
_buildTeamMember("Lic. Evelyn J. Jimbo J.", "Secretaria / Marketing"),

const SizedBox(height: 30),

// --- BOTONES DE CONTACTO ---
SizedBox(
width: double.infinity,
child: ElevatedButton.icon(
style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
icon: const Icon(Icons.phone), // Icono de WhatsApp
label: const Text("WhatsApp Oficial (+593 983123356)"),
// Usamos el formato internacional sin el '+'
onPressed: () => _launchURL("https://wa.me/593983123356"),
),
),
const SizedBox(height: 10),

Row(
mainAxisAlignment: MainAxisAlignment.center,
children: [
// EMAIL
_SocialButton(
icon: Icons.email,
color: Colors.redAccent,
onTap: () => _launchURL("mailto:sevigdrone25@gmail.com")
),
const SizedBox(width: 20),
// TIKTOK (Ejemplo genérico, cámbialo por tu link real si lo tienes)
_SocialButton(
icon: Icons.tiktok,
color: Colors.white,
onTap: () => _launchURL("https://www.tiktok.com/@sevigdrone25")
),
const SizedBox(width: 20),
// INSTAGRAM
_SocialButton(
icon: Icons.camera_alt,
color: Colors.purpleAccent,
onTap: () => _launchURL("https://www.instagram.com/sevigdrone25")
),
],
),
const SizedBox(height: 20),
const Center(child: Text("Riobamba - Ecuador", style: TextStyle(color: Colors.grey))),
],
),
),
);
}

Widget _buildInfoCard(BuildContext context, String title, String content) {
return Card(
color: const Color(0xFF1E1E1E),
margin: const EdgeInsets.only(bottom: 15),
child: Padding(
padding: const EdgeInsets.all(16.0),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(title, style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
const SizedBox(height: 5),
Text(content, style: const TextStyle(color: Colors.white)),
],
),
),
);
}

Widget _buildTeamMember(String name, String role) {
return Padding(
padding: const EdgeInsets.symmetric(vertical: 4.0),
child: Row(
children: [
const Icon(Icons.person, color: Colors.grey, size: 18),
const SizedBox(width: 10),
Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
Text(role, style: const TextStyle(color: Colors.grey, fontSize: 12)),
]))
],
),
);
}
}

// Botón Redondo Auxiliar
class _SocialButton extends StatelessWidget {
final IconData icon;
final VoidCallback onTap;
final Color color;
const _SocialButton({required this.icon, required this.onTap, required this.color});

@override
Widget build(BuildContext context) {
return InkWell(
onTap: onTap,
borderRadius: BorderRadius.circular(50),
child: Container(
padding: const EdgeInsets.all(12),
decoration: BoxDecoration(
shape: BoxShape.circle,
border: Border.all(color: Colors.grey),
color: Colors.black,
),
child: Icon(icon, color: color, size: 30),
),
);
}
}