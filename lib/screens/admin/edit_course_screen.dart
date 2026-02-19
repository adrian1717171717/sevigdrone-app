import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../models/course_model.dart';
import '../../repositories/course_repository.dart';

class EditCourseScreen extends StatefulWidget {
  final CourseModel? course;

  const EditCourseScreen({super.key, this.course});

  @override
  State<EditCourseScreen> createState() => _EditCourseScreenState();
}

class _EditCourseScreenState extends State<EditCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controladores del Curso
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _imageCtrl;
  late TextEditingController _instrCtrl;

  bool _isSaving = false;

  // Si course no es null, estamos editando
  bool get _isEditing => widget.course != null;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.course?.title ?? '');
    _descCtrl = TextEditingController(text: widget.course?.description ?? '');
    _priceCtrl = TextEditingController(text: widget.course?.price.toString() ?? '');
    _imageCtrl = TextEditingController(text: widget.course?.imageUrl ?? '');
    _instrCtrl = TextEditingController(text: widget.course?.instructor ?? '');
  }

  @override
  void dispose() {
    _titleCtrl.dispose(); _descCtrl.dispose(); _priceCtrl.dispose(); 
    _imageCtrl.dispose(); _instrCtrl.dispose();
    super.dispose();
  }

  // --- GUARDAR CURSO PRINCIPAL ---
  Future<void> _saveCourse() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final repo = Provider.of<CourseRepository>(context, listen: false);
    final double price = double.tryParse(_priceCtrl.text) ?? 0.0;

    final courseData = CourseModel(
      id: widget.course?.id ?? '', // Si es nuevo, el repo generará el ID o Firebase lo ignorará al usar add()
      title: _titleCtrl.text,
      description: _descCtrl.text,
      price: price,
      imageUrl: _imageCtrl.text,
      instructor: _instrCtrl.text,
    );

    try {
      if (_isEditing) {
        await repo.updateCourse(courseData);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Curso actualizado")));
      } else {
        await repo.addCourse(courseData);
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Curso creado. Ábrelo de nuevo para añadir recursos.")));
           Navigator.pop(context); // Salimos para que el admin entre a editar y añada recursos
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // --- GESTIÓN DE RECURSOS (VIDEOS/PDFs) ---
  void _showAddResourceDialog() {
    final titleCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    String type = 'video'; // por defecto

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: const Text("Añadir Recurso", style: TextStyle(color: Colors.white)),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Título del recurso", labelStyle: TextStyle(color: Colors.grey))),
                const SizedBox(height: 10),
                TextField(controller: urlCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "URL (YouTube, PDF, Web...)", labelStyle: TextStyle(color: Colors.grey))),
                const SizedBox(height: 15),
                DropdownButton<String>(
                  value: type,
                  dropdownColor: const Color(0xFF2C2C2C),
                  style: const TextStyle(color: Colors.white),
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'video', child: Text("Video")),
                    DropdownMenuItem(value: 'pdf', child: Text("Documento PDF")),
                    DropdownMenuItem(value: 'link', child: Text("Enlace Web")),
                  ], 
                  onChanged: (val) => setDialogState(() => type = val!)
                ),
              ],
            );
          }
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          TextButton(
            onPressed: () async {
              if (titleCtrl.text.isNotEmpty && urlCtrl.text.isNotEmpty) {
                final repo = Provider.of<CourseRepository>(context, listen: false);
                await repo.addResource(widget.course!.id, {
                  'title': titleCtrl.text,
                  'url': urlCtrl.text,
                  'type': type,
                  'createdAt': FieldValue.serverTimestamp(),
                });
                if(context.mounted) Navigator.pop(ctx);
              }
            }, 
            child: const Text("AÑADIR", style: TextStyle(color: Color(0xFFD4AF37)))
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const goldColor = Color(0xFFD4AF37);
    final repo = Provider.of<CourseRepository>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? "Editar Curso" : "Nuevo Curso"),
        actions: [
          IconButton(icon: const Icon(Icons.save, color: goldColor), onPressed: _saveCourse),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- FORMULARIO PRINCIPAL ---
            Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildInput(_titleCtrl, "Título", Icons.title),
                  const SizedBox(height: 10),
                  _buildInput(_descCtrl, "Descripción", Icons.description, maxLines: 3),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _buildInput(_priceCtrl, "Precio (\$)", Icons.attach_money, isNumber: true)),
                      const SizedBox(width: 10),
                      Expanded(child: _buildInput(_instrCtrl, "Instructor", Icons.person)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildInput(_imageCtrl, "URL Imagen", Icons.image),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            // --- SECCIÓN DE RECURSOS (Solo visible si ya existe el curso) ---
            if (_isEditing) ...[
              const Divider(color: goldColor),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("RECURSOS DEL CURSO", style: TextStyle(color: goldColor, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.green),
                    onPressed: _showAddResourceDialog,
                    tooltip: "Añadir Video o PDF",
                  ),
                ],
              ),
              const SizedBox(height: 10),
              
              // Lista de recursos en tiempo real
              StreamBuilder<QuerySnapshot>(
                stream: repo.getCourseContentStream(widget.course!.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: LinearProgressIndicator(color: goldColor));
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(20),
                      width: double.infinity,
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey[800]!), borderRadius: BorderRadius.circular(10)),
                      child: const Center(child: Text("No hay contenido subido.", style: TextStyle(color: Colors.grey))),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var doc = snapshot.data!.docs[index];
                      var data = doc.data() as Map<String, dynamic>;
                      bool isVideo = data['type'] == 'video';

                      return Card(
                        color: const Color(0xFF1E1E1E),
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(isVideo ? Icons.play_circle_fill : Icons.picture_as_pdf, color: isVideo ? Colors.red : Colors.blue),
                          title: Text(data['title'] ?? 'Sin título', style: const TextStyle(color: Colors.white)),
                          subtitle: Text(data['url'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.grey),
                            onPressed: () => repo.deleteResource(widget.course!.id, doc.id),
                          ),
                        ),
                      );
                    },
                  );
                },
              )
            ] else ...[
              const Center(child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text("Guarda el curso primero para añadir videos y PDFs.", style: TextStyle(color: Colors.grey)),
              ))
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController ctrl, String label, IconData icon, {bool isNumber = false, int maxLines = 1}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFFD4AF37)),
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        labelStyle: const TextStyle(color: Colors.grey),
      ),
      validator: (v) => v!.isEmpty ? "Requerido" : null,
    );
  }
}