import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SensorHistoryService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  static const String _lastSaveKey = 'last_sensor_save';
  static const int _intervalDays = 3;

  // Appeler cette méthode à chaque lecture de capteur
  Future<void> maybeSaveSensorData({
    required double temperature,
    required double humidity,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final lastSave = prefs.getInt(_lastSaveKey) ?? 0;
    final lastSaveDate = DateTime.fromMillisecondsSinceEpoch(lastSave);
    final now = DateTime.now();

    // Sauvegarder si 3 jours se sont écoulés (ou première fois)
    if (now.difference(lastSaveDate).inDays >= _intervalDays) {
      await _saveSensorSnapshot(temperature, humidity, now);
      await prefs.setInt(_lastSaveKey, now.millisecondsSinceEpoch);
    }
  }

  Future<void> _saveSensorSnapshot(
      double temperature, double humidity, DateTime date) async {
    final key = date.millisecondsSinceEpoch.toString();
    await _db.child('sensor_history').child(key).set({
      'temperature': temperature,
      'humidity': humidity,
      'timestamp': date.toIso8601String(),
      'date': '${date.day}/${date.month}/${date.year}',
    });
  }

  // Lire l'historique des capteurs
  Stream<List<Map<String, dynamic>>> getHistoryStream() {
    return _db.child('sensor_history').onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return [];
      return data.entries.map((e) {
        final v = Map<String, dynamic>.from(e.value);
        return v;
      }).toList()
        ..sort((a, b) =>
            (b['timestamp'] as String).compareTo(a['timestamp'] as String));
    });
  }
}