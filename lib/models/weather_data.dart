class WeatherData {
  final double temperature;
  final double windspeed;
  final int weatherCode;
  final List<HourlyWeather> hourly;

  WeatherData({
    required this.temperature,
    required this.windspeed,
    required this.weatherCode,
    required this.hourly,
  });
}

class HourlyWeather {
  final String hour;
  final double temp;
  final int code;

  HourlyWeather({required this.hour, required this.temp, required this.code});
}