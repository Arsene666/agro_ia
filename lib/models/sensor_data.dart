class SensorData {
  final double temperature;
  final double humidity;

  SensorData({
    required this.temperature,
    required this.humidity,
  });

  factory SensorData.fromMap(Map<dynamic, dynamic> map) {
    return SensorData(
      temperature: (map['temperature'] ?? 0).toDouble(),
      humidity: (map['humidity'] ?? 0).toDouble(),
    );
  }
}
