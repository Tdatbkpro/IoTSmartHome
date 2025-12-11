// weather_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class WeatherData {
  final double temperature;
  final int humidity;
  final String description;
  final String condition;

  WeatherData({
    required this.temperature,
    required this.humidity,
    required this.description,
    required this.condition,
  });
}

class WeatherService {
  Future<WeatherData> getWeatherData(double lat, double lng) async {
    try {
      // Sử dụng OpenWeatherMap API (cần đăng ký API key)
      final response = await http.get(Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lng&appid=5e291ca059d5853f4267a955694d957e&units=metric&lang=vi'
      ));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return WeatherData(
          temperature: data['main']['temp'].toDouble(),
          humidity: data['main']['humidity'],
          description: data['weather'][0]['description'],
          condition: data['weather'][0]['main'].toLowerCase(),
        );
      }
    } catch (e) {
      print('Lỗi weather API: $e');
    }

    // Fallback data
    return WeatherData(
      temperature: 26.0,
      humidity: 79,
      description: "Thời tiết đẹp, mát mẻ",
      condition: "clear",
    );
  }

  String getWeatherIcon(String condition) {
    switch (condition) {
      case 'clear':
        return '☀️';
      case 'clouds':
        return '☁️';
      case 'rain':
        return '🌧️';
      case 'drizzle':
        return '🌦️';
      case 'thunderstorm':
        return '⛈️';
      case 'snow':
        return '❄️';
      case 'mist':
      case 'fog':
        return '🌫️';
      default:
        return '🌤️';
    }
  }
}