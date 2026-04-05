import 'package:firebase_database/firebase_database.dart';
import '../models/stock_item.dart';

class PredictionService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // Récupérer les prédictions pour un lot spécifique
  Future<Map<String, dynamic>?> getLotPrediction(String lotId) async {
    try {
      final snapshot = await _database.child('lot_predictions/$lotId').get();

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        Map<String, dynamic> typedData = {};
        data.forEach((key, value) {
          typedData[key.toString()] = value;
        });
        return typedData;
      }
      return null;
    } catch (e) {
      print('Erreur récupération prédiction: $e');
      return null;
    }
  }

  // Mettre à jour les prédictions pour un stock
  Future<void> updateStockPredictions(StockItem stock) async {
    try {
      // Calculer les prédictions basées sur le type de produit et les conditions
      final predictions = _calculatePredictions(stock);

      await _database.child('lot_predictions/${stock.id}').set({
        'product_name': stock.productName,
        'quantity': stock.quantity,
        'harvest_date': stock.harvestDate.toIso8601String(),
        'predicted_expiry_days': predictions['expiryDays'],
        'contamination_risk': predictions['contaminationRisk'],
        'recommended_action': predictions['recommendedAction'],
        'status': predictions['status'],
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Mettre à jour le stock avec les prédictions
      await _database.child('stocks/${stock.id}').update({
        'predictedExpiryDays': predictions['expiryDays'],
        'contaminationStatus': predictions['contaminationRisk'],
        'lastPredictionUpdate': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Erreur mise à jour prédictions: $e');
    }
  }

  // Calculer les prédictions (à améliorer)
  Map<String, dynamic> _calculatePredictions(StockItem stock) {
    // Facteurs influençant la conservation
    final productType = stock.productName.toLowerCase();
    final daysSinceHarvest = stock.daysSinceHarvest;

    // Durée de conservation estimée selon le produit
    int estimatedShelfLife = _getEstimatedShelfLife(productType);
    double daysLeft = (estimatedShelfLife - daysSinceHarvest) as double;

    // Évaluer le risque de contamination
    String contaminationRisk = _evaluateContaminationRisk(stock, daysLeft as int);

    // Statut global
    String status;
    if (daysLeft <= 0) {
      status = 'expired';
    } else if (daysLeft <= 3) {
      status = 'critical';
    } else if (daysLeft <= 7) {
      status = 'warning';
    } else {
      status = 'good';
    }

    // Action recommandée
    String recommendedAction;
    if (status == 'expired') {
      recommendedAction = 'Éliminer immédiatement';
    } else if (status == 'critical') {
      recommendedAction = 'Utiliser en urgence ou transformer';
    } else if (status == 'warning') {
      recommendedAction = 'Prioriser la vente/utilisation';
    } else {
      recommendedAction = 'Stockage normal, surveiller régulièrement';
    }

    return {
      'expiryDays': daysLeft.clamp(0, 999),
      'contaminationRisk': contaminationRisk,
      'status': status,
      'recommendedAction': recommendedAction,
    };
  }

  int _getEstimatedShelfLife(String productType) {
    if (productType.contains('tomate')) return 14;
    if (productType.contains('pomme')) return 30;
    if (productType.contains('banane')) return 7;
    if (productType.contains('carotte')) return 21;
    if (productType.contains('laitue')) return 5;
    return 10; // Valeur par défaut
  }

  String _evaluateContaminationRisk(StockItem stock, int daysLeft) {
    // Facteurs de risque
    List<String> risks = [];

    if (daysLeft <= 0) {
      risks.add('Produit périmé');
    } else if (daysLeft <= 3) {
      risks.add('Conservation critique');
    }

    if (stock.notes != null && stock.notes!.toLowerCase().contains('moisissure')) {
      risks.add('Signes de moisissure');
    }

    if (risks.isEmpty) {
      return 'Faible';
    } else if (risks.length == 1) {
      return 'Moyen';
    } else {
      return 'Eleve';
    }
  }

  // Analyser tous les stocks et générer des alertes
  Future<List<Map<String, dynamic>>> analyzeAllStocks(List<StockItem> stocks) async {
    List<Map<String, dynamic>> alerts = [];

    for (var stock in stocks) {
      final prediction = await getLotPrediction(stock.id);

      if (prediction != null) {
        final status = prediction['status'];
        final risk = prediction['contamination_risk'];

        if (status == 'expired') {
          alerts.add({
            'type': 'expired',
            'product': stock.productName,
            'message': '${stock.productName} est périmé et doit être éliminé',
            'severity': 'high',
            'stockId': stock.id,
          });
        } else if (status == 'critical') {
          alerts.add({
            'type': 'critical',
            'product': stock.productName,
            'message': '${stock.productName} arrive à expiration dans ${prediction['predicted_expiry_days']} jours',
            'severity': 'high',
            'stockId': stock.id,
          });
        } else if (risk == 'high') {
          alerts.add({
            'type': 'contamination',
            'product': stock.productName,
            'message': 'Risque de contamination élevé pour ${stock.productName}',
            'severity': 'medium',
            'stockId': stock.id,
          });
        }
      }
    }

    return alerts;
  }

  // Calculer le schéma d'écoulement des stocks
  Future<Map<String, dynamic>> calculateFlowSchema(List<StockItem> stocks) async {
    Map<String, dynamic> schema = {
      'totalQuantity': 0.0,
      'totalProducts': stocks.length,
      'byProductType': <String, Map<String, dynamic>>{},
      'byLocation': <String, Map<String, dynamic>>{},
      'criticalStocks': [],
      'recommendedActions': [],
    };

    double totalQuantity = 0;

    for (var stock in stocks) {
      totalQuantity += stock.quantity;

      // Par type de produit
      if (!schema['byProductType'].containsKey(stock.productName)) {
        schema['byProductType'][stock.productName] = {
          'quantity': 0.0,
          'count': 0,
          'avgConservation': 0.0,
        };
      }
      schema['byProductType'][stock.productName]['quantity'] += stock.quantity;
      schema['byProductType'][stock.productName]['count']++;

      // Par localisation
      if (!schema['byLocation'].containsKey(stock.location)) {
        schema['byLocation'][stock.location] = {
          'quantity': 0.0,
          'count': 0,
          'products': [],
        };
      }
      schema['byLocation'][stock.location]['quantity'] += stock.quantity;
      schema['byLocation'][stock.location]['count']++;
      schema['byLocation'][stock.location]['products'].add(stock.productName);

      // Stocks critiques
      if (stock.stockStatus == 'critical' || stock.stockStatus == 'expired') {
        schema['criticalStocks'].add({
          'id': stock.id,
          'product': stock.productName,
          'quantity': stock.quantity,
          'status': stock.stockStatus,
          'daysSinceHarvest': stock.daysSinceHarvest,
        });

        // Actions recommandées
        if (stock.stockStatus == 'critical') {
          schema['recommendedActions'].add({
            'product': stock.productName,
            'action': 'Prioriser la vente ou transformation de ${stock.productName}',
            'quantity': stock.quantity,
            'urgency': 'high',
          });
        }
      }
    }

    schema['totalQuantity'] = totalQuantity;

    // Calculer les moyennes de conservation
    for (var product in schema['byProductType'].keys) {
      final productData = schema['byProductType'][product];
      final productStocks = stocks.where((s) => s.productName == product).toList();
      double totalConservation = 0;
      for (var stock in productStocks) {
        totalConservation += stock.conservationPercentage;
      }
      productData['avgConservation'] = productStocks.isEmpty
          ? 0
          : totalConservation / productStocks.length;
    }

    return schema;
  }
}

extension on String {
  toIso8601String() {}
}