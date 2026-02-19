import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class WeatherService {
  final String _weatherBaseUrl = 'https://api.open-meteo.com/v1/forecast';
  // Nota: Para Kp index, Open-Meteo no tiene endpoint directo gratis fácil de usar en este contexto sin Auth o API key a veces,
  // pero usaremos un endpoint de NOAA o similar si es posible, o simulado si no hay uno público abierto sin key fiable.
  // Sin embargo, Open-Meteo tiene "Space Weather" en beta o endpoints separados.
  // Para simplificar y cumplir con "gratis", usaremos datos de clima reales y un placeholder o API pública simple para Kp si encontramos.
  // URL de ejemplo para Kp: https://services.swpc.noaa.gov/json/planetary_k_index_1m.json

  Future<Map<String, dynamic>> getWeather(double lat, double lon) async {
    try {
      final url = Uri.parse(
          '$_weatherBaseUrl?latitude=$lat&longitude=$lon&current=temperature_2m,relative_humidity_2m,precipitation,rain,showers,weather_code,cloud_cover,wind_speed_10m,wind_direction_10m,wind_gusts_10m&hourly=visibility&timezone=auto&foreground_color=white');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error al cargar datos del clima');
      }
    } catch (e) {
      print('Error WeatherService: $e');
      return {};
    }
  }

  Future<int> getKpIndex() async {
    try {
      // Endpoint de NOAA para K-index (tiempo real / reciente)
      final url = Uri.parse('https://services.swpc.noaa.gov/products/noaa-planetary-k-index.json');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        // El formato es [[time, kp, a_running, station_count], ...]
        // El último elemento es el más reciente.
        if (data.isNotEmpty && data.length > 1) {
          final lastEntry = data.last; // Última entrada
          // lastEntry[1] es el Kp index (puede ser string o num)
          final kp = double.tryParse(lastEntry[1].toString()) ?? 0.0;
          return kp.round();
        }
      }
      return 0;
    } catch (e) {
      print('Error KpIndex: $e');
      return 0; // Valor seguro por defecto
    }
  }

  Future<Position?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    return await Geolocator.getCurrentPosition();
  }
}
