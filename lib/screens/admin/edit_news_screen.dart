import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:metadata_fetch/metadata_fetch.dart';
import '../../models/news_model.dart';
import '../../repositories/news_repository.dart';

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
  late TextEditingController _urlCtrl;

  bool _isSaving = false;
  bool _isFetchingMetadata = false;

  bool get _isEditing => widget.news != null;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.news?.title ?? '');
    _bodyCtrl = TextEditingController(text: widget.news?.body ?? '');
    _imageCtrl = TextEditingController(text: widget.news?.image ?? '');
    _urlCtrl = TextEditingController(text: widget.news?.url ?? '');
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _imageCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchMetadataFromUrl() async {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty || !url.startsWith('http')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ingresa una URL válida (http...)")));
      return;
    }
    setState(() => _isFetchingMetadata = true);
    try {
      var data = await MetadataFetch.extract(url);
      if (data != null) {
        if (data.title != null && data.title!.isNotEmpty) {
          _titleCtrl.text = data.title!;
        }
        if (data.image != null && data.image!.isNotEmpty) {
          _imageCtrl.text = data.image!;
        }
        if (data.description != null && data.description!.isNotEmpty && _bodyCtrl.text.isEmpty) {
          _bodyCtrl.text = data.description!;
        }
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Metadatos extraídos correctamente"), backgroundColor: Colors.green));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No se encontraron metadatos en la URL")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error al extraer metadatos: $e")));
    } finally {
      setState(() => _isFetchingMetadata = false);
    }
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
      'url': _urlCtrl.text,
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
                  controller: _urlCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "URL de la Noticia (Pegar aquí)",
                    border: const OutlineInputBorder(),
                    suffixIcon: _isFetchingMetadata
                        ? const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : IconButton(
                            icon: const Icon(Icons.download_for_offline, color: Color(0xFFD4AF37)),
                            tooltip: "Extraer Datos (Open Graph)",
                            onPressed: _fetchMetadataFromUrl,
                          ),
                  ),
                ),
                const SizedBox(height: 16),
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
                  decoration: const InputDecoration(labelText: "URL de la Imagen (Opcional)", border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
        ),
    );
  }
}
