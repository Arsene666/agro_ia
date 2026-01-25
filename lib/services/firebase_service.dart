import 'package:firebase_database/firebase_database.dart';
import '../models/sensor_data.dart';

class FirebaseService {
  final DatabaseReference _dbRef =
      FirebaseDatabase.instance.ref("sensor");

  Stream<SensorData?> getSensorStream() {
    return _dbRef.onValue.map((event) {
      final snapshot = event.snapshot;

      if (snapshot.value == null) {
        return null;
      }

      final data = snapshot.value as Map<dynamic, dynamic>;
      return SensorData.fromMap(data);
    });
  }
}
