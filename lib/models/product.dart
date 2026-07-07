class Product {
  Product({
    this.id,
    required this.categoryId,
    required this.brand,
    required this.name,
    required this.unitType,
    required this.pricePerUnit,
    this.imagePath,
    required this.createdAt,
  });

  final int? id;
  final int categoryId;
  final String brand;
  final String name;
  final String unitType;
  final double pricePerUnit;
  final String? imagePath;
  final DateTime createdAt;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'categoryId': categoryId,
      'brand': brand,
      'name': name,
      'unitType': unitType,
      'pricePerUnit': pricePerUnit,
      'imagePath': imagePath,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int?,
      categoryId: map['categoryId'] as int,
      brand: map['brand'] as String,
      name: map['name'] as String,
      unitType: map['unitType'] as String,
      pricePerUnit: (map['pricePerUnit'] as num).toDouble(),
      imagePath: map['imagePath'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  Product copyWith({
    int? id,
    int? categoryId,
    String? brand,
    String? name,
    String? unitType,
    double? pricePerUnit,
    String? imagePath,
    DateTime? createdAt,
  }) {
    return Product(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      brand: brand ?? this.brand,
      name: name ?? this.name,
      unitType: unitType ?? this.unitType,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
