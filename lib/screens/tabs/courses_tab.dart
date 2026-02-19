import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/course_model.dart';
import '../../services/auth_service.dart';
import '../../repositories/course_repository.dart';


class CoursesTab extends StatelessWidget {
  const CoursesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final courseRepo = Provider.of<CourseRepository>(context);
    // AuthService listener is handled by Provider.of in child widgets if needed, 
    // or we can get user here if we need it for the stream query (not needed yet).

    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.black,
            expandedHeight: 100.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                "ESCUELA DE PILOTOS SEVIGDRONE",
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              centerTitle: true,
            ),
          ),
          StreamBuilder<List<CourseModel>>(
            stream: courseRepo.getCoursesStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(child: Text("No hay cursos disponibles.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white))),
                );
              }

              final courses = snapshot.data!;

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final course = courses[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: _CourseImageCard(course: course),
                    );
                  },
                  childCount: courses.length,
                ),
              );
            },
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 80)), // Espacio para el bottom nav
        ],
      ),
    );
  }
}

class _CourseImageCard extends StatelessWidget {
  final CourseModel course;

  const _CourseImageCard({required this.course});

  @override
  Widget build(BuildContext context) {
    // Usamos Consumer para reconstruir solo este widget si el usuario cambia (ej. compra curso)
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        final user = authService.user;
        final bool isUnlocked = user?.purchasedCourses.contains(course.id) ?? false;
        final bool isAdmin = user?.role == 'admin';
        final goldColor = Theme.of(context).primaryColor;

        return Card(
          elevation: 8,
          shadowColor: goldColor.withOpacity(0.3),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: isUnlocked 
                ? BorderSide(color: Colors.green.withOpacity(0.8), width: 1.5)
                : BorderSide(color: Colors.white.withOpacity(0.1), width: 0.5),
          ),
          color: const Color(0xFF1A1A1A),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Imagen + Overlay Estado
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: CachedNetworkImage(
                      imageUrl: course.image ?? course.imageUrl ?? '',
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[900],
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[900],
                        child: const Icon(Icons.school, size: 50, color: Colors.white24),
                      ),
                    ),
                  ),
                  
                  // Gradiente oscuro abajo
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.8),
                          ],
                          stops: const [0.6, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Gestor de toques para ver imagen completa - REMOVIDO POR SOLICITUD
                  /*
                  Positioned.fill(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                           Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FullScreenImageViewer(
                                imageUrl: course.image ?? course.imageUrl ?? '',
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  */

                  // Admin Toggle
                  if (isAdmin)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: goldColor, width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isUnlocked ? "ACCESO ACTIVO" : "BLOQUEADO",
                              style: TextStyle(
                                color: isUnlocked ? Colors.green : Colors.red,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Switch(
                              value: isUnlocked,
                              onChanged: (val) {
                                authService.toggleCoursePurchase(course.id, val);
                              },
                              activeColor: Colors.green,
                              inactiveTrackColor: Colors.red.withOpacity(0.3),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  // Label de Precio (si está bloqueado)
                  if (!isUnlocked)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: goldColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 4, offset: const Offset(0, 2)),
                          ],
                        ),
                        child: Text(
                          "\$${course.price ?? 'CONSULTAR'}",
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),

                  // Overlay de Candado (si está bloqueado)
                  if (!isUnlocked)
                    Positioned.fill(
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                            border: Border.all(color: goldColor, width: 2),
                          ),
                          child: Icon(Icons.lock, color: goldColor, size: 40),
                        ),
                      ),
                    ),
                ],
              ),

              // Contenido Info
              InkWell(
                onTap: () {
                   if (isUnlocked) {
                    _showCourseContent(context, course);
                  } else {
                    _contactSales(course.title);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              course.title.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isUnlocked)
                            const Tooltip(
                              message: "Curso Habilitado",
                              child: Icon(Icons.check_circle, color: Colors.green, size: 24),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        course.subtitle.isNotEmpty ? course.subtitle : (course.description.isNotEmpty ? course.description : "Sin descripción disponible."),
                        style: TextStyle(color: Colors.grey[400], fontSize: 13, height: 1.4),
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 16),
                      if (!isUnlocked)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: goldColor,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => _contactSales(course.title),
                            icon: const Icon(Icons.shopping_cart),
                            label: const Text("ADQUIRIR AHORA", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      if (isUnlocked)
                         SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.green,
                              side: const BorderSide(color: Colors.green),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => _showCourseContent(context, course),
                            icon: const Icon(Icons.play_lesson),
                            label: const Text("VER CONTENIDO", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _contactSales(String courseName) async {
    final url = Uri.parse("https://wa.me/593983123356?text=Hola SEVIGDRONE, quiero inscribirme en: $courseName");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _showCourseContent(BuildContext context, CourseModel course) {
    // Usamos el repositorio aquí también
    final courseRepo = Provider.of<CourseRepository>(context, listen: false);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, // Transparente para ver bordes redondeados
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 1.0,
        expand: false,
        builder: (_, controller) {
          return Container(
            decoration: const BoxDecoration(
              color: Color(0xFF121212),
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              children: [
                // Header del BottomSheet
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 20),
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: courseRepo.getCourseContentStream(course.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                         return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.folder_off, size: 60, color: Colors.grey[800]),
                              const SizedBox(height: 10),
                              const Text("No hay material subido aún.", style: TextStyle(color: Colors.white54)),
                            ],
                          ),
                        );
                      }
                      
                      return ListView.builder(
                        controller: controller,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: snapshot.data!.docs.length + 1, // +1 para el header info del curso
                        itemBuilder: (context, index) {
                          if (index == 0) {
                             return Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                 Text(
                                   course.title, 
                                   style: TextStyle(
                                     color: Theme.of(context).primaryColor, fontSize: 24, fontWeight: FontWeight.bold
                                   )
                                 ),
                                 const SizedBox(height: 8),
                                 Text(
                                   "Contenido del Curso", 
                                   style: TextStyle(color: Colors.grey[400], fontSize: 14)
                                 ),
                                 const Divider(color: Colors.white24, height: 40),
                               ],
                             );
                          }

                          var res = snapshot.data!.docs[index - 1].data() as Map<String, dynamic>;
                          final url = Uri.parse(res['url']);
                          final type = res['type'] ?? 'link';

                          IconData icon;
                          Color iconColor;
                          if (type == 'video') {
                            icon = Icons.play_circle_fill;
                            iconColor = Colors.redAccent;
                          } else if (type == 'pdf') {
                            icon = Icons.picture_as_pdf;
                            iconColor = Colors.orangeAccent;
                          } else if (type == 'drive') {
                            icon = Icons.add_to_drive;
                            iconColor = Colors.greenAccent;
                          } else {
                            icon = Icons.link;
                            iconColor = Colors.blueAccent;
                          }

                          return Card(
                            color: const Color(0xFF1E1E1E),
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(icon, color: iconColor),
                              ),
                              title: Text(res['title'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                              subtitle: Text(type.toUpperCase(), style: const TextStyle(color: Colors.grey, fontSize: 10)),
                              trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
                              onTap: () async {
                                 try {
                                  if (await canLaunchUrl(url)) {
                                    await launchUrl(url, mode: LaunchMode.externalApplication);
                                  } else {
                                     if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No se pudo abrir el enlace")));
                                  }
                                } catch (e) {
                                   if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                                }
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
