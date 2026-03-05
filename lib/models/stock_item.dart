class StockItem {
  final String id;
  final String productName;
  final double quantity;
  final String unit;
  final String harvestDate;
  final String harvestTime;
  final String location;
  final String notes;
  final DateTime createdAt;

  StockItem({
    required this.id,
    required this.productName,
    required this.quantity,
    required this.unit,
    required this.harvestDate,
    required this.harvestTime,
    required this.location,
    required this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productName': productName,
      'quantity': quantity,
      'unit': unit,
      'harvestDate': harvestDate,
      'harvestTime': harvestTime,
      'location': location,
      'notes': notes,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory StockItem.fromMap(String id, Map<dynamic, dynamic> map) {
    return StockItem(
      id: id,
      productName: map['productName'] ?? '',
      quantity: (map['quantity'] ?? 0).toDouble(),
      unit: map['unit'] ?? 'kg',
      harvestDate: map['harvestDate'] ?? '',
      harvestTime: map['harvestTime'] ?? '',
      location: map['location'] ?? '',
      notes: map['notes'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
    );
  }
}