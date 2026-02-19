import 'package:flutter/material.dart';

// Este mapa convierte el texto de Firebase en un Icono real
final Map<String, IconData> iconMap = {
  'flight': Icons.flight_takeoff,
  'security': Icons.security,
  'exam': Icons.assignment_turned_in,
  'world': Icons.public,
  'book': Icons.menu_book,
  'video': Icons.play_circle_fill,
  'pdf': Icons.picture_as_pdf,
};

// Función auxiliar para obtener el icono
IconData getIcon(String? key) {
  return iconMap[key] ?? Icons.help_outline; // Si no encuentra, pone un signo de interrogación
}