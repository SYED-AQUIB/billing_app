import 'package:flutter_test/flutter_test.dart';
import 'package:grocery_billing_app/models/product.dart';
import 'package:grocery_billing_app/providers/product_provider.dart';
import 'package:grocery_billing_app/repositories/product_repository.dart';

class FakeProductRepository extends ProductRepository {
  final List<Product> _products = [];

  @override
  Future<List<Product>> getAllProducts() async => List.unmodifiable(_products);

  @override
  Future<bool> productExists({required int categoryId, required String brand, required String name, int? excludeId}) async {
    final normalizedBrand = brand.trim().toLowerCase();
    final normalizedName = name.trim().toLowerCase();

    return _products.any((item) {
      final currentCategoryId = item.categoryId;
      final currentBrand = item.brand.trim().toLowerCase();
      final currentName = item.name.trim().toLowerCase();
      return currentCategoryId == categoryId &&
          currentBrand == normalizedBrand &&
          currentName == normalizedName &&
          (excludeId == null || item.id != excludeId);
    });
  }

  @override
  Future<int> insertProduct(Product product) async {
    _products.add(product.copyWith(id: _products.length + 1));
    return _products.last.id!;
  }
}

void main() {
  test('prevents duplicates in the same category and brand', () async {
    final repository = FakeProductRepository();
    final provider = ProductProvider(repository: repository);

    final product = Product(
      categoryId: 1,
      brand: 'Fresh',
      name: 'Milk',
      unitType: 'Bottle',
      pricePerUnit: 40,
      createdAt: DateTime.now(),
    );

    final added = await provider.addProduct(product);
    final duplicate = await provider.addProduct(product);

    expect(added, isTrue);
    expect(duplicate, isFalse);
    expect(provider.products.length, 1);
  });
}
