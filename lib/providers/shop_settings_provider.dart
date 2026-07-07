import 'package:flutter/material.dart';

import '../models/shop_settings.dart';
import '../repositories/shop_settings_repository.dart';

class ShopSettingsProvider extends ChangeNotifier {
  ShopSettingsProvider({ShopSettingsRepository? repository}) : _repository = repository ?? ShopSettingsRepository();

  final ShopSettingsRepository _repository;
  ShopSettings? _settings;
  bool _isLoading = false;
  bool _isSaving = false;

  ShopSettings? get settings => _settings;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;

  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();
    try {
      _settings = await _repository.getSettings();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveSettings({required String shopName, String? ownerName, String? phoneNumber, String? shopAddress}) async {
    if (shopName.trim().isEmpty) {
      return false;
    }

    _isSaving = true;
    notifyListeners();
    try {
      final payload = ShopSettings(
        id: _settings?.id,
        shopName: shopName.trim(),
        ownerName: ownerName?.trim().isEmpty == true ? null : ownerName?.trim(),
        phoneNumber: phoneNumber?.trim().isEmpty == true ? null : phoneNumber?.trim(),
        shopAddress: shopAddress?.trim().isEmpty == true ? null : shopAddress?.trim(),
        createdAt: _settings?.createdAt ?? DateTime.now(),
      );
      final id = await _repository.upsertSettings(payload);
      _settings = payload.copyWith(id: id);
      return true;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
