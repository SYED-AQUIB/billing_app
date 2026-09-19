import 'package:flutter/foundation.dart';

import '../core/app_constants.dart';
import '../models/bill_item_model.dart';
import '../models/bill_model.dart';
import '../models/product.dart';
import '../repositories/bill_repository.dart';

class BillProvider extends ChangeNotifier {
  final BillRepository _repository = BillRepository();

  String _billNumber = '';
  String? _customerName;
  String? _customerPhone;
  final List<BillItemModel> _cartItems = [];
  List<BillModel> _historyBills = [];
  List<BillModel> _filteredBills = [];
  final Map<int?, int> _billItemCounts = {};
  BillModel? _selectedBill;
  List<BillItemModel> _selectedBillItems = [];
  bool _isLoadingHistory = false;
  bool _isLoadingDetails = false;

  String get billNumber => _billNumber;
  String? get customerName => _customerName;
  String? get customerPhone => _customerPhone;
  List<BillItemModel> get cartItems => List.unmodifiable(_cartItems);
  List<BillModel> get historyBills => List.unmodifiable(_historyBills);
  List<BillModel> get filteredBills => List.unmodifiable(_filteredBills);
  BillModel? get selectedBill => _selectedBill;
  List<BillItemModel> get selectedBillItems => List.unmodifiable(_selectedBillItems);
  bool get isLoadingHistory => _isLoadingHistory;
  bool get isLoadingDetails => _isLoadingDetails;

  double get subtotal => _cartItems.fold<double>(0, (sum, item) => sum + item.lineTotal);
  double get total => subtotal;

  Future<void> initializeBillNumber() async {
    if (_billNumber.isNotEmpty) {
      return;
    }
    _billNumber = await _repository.getNextBillNumber();
    notifyListeners();
  }

  Future<void> refreshBillNumber() async {
    clearCart();
    _billNumber = await _repository.getNextBillNumber();
    notifyListeners();
  }

  void addItem(Product product, {required double quantity, required double pricePerUnit}) {
    final productId = product.id ?? 0;
    final existingIndex = _cartItems.indexWhere((item) => item.productId == productId);

    if (existingIndex >= 0) {
      final existing = _cartItems[existingIndex];
      final newQuantity = existing.quantity + quantity;
      _cartItems[existingIndex] = _createCartItem(
        productId: existing.productId,
        productName: existing.productName,
        brand: existing.brand,
        unitType: existing.unitType,
        quantity: newQuantity,
        pricePerUnit: pricePerUnit,
      );
    } else {
      _cartItems.add(
        _createCartItem(
          productId: productId,
          productName: product.name,
          brand: product.brand,
          unitType: product.unitType,
          quantity: quantity,
          pricePerUnit: pricePerUnit,
        ),
      );
    }

    notifyListeners();
  }

  void updateQuantity(int index, double quantity) {
    if (index < 0 || index >= _cartItems.length || quantity <= 0) {
      return;
    }

    final item = _cartItems[index];
    _cartItems[index] = _createCartItem(
      productId: item.productId,
      productName: item.productName,
      brand: item.brand,
      unitType: item.unitType,
      quantity: quantity,
      pricePerUnit: item.pricePerUnit,
    );
    notifyListeners();
  }

  void increaseQuantity(int index) {
    if (index < 0 || index >= _cartItems.length) {
      return;
    }
    updateQuantity(index, _cartItems[index].quantity + 1);
  }

  void decreaseQuantity(int index) {
    if (index < 0 || index >= _cartItems.length) {
      return;
    }

    final newQuantity = _cartItems[index].quantity - 1;
    if (newQuantity <= 0) {
      removeItem(index);
      return;
    }
    updateQuantity(index, newQuantity);
  }

  void removeItem(int index) {
    if (index < 0 || index >= _cartItems.length) {
      return;
    }
    _cartItems.removeAt(index);
    notifyListeners();
  }

  void clearCart() {
    _cartItems.clear();
    _customerName = null;
    _customerPhone = null;
    notifyListeners();
  }

  void setCustomerDetails({String? name, String? phone}) {
    final normalizedName = name?.trim();
    final normalizedPhone = phone?.trim();
    final customerName = normalizedName == null || normalizedName.isEmpty ? null : normalizedName;
    final customerPhone = normalizedPhone == null || normalizedPhone.isEmpty ? null : normalizedPhone;
    if (_customerName == customerName && _customerPhone == customerPhone) {
      return;
    }
    _customerName = customerName;
    _customerPhone = customerPhone;
    notifyListeners();
  }

  Future<bool> saveBill() async {
    if (_cartItems.isEmpty) {
      return false;
    }

    if (_billNumber.isEmpty) {
      _billNumber = await _repository.getNextBillNumber();
    }

    final bill = BillModel(
      billNumber: _billNumber,
      customerName: _customerName,
      customerPhone: _customerPhone,
      subtotal: subtotal,
      total: total,
      createdAt: DateTime.now(),
    );

    await _repository.saveBillWithItems(bill: bill, items: _cartItems);
    clearCart();
    await loadHistory();
    return true;
  }

  Future<void> loadHistory() async {
    _isLoadingHistory = true;
    notifyListeners();

    _historyBills = await _repository.getAllBills();
    _filteredBills = List<BillModel>.from(_historyBills);
    await _loadItemCounts(_historyBills);

    _isLoadingHistory = false;
    notifyListeners();
  }

  Future<void> searchBills(String query) async {
    _isLoadingHistory = true;
    notifyListeners();

    _filteredBills = await _repository.searchBills(query);
    await _loadItemCounts(_filteredBills);

    _isLoadingHistory = false;
    notifyListeners();
  }

  Future<void> filterBills(String filter) async {
    final now = DateTime.now();
    if (filter == AppConstants.filterToday) {
      await filterBillsByDateRange(now, now);
    } else if (filter == AppConstants.filterLast7Days) {
      await filterBillsByDateRange(now.subtract(const Duration(days: 6)), now);
    } else if (filter == AppConstants.filterLast30Days) {
      await filterBillsByDateRange(now.subtract(const Duration(days: 29)), now);
    } else {
      await loadHistory();
    }
  }

  Future<void> filterBillsByDateRange(DateTime start, DateTime end) async {
    _isLoadingHistory = true;
    notifyListeners();

    _filteredBills = await _repository.filterBillsByDateRange(start, end);
    await _loadItemCounts(_filteredBills);

    _isLoadingHistory = false;
    notifyListeners();
  }

  Future<void> loadBillDetails(int billId) async {
    _isLoadingDetails = true;
    notifyListeners();

    _selectedBill = await _repository.getBillById(billId);
    _selectedBillItems = await _repository.getBillItems(billId);

    _isLoadingDetails = false;
    notifyListeners();
  }

  Future<bool> deleteBill(int billId) async {
    final deleted = await _repository.deleteBill(billId);
    if (deleted) {
      _selectedBill = null;
      _selectedBillItems = [];
      _billItemCounts.remove(billId);
      await loadHistory();
    }
    return deleted;
  }

  int getItemCountForBill(int? billId) {
    if (billId == null) {
      return 0;
    }
    return _billItemCounts[billId] ?? 0;
  }

  BillItemModel _createCartItem({
    required int productId,
    required String productName,
    required String brand,
    required String unitType,
    required double quantity,
    required double pricePerUnit,
  }) {
    return BillItemModel(
      billId: 0,
      productId: productId,
      productName: productName,
      brand: brand,
      unitType: unitType,
      quantity: quantity,
      pricePerUnit: pricePerUnit,
      lineTotal: quantity * pricePerUnit,
    );
  }

  Future<void> _loadItemCounts(List<BillModel> bills) async {
    for (final bill in bills) {
      final billId = bill.id;
      if (billId != null) {
        _billItemCounts[billId] = await _repository.getBillItemCount(billId);
      }
    }
  }
}
