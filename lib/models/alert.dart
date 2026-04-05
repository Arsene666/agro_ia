import 'package:flutter/material.dart';


class Alert {
  final String id;
  final AlertType  type;       // 'temperature', 'humidity', 'stock_critical', 'stock_expired'
  final String titre;
  final String description;
  final String time;
  final AlertSeverity severity;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;
  final bool smsSent;

  Alert({
    required this.id,
    required this.type,
    required this.titre,
    required this.time,
    required this.description,
    required this.severity,
    this.isRead = false,
    required this.createdAt,
    this.metadata,
    this.smsSent = false,
  });

  factory Alert.fromMap(String id, Map<String, dynamic> map) {
    return Alert(
      id: id,
      type: _parseAlertType(map['type']),
      titre: map['titre'] ?? '',
      description: map['description'] ?? '',
      time: map['time'] ?? '',
      severity: _parseAlertSeverity(map['severity']),
      isRead: map['isRead'] ?? false,
      smsSent: map['smsSent'] as bool? ?? false,
      createdAt: DateTime.parse(map['createdAt']),
      metadata: map['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'titre': titre,
      'time': time,
      'type': type.toString().split('.').last,
      'severity': severity.toString().split('.').last,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'metadata': metadata,
      'smsSent': smsSent,
    };
  }

  static AlertType _parseAlertType(String? type) {
    switch (type) {
      case 'temperature':
        return AlertType.temperature;
      case 'humidity':
        return AlertType.humidity;
      case 'stock':
        return AlertType.stock;
      case 'battery':
        return AlertType.battery;
      case 'system':
        return AlertType.system;
      default:
        return AlertType.system;
    }
  }

  static AlertSeverity _parseAlertSeverity(String? severity) {
    switch (severity) {
      case 'critical':
        return AlertSeverity.critical;
      case 'high':
        return AlertSeverity.high;
      case 'medium':
        return AlertSeverity.medium;
      default:
        return AlertSeverity.low;
    }
  }

  Color get color {
    switch (severity) {
      case AlertSeverity.critical:
        return Colors.red;
      case AlertSeverity.high:
        return Colors.orange;
      case AlertSeverity.medium:
        return Colors.yellow.shade700;
      default:
        return Colors.grey;
    }
  }

  Color get bgColor {
    switch (severity) {
      case AlertSeverity.critical:
        return Colors.red.shade50;
      case AlertSeverity.high:
        return Colors.orange.shade50;
      case AlertSeverity.medium:
        return Colors.yellow.shade50;
      default:
        return Colors.grey.shade50;
    }
  }

  IconData get icon {
    switch (type) {
      case AlertType.temperature:
        return Icons.thermostat_rounded;
      case AlertType.humidity:
        return Icons.water_drop_rounded;
      case AlertType.stock:
        return Icons.inventory_2_rounded;
      case AlertType.battery:
        return Icons.battery_alert_rounded;
      default:
        return Icons.warning_amber_rounded;
    }
  }


}

enum AlertType {
  temperature,
  humidity,
  stock,
  battery,
  system, general,
}

enum AlertSeverity {
  low,     // Info
  medium,  // Warning
  high,    // Urgent
  critical,// Critique
}

