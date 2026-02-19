import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

class DroneDetailScreen extends StatefulWidget {
  final DocumentReference droneReference;

  const DroneDetailScreen({super.key, required this.droneReference});

  @override
  State<DroneDetailScreen> createState() => _DroneDetailScreenState();
}

class _DroneDetailScreenState extends State<DroneDetailScreen> {

  void _showEditDroneDialog(Map<String, dynamic> currentData) {
    final nameController = TextEditingController(text: currentData['name']);
    final modelController = TextEditingController(text: currentData['model']);
    final weightController = TextEditingController(text: currentData['weight']);
    final imageUrlController = TextEditingController(text: currentData['image_url']);
    final flightMinutesController = TextEditingController(text: currentData['flight_minutes']?.toString() ?? '0');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: const Text("Editar Aeronave", style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: "Nombre")),
              TextField(controller: modelController, decoration: const InputDecoration(labelText: "Modelo/Serie")),
              TextField(controller: weightController, decoration: const InputDecoration(labelText: "Peso (g)")),
              TextField(controller: imageUrlController, decoration: const InputDecoration(labelText: "URL de la Imagen")),
              TextField(controller: flightMinutesController, decoration: const InputDecoration(labelText: "Total Minutos de Vuelo"), keyboardType: TextInputType.number),
            ].map((e) => Padding(padding: const EdgeInsets.only(bottom: 10), child: e)).toList(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () {
              final updatedData = {
                'name': nameController.text,
                'model': modelController.text,
                'weight': weightController.text,
                'image_url': imageUrlController.text,
                'flight_minutes': int.tryParse(flightMinutesController.text) ?? 0,
              };
              widget.droneReference.update(updatedData);
              Navigator.pop(context);
            },
            child: const Text("Guardar Cambios"),
          ),
        ],
      ),
    );
  }

  void _showAddFlightTimeDialog() {
    final hoursController = TextEditingController();
    final minutesController = TextEditingController();

    showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF2C2C2C),
          title: const Text("Añadir Tiempo de Vuelo", style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: hoursController, decoration: const InputDecoration(labelText: "Horas"), keyboardType: TextInputType.number),
              TextField(controller: minutesController, decoration: const InputDecoration(labelText: "Minutos"), keyboardType: TextInputType.number),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
            ElevatedButton(
              onPressed: () {
                final hours = int.tryParse(hoursController.text) ?? 0;
                final minutes = int.tryParse(minutesController.text) ?? 0;
                final totalMinutesToAdd = (hours * 60) + minutes;
                if (totalMinutesToAdd > 0) {
                  // Actualizar horas del dron
                  widget.droneReference.update({'flight_minutes': FieldValue.increment(totalMinutesToAdd)});
                  
                  // Actualizar horas totales del piloto (User)
                  // widget.droneReference -> collection 'drones' -> doc 'userId' (User)
                  widget.droneReference.parent.parent?.update({
                    'total_flight_minutes': FieldValue.increment(totalMinutesToAdd)
                  });
                }
                Navigator.pop(context);
              },
              child: const Text("Añadir"),
            ),
          ],
        ));
  }

  void _showAddBatteryDialog() {
    final nameController = TextEditingController();
    final cycleController = TextEditingController(text: '0');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: const Text("Añadir Nueva Batería", style: TextStyle(color: Colors.white)),
        content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: "Nombre de la Batería (ej: Batería 1)")),
              const SizedBox(height: 10),
              TextField(controller: cycleController, decoration: const InputDecoration(labelText: "Ciclos Iniciales"), keyboardType: TextInputType.number),
            ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                widget.droneReference.collection('batteries').add({
                  'name': nameController.text,
                  'cycle_count': int.tryParse(cycleController.text) ?? 0,
                  'added_at': FieldValue.serverTimestamp(),
                });
                Navigator.pop(context);
              }
            },
            child: const Text("Añadir"),
          ),
        ],
      ),
    );
  }

  Color _getHealthColor(int cycles) {
    if (cycles <= 100) return Colors.greenAccent;
    if (cycles <= 200) return Colors.yellowAccent;
    return Colors.redAccent;
  }

  String _formatFlightTime(int totalMinutes) {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    return "${hours}h ${minutes}m";
  }

  void _confirmDeleteBattery(BuildContext context, DocumentReference batteryRef) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: const Text("¿Eliminar Batería?", style: TextStyle(color: Colors.white)),
        content: const Text("Esta acción no se puede deshacer.", style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar", style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () {
              batteryRef.delete();
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
    return StreamBuilder<DocumentSnapshot>(
      stream: widget.droneReference.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final droneData = snapshot.data!.data() as Map<String, dynamic>;;
        final imageUrl = droneData['image_url'] as String?;
        final flightMinutes = droneData['flight_minutes'] ?? 0;

        return Scaffold(
          appBar: AppBar(
            title: Text(droneData['name'] ?? 'Detalles del Dron'),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_note), 
                onPressed: () => _showEditDroneDialog(droneData),
                tooltip: "Editar Datos del Dron",
              ),
            ],
          ),
          body: ListView(
            children: [
              if (imageUrl != null && imageUrl.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: imageUrl,
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const SizedBox(height: 250, child: Center(child: CircularProgressIndicator())),
                  errorWidget: (context, url, error) => const SizedBox(height: 250, child: Icon(Icons.broken_image)),
                ),

              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Modelo: ${droneData['model'] ?? 'N/A'}", style: const TextStyle(fontSize: 16, color: Colors.grey)),
                    Text("Peso: ${droneData['weight'] ?? 'N/A'}g", style: const TextStyle(fontSize: 16, color: Colors.grey)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Tiempo de Vuelo: ${_formatFlightTime(flightMinutes)}", style: const TextStyle(fontSize: 18, color: Colors.white)),
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: Colors.cyanAccent),
                          tooltip: "Añadir Tiempo de Vuelo",
                          onPressed: _showAddFlightTimeDialog,
                        )
                      ],
                    )
                  ],
                ),
              ),
              const Divider(),

              // --- SECCIÓN DE BATERÍAS ---
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Gestión de Baterías", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                          IconButton(icon: const Icon(Icons.add_box, color: Colors.greenAccent), onPressed: _showAddBatteryDialog, tooltip: "Añadir Batería"),
                        ],
                    ),
                    const SizedBox(height: 10),
                    StreamBuilder<QuerySnapshot>(
                      stream: widget.droneReference.collection('batteries').orderBy('name').snapshots(),
                      builder: (context, batterySnapshot) {
                        if (batterySnapshot.hasError) {
                          return Center(child: Text("Error al cargar baterías: ${batterySnapshot.error}", style: const TextStyle(color: Colors.red)));
                        }
                        if (!batterySnapshot.hasData) return const Center(child: CircularProgressIndicator());
                        if (batterySnapshot.data!.docs.isEmpty) return const Center(child: Text("No hay baterías registradas.", style: TextStyle(color: Colors.grey)));

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: batterySnapshot.data!.docs.length,
                          itemBuilder: (context, index) {
                            final batteryDoc = batterySnapshot.data!.docs[index];
                            final batteryData = batteryDoc.data() as Map<String, dynamic>;
                            final cycles = batteryData['cycle_count'] ?? 0;

                            return Card(
                              color: const Color(0xFF1E1E1E),
                              child: ListTile(
                                leading: CircleAvatar(backgroundColor: _getHealthColor(cycles), radius: 10),
                                title: Text(batteryData['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                subtitle: Text("$cycles ciclos de carga", style: const TextStyle(color: Colors.grey)),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.add, color: Colors.white),
                                      onPressed: () => batteryDoc.reference.update({'cycle_count': FieldValue.increment(1)}),
                                      tooltip: "Añadir Ciclo",
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _confirmDeleteBattery(context, batteryDoc.reference),
                                      tooltip: "Eliminar Batería",
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
