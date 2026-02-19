import 'package:flutter/material.dart';

class ChecklistScreen extends StatefulWidget {
  const ChecklistScreen({super.key});

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  // Estado de los cheques (Basado en MIP Sevigdrone)
  bool _checkPropellers = false;
  bool _checkBattery = false;
  bool _checkCompass = false;
  bool _checkVLOS = false;
  bool _checkWeather = false;
  bool _checkInsurance = false;

  bool get _isReady => _checkPropellers && _checkBattery && _checkCompass && _checkVLOS && _checkWeather && _checkInsurance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("PRE-VUELO (SORA)"),
        backgroundColor: _isReady ? Colors.green[800] : Colors.black,
      ),
      body: Column(
        children: [
          // CABECERA DE ESTADO
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: _isReady ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
            child: Column(
              children: [
                Icon(
                  _isReady ? Icons.check_circle : Icons.warning_amber_rounded,
                  size: 60,
                  color: _isReady ? Colors.green : Colors.red,
                ),
                const SizedBox(height: 10),
                Text(
                  _isReady ? "AUTORIZADO PARA EL DESPEGUE" : "AERONAVE EN TIERRA",
                  style: TextStyle(
                      color: _isReady ? Colors.green : Colors.red,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text("INSPECCIÓN FÍSICA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const Divider(color: Colors.grey),

                _buildCheckItem("Hélices y Motores", "Sin fisuras ni obstrucciones.", _checkPropellers, (v) => setState(() => _checkPropellers = v)),
                _buildCheckItem("Batería Inteligente", "Asegurada y voltaje correcto.", _checkBattery, (v) => setState(() => _checkBattery = v)),
                _buildCheckItem("Calibración de Sensores", "Brújula e IMU OK.", _checkCompass, (v) => setState(() => _checkCompass = v)),

                const SizedBox(height: 20),
                const Text("SEGURIDAD OPERACIONAL", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const Divider(color: Colors.grey),

                _buildCheckItem("Zona VLOS", "Contacto visual garantizado.", _checkVLOS, (v) => setState(() => _checkVLOS = v)),
                _buildCheckItem("Meteorología", "Viento < 10m/s, sin lluvia.", _checkWeather, (v) => setState(() => _checkWeather = v)),
                _buildCheckItem("Documentación", "Seguro y Permiso vigentes.", _checkInsurance, (v) => setState(() => _checkInsurance = v)),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20.0),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isReady ? Colors.green : Colors.grey[800],
                  foregroundColor: Colors.white,
                ),
                onPressed: _isReady ? () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("🚀 ¡Buen vuelo! Operación registrada."), backgroundColor: Colors.green)
                  );
                } : null,
                icon: Icon(_isReady ? Icons.flight_takeoff : Icons.lock),
                label: const Text("INICIAR OPERACIÓN"),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCheckItem(String title, String subtitle, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      activeColor: Colors.green,
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      value: value,
      onChanged: onChanged,
    );
  }
}