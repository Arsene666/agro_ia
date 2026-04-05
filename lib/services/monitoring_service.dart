import 'package:firebase_database/firebase_database.dart';
import 'alert_service.dart';
import '../models/alert.dart';
import '../models/sensor_data.dart';

class MonitoringService {
  final AlertService _alertService = AlertService();
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  // Seuils d'alerte (à configurer)
  static const double _maxTemp = 35.0;
  static const double _minTemp = 15.0;
  static const double _maxHumidity = 85.0;
  static const double _minHumidity = 40.0;

  // Dernière alerte envoyée pour éviter les spams
  DateTime? _lastTempAlert;
  DateTime? _lastHumidityAlert;
  static const Duration _alertCooldown = Duration(minutes: 30);

  // Vérifier les données des capteurs
  Future<void> checkSensorData(SensorData sensor) async {
    await _checkTemperature(sensor.temperature);
    await _checkHumidity(sensor.humidity);
  }

  // Vérifier la température
  Future<void> _checkTemperature(double temperature) async {
    if (temperature > _maxTemp) {
      // Vérifier si on peut envoyer une nouvelle alerte
      if (_lastTempAlert == null ||
          DateTime.now().difference(_lastTempAlert!) > _alertCooldown) {

        await _alertService.createAlert(
          titre: 'Température critique',
          description: 'Température de ${temperature.toStringAsFixed(1)}°C dépasse le seuil maximum de ${_maxTemp}°C.',
          type: AlertType.temperature,
          severity: temperature > _maxTemp + 5 ? AlertSeverity.critical : AlertSeverity.high,
          metadata: {'temperature': temperature, 'threshold': _maxTemp},
        );

        _lastTempAlert = DateTime.now();
      }
    }
    else if (temperature < _minTemp) {
      if (_lastTempAlert == null ||
          DateTime.now().difference(_lastTempAlert!) > _alertCooldown) {

        await _alertService.createAlert(
          titre: 'Température basse',
          description: 'Température de ${temperature.toStringAsFixed(1)}°C est inférieure au seuil minimum de ${_minTemp}°C.',
          type: AlertType.temperature,
          severity: temperature < _minTemp - 5 ? AlertSeverity.high : AlertSeverity.medium,
          metadata: {'temperature': temperature, 'threshold': _minTemp},
        );

        _lastTempAlert = DateTime.now();
      }
    }
  }

  // Vérifier l'humidité
  Future<void> _checkHumidity(double humidity) async {
    if (humidity > _maxHumidity) {
      if (_lastHumidityAlert == null ||
          DateTime.now().difference(_lastHumidityAlert!) > _alertCooldown) {

        await _alertService.createAlert(
          titre: 'Humidité excessive',
          description: 'Humidité de ${humidity.toStringAsFixed(0)}% dépasse le seuil maximum de ${_maxHumidity}%. Risque de moisissure.',
          type: AlertType.humidity,
          severity: humidity > _maxHumidity + 10 ? AlertSeverity.high : AlertSeverity.medium,
          metadata: {'humidity': humidity, 'threshold': _maxHumidity},
        );

        _lastHumidityAlert = DateTime.now();
      }
    }
    else if (humidity < _minHumidity) {
      if (_lastHumidityAlert == null ||
          DateTime.now().difference(_lastHumidityAlert!) > _alertCooldown) {

        await _alertService.createAlert(
          titre: 'Air trop sec',
          description: 'Humidité de ${humidity.toStringAsFixed(0)}% est inférieure au seuil minimum de ${_minHumidity}%.',
          type: AlertType.humidity,
          severity: AlertSeverity.medium,
          metadata: {'humidity': humidity, 'threshold': _minHumidity},
        );

        _lastHumidityAlert = DateTime.now();
      }
    }
  }

  // Vérifier les stocks (expiration)
  Future<void> checkStockExpiry(List<dynamic> stocks) async {
    for (var stock in stocks) {
      final daysLeft = stock.daysSinceHarvest;

      if (daysLeft <= 0) {
        await _alertService.createAlert(
          titre: 'Stock périmé',
          description: '${stock.productName} est périmé depuis ${-daysLeft} jours.',
          type: AlertType.stock,
          severity: AlertSeverity.critical,
          metadata: {'product': stock.productName, 'daysLeft': daysLeft},
        );
      }
      else if (daysLeft <= 3) {
        await _alertService.createAlert(
          titre: 'Expiration imminente',
          description: '${stock.productName} expire dans $daysLeft jours.',
          type: AlertType.stock,
          severity: AlertSeverity.high,
          metadata: {'product': stock.productName, 'daysLeft': daysLeft},
        );
      }
      else if (daysLeft <= 7) {
        await _alertService.createAlert(
          titre: 'Attention stock',
          description: '${stock.productName} expire dans $daysLeft jours.',
          type: AlertType.stock,
          severity: AlertSeverity.medium,
          metadata: {'product': stock.productName, 'daysLeft': daysLeft},
        );
      }
    }
  }
}