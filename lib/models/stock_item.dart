import 'package:flutter/material.dart';

class StockItem {
  final String id;
  final String productName;
  final double quantity;
  final String unit;
  final String harvestDateStr;
  final String harvestTime;
  final String location;
  DateTime? expiryDate;
  String? notes;
  final DateTime createdAt;

  // Champs pour les prédictions
  int? predictedExpiryDays;
  String? contaminationStatus;
  DateTime? lastPredictionUpdate;

  // Getter pour la date de récolte en DateTime
  DateTime get harvestDate => _parseDate(harvestDateStr, harvestTime);

  StockItem({
    required this.id,
    required this.productName,
    required this.quantity,
    required this.unit,
    required this.harvestDateStr,
    required this.harvestTime,
    required this.location,
    this.notes,
    required this.createdAt,
    this.expiryDate,
    this.predictedExpiryDays,
    this.contaminationStatus,
    this.lastPredictionUpdate,
  });

  Map<String, dynamic> toMap() {
    return {
      'productName': productName,
      'quantity': quantity,
      'unit': unit,
      'harvestDate': harvestDateStr,
      'harvestTime': harvestTime,
      'location': location,
      'notes': notes,
      'createdAt': createdAt.millisecondsSinceEpoch.toString(),
      if (expiryDate != null) 'expiryDate': expiryDate!.toIso8601String(),
      if (predictedExpiryDays != null) 'predictedExpiryDays': predictedExpiryDays,
      if (contaminationStatus != null) 'contaminationStatus': contaminationStatus,
      if (lastPredictionUpdate != null) 'lastPredictionUpdate': lastPredictionUpdate!.toIso8601String(),
    };
  }

  static DateTime _parseDate(String dateStr, String timeStr) {
    try {
      // Format: "1/3/2026"
      final parts = dateStr.split('/');
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);

        int hour = 0;
        int minute = 0;

        if (timeStr.isNotEmpty) {
          // Format: "10:06 AM"
          final timeParts = timeStr.split(' ');
          if (timeParts.length == 2) {
            final hm = timeParts[0].split(':');
            if (hm.length == 2) {
              hour = int.parse(hm[0]);
              minute = int.parse(hm[1]);

              if (timeParts[1].toUpperCase() == 'PM' && hour != 12) {
                hour += 12;
              } else if (timeParts[1].toUpperCase() == 'AM' && hour == 12) {
                hour = 0;
              }
            }
          }
        }

        return DateTime(year, month, day, hour, minute);
      }
    } catch (e) {
      print('Erreur parsing date: $e');
    }
    return DateTime.now();
  }

  factory StockItem.fromMap(Map<String, dynamic> map, String id) {
    print('Converting stock: $id'); // Debug
    print('Map data: $map'); // Debug

    return StockItem(
      id: id,
      productName: map['productName'] ?? 'Produit inconnu',
      quantity: (map['quantity'] ?? 0).toDouble(),
      unit: map['unit'] ?? 'kg',
      harvestDateStr: map['harvestDate'] ?? '',
      harvestTime: map['harvestTime'] ?? '',
      location: map['location'] ?? 'Non spécifié',
      notes: map['notes'],
      createdAt: _parseCreatedAt(map['createdAt']),
      expiryDate: map['expiryDate'] != null ? DateTime.parse(map['expiryDate']) : null,
      predictedExpiryDays: map['predictedExpiryDays'],
      contaminationStatus: map['contaminationStatus'],
      lastPredictionUpdate: map['lastPredictionUpdate'] != null
          ? DateTime.parse(map['lastPredictionUpdate'])
          : null,
    );
  }

  static DateTime _parseCreatedAt(dynamic createdAtValue) {
    try {
      if (createdAtValue is String) {
        return DateTime.fromMillisecondsSinceEpoch(int.parse(createdAtValue));
      } else if (createdAtValue is int) {
        return DateTime.fromMillisecondsSinceEpoch(createdAtValue);
      } else if (createdAtValue is double) {
        return DateTime.fromMillisecondsSinceEpoch(createdAtValue.toInt());
      }
    } catch (e) {
      print('Erreur parsing createdAt: $e');
    }
    return DateTime.now();
  }

  // Calculer les jours depuis la récolte
  int get daysSinceHarvest {
    return DateTime.now().difference(harvestDate).inDays;
  }

  // Calculer le pourcentage de conservation
  double get conservationPercentage {
    if (expiryDate == null) return 100;
    final totalDays = expiryDate!.difference(harvestDate).inDays;
    if (totalDays <= 0) return 0;
    final daysLeft = expiryDate!.difference(DateTime.now()).inDays;
    return (daysLeft / totalDays * 100).clamp(0, 100);
  }

  // Statut de l'état du stock
  String get stockStatus {
    if (expiryDate == null) return 'good';
    final daysLeft = expiryDate!.difference(DateTime.now()).inDays;

    if (daysLeft <= 0) return 'expired';
    if (daysLeft <= 3) return 'critical';
    if (daysLeft <= 7) return 'warning';
    return 'good';
  }

  // Couleur selon le statut
  Color get statusColor {
    switch (stockStatus) {
      case 'expired':
        return Colors.red;
      case 'critical':
        return Colors.orange;
      case 'warning':
        return Colors.yellow.shade700;
      default:
        return Colors.green;
    }
  }

  // Icône selon le statut
  IconData get statusIcon {
    switch (stockStatus) {
      case 'expired':
        return Icons.warning_amber_rounded;
      case 'critical':
        return Icons.priority_high;
      case 'warning':
        return Icons.info_outline;
      default:
        return Icons.check_circle_outline;
    }
  }
}