import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../repositories/course_repository.dart';

class CourseContentManagementScreen extends StatefulWidget {
  final String courseId;
  final String courseTitle;

  const CourseContentManagementScreen({
    super.key,
    required this.courseId,
    required this.courseTitle,
  });

  @override
  State<CourseContentManagementScreen> createState() => _CourseContentManagementScreenState();
}

class _CourseContentManagementScreenState extends State<CourseContentManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _urlController = TextEditingController();
  String _selectedType = 'link';

  @override
  void dispose() {
    _titleController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  void _showAddResourceDialog(BuildContext context) {
    _titleController.clear();
    _urlController.clear();
    _selectedType = 'link';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2C2C2C),
          title: const Text("Añadir Recurso", style: TextStyle(color: Colors.white)),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: "Título",
                    labelStyle: TextStyle(color: Colors.grey),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                  ),
                  validator: (value) => value!.isEmpty ? 'Ingresa un título' : null,
                ),
                TextFormField(
                  controller: _urlController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: "URL",
                    labelStyle: TextStyle(color: Colors.grey),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                  ),
                  validator: (value) => value!.isEmpty ? 'Ingresa una URL' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  dropdownColor: const Color(0xFF2C2C2C),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: "Tipo",
                    labelStyle: TextStyle(color: Colors.grey),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'link', child: Text("Enlace")),
                    DropdownMenuItem(value: 'video', child: Text("Video (YouTube)")),
                    DropdownMenuItem(value: 'pdf', child: Text("Documento PDF")),
                    DropdownMenuItem(value: 'drive', child: Text("Google Drive")),
                  ],
                  onChanged: (val) => setState(() => _selectedType = val!),
                )
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor),
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final newItem = {
                    'title': _titleController.text.trim(),
                    'url': _urlController.text.trim(),
                    'type': _selectedType,
                    'createdAt': FieldValue.serverTimestamp(),
                  };

                  final repo = Provider.of<CourseRepository>(context, listen: false);
                  await repo.addResource(widget.courseId, newItem);
                  
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text("Añadir", style: TextStyle(color: Colors.black)),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(String resourceId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: const Text("¿Borrar recurso?", style: TextStyle(color: Colors.white)),
        content: const Text("Esta acción no se puede deshacer.", style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
               final repo = Provider.of<CourseRepository>(context, listen: false);
               repo.deleteResource(widget.courseId, resourceId);
               Navigator.pop(context);
            },
            child: const Text("Borrar", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = Provider.of<CourseRepository>(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("Contenido: ${widget.courseTitle}", style: const TextStyle(fontSize: 14)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add, color: Colors.black),
        onPressed: () => _showAddResourceDialog(context),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: repo.getCourseContentStream(widget.courseId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open, size: 60, color: Colors.grey[800]),
                  const SizedBox(height: 10),
                  const Text("No hay contenido añadido.", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final type = data['type'] ?? 'link';
              
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
                child: ListTile(
                  leading: Icon(icon, color: iconColor),
                  title: Text(data['title'], style: const TextStyle(color: Colors.white)),
                  subtitle: Text(data['url'], style: const TextStyle(color: Colors.grey, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _confirmDelete(doc.id),
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
