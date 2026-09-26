import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/bill_item_model.dart';
import '../models/bill_model.dart';
import '../providers/bill_provider.dart';
import '../providers/shop_settings_provider.dart';
import '../services/bluetooth_printer_service.dart';
import '../services/receipt_formatter.dart';
import '../widgets/printer_selection_dialog.dart';

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
          title: const Text('Customer Details'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name (optional)',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone (optional)',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final phone = phoneController.text.trim();
                final validPhone = phone.isEmpty || RegExp(r'^\d{10,}$').hasMatch(phone);
                if (!validPhone) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Enter a valid phone number (at least 10 digits)')),
                  );
                  return;
                }

                Navigator.of(dialogContext).pop((name: nameController.text.trim(), phone: phone));
              },
              child: const Text('Continue'),
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
  Future<T?> _showCompletedDialog<T>({
    required WidgetBuilder builder,
    bool barrierDismissible = true,
  }) async {
    final navigator = Navigator.of(context);
    final route = DialogRoute<T>(
      context: context,
      builder: builder,
      barrierDismissible: barrierDismissible,
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
                  Text(
                    'Bill No: ${provider.billNumber}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (customerName != null && customerName.isNotEmpty) ...[
                    Text('Customer: $customerName'),
                    const SizedBox(height: 4),
                  ],
                  if (customerPhone != null && customerPhone.isNotEmpty) ...[
                    Text('Phone: $customerPhone'),
                    const SizedBox(height: 4),
                  ],
                  const Divider(),
                  ...provider.cartItems.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal'),
                      Text('₹${provider.subtotal.toStringAsFixed(2)}'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total',
                        style: Theme.of(dialogContext).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '₹${provider.total.toStringAsFixed(2)}',
                        style: Theme.of(dialogContext).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(dialogContext).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Back'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Save & Issue Bill'),
            ),
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
        final savedBill = provider.historyBills.isNotEmpty ? provider.historyBills.first : null;
        List<BillItemModel> savedBillItems = [];
        if (savedBill?.id != null) {
          await provider.loadBillDetails(savedBill!.id!);
          if (mounted) {
            savedBillItems = provider.selectedBillItems;
          }
        }

        if (!mounted) return;

        if (savedBill != null) {
          await _showPostSaveSuccessDialog(
            savedBill: savedBill,
            savedItems: savedBillItems,
          );
        }

        if (mounted) {
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

  Future<void> _showPostSaveSuccessDialog({
    required BillModel savedBill,
    required List<BillItemModel> savedItems,
  }) async {
    final BluetoothPrinterService printerService = BluetoothPrinterService();
    bool isPrinting = false;
    final messenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);

    await _showCompletedDialog<void>(
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (builderContext, setDialogState) {
            final hasCustomerName = savedBill.customerName != null && savedBill.customerName!.trim().isNotEmpty;
            final hasCustomerPhone = savedBill.customerPhone != null && savedBill.customerPhone!.trim().isNotEmpty;

            return AlertDialog(
              title: const Text('Bill Issued Successfully'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bill No: ${savedBill.billNumber}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Total: Rs. ${savedBill.total.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  if (hasCustomerName) ...[
                    const SizedBox(height: 4),
                    Text('Customer: ${savedBill.customerName!.trim()}'),
                  ],
                  if (hasCustomerPhone) ...[
                    const SizedBox(height: 4),
                    Text('Phone: ${savedBill.customerPhone!.trim()}'),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    '${savedItems.length} item${savedItems.length == 1 ? '' : 's'}',
                    style: TextStyle(color: theme.colorScheme.outline),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isPrinting ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Done'),
                ),
                FilledButton.icon(
                  onPressed: isPrinting
                      ? null
                      : () async {
                          final selection = await showPrinterSelectionDialog(
                            context: dialogContext,
                            printerService: printerService,
                          );

                          if (selection == null || !mounted) {
                            return;
                          }

                          setDialogState(() {
                            isPrinting = true;
                          });

                          try {
                            final connected = await printerService.connect(selection.printer);
                            if (!connected) {
                              final errorMsg = printerService.lastError ?? 'Could not connect to the printer.';
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(errorMsg),
                                  backgroundColor: theme.colorScheme.error,
                                ),
                              );
                              return;
                            }

                            if (!mounted) return;

                            var shopSettings = context.read<ShopSettingsProvider>().settings;
                            if (shopSettings == null) {
                              await context.read<ShopSettingsProvider>().loadSettings();
                              if (mounted) {
                                shopSettings = context.read<ShopSettingsProvider>().settings;
                              }
                            }

                            final bytes = await ReceiptFormatter.generateReceipt(
                              bill: savedBill,
                              items: savedItems,
                              shopSettings: shopSettings,
                              paperSize: selection.paperSize,
                            );

                            final printed = await printerService.printBytes(bytes);

                            if (printed) {
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Bill printed successfully.'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } else {
                              final errorMsg = printerService.lastError ?? 'Could not send the receipt to the printer.';
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(errorMsg),
                                  backgroundColor: theme.colorScheme.error,
                                ),
                              );
                            }
                          } catch (e) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('Print error: $e'),
                                backgroundColor: theme.colorScheme.error,
                              ),
                            );
                          } finally {
                            await printerService.disconnect();
                            if (mounted) {
                              setDialogState(() {
                                isPrinting = false;
                              });
                            }
                          }
                        },
                  icon: isPrinting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.print),
                  label: Text(isPrinting ? 'Printing...' : 'Print Bill'),
                ),
              ],
            );
          },
        );
      },
    );

    await printerService.disconnect();
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
