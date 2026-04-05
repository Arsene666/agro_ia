import 'package:firebase_database/firebase_database.dart';
import '../models/alert.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/stock_item.dart';

class AlertService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  static const String _alertsPath = 'alerts';

// =========================================================
//  CONFIGURATION TWILIO
// =========================================================
  static const String _twilioAccountSid =
  String.fromEnvironment('TWILIO_ACCOUNT_SID', defaultValue: '');
  static const String _twilioAuthToken =
  String.fromEnvironment('TWILIO_AUTH_TOKEN', defaultValue: '');
  static const String _twilioFromNumber =
  String.fromEnvironment('TWILIO_FROM', defaultValue: '');

  // Seuils capteurs
  static const double _tempMax  = 30.0;
  static const double _tempMin  = 10.0;
  static const double _humidMax = 80.0;
  static const double _humidMin = 30.0;

  // =========================================================
  // CONFIGURATION NUMÉRO SMS
  // =========================================================
  static String _smsPhoneNumber = '+33745765574';

  void setSmsPhoneNumber(String phoneNumber) {
    _smsPhoneNumber = phoneNumber;
    _db.child('settings/sms_phone').set(phoneNumber);
  }

  Future<String?> getSmsPhoneNumber() async {
    final snapshot = await _db.child('settings/sms_phone').get();
    return snapshot.exists ? snapshot.value as String : _smsPhoneNumber;
  }

  // =========================================================
  // CRÉER UNE ALERTE
  // =========================================================
  Future<void> createAlert({
    required String titre,
    required String description,
    required AlertType type,
    required AlertSeverity severity,
    Map<String, dynamic>? metadata,
  }) async {
    final now = DateTime.now();
    final alertId = now.millisecondsSinceEpoch.toString();

    final alert = Alert(
      id: alertId,
      titre: titre,
      description: description,
      time: _formatTime(now),
      type: type,
      severity: severity,
      createdAt: now,
      metadata: metadata,
    );

    await _db.child('$_alertsPath/$alertId').set(alert.toMap());

    // SMS uniquement pour critique/haute sévérité
    if (severity == AlertSeverity.critical || severity == AlertSeverity.high) {
      await sendSmsAlert(alert);
    }
  }

  // =========================================================
  // VÉRIFICATION CAPTEURS
  // =========================================================
  Future<void> checkSensorAndAlert({
    required double temperature,
    required double humidity,
  }) async {
    if (temperature > _tempMax) {
      if (!await _alertExistsRecently('temperature', 30)) {
        await createAlert(
          titre: 'Température critique',
          description: 'Température élevée : ${temperature.toStringAsFixed(1)}°C (seuil max : ${_tempMax}°C). Risque de dégradation.',
          type: AlertType.temperature,
          severity: AlertSeverity.high,
        );
      }
    }
    if (temperature < _tempMin) {
      if (!await _alertExistsRecently('temperature', 30)) {
        await createAlert(
          titre: 'Température trop basse',
          description: 'Température basse : ${temperature.toStringAsFixed(1)}°C (seuil min : ${_tempMin}°C).',
          type: AlertType.temperature,
          severity: AlertSeverity.medium,
        );
      }
    }
    if (humidity > _humidMax) {
      if (!await _alertExistsRecently('humidity', 30)) {
        await createAlert(
          titre: "Pic d'humidité",
          description: 'Humidité élevée : ${humidity.toStringAsFixed(0)}% (seuil max : ${_humidMax}%). Vérifiez la ventilation.',
          type: AlertType.humidity,
          severity: AlertSeverity.medium,
        );
      }
    }
    if (humidity < _humidMin) {
      if (!await _alertExistsRecently('humidity', 30)) {
        await createAlert(
          titre: 'Humidité insuffisante',
          description: 'Humidité trop basse : ${humidity.toStringAsFixed(0)}% (seuil min : ${_humidMin}%).',
          type: AlertType.humidity,
          severity: AlertSeverity.low,
        );
      }
    }
  }

  // =========================================================
  // VÉRIFICATION STOCKS
  // =========================================================
  Future<void> checkStocksAndAlert(List<StockItem> stocks) async {
    for (final stock in stocks) {
      if (stock.stockStatus == 'expired') {
        if (!await _alertExistsRecently('stock', 1440)) {
          await createAlert(
            titre: 'Stock périmé',
            description: '${stock.productName} (${stock.quantity} ${stock.unit}) est périmé. À éliminer immédiatement.',
            type: AlertType.stock,
            severity: AlertSeverity.critical,
            metadata: {'stockId': stock.id, 'location': stock.location},
          );
        }
      } else if (stock.stockStatus == 'critical') {
        if (!await _alertExistsRecently('stock', 360)) {
          await createAlert(
            titre: 'Stock critique',
            description: '${stock.productName} (${stock.quantity} ${stock.unit}) arrive à expiration. Priorisez son écoulement.',
            type: AlertType.stock,
            severity: AlertSeverity.high,
            metadata: {'stockId': stock.id, 'location': stock.location},
          );
        }
      }
    }
  }

  // =========================================================
  //  RÉCUPÉRER LES ALERTES — CORRIGÉ
  // =========================================================
  Future<List<Alert>> getAllAlerts() async {
    try {
      final snapshot = await _db.child(_alertsPath).get();
      if (!snapshot.exists) return [];

      final data = snapshot.value as Map<dynamic, dynamic>;
      final alerts = <Alert>[];

      for (final entry in data.entries) {
        try {
          // Conversion propre sans cast invalide
          final typedData = Map<String, dynamic>.from(entry.value as Map);
          // fromMap(map, id) — Map en 1er, String id en 2ème
          alerts.add(Alert.fromMap(entry.key.toString(), typedData));
        } catch (e) {
          print('Erreur parsing alerte ${entry.key}: $e');
        }
      }

      alerts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return alerts;
    } catch (e) {
      print('Erreur récupération alertes: $e');
      return [];
    }
  }

  Future<List<Alert>> getUnreadAlerts() async {
    final all = await getAllAlerts();
    return all.where((a) => !a.isRead).toList();
  }

  // STREAM
  Stream<List<Alert>> watchAlerts() {
    return _db.child(_alertsPath).onValue.map((event) {
      if (!event.snapshot.exists) return <Alert>[];

      final data = event.snapshot.value as Map<dynamic, dynamic>;
      final alerts = <Alert>[];

      for (final entry in data.entries) {
        try {
          final typedData = Map<String, dynamic>.from(entry.value as Map);
          alerts.add(Alert.fromMap(entry.key.toString(), typedData));
        } catch (e) {
          print('Erreur parsing alerte stream ${entry.key}: $e');
        }
      }

      alerts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return alerts;
    });
  }

  // =========================================================
  // ACTIONS SUR LES ALERTES
  // =========================================================
  Future<void> markAsRead(String alertId) async {
    await _db.child('$_alertsPath/$alertId/isRead').set(true);
  }

  Future<void> markAllAsRead() async {
    final alerts = await getAllAlerts();
    for (final alert in alerts) {
      if (!alert.isRead) await markAsRead(alert.id);
    }
  }

  Future<void> deleteAlert(String alertId) async {
    await _db.child('$_alertsPath/$alertId').remove();
  }

  Future<void> clearAllAlerts() async {
    await _db.child(_alertsPath).remove();
  }

  Future<void> deleteOldAlerts() async {
    final alerts = await getAllAlerts();
    final limit = DateTime.now().subtract(const Duration(days: 30));
    for (final alert in alerts) {
      if (alert.createdAt.isBefore(limit)) await deleteAlert(alert.id);
    }
  }

  // =========================================================
  // ENVOI SMS VIA TWILIO
  // =========================================================
  Future<bool> sendSmsAlert(Alert alert) async {
    try {
      final url = Uri.parse(
        'https://api.twilio.com/2010-04-01/Accounts/$_twilioAccountSid/Messages.json',
      );

      final emoji = (alert.severity == AlertSeverity.critical ||
          alert.severity == AlertSeverity.high)
          ? '🚨'
          : '⚠️';

      final smsBody =
          ' AGRO-IA ALERTE\n$emoji ${alert.titre}\n${alert.description}\n🕐 ${alert.time}';

      final response = await http.post(
        url,
        headers: {
          'Authorization':
          'Basic ${base64Encode(utf8.encode('$_twilioAccountSid:$_twilioAuthToken'))}',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'From': _twilioFromNumber,
          'To': _smsPhoneNumber,
          'Body': smsBody,
        },
      );

      if (response.statusCode == 201) {
        print('[AlertService] SMS envoyé avec succès');
        await _db.child('$_alertsPath/${alert.id}').update({'smsSent': true});
        return true;
      } else {
        print('[AlertService] Erreur SMS: ${response.statusCode} ${response.body}');
        return false;
      }
    } catch (e) {
      print('[AlertService] Exception SMS: $e');
      return false;
    }
  }

  // =========================================================
  // HELPERS PRIVÉS
  // =========================================================
  Future<bool> _alertExistsRecently(String typeKey, int minutes) async {
    try {
      final since = DateTime.now()
          .subtract(Duration(minutes: minutes))
          .millisecondsSinceEpoch;
      final snapshot = await _db.child(_alertsPath).get();
      if (!snapshot.exists) return false;
      final data = snapshot.value as Map<dynamic, dynamic>;
      return data.values.any((v) {
        final map = v as Map;
        final ts = (map['createdAt'] as int?) ?? 0;
        final type = map['type']?.toString() ?? '';
        return ts >= since && type.contains(typeKey);
      });
    } catch (_) {
      return false;
    }
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}