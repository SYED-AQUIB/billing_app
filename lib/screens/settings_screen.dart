import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_constants.dart';
import '../providers/category_provider.dart';
import '../providers/product_provider.dart';
import '../providers/shop_settings_provider.dart';
import '../providers/bill_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _shopNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShopSettingsProvider>().loadSettings();
    });
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _ownerNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ShopSettingsProvider>();
    final categoryProvider = context.watch<CategoryProvider>();
    final productProvider = context.watch<ProductProvider>();
    final billProvider = context.watch<BillProvider>();
    final settings = provider.settings;

    if (settings != null && _shopNameController.text.isEmpty) {
      _shopNameController.text = settings.shopName;
      _ownerNameController.text = settings.ownerName ?? '';
      _phoneController.text = settings.phoneNumber ?? '';
      _addressController.text = settings.shopAddress ?? '';
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Shop Settings')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: provider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Store details for receipts and billing',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _shopNameController,
                        decoration: const InputDecoration(labelText: 'Shop Name'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _ownerNameController,
                        decoration: const InputDecoration(labelText: 'Owner Name'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(labelText: 'Phone Number'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _addressController,
                        maxLines: 2,
                        decoration: const InputDecoration(labelText: 'Address'),
                      ),
                      const SizedBox(height: 20),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('App Summary', style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 8),
                              _SummaryRow(label: 'Shop Name', value: settings?.shopName ?? 'Not set'),
                              _SummaryRow(label: 'Owner Name', value: settings?.ownerName ?? 'Not set'),
                              _SummaryRow(label: 'Phone', value: settings?.phoneNumber ?? 'Not set'),
                              _SummaryRow(label: 'Address', value: settings?.shopAddress ?? 'Not set'),
                              _SummaryRow(label: 'Categories', value: '${categoryProvider.categories.length}'),
                              _SummaryRow(label: 'Products', value: '${productProvider.products.length}'),
                              _SummaryRow(label: 'Bills', value: '${billProvider.historyBills.length}'),
                              _SummaryRow(label: 'App Version', value: AppConstants.appVersion),
                              _SummaryRow(label: 'Database Version', value: '${AppConstants.databaseVersion}'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: provider.isSaving ? null : () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final saved = await provider.saveSettings(
                            shopName: _shopNameController.text,
                            ownerName: _ownerNameController.text,
                            phoneNumber: _phoneController.text,
                            shopAddress: _addressController.text,
                          );
                          if (!mounted) {
                            return;
                          }
                          messenger.showSnackBar(
                            SnackBar(content: Text(saved ? 'Settings saved' : 'Shop name is required')),
                          );
                        },
                        icon: const Icon(Icons.save_outlined),
                        label: provider.isSaving ? const Text('Saving...') : const Text('Save Settings'),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
          Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
