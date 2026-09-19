import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/bill_provider.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  void _showManualQuantityDialog(int index) {
    final item = context.read<BillProvider>().cartItems[index];
    final controller = TextEditingController(text: item.quantity.toString());

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Update Quantity'),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: 'Quantity (${item.unitType})'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                final quantity = double.tryParse(controller.text);
                if (quantity == null || quantity <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter valid quantity')));
                  return;
                }
                context.read<BillProvider>().updateQuantity(index, quantity);
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    ).whenComplete(controller.dispose);
  }

  Future<void> _showGenerateBillDialog() async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    final customerDetails = await _showCompletedDialog<({String name, String phone})>(
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Generate Bill'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Customer Name (Optional)')),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Customer Phone (Optional)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                final phone = phoneController.text.trim();
                final validPhone = phone.isEmpty || RegExp(r'^\d{10,}$').hasMatch(phone);
                if (!validPhone) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(const SnackBar(content: Text('Enter a valid phone number')));
                  return;
                }

                Navigator.of(dialogContext).pop((name: nameController.text.trim(), phone: phone));
              },
              child: const Text('Generate'),
            ),
          ],
        );
      },
    );
    nameController.dispose();
    phoneController.dispose();

    if (!mounted || customerDetails == null) {
      return;
    }

    context.read<BillProvider>().setCustomerDetails(name: customerDetails.name, phone: customerDetails.phone);
    await _showBillPreview();
  }

  /// Waits until the dialog overlay has been removed before state changes.
  Future<T?> _showCompletedDialog<T>({required WidgetBuilder builder}) async {
    final navigator = Navigator.of(context);
    final route = DialogRoute<T>(
      context: context,
      builder: builder,
      themes: InheritedTheme.capture(from: context, to: navigator.context),
    );
    final result = await navigator.push(route);
    await route.completed;
    return result;
  }

  Future<void> _showBillPreview() async {
    final provider = context.read<BillProvider>();
    final customerName = provider.customerName?.trim();
    final customerPhone = provider.customerPhone?.trim();
    final confirmed = await _showCompletedDialog<bool>(
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Bill Preview'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Bill Number: ${provider.billNumber}'),
                  const SizedBox(height: 8),
                  if (customerName != null && customerName.isNotEmpty) ...[
                    Text('Customer: $customerName'),
                    const SizedBox(height: 8),
                  ],
                  if (customerPhone != null && customerPhone.isNotEmpty) ...[
                    Text('Phone: $customerPhone'),
                    const SizedBox(height: 8),
                  ],
                  ...provider.cartItems.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${item.productName} • ${item.quantity.toStringAsFixed(2)} ${item.unitType}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('₹${item.lineTotal.toStringAsFixed(2)}'),
                        ],
                      ),
                    ),
                  ),
                  const Divider(),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Subtotal'), Text('₹${provider.subtotal.toStringAsFixed(2)}')]),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Total'), Text('₹${provider.total.toStringAsFixed(2)}')]),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Back')),
            FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Confirm')),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _showAcknowledgementDialog();
    }
  }

  Future<void> _showAcknowledgementDialog() async {
    final provider = context.read<BillProvider>();
    final confirmed = await _showCompletedDialog<bool>(
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Bill Generated Successfully'),
          content: const Text('Please confirm that the customer has received the bill.'),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Back')),
            FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Received')),
          ],
        );
      },
    );

    if (confirmed == true) {
      final saved = await provider.saveBill();
      if (!mounted) {
        return;
      }

      if (saved) {
        final startNewBill = await _showCompletedDialog<bool>(
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Bill Saved Successfully'),
              content: const Text('Start a new bill.'),
              actions: [
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('New Bill'),
                ),
              ],
            );
          },
        );
        if (startNewBill == true && mounted) {
          await provider.refreshBillNumber();
          if (mounted) {
            Navigator.of(context).pop();
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cart is empty')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final billProvider = context.watch<BillProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Cart • ${billProvider.billNumber}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bill Number: ${billProvider.billNumber}', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Expanded(
              child: billProvider.cartItems.isEmpty
                  ? const Center(child: Text('No items yet'))
                  : ListView.builder(
                      itemCount: billProvider.cartItems.length,
                      itemBuilder: (context, index) {
                        final item = billProvider.cartItems[index];
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.productName,
                                        style: Theme.of(context).textTheme.titleMedium,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text('₹${item.lineTotal.toStringAsFixed(2)}', style: Theme.of(context).textTheme.titleMedium),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(item.brand, maxLines: 1, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 8),
                                Text(
                                  '${item.quantity.toStringAsFixed(2)} ${item.unitType} • ₹${item.pricePerUnit.toStringAsFixed(2)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    IconButton(onPressed: () => billProvider.decreaseQuantity(index), icon: const Icon(Icons.remove)),
                                    const SizedBox(width: 4),
                                    FilledButton(onPressed: () => _showManualQuantityDialog(index), child: Text(item.quantity.toStringAsFixed(2))),
                                    const SizedBox(width: 4),
                                    IconButton(onPressed: () => billProvider.increaseQuantity(index), icon: const Icon(Icons.add)),
                                    const Spacer(),
                                    IconButton(onPressed: () => billProvider.removeItem(index), icon: const Icon(Icons.delete_outline)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Subtotal'), Text('₹${billProvider.subtotal.toStringAsFixed(2)}')]),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Total'), Text('₹${billProvider.total.toStringAsFixed(2)}')]),
            const SizedBox(height: 8),
            SizedBox(
              height: 48,
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: billProvider.cartItems.isEmpty ? null : _showGenerateBillDialog,
                icon: const Icon(Icons.receipt_long),
                label: const Text('Generate Bill'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
