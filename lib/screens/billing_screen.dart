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
    final priceController = TextEditingController(
      text: product.pricePerUnit.toStringAsFixed(2),
    );
    final isWeightedUnit = _isWeightedUnit(product.unitType);
    final quantityFocusNode = FocusNode();
    final amountFocusNode = FocusNode();
    bool amountMode = false;
    bool updatePrice = false; // checkbox state for permanent price update

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
              final price = double.tryParse(priceController.text);
              final effectivePrice = price ?? product.pricePerUnit;
              final amount = double.tryParse(amountController.text);
              final liveWeight =
                  amount != null && amount > 0 && effectivePrice > 0
                      ? amount / effectivePrice
                      : null;
              final quantity = double.tryParse(quantityController.text);
              final liveAmount =
                  quantity != null && quantity > 0 && effectivePrice > 0
                      ? quantity * effectivePrice
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
                  // Price override input
                  TextField(
                    controller: priceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setBottomSheetState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Price per unit',
                    ),
                  ),
                  CheckboxListTile(
                    title: const Text('Update product price'),
                    value: updatePrice,
                    onChanged: (val) => setBottomSheetState(() => updatePrice = val ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
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
                        onChanged: (_) => setBottomSheetState(() {}),
                        decoration: InputDecoration(
                          labelText: 'Quantity (${product.unitType})',
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (liveAmount != null)
                        Text(
                          'Calculated total: ₹${liveAmount.toStringAsFixed(2)}',
                          style: Theme.of(bottomSheetContext).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(bottomSheetContext).colorScheme.primary,
                          ),
                        ),
                    ] else ...[
                      TextField(
                        controller: amountController,
                        focusNode: amountFocusNode,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (_) => setBottomSheetState(() {}),
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
                          ).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(bottomSheetContext).colorScheme.primary,
                          ),
                        ),
                    ],
                  ] else ...[
                    Row(
                      children: [
                        IconButton.filledTonal(
                          icon: const Icon(Icons.remove),
                          onPressed: () {
                            final current = double.tryParse(quantityController.text) ?? 1;
                            if (current > 1) {
                              final next = current - 1;
                              quantityController.text = next == next.roundToDouble()
                                  ? next.toInt().toString()
                                  : next.toString();
                              setBottomSheetState(() {});
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: quantityController,
                            focusNode: quantityFocusNode,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            textAlign: TextAlign.center,
                            onChanged: (_) => setBottomSheetState(() {}),
                            decoration: InputDecoration(
                              labelText: 'Quantity (${product.unitType})',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            final current = double.tryParse(quantityController.text) ?? 0;
                            final next = current + 1;
                            quantityController.text = next == next.roundToDouble()
                                ? next.toInt().toString()
                                : next.toString();
                            setBottomSheetState(() {});
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (liveAmount != null)
                      Text(
                        'Total: ₹${liveAmount.toStringAsFixed(2)}',
                        style: Theme.of(bottomSheetContext).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(bottomSheetContext).colorScheme.primary,
                        ),
                      ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 48,
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        double? parsedQuantity;
                        // Determine effective price per unit
                        final effectivePrice = price ?? product.pricePerUnit;
                        if (isWeightedUnit && amountMode) {
                          final parsedAmount = double.tryParse(amountController.text);
                          if (parsedAmount == null || parsedAmount <= 0) {
                            ScaffoldMessenger.of(bottomSheetContext).showSnackBar(
                              const SnackBar(content: Text('Enter valid amount')),
                            );
                            return;
                          }
                          parsedQuantity = parsedAmount / effectivePrice;
                        } else {
                          parsedQuantity = double.tryParse(quantityController.text);
                          if (parsedQuantity == null || parsedQuantity <= 0) {
                            ScaffoldMessenger.of(bottomSheetContext).showSnackBar(
                              const SnackBar(content: Text('Enter valid quantity')),
                            );
                            return;
                          }
                        }
                        // Capture context-dependent objects before the async gap
                        final productProvider = context.read<ProductProvider>();
                        final billProvider = context.read<BillProvider>();
                        final scaffoldMessenger = ScaffoldMessenger.of(context);
                        final navigator = Navigator.of(sheetContext);
                        // If permanent price update requested, update product via provider
                        if (updatePrice && effectivePrice != product.pricePerUnit) {
                          final updatedProduct = Product(
                            id: product.id,
                            categoryId: product.categoryId,
                            brand: product.brand,
                            name: product.name,
                            unitType: product.unitType,
                            pricePerUnit: effectivePrice,
                            imagePath: product.imagePath,
                            createdAt: product.createdAt,
                          );
                          await productProvider.updateProduct(updatedProduct);
                        }
                        // Add to cart with the effective price
                        billProvider.addItem(
                          product,
                          quantity: parsedQuantity,
                          pricePerUnit: effectivePrice,
                        );
                        navigator.pop();
                        scaffoldMessenger.showSnackBar(
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
      priceController.dispose();
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

    final List<({String title, List<Product> products})> sections = [];
    if (_selectedCategoryId != null) {
      final category = categoryProvider.categories
          .where((c) => c.id == _selectedCategoryId)
          .firstOrNull;
      final title = category?.name ?? 'Category';
      if (filteredProducts.isNotEmpty) {
        sections.add((title: title, products: filteredProducts));
      }
    } else {
      for (final cat in categoryProvider.categories) {
        final prods =
            filteredProducts.where((p) => p.categoryId == cat.id).toList();
        if (prods.isNotEmpty) {
          sections.add((title: cat.name, products: prods));
        }
      }
      final knownIds = categoryProvider.categories.map((c) => c.id).toSet();
      final otherProds = filteredProducts
          .where((p) => !knownIds.contains(p.categoryId))
          .toList();
      if (otherProds.isNotEmpty) {
        sections.add((title: 'Other', products: otherProds));
      }
    }

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
                  : filteredProducts.isEmpty
                      ? const Center(child: Text('No products found'))
                      : CustomScrollView(
                          slivers: [
                            for (final section in sections) ...[
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        section.title.toUpperCase(),
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
                              ),
                              SliverPadding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                sliver: SliverGrid(
                                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                    maxCrossAxisExtent: 240,
                                    mainAxisSpacing: 12,
                                    crossAxisSpacing: 12,
                                    childAspectRatio: 0.72,
                                  ),
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) {
                                      final product = section.products[index];
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
                                    childCount: section.products.length,
                                  ),
                                ),
                              ),
                            ],
                            const SliverToBoxAdapter(child: SizedBox(height: 16)),
                          ],
                        ),
            ),
          ],
        ),
        bottomNavigationBar: Selector<BillProvider, ({int count, double total})>(
  selector: (_, provider) => (count: provider.cartItems.length, total: provider.total),
  builder: (context, cart, _) {
    final isEmpty = cart.count == 0;
    return Material(
      elevation: 4,
      child: InkWell(
        onTap: _openCart,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isEmpty ? 'Cart is empty' : '${cart.count} Items',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              if (!isEmpty)
                Text(
                  '₹${cart.total.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  },
),
      ),
    );
  }
}
