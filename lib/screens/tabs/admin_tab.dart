import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../models/course_model.dart';
import '../../models/news_model.dart';
import '../../repositories/course_repository.dart';
import '../../repositories/news_repository.dart'; // Importamos el repositorio
import '../admin/edit_course_screen.dart';
import '../admin/edit_news_screen.dart';
import '../admin/course_content_management_screen.dart';

class AdminTab extends StatefulWidget {
  const AdminTab({super.key});

  @override
  State<AdminTab> createState() => _AdminTabState();
}

class _AdminTabState extends State<AdminTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.black,
          child: TabBar(
            controller: _tabController,
            indicatorColor: Colors.redAccent,
            labelColor: Colors.redAccent,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(icon: Icon(Icons.people), text: "USUARIOS"),
              Tab(icon: Icon(Icons.school), text: "CURSOS"),
              Tab(icon: Icon(Icons.campaign), text: "NOTICIAS"),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              UserManagementView(),
              CourseManagementView(),
              NewsManagementView(),
            ],
          ),
        ),
      ],
    );
  }
}

// ==========================================================
// VISTA 1: GESTIÓN DE USUARIOS
// ==========================================================
class UserManagementView extends StatefulWidget {
  const UserManagementView({super.key});

  @override
  State<UserManagementView> createState() => _UserManagementViewState();
}

class _UserManagementViewState extends State<UserManagementView> {
  String _searchQuery = "";

  // Crear usuario con App secundaria para no desloguear al admin
  Future<void> _createUser(String email, String password, String name, String role) async {
    FirebaseApp? secondaryApp;
    try {
      secondaryApp = await Firebase.initializeApp(
        name: 'SecondaryApp',
        options: Firebase.app().options,
      );

      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      final userCredential = await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Crear documento en Firestore
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'name': name,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
        'purchased_courses': [],
        'total_flight_minutes': 0,
        'flight_hours': 0, // Legacy field
      });
      
      await secondaryAuth.signOut(); // Cerrar sesión en la app secundaria

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Usuario creado exitosamente"), backgroundColor: Colors.green));
      }

    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${e.message}"), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
      }
    } finally {
      // Importante: Eliminar la app secundaria para liberar recursos
      await secondaryApp?.delete();
    }
  }

  void _showCreateUserDialog() {
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    String role = 'user';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF2C2C2C),
            title: const Text("Crear Nuevo Usuario", style: TextStyle(color: Colors.white)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   TextField(controller: nameCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Nombre Completo", labelStyle: TextStyle(color: Colors.grey))),
                   TextField(controller: emailCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Email", labelStyle: TextStyle(color: Colors.grey))),
                   TextField(controller: passCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Contraseña", labelStyle: TextStyle(color: Colors.grey))),
                   const SizedBox(height: 10),
                   DropdownButton<String>(
                     value: role,
                     dropdownColor: const Color(0xFF3C3C3C),
                     style: const TextStyle(color: Colors.white),
                     items: const [
                       DropdownMenuItem(value: "user", child: Text("Usuario (Piloto)")),
                       DropdownMenuItem(value: "admin", child: Text("Administrador")),
                     ],
                     onChanged: (val) => setState(() => role = val!),
                   ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
              ElevatedButton(
                onPressed: () {
                  if (emailCtrl.text.isNotEmpty && passCtrl.text.isNotEmpty && nameCtrl.text.isNotEmpty) {
                    _createUser(emailCtrl.text.trim(), passCtrl.text.trim(), nameCtrl.text.trim(), role);
                    Navigator.pop(context);
                  }
                },
                child: const Text("CREAR"),
              )
            ],
          );
        }
      ),
    );
  }

  void _confirmDeleteUser(String userId, String userName) {
    showDialog(context: context, builder: (c) => AlertDialog(
      backgroundColor: Colors.red[900],
      title: Text("Eliminar a $userName?", style: const TextStyle(color: Colors.white)),
      content: const Text("ATENCIÓN: Esto solo eliminará los datos del usuario de la base de datos (perfil, drones, historial). NO elimina la cuenta de autenticación (login). El usuario perderá acceso a sus datos.", style: TextStyle(color: Colors.white70)),
      actions: [
        TextButton(onPressed: ()=>Navigator.pop(c), child: const Text("Cancelar", style: TextStyle(color: Colors.white))),
        TextButton(onPressed: (){
            FirebaseFirestore.instance.collection('users').doc(userId).delete();
            Navigator.pop(c);
        }, child: const Text("ELIMINAR DATOS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
      ]
    ));
  }

  void _showEditRoleDialog(DocumentReference userRef, String currentRole, String currentName) {
     String newRole = currentRole;
     showDialog(context: context, builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: Text("Editar Rol de $currentName", style: const TextStyle(color: Colors.white)),
        content: StatefulBuilder(
           builder: (context, setState) => DropdownButton<String>(
               value: newRole,
               dropdownColor: const Color(0xFF3C3C3C),
               style: const TextStyle(color: Colors.white),
               isExpanded: true,
               items: const [
                 DropdownMenuItem(value: "user", child: Text("Usuario (Piloto)")),
                 DropdownMenuItem(value: "admin", child: Text("Administrador")),
               ],
               onChanged: (val) => setState(() => newRole = val!),
           ),
        ),
        actions: [
           TextButton(onPressed: ()=>Navigator.pop(c), child: const Text("Cancelar")),
           ElevatedButton(onPressed: (){
              userRef.update({'role': newRole});
              Navigator.pop(c);
           }, child: const Text("Guardar"))
        ],
     ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blueAccent,
        icon: const Icon(Icons.person_add),
        label: const Text("CREAR USUARIO"),
        onPressed: _showCreateUserDialog,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Buscar piloto por email...",
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').orderBy('createdAt', descending: true).snapshots(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) return const Center(child: CircularProgressIndicator());
  
                var users = userSnapshot.data!.docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  String email = (data['email'] ?? "").toString().toLowerCase();
                  String name = (data['name'] ?? "").toString().toLowerCase();
                  return email.contains(_searchQuery) || name.contains(_searchQuery);
                }).toList();
  
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80), // Space for FAB
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    var userDoc = users[index];
                    var userData = userDoc.data() as Map<String, dynamic>;
                    String email = userData['email'] ?? "Sin correo";
                    String name = userData['name'] ?? "Sin nombre";
                    String role = userData['role'] ?? "user";
                    List<dynamic> userCourses = userData['purchased_courses'] ?? [];
  
                    return Card(
                      color: const Color(0xFF1E1E1E),
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: role == 'admin' ? Colors.redAccent : Theme.of(context).primaryColor,
                          child: Icon(role == 'admin' ? Icons.admin_panel_settings : Icons.person, color: Colors.black),
                        ),
                        title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: Text("$email\nRol: ${role.toUpperCase()}", style: const TextStyle(color: Colors.grey)),
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                               TextButton.icon(
                                 icon: const Icon(Icons.edit, size: 16, color: Colors.blue),
                                 label: const Text("Cambiar Rol", style: TextStyle(color: Colors.blue)),
                                 onPressed: () => _showEditRoleDialog(userDoc.reference, role, name),
                               ),
                               TextButton.icon(
                                 icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                                 label: const Text("Eliminar Datos", style: TextStyle(color: Colors.red)),
                                 onPressed: () => _confirmDeleteUser(userDoc.id, name),
                               ),
                            ],
                          ),
                          const Divider(color: Colors.grey),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time, color: Colors.orangeAccent),
                                const SizedBox(width: 10),
                                Text(
                                  "Tiempo de Vuelo Total: ${_formatFlightTime(userData['total_flight_minutes'] ?? 0)}", 
                                  style: const TextStyle(color: Colors.white, fontSize: 16)
                                ),
                              ],
                            ),
                          ),
                          const Divider(color: Colors.grey),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Text("CONTROL DE ACCESOS", style: TextStyle(color: Colors.white70, letterSpacing: 1.5, fontSize: 12)),
                          ),
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance.collection('courses').snapshots(),
                            builder: (context, courseSnapshot) {
                              if (!courseSnapshot.hasData) return const LinearProgressIndicator();
                              var allCourses = courseSnapshot.data!.docs;
                              if (allCourses.isEmpty) return const Text("No hay cursos creados.", style: TextStyle(color: Colors.grey));
  
                              return Column(
                                children: allCourses.map((courseDoc) {
                                  var courseData = courseDoc.data() as Map<String, dynamic>?;
                                  return _buildCourseSwitch(
                                      userDoc.reference,
                                      courseData?['title'] ?? 'Curso sin título',
                                      courseDoc.id,
                                      userCourses
                                  );
                                }).toList(),
                              );
                            },
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseSwitch(DocumentReference userRef, String label, String courseId, List<dynamic> currentCourses) {
    bool hasAccess = currentCourses.contains(courseId);

    return SwitchListTile(
      activeColor: Colors.greenAccent,
      inactiveThumbColor: Colors.redAccent,
      inactiveTrackColor: Colors.grey[800],
      title: Text(label, style: TextStyle(color: hasAccess ? Colors.white : Colors.grey)),
      value: hasAccess,
      onChanged: (val) {
        if (val) {
          userRef.update({'purchased_courses': FieldValue.arrayUnion([courseId])});
        } else {
          userRef.update({'purchased_courses': FieldValue.arrayRemove([courseId])});
        }
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
    );
  }

  String _formatFlightTime(int totalMinutes) {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    return "${hours}h ${minutes}m";
  }
}

// ==========================================================
// VISTA 2: GESTIÓN DE CURSOS (REFACTORIZADA)
// ==========================================================
class CourseManagementView extends StatelessWidget {
  const CourseManagementView({super.key});

  void _navigateAndEdit(BuildContext context, {CourseModel? course}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditCourseScreen(course: course),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final courseRepo = Provider.of<CourseRepository>(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.redAccent,
        icon: const Icon(Icons.add),
        label: const Text("NUEVO CURSO"),
        onPressed: () => _navigateAndEdit(context),
      ),
      body: StreamBuilder<List<CourseModel>>(
        stream: courseRepo.getCoursesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Aún no hay cursos creados.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)));
          }
          final courses = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];

              return Card(
                color: const Color(0xFF1E1E1E),
                clipBehavior: Clip.antiAlias,
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                      title: Text(course.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: Text("ID: ${course.id}", style: const TextStyle(color: Colors.grey)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                           IconButton(
                            icon: const Icon(Icons.edit, color: Colors.cyanAccent),
                            onPressed: () => _navigateAndEdit(context, course: course),
                            tooltip: "Editar Curso",
                          ),
                           IconButton(
                            icon: const Icon(Icons.folder_special, color: Colors.orangeAccent),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CourseContentManagementScreen(
                                    courseId: course.id, 
                                    courseTitle: course.title,
                                  ),
                                ),
                              );
                            },
                            tooltip: "Gestionar Contenido",
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _confirmDelete(context, course.id, "curso", courseRepo),
                          ),
                        ],
                      ),
                    ),
              );
            },
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, String courseId, String type, CourseRepository repo) {
    showDialog(context: context, builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: Text("¿Borrar $type?", style: const TextStyle(color: Colors.white)),
        content: const Text("Esta acción es permanente.", style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(onPressed: ()=>Navigator.pop(c), child: const Text("Cancelar")),
          TextButton(onPressed: (){
             repo.deleteCourse(courseId);
             Navigator.pop(c); 
          }, child: const Text("BORRAR", style: TextStyle(color: Colors.red))),
        ]
    ));
  }
}

// ==========================================================
// VISTA 3: GESTIÓN DE NOTICIAS (REFACTORIZADA)
// ==========================================================
class NewsManagementView extends StatelessWidget {
  const NewsManagementView({super.key});

  void _navigateAndEdit(BuildContext context, {NewsModel? news}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditNewsScreen(news: news), // FIX: Pasamos el NewsModel
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final newsRepo = Provider.of<NewsRepository>(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
       floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.redAccent,
        icon: const Icon(Icons.add),
        label: const Text("NUEVA NOTICIA"),
        onPressed: () => _navigateAndEdit(context),
      ),
      body: StreamBuilder<List<NewsModel>>(
        stream: newsRepo.getNewsStream(), // Usamos el Repositorio
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No hay noticias publicadas.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)));
          }

          final newsList = snapshot.data!;
          
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: newsList.length,
            itemBuilder: (context, index) {
              final newsItem = newsList[index];
              final formattedDate = DateFormat('dd/MM/yyyy, HH:mm').format(newsItem.date.toDate());

              return Card(
                color: const Color(0xFF1E1E1E),
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(newsItem.title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  subtitle: Text(formattedDate, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.cyanAccent, size: 22),
                        onPressed: () => _navigateAndEdit(context, news: newsItem),
                        tooltip: "Editar Noticia",
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent, size: 22),
                        onPressed: () => newsRepo.deleteNews(newsItem.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
