class ShopSettings {
  ShopSettings({
    this.id,
    required this.shopName,
    this.ownerName,
    this.phoneNumber,
    this.shopAddress,
    required this.createdAt,
  });

  final int? id;
  final String shopName;
  final String? ownerName;
  final String? phoneNumber;
  final String? shopAddress;
  final DateTime createdAt;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'shopName': shopName,
      'ownerName': ownerName,
      'phoneNumber': phoneNumber,
      'shopAddress': shopAddress,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ShopSettings.fromMap(Map<String, dynamic> map) {
    return ShopSettings(
      id: map['id'] as int?,
      shopName: map['shopName'] as String,
      ownerName: map['ownerName'] as String?,
      phoneNumber: map['phoneNumber'] as String?,
      shopAddress: map['shopAddress'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  ShopSettings copyWith({int? id, String? shopName, String? ownerName, String? phoneNumber, String? shopAddress, DateTime? createdAt}) {
    return ShopSettings(
      id: id ?? this.id,
      shopName: shopName ?? this.shopName,
      ownerName: ownerName ?? this.ownerName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      shopAddress: shopAddress ?? this.shopAddress,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
