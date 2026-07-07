class BillItemModel {
  BillItemModel({
    this.id,
    required this.billId,
    required this.productId,
    required this.productName,
    required this.brand,
    required this.unitType,
    required this.quantity,
    required this.pricePerUnit,
    required this.lineTotal,
  });

  final int? id;
  final int billId;
  final int productId;
  final String productName;
  final String brand;
  final String unitType;
  final double quantity;
  final double pricePerUnit;
  final double lineTotal;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'billId': billId,
      'productId': productId,
      'productName': productName,
      'brand': brand,
      'unitType': unitType,
      'quantity': quantity,
      'pricePerUnit': pricePerUnit,
      'lineTotal': lineTotal,
    };
  }

  factory BillItemModel.fromMap(Map<String, dynamic> map) {
    return BillItemModel(
      id: map['id'] as int?,
      billId: map['billId'] as int,
      productId: map['productId'] as int,
      productName: map['productName'] as String,
      brand: map['brand'] as String,
      unitType: map['unitType'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      pricePerUnit: (map['pricePerUnit'] as num).toDouble(),
      lineTotal: (map['lineTotal'] as num).toDouble(),
    );
  }

  BillItemModel copyWith({int? billId}) {
    return BillItemModel(
      id: id,
      billId: billId ?? this.billId,
      productId: productId,
      productName: productName,
      brand: brand,
      unitType: unitType,
      quantity: quantity,
      pricePerUnit: pricePerUnit,
      lineTotal: lineTotal,
    );
  }
}
