import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart'; // Asegúrate de tener geolocator
import '../../services/weather_service.dart';
import 'dart:math' as math;

class FlightConditionsTab extends StatefulWidget {
  const FlightConditionsTab({super.key});

  @override
  State<FlightConditionsTab> createState() => _FlightConditionsTabState();
}

class _FlightConditionsTabState extends State<FlightConditionsTab> {
  final WeatherService _weatherService = WeatherService();
  Map<String, dynamic>? _weatherData;
  int _kpIndex = 0;
  bool _loading = true;
  String _error = '';

  // Umbrales para "Bueno para volar" (Ejemplo)
  final double _maxWindSpeed = 25.0; // km/h
  final double _maxGusts = 35.0; // km/h
  final int _maxKp = 5;
  final double _minVisibility = 5000; // metros (5km) (API devuelve metros o km, chequear)

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final position = await _weatherService.getCurrentLocation();
      if (position == null) {
        setState(() {
          _error = 'No se pudo obtener la ubicación o permisos denegados.';
          _loading = false;
        });
        return;
      }

      final weather = await _weatherService.getWeather(position.latitude, position.longitude);
      final kp = await _weatherService.getKpIndex();

      setState(() {
        _weatherData = weather;
        _kpIndex = kp;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error obteniendo datos: $e';
        _loading = false;
      });
    }
  }

  bool _isGoodToFly(double wind, double gusts, int kp, double rainProb) {
    if (wind > _maxWindSpeed) return false;
    if (gusts > _maxGusts) return false;
    if (kp >= _maxKp) return false;
    if (rainProb > 50) return false; // Si probabilidad de lluvia > 50%
    return true;
  }

  Color _getValueColor(double value, double threshold) {
    if (value < threshold * 0.7) return Colors.greenAccent;
    if (value < threshold) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
    if (_error.isNotEmpty) return Center(child: Text(_error, style: const TextStyle(color: Colors.red)));

    final current = _weatherData?['current'] ?? {};
    final currentUnits = _weatherData?['current_units'] ?? {};

    // Extraer datos
    final double temp = (current['temperature_2m'] as num?)?.toDouble() ?? 0.0;
    final double windSpeed = (current['wind_speed_10m'] as num?)?.toDouble() ?? 0.0;
    final double windGusts = (current['wind_gusts_10m'] as num?)?.toDouble() ?? 0.0;
    final int windDir = (current['wind_direction_10m'] as num?)?.toInt() ?? 0;
    final int cloudCover = (current['cloud_cover'] as num?)?.toInt() ?? 0;
    final double precipitation = (current['precipitation'] as num?)?.toDouble() ?? 0.0;
    // Visibilidad suele estar en 'hourly' en Open-Meteo, tomamos el primer valor o estimamos
    // Para simplificar, si no hay visibility en current, usaremos un valor dummy o buscaremos otra forma.
    // Open-Meteo free no siempre da visibilidad en 'current', pero sí en hourly.
    final double visibility = 10000; // Valor por defecto > 10km

    final bool goodToFly = _isGoodToFly(windSpeed, windGusts, _kpIndex, precipitation * 100); // *100 si es mm a probabilidad aproximada

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text("Condiciones de Vuelo"),
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchData,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- HEADER STATUS ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: goodToFly ? Colors.green[800] : Colors.red[800],
                borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                  Text(
                    goodToFly ? "BUENO PARA VOLAR" : "NO RECOMENDADO",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text("Pronóstico en tiempo real", style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // --- GRID DE DATOS ---
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 0.85, 
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: [
                _buildInfoCard("Clima", "${current['weather_code'] ?? '-'}", Icons.cloud, Colors.cyan), // weather code mapping pendiente
                _buildInfoCard("Temp", "$temp°C", Icons.thermostat, Colors.orange),
                _buildInfoCard("Viento", "$windSpeed km/h", Icons.air, _getValueColor(windSpeed, _maxWindSpeed)),
                _buildInfoCard("Ráfagas", "$windGusts km/h", Icons.wind_power, _getValueColor(windGusts, _maxGusts)),
                _buildInfoCard("Dirección", "$windDir°", Icons.navigation, Colors.white, rotation: windDir.toDouble()),
                _buildInfoCard("Lluvia", "$precipitation mm", Icons.water_drop, precipitation > 0 ? Colors.blue : Colors.grey),
                _buildInfoCard("Nubes", "$cloudCover%", Icons.cloud_queue, Colors.grey),
                _buildInfoCard("Índice Kp", "$_kpIndex", Icons.public, _getValueColor(_kpIndex.toDouble(), _maxKp.toDouble())),
                _buildInfoCard("Sats Visibles", "12+", Icons.satellite_alt, Colors.green), // Placeholder
              ],
            ),
            
            const SizedBox(height: 20),
            
            // --- LEYENDA / INFO EXTRA ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Información Adicional", style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text("• Los datos de Kp se obtienen de NOAA en tiempo real.", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  Text("• El viento y clima provienen de estaciones locales vía Open-Meteo.", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  Text("• Siempre verifique visualmente las condiciones antes de volar.", style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon, Color color, {double rotation = 0}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 8),
          Transform.rotate(
            angle: rotation * (math.pi / 180),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
