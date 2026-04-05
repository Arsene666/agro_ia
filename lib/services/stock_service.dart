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
      print('Erreur sauvegarde: $e');
      return false;
    }
  }

  // Récupérer tous les stocks
  Future<List<StockItem>> getAllStocks() async {
    try {
      final snapshot = await _db.child('stocks').get();

      List<StockItem> stocks = [];

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;

        for (var entry in data.entries) {
          final key = entry.key.toString();
          final value = entry.value as Map<dynamic, dynamic>;

          Map<String, dynamic> typedData = {};
          value.forEach((k, v) {
            typedData[k.toString()] = v;
          });

          stocks.add(StockItem.fromMap(typedData, key));
        }
      }

      // Trier par date de création (plus récent d'abord)
      stocks.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      print('Stocks chargés: ${stocks.length}'); // Debug
      return stocks;
    } catch (e) {
      print('Erreur récupération stocks: $e');
      return [];
    }
  }

  // Récupérer les stocks critiques (expiration proche)
  Future<List<StockItem>> getCriticalStocks() async {
    final allStocks = await getAllStocks();
    return allStocks.where((stock) =>
    stock.stockStatus == 'critical' || stock.stockStatus == 'expired'
    ).toList();
  }

  // Ajouter un nouveau stock
  Future<void> addStock(StockItem stock) async {
    try {
      await _db.child('stocks/${stock.id}').set(stock.toMap());
    } catch (e) {
      throw Exception('Erreur ajout stock: $e');
    }
  }

  // Mettre à jour un stock
  Future<void> updateStock(StockItem stock) async {
    try {
      await _db.child('stocks/${stock.id}').update(stock.toMap());
    } catch (e) {
      throw Exception('Erreur mise à jour stock: $e');
    }
  }

  // Supprimer un stock
  Future<void> deleteStock(String id) async {
    try {
      await _db.child('stocks/$id').remove();
      // Supprimer aussi les prédictions associées
      await _db.child('lot_predictions/$id').remove();
    } catch (e) {
      throw Exception('Erreur suppression stock: $e');
    }
  }

  // Écouter les changements en temps réel
  Stream<List<StockItem>> watchStocks() {
    return _db
        .child('stocks')
        .onValue
        .map((event) {
      List<StockItem> stocks = [];

      if (event.snapshot.exists) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;

        data.forEach((key, value) {
          final stockData = value as Map<dynamic, dynamic>;
          Map<String, dynamic> typedData = {};
          stockData.forEach((k, v) {
            typedData[k.toString()] = v;
          });

          stocks.add(StockItem.fromMap(typedData, key.toString()));
        });
      }

      stocks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return stocks;
    });
  }
}