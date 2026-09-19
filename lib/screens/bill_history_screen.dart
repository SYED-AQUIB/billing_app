import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/app_constants.dart';
import '../providers/bill_provider.dart';

class BillHistoryScreen extends StatefulWidget {
  const BillHistoryScreen({super.key});

  @override
  State<BillHistoryScreen> createState() => _BillHistoryScreenState();
}

class _BillHistoryScreenState extends State<BillHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _filter = 'All';
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  String _formatBillDateTime(DateTime createdAt) {
    return '${DateFormat('dd/MM/yyyy').format(createdAt)} • ${DateFormat('hh:mm a').format(createdAt)}';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BillProvider>().loadHistory();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BillProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bill History'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => provider.searchBills(value),
              decoration: const InputDecoration(
                labelText: 'Search bills',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _filter == 'All',
                  onSelected: (_) {
                    setState(() => _filter = 'All');
                    provider.filterBills('All');
                  },
                ),
                FilterChip(
                  label: const Text('Today'),
                  selected: _filter == 'Today',
                  onSelected: (_) {
                    setState(() => _filter = 'Today');
                    provider.filterBills('Today');
                  },
                ),
                FilterChip(
                  label: const Text('Last 7 Days'),
                  selected: _filter == 'Last 7 Days',
                  onSelected: (_) {
                    setState(() => _filter = 'Last 7 Days');
                    provider.filterBills('Last 7 Days');
                  },
                ),
                FilterChip(
                  label: const Text('Last 30 Days'),
                  selected: _filter == 'Last 30 Days',
                  onSelected: (_) {
                    setState(() => _filter = 'Last 30 Days');
                    provider.filterBills('Last 30 Days');
                  },
                ),
                FilterChip(
                  label: const Text('Custom Date'),
                  selected: _filter == 'Custom Date',
                  onSelected: (_) async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      initialDateRange: _customStartDate != null && _customEndDate != null
                          ? DateTimeRange(start: _customStartDate!, end: _customEndDate!)
                          : null,
                    );
                    if (picked != null) {
                      setState(() {
                        _filter = 'Custom Date';
                        _customStartDate = picked.start;
                        _customEndDate = picked.end;
                      });
                      provider.filterBillsByDateRange(picked.start, picked.end);
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: provider.isLoadingHistory
                ? const Center(child: CircularProgressIndicator())
                : provider.filteredBills.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.receipt_long_outlined, size: 56),
                            SizedBox(height: 12),
                            Text('No Bills Yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                            SizedBox(height: 4),
                            Text('Generated bills will appear here.'),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        itemCount: provider.filteredBills.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final bill = provider.filteredBills[index];
                          return Card(
                            child: InkWell(
                              onTap: () => Navigator.of(context).pushNamed(AppConstants.routeBillDetails, arguments: bill.id),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(child: Text(bill.billNumber, style: Theme.of(context).textTheme.titleMedium)),
                                        Text('₹${bill.total.toStringAsFixed(2)}', style: Theme.of(context).textTheme.titleMedium),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(_formatBillDateTime(bill.createdAt)),
                                    const SizedBox(height: 4),
                                    if (bill.customerName != null && bill.customerName!.isNotEmpty) ...[
                                      Text('Customer: ${bill.customerName}'),
                                      const SizedBox(height: 4),
                                    ],
                                    if (bill.customerPhone != null && bill.customerPhone!.isNotEmpty) ...[
                                      Text('Phone: ${bill.customerPhone}'),
                                      const SizedBox(height: 4),
                                    ],
                                    const SizedBox(height: 4),
                                    Text('${provider.getItemCountForBill(bill.id)} items'),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
