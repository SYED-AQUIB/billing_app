import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/bill_provider.dart';

class BillDetailsScreen extends StatefulWidget {
  const BillDetailsScreen({super.key, required this.billId});

  final int billId;

  @override
  State<BillDetailsScreen> createState() => _BillDetailsScreenState();
}

class _BillDetailsScreenState extends State<BillDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BillProvider>().loadBillDetails(widget.billId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BillProvider>();
    final bill = provider.selectedBill;
    final items = provider.selectedBillItems;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt'),
        actions: [
          IconButton(
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (dialogContext) {
                  return AlertDialog(
                    title: const Text('Delete this bill?'),
                    content: const Text('This action cannot be undone.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
                      FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Delete')),
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
          ),
        ],
      ),
      body: provider.isLoadingDetails
          ? const Center(child: CircularProgressIndicator())
          : bill == null
              ? const Center(child: Text('Bill not found'))
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: ListView(
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Bill Number: ${bill.billNumber}', style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 8),
                              Text('Date: ${bill.createdAt.day}/${bill.createdAt.month}/${bill.createdAt.year}'),
                              Text('Time: ${bill.createdAt.hour.toString().padLeft(2, '0')}:${bill.createdAt.minute.toString().padLeft(2, '0')}'),
                              const SizedBox(height: 8),
                              Text('Customer: ${bill.customerName ?? 'Walk-in Customer'}'),
                              Text('Phone: ${bill.customerPhone ?? 'No phone'}'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Items', style: TextStyle(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 8),
                              ...items.map((item) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                        Text(item.brand),
                                        const SizedBox(height: 4),
                                        Text('${item.quantity.toStringAsFixed(2)} ${item.unitType} • ₹${item.pricePerUnit.toStringAsFixed(2)}'),
                                        Text('Line Total: ₹${item.lineTotal.toStringAsFixed(2)}'),
                                      ],
                                    ),
                                  )),
                              const Divider(),
                              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Subtotal'), Text('₹${bill.subtotal.toStringAsFixed(2)}')]),
                              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Total'), Text('₹${bill.total.toStringAsFixed(2)}')]),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
