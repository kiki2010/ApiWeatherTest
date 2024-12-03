import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather API Demo',
      theme: ThemeData.dark(useMaterial3: true),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String latitude = "";
  String longitude = "";
  String apiResponse = "Cargando datos...";

  final String apiKey = "026cda1f35b54cddacda1f35b53cdda3"; // Tu clave de API

  @override
  void initState() {
    super.initState();
    getCurrentPosition(); // Obtener ubicación al iniciar la app
  }

  Future<Position> determinePosition() async {
    LocationPermission permission;

    // Verifica y solicita permisos
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Permiso denegado');
      }
    }

    return await Geolocator.getCurrentPosition();
  }

  void getCurrentPosition() async {
    try {
      Position position = await determinePosition();

      // Redondea latitud y longitud a 2 decimales
      double roundedLat = double.parse(position.latitude.toStringAsFixed(3));
      double roundedLon = double.parse(position.longitude.toStringAsFixed(3));

      setState(() {
        latitude = roundedLat.toString();
        longitude = roundedLon.toString();
      });

      // Llama a la API con las coordenadas obtenidas
      fetchApiData(roundedLat, roundedLon);
    } catch (e) {
      setState(() {
        latitude = "Error obteniendo ubicación";
        longitude = "Error obteniendo ubicación";
        apiResponse = "No se pudo obtener la ubicación.";
      });
    }
  }

  Future<void> fetchApiData(double lat, double lon) async {
    final String apiUrl =
        "https://api.weather.com/v3/location/near?geocode=$latitude,$longitude&product=PWS&format=json&apiKey=$apiKey";

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        // Decodifica la respuesta JSON
        final data = json.decode(response.body);

        setState(() {
          apiResponse = "Datos obtenidos:\n${data.toString()}";
        });
      } else {
        setState(() {
          apiResponse = "Error al obtener datos: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        apiResponse = "Error al conectar con la API: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather API Demo'),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Latitud: $latitude"),
            Text("Longitud: $longitude"),
            const SizedBox(height: 20),
            Text("Respuesta de la API:"),
            Text(
              apiResponse,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
