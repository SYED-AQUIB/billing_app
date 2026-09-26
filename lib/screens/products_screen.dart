import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/category_provider.dart';
import '../providers/product_provider.dart';
import '../utils/unit_types.dart';
import '../widgets/image_picker_field.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().loadCategories();
      context.read<ProductProvider>().loadProducts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showProductDialog({Product? product}) async {
    final categoryProvider = context.read<CategoryProvider>();
    final productProvider = context.read<ProductProvider>();

    final brandController = TextEditingController(text: product?.brand ?? '');
    final nameController = TextEditingController(text: product?.name ?? '');
    final unitTypeController = TextEditingController(text: product?.unitType ?? 'Kg');
    final priceController = TextEditingController(text: product?.pricePerUnit.toString() ?? '');
    int? selectedCategoryId = product?.categoryId;
    String? imagePath = product?.imagePath;

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return AlertDialog(
              title: Text(product == null ? 'Add Product' : 'Edit Product'),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 360,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<int>(
                        initialValue: selectedCategoryId,
                        items: categoryProvider.categories
                            .map((c) => DropdownMenuItem<int>(value: c.id, child: Text(c.name)))
                            .toList(),
                        onChanged: (v) => setState(() => selectedCategoryId = v),
                        decoration: const InputDecoration(labelText: 'Category'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: brandController,
                        decoration: const InputDecoration(labelText: 'Brand'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Product Name'),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: unitTypeController.text.isEmpty ? 'Kg' : unitTypeController.text,
                        items: UnitTypes.values
                            .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) {
                            unitTypeController.text = v;
                            setState(() {});
                          }
                        },
                        decoration: const InputDecoration(labelText: 'Unit Type'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: priceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Price Per Unit'),
                      ),
                      const SizedBox(height: 12),
                      ImagePickerField(
                        initialPath: imagePath,
                        onPicked: (p) => imagePath = p,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final categoryId = selectedCategoryId;
                    final brand = brandController.text.trim();
                    final name = nameController.text.trim();
                    final unitType = unitTypeController.text.trim();
                    final priceText = priceController.text.trim();
                    if (categoryId == null || brand.isEmpty || name.isEmpty || unitType.isEmpty || priceText.isEmpty) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All fields are required')));
                      return;
                    }
                    final price = double.tryParse(priceText);
                    if (price == null) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid price')));
                      return;
                    }
                    final productToSave = Product(
                      id: product?.id,
                      categoryId: categoryId,
                      brand: brand,
                      name: name,
                      unitType: unitType,
                      pricePerUnit: price,
                      imagePath: imagePath,
                      createdAt: product?.createdAt ?? DateTime.now(),
                    );
                    final success = product == null
                        ? await productProvider.addProduct(productToSave)
                        : await productProvider.updateProduct(productToSave);
                    if (!mounted) return;
                    if (success) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(product == null ? 'Product added' : 'Product updated')));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to save product')));
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteProduct(Product product) async {
    final provider = context.read<ProductProvider>();
    final deleted = await provider.deleteProduct(product.id!);
    if (!mounted) return;
    if (deleted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product deleted')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to delete product')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final categoryProvider = context.watch<CategoryProvider>();
    final products = productProvider.products;

    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => productProvider.search(v),
              decoration: const InputDecoration(
                labelText: 'Search products',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          if (categoryProvider.isLoading || productProvider.isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            )
          else if (products.isEmpty)
            const Expanded(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No products found. Add one to start building your billing catalog.'),
                ),
              ),
            )
          else
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.78,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return Card(
                    child: InkWell(
                      onTap: () => _showProductDialog(product: product),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: product.imagePath != null && product.imagePath!.isNotEmpty
                                  ? Image.file(File(product.imagePath!), height: 80, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, _, _) => const Icon(Icons.image_not_supported_outlined, size: 40))
                                  : const Icon(Icons.shopping_bag_outlined, size: 48),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              product.name,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (product.brand.isNotEmpty)
                              Text(product.brand, style: Theme.of(context).textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Text('${product.unitType} • ₹${product.pricePerUnit.toStringAsFixed(2)}', style: Theme.of(context).textTheme.bodySmall),
                            const Spacer(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _showProductDialog(product: product)),
                                IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _deleteProduct(product)),
                              ],
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showProductDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
