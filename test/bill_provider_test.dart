import 'package:flutter_test/flutter_test.dart';
import 'package:grocery_billing_app/models/product.dart';
import 'package:grocery_billing_app/providers/bill_provider.dart';

void main() {
  group('BillProvider cart behavior', () {
    test('updates quantity and totals in memory without database writes', () {
      final provider = BillProvider();
      final product = Product(
        id: 1,
        categoryId: 1,
        brand: 'Fresh',
        name: 'Milk',
        unitType: 'Bottle',
        pricePerUnit: 40,
        createdAt: DateTime.now(),
      );

      provider.addItem(product, quantity: 2, pricePerUnit: 40);
      expect(provider.cartItems.length, 1);
      expect(provider.subtotal, 80);

      provider.updateQuantity(0, 5);
      expect(provider.cartItems.single.quantity, 5);
      expect(provider.subtotal, 200);

      provider.clearCart();
      expect(provider.cartItems, isEmpty);
      expect(provider.subtotal, 0);
    });
  });

  group('BillProvider customer details', () {
    test('supports every optional customer detail combination', () {
      final provider = BillProvider();

      provider.setCustomerDetails(name: '', phone: '');
      expect(provider.customerName, isNull);
      expect(provider.customerPhone, isNull);

      provider.setCustomerDetails(name: 'Asha', phone: '');
      expect(provider.customerName, 'Asha');
      expect(provider.customerPhone, isNull);

      provider.setCustomerDetails(name: '', phone: '9876543210');
      expect(provider.customerName, isNull);
      expect(provider.customerPhone, '9876543210');

      provider.setCustomerDetails(name: 'Asha', phone: '9876543210');
      expect(provider.customerName, 'Asha');
      expect(provider.customerPhone, '9876543210');
    });
  });
}
