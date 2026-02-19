import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sevigdrone/screens/checklist_screen.dart';
import '../hangar/drone_detail_screen.dart'; // Import the new screen

class HangarTab extends StatelessWidget {
  const HangarTab({super.key});

  // Lista de drones comunes
  static const List<Map<String, String>> _commonDrones = [
    {
      "name": "DJI Mavic 3",
      "model": "M3-2023",
      "weight": "895",
      "image": "https://images.unsplash.com/photo-1579829366248-26e6d1c828e1?auto=format&fit=crop&w=800&q=80"
    },
    {
      "name": "DJI Air 2S",
      "model": "A2S-2021",
      "weight": "595",
      "image": "https://images.unsplash.com/photo-1506947411487-a56738267384?auto=format&fit=crop&w=800&q=80"
    },
    {
      "name": "DJI Mini 3 Pro",
      "model": "M3P-2022",
      "weight": "249",
      "image": "https://images.unsplash.com/photo-1527977966376-1c8408f9f108?auto=format&fit=crop&w=800&q=80"
    },
    {
      "name": "Autel Evo Lite+",
      "model": "ELP-2022",
      "weight": "835",
      "image": "https://images.unsplash.com/photo-1508614589041-895b8c9d7b18?auto=format&fit=crop&w=800&q=80"
    },
    {
      "name": "DJI Phantom 4 Pro",
      "model": "P4P-V2",
      "weight": "1375",
      "image": "https://images.unsplash.com/photo-1473968512647-3e447244af8f?auto=format&fit=crop&w=800&q=80"
    },
  ];

  // Función para AÑADIR un dron nuevo
  void _showAddDroneDialog(BuildContext context, String? userId) {
    final nameController = TextEditingController();
    final modelController = TextEditingController();
    final weightController = TextEditingController();
    final imageUrlController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder( // StatefulBuilder para actualizar el dropdown
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            title: const Text("Registrar Aeronave", style: TextStyle(color: Colors.white)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   const Text("Modelos Comunes:", style: TextStyle(color: Colors.grey, fontSize: 12)),
                   DropdownButton<Map<String, String>>(
                     isExpanded: true,
                     dropdownColor: const Color(0xFF2C2C2C),
                     hint: const Text("Seleccionar modelo...", style: TextStyle(color: Colors.white70)),
                     items: _commonDrones.map((drone) {
                       return DropdownMenuItem(
                         value: drone,
                         child: Text(drone['name']!, style: const TextStyle(color: Colors.white)),
                       );
                     }).toList(),
                     onChanged: (val) {
                       if (val != null) {
                         nameController.text = val['name']!;
                         modelController.text = val['model']!;
                         weightController.text = val['weight']!;
                         imageUrlController.text = val['image']!;
                         setState(() {}); // Actualizar UI si fuera necesario
                       }
                     },
                   ),
                   const Divider(color: Colors.grey),
                   const SizedBox(height: 10),
                  _buildTextField(nameController, "Nombre (Ej: Mavic 3)"),
                  const SizedBox(height: 10),
                  _buildTextField(modelController, "Modelo/Serie"),
                  const SizedBox(height: 10),
                  _buildTextField(weightController, "Peso (g)", isNumeric: true),
                  const SizedBox(height: 10),
                  _buildTextField(imageUrlController, "URL de la Imagen (Opcional)"),
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
                onPressed: () {
                  if (userId != null && nameController.text.isNotEmpty) {
                      final droneCreateData = {
                        'name': nameController.text,
                        'model': modelController.text,
                        'weight': weightController.text,
                        'image_url': imageUrlController.text,
                        'flight_hours': 0,
                        'status': 'Operativo',
                        'registered_at': FieldValue.serverTimestamp(), 
                      };
                      FirebaseFirestore.instance.collection('users').doc(userId).collection('drones').add(droneCreateData);
                    
                    Navigator.pop(context);
                  }
                },
                child: const Text("REGISTRAR", style: TextStyle(color: Colors.black)),
              )
            ],
          );
        }
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool isNumeric = false}) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.black,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _confirmDeleteDrone(BuildContext context, DocumentReference droneRef) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: const Text("¿Eliminar Dron?", style: TextStyle(color: Colors.white)),
        content: const Text("Esta acción no se puede deshacer. Se perderá el historial de vuelo de este dron.", style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar", style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () {
              droneRef.delete();
              Navigator.pop(context);
            },
            child: const Text("ELIMINAR", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final goldColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            color: Colors.black,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text("HANGAR VIRTUAL", style: TextStyle(color: goldColor, fontSize: 12, letterSpacing: 2)),
                const Text("Flota de Aeronaves", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).collection('drones').orderBy('registered_at', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                if (snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.airplanemode_active, size: 50, color: Colors.grey),
                        Text("No tienes drones registrados.", style: TextStyle(color: Colors.grey)),
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
                    final imageUrl = data['image_url'] as String?;

                    return Card(
                      color: const Color(0xFF1E1E1E),
                      margin: const EdgeInsets.only(bottom: 12),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => DroneDetailScreen(droneReference: doc.reference)),
                          );
                        },
                        child: Column(
                          children: [
                            if (imageUrl != null && imageUrl.isNotEmpty)
                              SizedBox(
                                height: 150,
                                width: double.infinity,
                                child: Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => Container(height: 150, color: Colors.grey[800], child: const Icon(Icons.broken_image, color: Colors.white24, size: 40)),
                                ),
                              ),
                            ListTile(
                              leading: Icon(Icons.flight_takeoff, color: goldColor, size: 30),
                              title: Text(data['name'] ?? "Dron", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              subtitle: Text("${data['model'] ?? 'N/A'} | ${data['flight_hours'] ?? 0} Horas/Ciclos", style: const TextStyle(color: Colors.grey)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _confirmDeleteDrone(context, doc.reference),
                                  ),
                                  const Icon(Icons.chevron_right, color: Colors.white),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: "btnChecklist",
            backgroundColor: Colors.green[700],
            foregroundColor: Colors.white,
            icon: const Icon(Icons.playlist_add_check),
            label: const Text("SORA / PRE-VUELO"),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ChecklistScreen()));
            },
          ),
          const SizedBox(height: 15),
          FloatingActionButton.extended(
            heroTag: "btnAddDrone",
            backgroundColor: goldColor,
            foregroundColor: Colors.black,
            icon: const Icon(Icons.add),
            label: const Text("AÑADIR DRON"),
            onPressed: () => _showAddDroneDialog(context, user?.uid),
          ),
        ],
      ),
    );
  }
}