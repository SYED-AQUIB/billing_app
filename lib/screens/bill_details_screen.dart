import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/bill_provider.dart';
import '../providers/shop_settings_provider.dart';
import '../services/bluetooth_printer_service.dart';
import '../services/receipt_formatter.dart';
import '../widgets/printer_selection_dialog.dart';

class BillDetailsScreen extends StatefulWidget {
  const BillDetailsScreen({super.key, required this.billId});

  final int billId;

  @override
  State<BillDetailsScreen> createState() => _BillDetailsScreenState();
}

class _BillDetailsScreenState extends State<BillDetailsScreen> {
  final BluetoothPrinterService _printerService = BluetoothPrinterService();
  bool _isPrinting = false;

  String _formatBillDate(DateTime createdAt) {
    return DateFormat('dd/MM/yyyy').format(createdAt);
  }

  String _formatBillTime(DateTime createdAt) {
    return DateFormat('hh:mm a').format(createdAt);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BillProvider>().loadBillDetails(widget.billId);
      context.read<ShopSettingsProvider>().loadSettings();
    });
  }

  @override
  void dispose() {
    _printerService.disconnect();
    super.dispose();
  }

  Future<void> _handlePrintBill() async {
    if (_isPrinting) {
      return;
    }

    final provider = context.read<BillProvider>();
    final bill = provider.selectedBill;
    final items = provider.selectedBillItems;

    if (bill == null || items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bill details not loaded. Cannot print.')),
      );
      return;
    }

    // 1. Prompt printer and paper size selection
    final selection = await showPrinterSelectionDialog(
      context: context,
      printerService: _printerService,
    );

    if (selection == null || !mounted) {
      return;
    }

    setState(() {
      _isPrinting = true;
    });

    final messenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);

    try {
      // 2. Connect to selected printer
      final connected = await _printerService.connect(selection.printer);
      if (!connected) {
        if (!mounted) return;
        final errorMsg = _printerService.lastError ?? 'Could not connect to the printer.';
        messenger.showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: theme.colorScheme.error,
          ),
        );
        return;
      }

      if (!mounted) return;

      // 3. Obtain current shop settings
      var shopSettings = context.read<ShopSettingsProvider>().settings;
      if (shopSettings == null) {
        await context.read<ShopSettingsProvider>().loadSettings();
        if (mounted) {
          shopSettings = context.read<ShopSettingsProvider>().settings;
        }
      }

      // 4. Generate receipt bytes strictly using SAVED bill, items, and settings
      final bytes = await ReceiptFormatter.generateReceipt(
        bill: bill,
        items: items,
        shopSettings: shopSettings,
        paperSize: selection.paperSize,
      );

      if (!mounted) return;

      // 5. Send bytes to printer
      final printed = await _printerService.printBytes(bytes);
      if (!mounted) return;

      if (printed) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Bill printed successfully.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final errorMsg = _printerService.lastError ?? 'Could not send the receipt to the printer.';
        messenger.showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Print error: $e'),
          backgroundColor: theme.colorScheme.error,
        ),
      );
    } finally {
      // 6. Always disconnect safely
      await _printerService.disconnect();
      if (mounted) {
        setState(() {
          _isPrinting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BillProvider>();
    final bill = provider.selectedBill;
    final items = provider.selectedBillItems;

    return Scaffold(
      appBar: AppBar(
        title: Text(bill != null ? 'Bill #${bill.billNumber}' : 'Bill Details'),
        actions: [
          IconButton(
            onPressed: (_isPrinting || bill == null) ? null : _handlePrintBill,
            icon: _isPrinting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.print_outlined),
            tooltip: 'Print Bill',
          ),
          IconButton(
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (dialogContext) {
                  return AlertDialog(
                    title: const Text('Delete this bill?'),
                    content: const Text('This action cannot be undone.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        child: const Text('Delete'),
                      ),
                    ],
                  );
                },
              );

              if (confirmed == true) {
                final deleted = await provider.deleteBill(widget.billId);
                if (!mounted) {
                  return;
                }
                if (deleted && context.mounted) {
                  Navigator.of(context).pop();
                }
              }
            },
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete Bill',
          ),
        ],
      ),
      body: provider.isLoadingDetails
          ? const Center(child: CircularProgressIndicator())
          : bill == null
              ? const Center(child: Text('Bill not found'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Bill Info Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Bill Number',
                                  style: TextStyle(color: Theme.of(context).colorScheme.outline),
                                ),
                                Text(
                                  bill.billNumber,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Date & Time',
                                  style: TextStyle(color: Theme.of(context).colorScheme.outline),
                                ),
                                Text(
                                  '${_formatBillDate(bill.createdAt)} • ${_formatBillTime(bill.createdAt)}',
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                            if (bill.customerName != null && bill.customerName!.trim().isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Customer',
                                    style: TextStyle(color: Theme.of(context).colorScheme.outline),
                                  ),
                                  Text(
                                    bill.customerName!.trim(),
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ],
                            if (bill.customerPhone != null && bill.customerPhone!.trim().isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Phone',
                                    style: TextStyle(color: Theme.of(context).colorScheme.outline),
                                  ),
                                  Text(
                                    bill.customerPhone!.trim(),
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Items and Totals Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ITEMS',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...items.map((item) {
                              final formattedQty = item.quantity == item.quantity.roundToDouble()
                                  ? item.quantity.toInt().toString()
                                  : item.quantity.toStringAsFixed(2);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.productName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '$formattedQty ${item.unitType} × ₹${item.pricePerUnit.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              color: Theme.of(context).colorScheme.outline,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '₹${item.lineTotal.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Subtotal'),
                                Text('₹${bill.subtotal.toStringAsFixed(2)}'),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '₹${bill.total.toStringAsFixed(2)}',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
      bottomNavigationBar: bill == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SizedBox(
                  height: 48,
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isPrinting ? null : _handlePrintBill,
                    icon: _isPrinting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.print),
                    label: Text(_isPrinting ? 'Printing...' : 'Print Bill'),
                  ),
                ),
              ),
            ),
    );
  }
}
