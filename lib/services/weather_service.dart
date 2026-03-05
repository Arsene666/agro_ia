import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_data.dart';

class WeatherService {
  // Coordonnées par défaut (Dakar, Sénégal — adapte selon ton besoin)
  static const double _lat = 14.6928;
  static const double _lon = -17.4467;

  Future<WeatherData?> fetchWeather() async {
    try {
      final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast'
            '?latitude=$_lat&longitude=$_lon'
            '&current_weather=true'
            '&hourly=temperature_2m,weathercode'
            '&forecast_days=1'
            '&timezone=auto',
      );

      final response = await http.get(url);
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      final current = data['current_weather'];
      final hourlyTemps = List<double>.from(data['hourly']['temperature_2m']);
      final hourlyCodes = List<int>.from(data['hourly']['weathercode']);
      final hourlyTimes = List<String>.from(data['hourly']['time']);

      // Prendre les 6 prochaines heures à partir de maintenant
      final now = DateTime.now().hour;
      final hourly = List.generate(6, (i) {
        final index = (now + i).clamp(0, 23);
        return HourlyWeather(
          hour: '${index}h',
          temp: hourlyTemps[index],
          code: hourlyCodes[index],
        );
      });

      return WeatherData(
        temperature: current['temperature'].toDouble(),
        windspeed: current['windspeed'].toDouble(),
        weatherCode: current['weathercode'],
        hourly: hourly,
      );
    } catch (e) {
      return null;
    }
  }
}