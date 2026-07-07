class BillModel {
  BillModel({
    this.id,
    required this.billNumber,
    this.customerName,
    this.customerPhone,
    required this.subtotal,
    required this.total,
    required this.createdAt,
  });

  final int? id;
  final String billNumber;
  final String? customerName;
  final String? customerPhone;
  final double subtotal;
  final double total;
  final DateTime createdAt;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'billNumber': billNumber,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'subtotal': subtotal,
      'total': total,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory BillModel.fromMap(Map<String, dynamic> map) {
    return BillModel(
      id: map['id'] as int?,
      billNumber: map['billNumber'] as String,
      customerName: map['customerName'] as String?,
      customerPhone: map['customerPhone'] as String?,
      subtotal: (map['subtotal'] as num).toDouble(),
      total: (map['total'] as num).toDouble(),
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  BillModel copyWith({int? id}) {
    return BillModel(
      id: id ?? this.id,
      billNumber: billNumber,
      customerName: customerName,
      customerPhone: customerPhone,
      subtotal: subtotal,
      total: total,
      createdAt: createdAt,
    );
  }
}
