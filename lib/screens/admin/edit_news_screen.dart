import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:sevigdrone/models/news_model.dart';
import 'package:sevigdrone/repositories/news_repository.dart';

class EditNewsScreen extends StatefulWidget {
  final NewsModel? news;

  const EditNewsScreen({super.key, this.news});

  @override
  State<EditNewsScreen> createState() => _EditNewsScreenState();
}

class _EditNewsScreenState extends State<EditNewsScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _titleCtrl;
  late TextEditingController _bodyCtrl;
  late TextEditingController _imageCtrl;

  bool _isSaving = false;

  bool get _isEditing => widget.news != null;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.news?.title ?? '');
    _bodyCtrl = TextEditingController(text: widget.news?.body ?? '');
    _imageCtrl = TextEditingController(text: widget.news?.image ?? '');
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _imageCtrl.dispose();
    super.dispose();
  }



  Future<void> _saveNews() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);

    final newsRepo = Provider.of<NewsRepository>(context, listen: false);

    // Creamos el Map directamente para Firestore
    final newsData = {
      'title': _titleCtrl.text,
      'body': _bodyCtrl.text,
      'image': _imageCtrl.text,
      'date': FieldValue.serverTimestamp(), 
      'author': 'Comandancia SEVIGDRONE',
    };

    try {
      if (_isEditing) {
        await newsRepo.updateNews(widget.news!.id, newsData);
      } else {
        await newsRepo.addNews(newsData);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Noticia guardada"), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error al guardar: $e")));
      }
    } finally {
      if(mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? "Editar Noticia" : "Nueva Noticia"),
        actions: [
          if (!_isSaving)
            IconButton(icon: const Icon(Icons.save), onPressed: _saveNews, tooltip: "Guardar"),
        ],
      ),
      body: _isSaving 
        ? const Center(child: CircularProgressIndicator()) 
        : Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

                TextFormField(
                  controller: _titleCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: "Título", border: OutlineInputBorder()),
                  validator: (v) => v!.isEmpty ? "El Título es obligatorio" : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _bodyCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: "Cuerpo de la noticia", border: OutlineInputBorder()),
                  maxLines: 10,
                  validator: (v) => v!.isEmpty ? "El contenido es obligatorio" : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _imageCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: "URL de la Imagen Directa (.jpg / .png)", border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
        ),
    );
  }
}
