import 'package:firebase_database/firebase_database.dart';
import '../models/stock_item.dart';

class StockService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  // Sauvegarder un produit dans le stock
  Future<bool> saveStockItem(StockItem item) async {
    try {
      await _db.child('stocks').child(item.id).set(item.toMap());
      return true;
    } catch (e) {
      return false;
    }
  }

  // Lire tous les stocks en temps réel
  Stream<List<StockItem>> getStocksStream() {
    return _db.child('stocks').onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return [];
      return data.entries
          .map((e) => StockItem.fromMap(e.key.toString(), e.value))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }
}