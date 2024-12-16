import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class WeatherForecast {
  final DateTime time;
  final double temperature2m;
  final double relativeHumidity2m;
  final double precipitation;
  final double rain;
  final double uvIndex;

  WeatherForecast({
    required this.time,
    required this.temperature2m,
    required this.relativeHumidity2m,
    required this.precipitation,
    required this.rain,
    required this.uvIndex,
  });

  factory WeatherForecast.fromJson(DateTime time, double temp, double humidity,
      double precipitation, double rain, double uvIndex) {
    return WeatherForecast(
      time: time,
      temperature2m: temp,
      relativeHumidity2m: humidity,
      precipitation: precipitation,
      rain: rain,
      uvIndex: uvIndex,
    );
  }
}

class WeatherData {
  final String timezone;
  final String timezoneAbbreviation;
  final double latitude;
  final double longitude;
  final List<WeatherForecast> hourlyForecasts;

  WeatherData({
    required this.timezone,
    required this.timezoneAbbreviation,
    required this.latitude,
    required this.longitude,
    required this.hourlyForecasts,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    // Parse times
    List<dynamic> timesList = json['hourly']['time'];
    List<DateTime> times = timesList.map((t) => DateTime.parse(t)).toList();

    // Parse temperature
    List<dynamic> temperatureList = json['hourly']['temperature_2m'];

    // Parse humidity
    List<dynamic> humidityList = json['hourly']['relative_humidity_2m'];

    // Parse precipitation
    List<dynamic> precipitationList = json['hourly']['precipitation'];

    // Parse rain
    List<dynamic> rainList = json['hourly']['rain'];

    // Parse UV index
    List<dynamic> uvIndexList = json['hourly']['uv_index'];

    // Create hourly forecasts
    List<WeatherForecast> hourlyForecasts = [];
    for (int i = 0; i < times.length; i++) {
      hourlyForecasts.add(WeatherForecast.fromJson(
        times[i],
        temperatureList[i].toDouble(),
        humidityList[i].toDouble(),
        precipitationList[i].toDouble(),
        rainList[i].toDouble(),
        uvIndexList[i].toDouble(),
      ));
    }

    return WeatherData(
      timezone: json['timezone'] ?? 'America/Sao_Paulo',
      timezoneAbbreviation: json['timezone_abbreviation'] ?? 'BRT',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      hourlyForecasts: hourlyForecasts,
    );
  }
}

class WeatherNotifier extends StateNotifier<AsyncValue<WeatherData>> {
  WeatherNotifier() : super(const AsyncValue.loading());

  Future<void> fetchWeatherForecast() async {
    try {
      // Simulate delay
      await Future.delayed(const Duration(seconds: 2));

      // Open-Meteo API endpoint for Sorocaba
      final url = Uri.parse('https://api.open-meteo.com/v1/forecast'
          '?latitude=-23.5017'
          '&longitude=-47.4581'
          '&hourly=temperature_2m,relative_humidity_2m,precipitation,rain,uv_index'
          '&timezone=America%2FSao_Paulo');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final weatherData = WeatherData.fromJson(jsonResponse);

        state = AsyncValue.data(weatherData);
      } else {
        state = AsyncValue.error('Failed to load weather', StackTrace.current);
      }
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
    }
  }
}

// Provider for Weather State
final weatherProvider =
    StateNotifierProvider<WeatherNotifier, AsyncValue<WeatherData>>((ref) {
  return WeatherNotifier();
});
