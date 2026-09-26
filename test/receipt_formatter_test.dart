import 'dart:convert';

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grocery_billing_app/models/bill_item_model.dart';
import 'package:grocery_billing_app/models/bill_model.dart';
import 'package:grocery_billing_app/models/shop_settings.dart';
import 'package:grocery_billing_app/services/receipt_formatter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final fixedTimestamp = DateTime(2025, 4, 15, 14, 30); // 15/04/2025, 02:30 PM

  BillModel createSampleBill({
    int? id = 1,
    String billNumber = 'B00142',
    String? customerName,
    String? customerPhone,
    double subtotal = 150.0,
    double total = 150.0,
    DateTime? createdAt,
  }) {
    return BillModel(
      id: id,
      billNumber: billNumber,
      customerName: customerName,
      customerPhone: customerPhone,
      subtotal: subtotal,
      total: total,
      createdAt: createdAt ?? fixedTimestamp,
    );
  }

  BillItemModel createSampleItem({
    int id = 1,
    int billId = 1,
    int productId = 10,
    String productName = 'Tata Salt',
    String brand = 'Tata',
    String unitType = 'PAC',
    double quantity = 2.0,
    double pricePerUnit = 25.0,
    double lineTotal = 50.0,
  }) {
    return BillItemModel(
      id: id,
      billId: billId,
      productId: productId,
      productName: productName,
      brand: brand,
      unitType: unitType,
      quantity: quantity,
      pricePerUnit: pricePerUnit,
      lineTotal: lineTotal,
    );
  }

  final sampleShopSettings = ShopSettings(
    id: 1,
    shopName: 'Apna Kirana Store',
    ownerName: 'Ramesh Gupta',
    phoneNumber: '9876543210',
    shopAddress: 'Shop 4, Main Market, MG Road',
    createdAt: DateTime(2025, 1, 1),
  );

  String decodeReceiptBytes(List<int> bytes) {
    return latin1.decode(bytes, allowInvalid: true);
  }

  group('ReceiptFormatter Unit Tests', () {
    // Test 1: Bill with customer name + phone
    test('Test 1: Bill with customer name + phone contains all required fields', () async {
      final bill = createSampleBill(
        customerName: 'Asha Sharma',
        customerPhone: '9988776655',
        subtotal: 50.0,
        total: 50.0,
      );
      final items = [createSampleItem()];

      final bytes = await ReceiptFormatter.generateReceipt(
        bill: bill,
        items: items,
        shopSettings: sampleShopSettings,
      );

      final text = decodeReceiptBytes(bytes);

      expect(text, contains('Customer: Asha Sharma'));
      expect(text, contains('Phone: 9988776655'));
      expect(text, contains('Bill No: B00142'));
      expect(text, contains('15/04/2025'));
      expect(text, contains('02:30 PM'));
      expect(text, contains('Rs. 50.00'));
    });

    // Test 2: Bill with name only
    test('Test 2: Bill with name only shows name and omits phone and fake labels', () async {
      final bill = createSampleBill(customerName: 'Asha Sharma');
      final items = [createSampleItem()];

      final bytes = await ReceiptFormatter.generateReceipt(
        bill: bill,
        items: items,
      );

      final text = decodeReceiptBytes(bytes);

      expect(text, contains('Customer: Asha Sharma'));
      expect(text.contains('Phone:'), isFalse);
      expect(text.contains('Walk-in'), isFalse);
      expect(text.contains('Anonymous'), isFalse);
    });

    // Test 3: Bill with phone only
    test('Test 3: Bill with phone only shows phone and omits customer name label', () async {
      final bill = createSampleBill(customerPhone: '9988776655');
      final items = [createSampleItem()];

      final bytes = await ReceiptFormatter.generateReceipt(
        bill: bill,
        items: items,
      );

      final text = decodeReceiptBytes(bytes);

      expect(text, contains('Phone: 9988776655'));
      expect(text.contains('Customer:'), isFalse);
      expect(text.contains('Walk-in'), isFalse);
      expect(text.contains('Anonymous'), isFalse);
    });

    // Test 4: Bill with no customer information
    test('Test 4: Bill with no customer info completely omits customer section and forbidden strings', () async {
      final bill = createSampleBill();
      final items = [createSampleItem()];

      final bytes = await ReceiptFormatter.generateReceipt(
        bill: bill,
        items: items,
      );

      final text = decodeReceiptBytes(bytes);

      expect(text.contains('Customer:'), isFalse);
      expect(text.contains('Phone:'), isFalse);
      expect(text.contains('Walk-in'), isFalse);
      expect(text.contains('Anonymous Customer'), isFalse);
      expect(text.contains('No Customer'), isFalse);
      expect(text.contains('Customer Type'), isFalse);
    });

    // Test 5: Persisted timestamp
    test('Test 5: Persisted timestamp uses exact BillModel.createdAt value and not DateTime.now()', () async {
      final historicalDate = DateTime(2023, 11, 24, 9, 15); // 24/11/2023, 09:15 AM
      final bill = createSampleBill(createdAt: historicalDate);
      final items = [createSampleItem()];

      final bytes = await ReceiptFormatter.generateReceipt(
        bill: bill,
        items: items,
      );

      final text = decodeReceiptBytes(bytes);

      expect(text, contains('24/11/2023'));
      expect(text, contains('09:15 AM'));

      // Ensure today's date does not mistakenly appear as the bill date
      final todayStr = '${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().year}';
      if (todayStr != '24/11/2023') {
        expect(text.contains(todayStr), isFalse);
      }
    });

    // Test 6: 58 mm
    test('Test 6: Works properly with PaperSize.mm58', () async {
      final bill = createSampleBill();
      final items = [createSampleItem()];

      final bytes = await ReceiptFormatter.generateReceipt(
        bill: bill,
        items: items,
        shopSettings: sampleShopSettings,
        paperSize: PaperSize.mm58,
      );

      expect(bytes, isNotEmpty);
      final text = decodeReceiptBytes(bytes);
      expect(text, contains('Apna Kirana Store'));
      expect(text, contains('Bill No: B00142'));
      expect(text, contains('Rs. 150.00'));
    });

    // Test 7: 80 mm
    test('Test 7: Works properly with PaperSize.mm80', () async {
      final bill = createSampleBill();
      final items = [createSampleItem()];

      final bytes = await ReceiptFormatter.generateReceipt(
        bill: bill,
        items: items,
        shopSettings: sampleShopSettings,
        paperSize: PaperSize.mm80,
      );

      expect(bytes, isNotEmpty);
      final text = decodeReceiptBytes(bytes);
      expect(text, contains('Apna Kirana Store'));
      expect(text, contains('Bill No: B00142'));
      expect(text, contains('Rs. 150.00'));
    });

    // Test 8: Long product name
    test('Test 8: Long product name generates valid receipt without throwing and preserves amounts', () async {
      const longName = 'Aashirvaad Select Sharbati Whole Wheat Atta 10kg Premium Quality Pack';
      final bill = createSampleBill(subtotal: 580.0, total: 580.0);
      final items = [
        createSampleItem(
          productName: longName,
          brand: 'Aashirvaad',
          quantity: 1.0,
          pricePerUnit: 580.0,
          lineTotal: 580.0,
        ),
      ];

      final bytes = await ReceiptFormatter.generateReceipt(
        bill: bill,
        items: items,
        paperSize: PaperSize.mm58,
      );

      expect(bytes, isNotEmpty);
      final text = decodeReceiptBytes(bytes);
      expect(text, contains('Aashirvaad'));
      expect(text, contains('Rs. 580.00'));
    });

    // Test 9: Multiple products
    test('Test 9: Multiple products all appear with line totals and overall total', () async {
      final items = [
        createSampleItem(id: 1, productName: 'Tata Salt', pricePerUnit: 25.0, quantity: 2.0, lineTotal: 50.0),
        createSampleItem(id: 2, productName: 'Fortune Oil', brand: 'Fortune', pricePerUnit: 140.0, quantity: 1.0, lineTotal: 140.0),
        createSampleItem(id: 3, productName: 'Basmati Rice', brand: 'India Gate', pricePerUnit: 110.0, quantity: 3.0, lineTotal: 330.0),
      ];
      final bill = createSampleBill(subtotal: 520.0, total: 520.0);

      final bytes = await ReceiptFormatter.generateReceipt(
        bill: bill,
        items: items,
      );

      final text = decodeReceiptBytes(bytes);
      expect(text, contains('Tata Salt'));
      expect(text, contains('Rs. 50.00'));
      expect(text, contains('Fortune Oil'));
      expect(text, contains('Rs. 140.00'));
      expect(text, contains('Basmati Rice'));
      expect(text, contains('Rs. 330.00'));
      expect(text, contains('TOTAL'));
      expect(text, contains('Rs. 520.00'));
    });

    // Test 10: Currency
    test('Test 10: Currency uses "Rs." and does NOT contain Unicode "₹"', () async {
      final bill = createSampleBill(total: 99.0);
      final items = [createSampleItem(lineTotal: 99.0)];

      final bytes = await ReceiptFormatter.generateReceipt(
        bill: bill,
        items: items,
      );

      final text = decodeReceiptBytes(bytes);
      expect(text, contains('Rs.'));
      expect(text.contains('₹'), isFalse);
    });

    // Test 11: Bill number
    test('Test 11: Saved bill number appears exactly as stored', () async {
      const expectedBillNumber = 'B99887';
      final bill = createSampleBill(billNumber: expectedBillNumber);
      final items = [createSampleItem()];

      final bytes = await ReceiptFormatter.generateReceipt(
        bill: bill,
        items: items,
      );

      final text = decodeReceiptBytes(bytes);
      expect(text, contains('Bill No: B99887'));
    });

    // Test 12: No mutation
    test('Test 12: ReceiptFormatter does not mutate BillModel or BillItemModel', () async {
      final bill = createSampleBill(
        id: 42,
        billNumber: 'B00042',
        customerName: 'Original Name',
        customerPhone: '1234567890',
        subtotal: 200.0,
        total: 200.0,
        createdAt: fixedTimestamp,
      );
      final item = createSampleItem(
        id: 1,
        billId: 42,
        productId: 5,
        productName: 'Original Item',
        brand: 'Original Brand',
        unitType: 'KG',
        quantity: 4.0,
        pricePerUnit: 50.0,
        lineTotal: 200.0,
      );
      final items = [item];

      await ReceiptFormatter.generateReceipt(
        bill: bill,
        items: items,
        shopSettings: sampleShopSettings,
      );

      // Verify BillModel unchanged
      expect(bill.id, 42);
      expect(bill.billNumber, 'B00042');
      expect(bill.customerName, 'Original Name');
      expect(bill.customerPhone, '1234567890');
      expect(bill.subtotal, 200.0);
      expect(bill.total, 200.0);
      expect(bill.createdAt, fixedTimestamp);

      // Verify BillItemModel unchanged
      expect(item.id, 1);
      expect(item.billId, 42);
      expect(item.productId, 5);
      expect(item.productName, 'Original Item');
      expect(item.brand, 'Original Brand');
      expect(item.unitType, 'KG');
      expect(item.quantity, 4.0);
      expect(item.pricePerUnit, 50.0);
      expect(item.lineTotal, 200.0);
    });
  });
}

