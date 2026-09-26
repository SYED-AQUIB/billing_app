import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/app_constants.dart';
import '../models/bill_model.dart';
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

  String _getDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final billDate = DateTime(date.year, date.month, date.day);
    final difference = today.difference(billDate).inDays;

    if (difference == 0) {
      return 'TODAY';
    } else if (difference == 1) {
      return 'YESTERDAY';
    } else {
      return DateFormat('dd MMM yyyy').format(date).toUpperCase();
    }
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

    // Group bills by date header
    final Map<String, List<BillModel>> groupedBills = {};
    for (final bill in provider.filteredBills) {
      final header = _getDateHeader(bill.createdAt);
      groupedBills.putIfAbsent(header, () => []).add(bill);
    }

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
                labelText: 'Search bills...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: _filter == 'All',
                    onSelected: (_) {
                      setState(() => _filter = 'All');
                      provider.filterBills('All');
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Today'),
                    selected: _filter == 'Today',
                    onSelected: (_) {
                      setState(() => _filter = 'Today');
                      provider.filterBills('Today');
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Last 7 Days'),
                    selected: _filter == 'Last 7 Days',
                    onSelected: (_) {
                      setState(() => _filter = 'Last 7 Days');
                      provider.filterBills('Last 7 Days');
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Last 30 Days'),
                    selected: _filter == 'Last 30 Days',
                    onSelected: (_) {
                      setState(() => _filter = 'Last 30 Days');
                      provider.filterBills('Last 30 Days');
                    },
                  ),
                  const SizedBox(width: 8),
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
          ),
          const SizedBox(height: 8),
          Expanded(
            child: provider.isLoadingHistory
                ? const Center(child: CircularProgressIndicator())
                : provider.filteredBills.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 64,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No Bills Found',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Generated bills will appear here.',
                              style: TextStyle(color: Theme.of(context).colorScheme.outline),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: groupedBills.keys.length,
                        itemBuilder: (context, sectionIndex) {
                          final header = groupedBills.keys.elementAt(sectionIndex);
                          final bills = groupedBills[header]!;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 16, bottom: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      header,
                                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.2,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                    const Divider(),
                                  ],
                                ),
                              ),
                              ...bills.map((bill) {
                                final hasCustomer = bill.customerName != null && bill.customerName!.trim().isNotEmpty;
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () => Navigator.of(context).pushNamed(
                                      AppConstants.routeBillDetails,
                                      arguments: bill.id,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                bill.billNumber,
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
                                          const SizedBox(height: 6),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              if (hasCustomer)
                                                Text(
                                                  'Customer: ${bill.customerName!.trim()}',
                                                  style: Theme.of(context).textTheme.bodyMedium,
                                                )
                                              else
                                                Text(
                                                  '${provider.getItemCountForBill(bill.id)} items',
                                                  style: TextStyle(color: Theme.of(context).colorScheme.outline),
                                                ),
                                              Text(
                                                DateFormat('hh:mm a').format(bill.createdAt),
                                                style: TextStyle(color: Theme.of(context).colorScheme.outline),
                                              ),
                                            ],
                                          ),
                                          if (bill.customerPhone != null && bill.customerPhone!.trim().isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              'Phone: ${bill.customerPhone!.trim()}',
                                              style: TextStyle(color: Theme.of(context).colorScheme.outline),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
