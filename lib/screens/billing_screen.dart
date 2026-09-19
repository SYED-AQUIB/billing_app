import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_constants.dart';
import '../models/product.dart';
import '../providers/bill_provider.dart';
import '../providers/category_provider.dart';
import '../providers/product_provider.dart';
import 'cart_screen.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  final TextEditingController _searchController = TextEditingController();
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().loadCategories();
      context.read<ProductProvider>().loadProducts();
      context.read<BillProvider>().initializeBillNumber();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showQuantityDialog(Product product) {
    final quantityController = TextEditingController(text: '1');
    final amountController = TextEditingController(
      text: product.pricePerUnit.toStringAsFixed(2),
    );
    final isWeightedUnit = _isWeightedUnit(product.unitType);
    final quantityFocusNode = FocusNode();
    final amountFocusNode = FocusNode();
    bool amountMode = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(sheetContext).viewInsets.bottom + 16,
          ),
          child: StatefulBuilder(
            builder: (bottomSheetContext, setBottomSheetState) {
              final amount = double.tryParse(amountController.text);
              final liveWeight =
                  amount != null && amount > 0 && product.pricePerUnit > 0
                  ? amount / product.pricePerUnit
                  : null;

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: Theme.of(
                            bottomSheetContext,
                          ).textTheme.titleLarge,
                        ),
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 56,
                          height: 56,
                          child: _buildProductImage(
                            bottomSheetContext,
                            product,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.brand,
                    style: Theme.of(bottomSheetContext).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${product.pricePerUnit.toStringAsFixed(2)} / ${product.unitType}',
                    style: Theme.of(bottomSheetContext).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  if (isWeightedUnit) ...[
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment<bool>(
                          value: false,
                          label: Text('Quantity'),
                        ),
                        ButtonSegment<bool>(value: true, label: Text('Amount')),
                      ],
                      selected: {amountMode},
                      onSelectionChanged: (selection) {
                        setBottomSheetState(() => amountMode = selection.first);
                      },
                    ),
                    const SizedBox(height: 12),
                    if (!amountMode) ...[
                      TextField(
                        controller: quantityController,
                        focusNode: quantityFocusNode,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Quantity (${product.unitType})',
                        ),
                      ),
                    ] else ...[
                      TextField(
                        controller: amountController,
                        focusNode: amountFocusNode,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Amount (₹)',
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (liveWeight != null)
                        Text(
                          'Calculated weight: ${liveWeight.toStringAsFixed(3)} ${product.unitType}',
                          style: Theme.of(
                            bottomSheetContext,
                          ).textTheme.bodyMedium,
                        ),
                    ],
                  ] else ...[
                    TextField(
                      controller: quantityController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Quantity (${product.unitType})',
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 48,
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        double? parsedQuantity;
                        if (isWeightedUnit && amountMode) {
                          final parsedAmount = double.tryParse(
                            amountController.text,
                          );
                          if (parsedAmount == null || parsedAmount <= 0) {
                            ScaffoldMessenger.of(
                              bottomSheetContext,
                            ).showSnackBar(
                              const SnackBar(
                                content: Text('Enter valid amount'),
                              ),
                            );
                            return;
                          }
                          parsedQuantity = parsedAmount / product.pricePerUnit;
                        } else {
                          parsedQuantity = double.tryParse(
                            quantityController.text,
                          );
                          if (parsedQuantity == null || parsedQuantity <= 0) {
                            ScaffoldMessenger.of(
                              bottomSheetContext,
                            ).showSnackBar(
                              const SnackBar(
                                content: Text('Enter valid quantity'),
                              ),
                            );
                            return;
                          }
                        }
                        context.read<BillProvider>().addItem(
                          product,
                          quantity: parsedQuantity,
                          pricePerUnit: product.pricePerUnit,
                        );
                        Navigator.of(sheetContext).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Added to Cart')),
                        );
                      },
                      child: const Text('Add to Cart'),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    ).whenComplete(() {
      quantityController.dispose();
      amountController.dispose();
      quantityFocusNode.dispose();
      amountFocusNode.dispose();
    });
  }

  bool _isWeightedUnit(String unitType) {
    return AppConstants.weightedUnits.contains(unitType);
  }

  Widget _buildProductImage(BuildContext context, Product product) {
    final imagePath = product.imagePath?.trim();
    final placeholder = ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Center(child: Icon(Icons.shopping_bag_outlined, size: 40)),
    );

    if (imagePath == null || imagePath.isEmpty) {
      return placeholder;
    }

    return Image.file(
      File(imagePath),
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => placeholder,
    );
  }

  void _openCart() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const CartScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final categoryProvider = context.watch<CategoryProvider>();
    final productProvider = context.watch<ProductProvider>();
    final billNumber = context.select<BillProvider, String>(
      (provider) => provider.billNumber,
    );
    final cartIsEmpty = context.select<BillProvider, bool>(
      (provider) => provider.cartItems.isEmpty,
    );

    final filteredProducts = productProvider.products.where((product) {
      final matchesCategory =
          _selectedCategoryId == null ||
          product.categoryId == _selectedCategoryId;
      final searchQuery = _searchController.text.trim().toLowerCase();
      final matchesSearch =
          searchQuery.isEmpty ||
          product.name.toLowerCase().contains(searchQuery) ||
          product.brand.toLowerCase().contains(searchQuery);
      return matchesCategory && matchesSearch;
    }).toList();

    return PopScope(
      canPop: cartIsEmpty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || cartIsEmpty) {
          return;
        }

        final shouldDiscard = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Discard current bill?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Discard'),
                ),
              ],
            );
          },
        );

        if (!context.mounted) {
          return;
        }

        if (shouldDiscard == true) {
          context.read<BillProvider>().clearCart();
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text('New Bill • $billNumber')),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Search products',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            SizedBox(
              height: 56,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: categoryProvider.categories.length + 1,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return ChoiceChip(
                      label: const Text('All'),
                      selected: _selectedCategoryId == null,
                      onSelected: (_) =>
                          setState(() => _selectedCategoryId = null),
                    );
                  }
                  final category = categoryProvider.categories[index - 1];
                  return ChoiceChip(
                    label: Text(category.name),
                    selected: _selectedCategoryId == category.id,
                    onSelected: (_) =>
                        setState(() => _selectedCategoryId = category.id),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: productProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 240,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.72,
                          ),
                      itemCount: filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = filteredProducts[index];
                        return Card(
                          child: InkWell(
                            onTap: () => _showQuantityDialog(product),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: SizedBox.expand(
                                        child: _buildProductImage(
                                          context,
                                          product,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    product.name,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (product.brand.trim().isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      product.brand,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                  const SizedBox(height: 4),
                                  Text(
                                    '${product.unitType} • ₹${product.pricePerUnit.toStringAsFixed(2)}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
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
        floatingActionButton:
            Selector<BillProvider, ({int count, double total})>(
              selector: (_, provider) =>
                  (count: provider.cartItems.length, total: provider.total),
              builder: (context, cart, _) {
                if (cart.count == 0) {
                  return const SizedBox.shrink();
                }

                return FloatingActionButton.extended(
                  onPressed: _openCart,
                  icon: const Icon(Icons.shopping_cart),
                  label: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Cart (${cart.count})'),
                      Text('₹${cart.total.toStringAsFixed(2)}'),
                    ],
                  ),
                );
              },
            ),
      ),
    );
  }
}
