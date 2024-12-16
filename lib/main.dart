import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loading_indicator/loading_indicator.dart';
import './weather-state-provider.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(
    const ProviderScope(
      child: ClimateApp(),
    ),
  );
}

class ClimateApp extends StatelessWidget {
  const ClimateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sorocaba Climate App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const WeatherHomePage(),
    );
  }
}

class WeatherHomePage extends ConsumerStatefulWidget {
  const WeatherHomePage({super.key});

  @override
  ConsumerState<WeatherHomePage> createState() => _WeatherHomePageState();
}

class _WeatherHomePageState extends ConsumerState<WeatherHomePage> {
  final TextEditingController _locationController =
      TextEditingController(text: 'Sorocaba');
  bool _isCelsius = true;

  @override
  void initState() {
    super.initState();
    // Fetch weather when the page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(weatherProvider.notifier).fetchWeatherForecast();
    });
  }

  // Helper method to convert temperature
  double _convertTemperature(double celsius) {
    return _isCelsius ? celsius : (celsius * 9 / 5) + 32;
  }

  @override
  Widget build(BuildContext context) {
    // Use MediaQuery to adapt UI based on screen size
    final mediaQuery = MediaQuery.of(context);
    final orientation = mediaQuery.orientation;

    // Background color changes based on orientation
    Color backgroundColor = orientation == Orientation.portrait
        ? Colors.blue.shade100
        : Colors.blue.shade200;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Sorocaba Weather Forecast'),
      ),
      body: Column(
        children: [
          // Location Input and Settings
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _locationController,
                    decoration: InputDecoration(
                      labelText: 'Location',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () {
                          ref
                              .read(weatherProvider.notifier)
                              .fetchWeatherForecast();
                        },
                      ),
                    ),
                  ),
                ),
                // Temperature Unit Toggle
                Chip(
                  label: Text(_isCelsius ? '°C' : '°F'),
                  onDeleted: () {
                    setState(() {
                      _isCelsius = !_isCelsius;
                    });
                  },
                ),
              ],
            ),
          ),

          // Weather Forecast List
          Expanded(
            child: Consumer(
              builder: (context, ref, child) {
                final weatherState = ref.watch(weatherProvider);

                return weatherState.when(
                  data: (weatherData) => ListView.builder(
                    itemCount: weatherData.hourlyForecasts.length,
                    itemBuilder: (context, index) {
                      final forecast = weatherData.hourlyForecasts[index];
                      return InkWell(
                        onTap: () {
                          // Show detailed weather information
                          _showWeatherDetails(context, forecast);
                        },
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: IntrinsicHeight(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          DateFormat('EEE, MMM d HH:mm')
                                              .format(forecast.time),
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                            'UV Index: ${forecast.uvIndex.toStringAsFixed(1)}'),
                                      ],
                                    ),
                                  ),
                                  VerticalDivider(color: Colors.grey.shade300),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                          'Temp: ${_convertTemperature(forecast.temperature2m).toStringAsFixed(1)}°${_isCelsius ? 'C' : 'F'}'),
                                      Text(
                                          'Precipitation: ${(forecast.precipitation * 100).toStringAsFixed(0)}%'),
                                      Text(
                                          'Humidity: ${forecast.relativeHumidity2m.toStringAsFixed(0)}%'),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  loading: () => Center(
                    child: LoadingIndicator(
                      indicatorType: Indicator.ballRotateChase,
                      colors: [Colors.blue.shade700],
                    ),
                  ),
                  error: (error, stack) => Center(
                    child: Text('Error: $error'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Method to show detailed weather information
  void _showWeatherDetails(BuildContext context, WeatherForecast forecast) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(DateFormat('EEE, MMM d HH:mm').format(forecast.time)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  'Temperature: ${_convertTemperature(forecast.temperature2m).toStringAsFixed(1)}°${_isCelsius ? 'C' : 'F'}'),
              Text(
                  'Humidity: ${forecast.relativeHumidity2m.toStringAsFixed(0)}%'),
              Text(
                  'Precipitation: ${(forecast.precipitation * 100).toStringAsFixed(0)}%'),
              Text('Rain: ${(forecast.rain * 100).toStringAsFixed(0)}%'),
              Text('UV Index: ${forecast.uvIndex.toStringAsFixed(1)}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
