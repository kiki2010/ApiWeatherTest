import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart'; // Library for obtaining geolocation
import 'package:http/http.dart' as http; // Library for making HTTP requests
import 'dart:convert'; // Library for working with JSON

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather API Demo',
      theme: ThemeData.dark(useMaterial3: true), // Applying a dark theme
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
  String latitude = ""; // Variable to store latitude
  String longitude = ""; // Variable to store longitude
  String apiResponse = "Loading data..."; // Variable to store API response

  final String apiKey = "..."; // Your API key

  @override
  void initState() {
    super.initState();
    getCurrentPosition(); // Get user's location when the app starts
  }

  // Method to determine the user's location with permission handling
  Future<Position> determinePosition() async {
    LocationPermission permission;

    // Check and request location permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Permission denied');
      }
    }

    // Return the current position
    return await Geolocator.getCurrentPosition();
  }

  // Method to get the current position and fetch API data
  void getCurrentPosition() async {
    try {
      Position position = await determinePosition();

      // Round latitude and longitude to 3 decimal places
      double roundedLat = double.parse(position.latitude.toStringAsFixed(3));
      double roundedLon = double.parse(position.longitude.toStringAsFixed(3));

      setState(() {
        latitude = roundedLat.toString(); // Update latitude
        longitude = roundedLon.toString(); // Update longitude
      });

      // Fetch data from the API using the obtained coordinates
      fetchApiData(roundedLat, roundedLon);
    } catch (e) {
      setState(() {
        latitude = "Error retrieving location";
        longitude = "Error retrieving location";
        apiResponse = "Could not retrieve location.";
      });
    }
  }

  // Method to fetch data from the Weather API
  Future<void> fetchApiData(double lat, double lon) async {
    final String apiUrl =
        "https://api.weather.com/v3/location/near?geocode=$latitude,$longitude&product=PWS&format=json&apiKey=$apiKey";

    try {
      final response = await http.get(Uri.parse(apiUrl)); // Make the API request

      if (response.statusCode == 200) {
        // Decode the JSON response
        final data = json.decode(response.body);

        setState(() {
          apiResponse = "Data retrieved:\n${data.toString()}"; // Display the API data
        });
      } else {
        setState(() {
          apiResponse = "Error retrieving data: ${response.statusCode}"; // Handle non-200 status codes
        });
      }
    } catch (e) {
      setState(() {
        apiResponse = "Error connecting to the API: $e"; // Handle connection errors
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather API Demo'),
        backgroundColor: Colors.blueAccent,
        centerTitle: true, // Center the title in the app bar
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Latitude: $latitude"), // Display latitude
            Text("Longitude: $longitude"), // Display longitude
            const SizedBox(height: 20), // Add some spacing
            Text("API Response:"),
            Text(
              apiResponse, // Display the API response
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
