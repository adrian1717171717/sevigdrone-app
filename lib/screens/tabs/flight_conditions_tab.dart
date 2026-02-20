import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart'; 
import 'package:flutter_compass/flutter_compass.dart';
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
  double? _heading = 0;

  @override
  void initState() {
    super.initState();
    _fetchData();
    FlutterCompass.events?.listen((CompassEvent event) {
      if (mounted) {
        setState(() {
          _heading = event.heading;
        });
      }
    });
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

  String _soraStatus = "APTO PARA VOLAR";
  Color _soraColor = Colors.green;
  IconData _soraIcon = Icons.check_circle;

  void _calculateSora(double wind, double gusts, double rainProp) {
    if (wind > 35.0 || rainProp > 20.0) {
      _soraStatus = "NO APTO (Peligro crítico)";
      _soraColor = Colors.red;
      _soraIcon = Icons.cancel;
    } else if (wind > 20.0 || gusts > 25.0) {
      _soraStatus = "PRECAUCIÓN (Viento Fuerte)";
      _soraColor = Colors.orange;
      _soraIcon = Icons.warning;
    } else {
      _soraStatus = "APTO PARA VOLAR";
      _soraColor = Colors.green;
      _soraIcon = Icons.check_circle;
    }
  }

  String _getWindDirectionLetter(int degrees) {
    if (degrees >= 337.5 || degrees < 22.5) return 'N';
    if (degrees >= 22.5 && degrees < 67.5) return 'NE';
    if (degrees >= 67.5 && degrees < 112.5) return 'E';
    if (degrees >= 112.5 && degrees < 157.5) return 'SE';
    if (degrees >= 157.5 && degrees < 202.5) return 'S';
    if (degrees >= 202.5 && degrees < 247.5) return 'SO';
    if (degrees >= 247.5 && degrees < 292.5) return 'O';
    if (degrees >= 292.5 && degrees < 337.5) return 'NO';
    return '';
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
    // Visibilidad no disponible directamente en current, usar precipitation de proxy
    // Interpretamos >0.5 mm como >20% de probabilidad de lluvia
    final double rainProb = precipitation > 0.5 ? 25.0 : 0.0; 

    _calculateSora(windSpeed, windGusts, rainProb);
    final goldColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text("Análisis de Vuelo - SORA", style: TextStyle(color: goldColor, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: goldColor),
            onPressed: _fetchData,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- HEADER SORA STATUS ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: _soraColor.withOpacity(0.9),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                  Icon(_soraIcon, size: 50, color: Colors.white),
                  const SizedBox(height: 10),
                  Text(
                    _soraStatus,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // --- COMPASS ---
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Brújula principal rotando con el hardware
                  Transform.rotate(
                    angle: ((_heading ?? 0) * (math.pi / 180) * -1),
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: goldColor, width: 2),
                        color: const Color(0xFF1E1E1E),
                      ),
                      child: Stack(
                        children: [
                          Positioned(top: 10, left: 105, child: Text("N", style: TextStyle(color: goldColor, fontWeight: FontWeight.bold, fontSize: 18))),
                          Positioned(bottom: 10, left: 105, child: Text("S", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 18))),
                          Positioned(right: 10, top: 100, child: Text("E", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 18))),
                          Positioned(left: 10, top: 100, child: Text("O", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 18))),
                          // Rosa de los vientos tick marks (opcional)
                        ],
                      ),
                    ),
                  ),
                  // Flecha indicadora central fija
                  Icon(Icons.navigation, color: goldColor, size: 60),

                  // Indicador visual de viento relativo a brújula
                  // El viento viene desde `windDir`. Si la brújula gira `_heading`, la posición en la UI es (windDir - _heading)
                  Transform.rotate(
                    angle: (windDir * (math.pi / 180)) + ((_heading ?? 0) * (math.pi / 180) * -1),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 25.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.air, color: Colors.cyanAccent, size: 24),
                            Text("${windSpeed.toInt()} km/h", style: const TextStyle(color: Colors.cyanAccent, fontSize: 10)),
                          ],
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text("BRÚJULA DE NAVEGACIÓN", style: TextStyle(color: goldColor, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            Text("Viento viene del: ${_getWindDirectionLetter(windDir)} ($windDir°)", style: const TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 30),

            // --- GRID DE DATOS ---
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 0.85, 
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: [
                _buildInfoCard("Viento", "$windSpeed km/h", Icons.air, _getValueColor(windSpeed, 35.0)),
                _buildInfoCard("Ráfagas", "$windGusts km/h", Icons.wind_power, _getValueColor(windGusts, 40.0)),
                _buildInfoCard("Dirección", "$windDir°", Icons.navigation, Colors.cyan, rotation: windDir.toDouble()),
                _buildInfoCard("Temp", "$temp°C", Icons.thermostat, Colors.orange),
                _buildInfoCard("Lluvia", "$precipitation mm", Icons.water_drop, precipitation > 0 ? Colors.blue : Colors.grey),
                _buildInfoCard("Nublado", "$cloudCover%", Icons.cloud_queue, Colors.grey),
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
                  Text("• Evaluación SORA basada en límites de viento operacionales.", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  Text("• El viento y clima provienen de la API de Open-Meteo en tiempo real.", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  Text("• Brújula magnética basada en sensor de hardware interno del dispositivo.", style: TextStyle(color: Colors.grey, fontSize: 12)),
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
