import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart'; // Library for obtaining geolocation
import 'package:http/http.dart' as http; // Library for making HTTP requests
import 'dart:convert'; // Library for working with JSON

//import 'package:intl/intl.dart';
import 'package:statistics/statistics.dart';
import 'package:intl/intl.dart';

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
  Map<String, dynamic> bestStation = {}; // Variable for the best station map
  Map<String, dynamic> observationData = {}; //variable for the observation api data

  final String apiKey = "026cda1f35b54cddacda1f35b53cdda3"; // Your API key

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

        // The data we're going to use from the first API
        final stationsIds = data['location']['stationId'];
        final updateTimes = data['location']['updateTimeUtc'];
        final distances = data['location']['distanceKm'];

        // We map the stations
        final List<Map<String, dynamic>> stations = [];
        for (int i = 0; i < stationsIds.length; i++) {
        stations.add({
          'stationId': stationsIds[i].toString(),
          'updateTime': updateTimes[i],
          'distance': distances[i].toDouble(),
        });
      }

      // Sort the stations by update time, descending
      stations.sort((a, b) => b['updateTime'].compareTo(a['updateTime']));

      // Select the station with the most recent update
      setState(() {
        bestStation = stations.first; // Take the station with the most recent update
      });


        // Refresh and print the data
        setState(() {
          bestStation = bestStation;
        });
        print("Estación seleccionada:");
        print("ID: ${bestStation['stationId']}");
        print("Última actualización: ${bestStation['updateTime']}");
        print("Distancia: ${bestStation['distance']} km");

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

    //best state validation 
    if (bestStation.isNotEmpty && bestStation.containsKey('stationId')){
      await fetchStationData(bestStation['stationId']);
      await fetchWeekData(bestStation['stationId']);
    } else {
      setState(() {
        apiResponse = "No valid station";
      });
    }
    
  }

  //funtion for obtaining weather station data
  Future<void> fetchStationData(String stationId) async {
    //Api URL
    final String observationApiUrl = 
      "https://api.weather.com/v2/pws/observations/current?stationId=${bestStation['stationId']}&format=json&units=m&apiKey=$apiKey"
    ;

    //get response and map data
    try {
      final response = await http.get(Uri.parse(observationApiUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        final observation = data['observations'] [0];

        setState(() {
          observationData = {
            "LocalTime": observation['obsTimeLocal'],
            "Neighborhood": observation['neighborhood'],
            "Country": observation['country'],
            "Humidity": observation['humidity'],
            "Temperature": observation['metric'] ['temp'],
            "windSpeed": observation['metric'] ['windSpeed'],
            "precipTotal": observation['metric'] ['precipTotal'],
          };
        });
      }
    } catch (e) {
      print("Error: $e");
    } finally {
      print('always');
    }
  }

  //Weather summary
  Future<void> fetchWeekData(String stationId) async {
  // URL of the API
  final String weekAPIUrl =
      "https://api.weather.com/v2/pws/dailysummary/7day?stationId=IVILLA166&format=json&units=m&apiKey=$apiKey";

  try {
    //Call Api
    final responseWeekApi = await http.get(Uri.parse(weekAPIUrl));

    //If we get a response
    if (responseWeekApi.statusCode == 200) {
      //Decode the JSON
      final dataWeekApi = json.decode(responseWeekApi.body);
      //get data
      final summaries = dataWeekApi['summaries'];

      if (summaries != null) {
        Map<DateTime, List<dynamic>> groupedByDay = {};

        for (var entry in summaries) {
          // get the dates
          String obsDateStr = entry['obsTimeLocal'].split(' ')[0];
          DateTime obsDate = DateFormat('yyyy-MM-dd').parse(obsDateStr);

          groupedByDay.putIfAbsent(obsDate, () => []).add(entry);
        }

        // Variables for the calculations
        double totalPrecipitation = 0;
        int daysWithData = 0;
        List<double> precipitationValues = [];

        // Browse throght the saved data
        groupedByDay.forEach((date, entries) {
          List<double> precipTotal = entries
              .where((e) => e['metric']?['precipTotal'] != null)
              .map((e) => e['metric']['precipTotal'] as double)
              .toList();

          double dailyPrecipitation =
              precipTotal.isNotEmpty ? precipTotal.reduce((a, b) => a + b) : 0;

          // Refresh data
          totalPrecipitation += dailyPrecipitation;
          if (dailyPrecipitation > 0) daysWithData++;
          precipitationValues.add(dailyPrecipitation);
        });

        // Calculate avg and standar deviation
        double avgPrecipitation = totalPrecipitation / 7;

        double stdDev = precipitationValues.standardDeviation;

        //Calculate the spi
        double spi = stdDev > 0
            ? (totalPrecipitation - avgPrecipitation) / stdDev
            : 0;

        // Refresh states
        setState(() {
          observationData['totalPrecipitation'] = totalPrecipitation;
          observationData['avgPrecipitation'] = avgPrecipitation;
          observationData['stdDev'] = stdDev;
          observationData['SPI'] = spi.toStringAsFixed(2);
        });

        print("Total Precipitation: $totalPrecipitation");
        print("Average Precipitation: $avgPrecipitation");
        print("Standard Deviation: $stdDev");
        print("SPI Value: ${spi.toStringAsFixed(2)}");
      } else {
        print("No se encontraron resúmenes en la respuesta de la API.");
      }
    } else {
      print("Error al obtener datos: ${responseWeekApi.statusCode}");
    }
  } catch (e) {
    print("Error: $e");
  } finally {
    print('Finalizado fetchWeekData');
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
            
            /*
            Text("API Response:"),
            Text(
              apiResponse, // Display the API response
              textAlign: TextAlign.center,
            ),
            */

            // When we get the optimal station, show the selected ID and update time
            if (bestStation.isNotEmpty) ...[
              Text("Selected Station ID: ${bestStation['stationId']}"),
              Text("Última actualización: ${bestStation['updateTime']}"),
              Text("Distancia: ${bestStation['distance']} km"),
            ] else
              const Text("No stations available"),
            
            //show data when recived from the Weather Station
            if (observationData.isNotEmpty) ...[
              Text("Local Time: ${observationData['LocalTime']}"),
              Text("Neighborhood: ${observationData['Neighborhood']}"),
              Text("Country: ${observationData['Country']}"),
              Text("Humidity: ${observationData['Humidity']} %"),
              Text("Temperature: ${observationData['Temperature']} °C "),
              Text("Wind Speed: ${observationData['windSpeed']} km/h"),
              Text("Precipitation: ${observationData['precipTotal']} mm"),
            ] else
              const Text("No stations available"),
            
            if (observationData.containsKey('totalPrecipitation')) ...[
                        Text("Total Precipitation: ${observationData['totalPrecipitation']} mm"),
                        Text("Avg Precipitation: ${observationData['avgPrecipitation']} mm"),
                        Text("Standard Deviation: ${observationData['stdDev']} mm"),
                        Text("SPI: ${observationData['SPI']}"),
            ],
          ],
        ),
      ),
    );
  }
}
