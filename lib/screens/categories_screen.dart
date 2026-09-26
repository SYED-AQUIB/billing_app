import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../providers/category_provider.dart';
import '../providers/product_provider.dart';
import '../widgets/image_picker_field.dart';
import '../models/product.dart';
import '../utils/unit_types.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().loadCategories();
    });
  }

  Future<void> _showCategoryDialog({Category? category}) async {
    final nameController = TextEditingController(text: category?.name ?? '');
    String? imagePath = category?.imagePath;

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(category == null ? 'Add Category' : 'Edit Category'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Category Name'),
                ),
                const SizedBox(height: 16),
                ImagePickerField(
                  initialPath: imagePath,
                  onPicked: (path) => imagePath = path,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Category name is required')));
                  return;
                }
                final provider = context.read<CategoryProvider>();
                final categoryToSave = Category(
                  id: category?.id,
                  name: name,
                  imagePath: imagePath,
                  createdAt: category?.createdAt ?? DateTime.now(),
                );
                final success = category == null ? await provider.addCategory(categoryToSave) : await provider.updateCategory(categoryToSave);
                if (!mounted) return;
                if (success) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(category == null ? 'Category added' : 'Category updated')));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to save category')));
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteCategory(Category category) async {
    final provider = context.read<CategoryProvider>();
    final deleted = await provider.deleteCategory(category.id!);
    if (!mounted) return;
    if (deleted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Category deleted')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot delete category with products')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryProvider = context.watch<CategoryProvider>();
    final productProvider = context.watch<ProductProvider>();
    final categories = categoryProvider.categories;

    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Add Category button
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () => _showCategoryDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Add Category'),
              ),
            ),
            const SizedBox(height: 16),
            if (categoryProvider.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (categories.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No categories yet. Add the first category to organize products.'),
                ),
              )
            else
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.92,
                  ),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final productCount = productProvider.products.where((p) => p.categoryId == category.id).length;
                    return Card(
                      child: InkWell(
                        onTap: () async {
                          // Navigate to category-specific product view
                          await Navigator.of(context).push(MaterialPageRoute(builder: (_) => CategoryProductsScreen(category: category)));
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: category.imagePath != null && category.imagePath!.isNotEmpty
                                      ? Image.file(File(category.imagePath!), fit: BoxFit.cover, errorBuilder: (_, _, _) => const Icon(Icons.image_not_supported_outlined, size: 40))
                                      : const Icon(Icons.category_outlined, size: 48),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                category.name,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$productCount product${productCount == 1 ? '' : 's'}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                              ),
                              const Spacer(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    onPressed: () => _showCategoryDialog(category: category),
                                    icon: const Icon(Icons.edit_outlined),
                                  ),
                                  IconButton(
                                    onPressed: () => _deleteCategory(category),
                                    icon: const Icon(Icons.delete_outline),
                                  ),
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
      ),
    );
  }
}

// --- New screen for viewing products within a category ---
class CategoryProductsScreen extends StatefulWidget {
  final Category category;
  const CategoryProductsScreen({required this.category, super.key});

  @override
  State<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Reuse product dialog from the original ProductsScreen (copy logic)
  Future<void> _showProductDialog({Product? product}) async {
    final categoryProvider = context.read<CategoryProvider>();
    final productProvider = context.read<ProductProvider>();

    final brandController = TextEditingController(text: product?.brand ?? '');
    final nameController = TextEditingController(text: product?.name ?? '');
    final unitTypeController = TextEditingController(text: product?.unitType ?? 'Kg');
    final priceController = TextEditingController(text: product?.pricePerUnit.toString() ?? '');
    int? selectedCategoryId = product?.categoryId ?? widget.category.id;
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
                        items: categoryProvider.categories.map((c) => DropdownMenuItem<int>(value: c.id, child: Text(c.name))).toList(),
                        onChanged: (v) => setState(() => selectedCategoryId = v),
                        decoration: const InputDecoration(labelText: 'Category'),
                      ),
                      const SizedBox(height: 12),
                      TextField(controller: brandController, decoration: const InputDecoration(labelText: 'Brand')),
                      const SizedBox(height: 12),
                      TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Product Name')),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: unitTypeController.text.isEmpty ? 'Kg' : unitTypeController.text,
                        items: UnitTypes.values.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
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
                TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
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
                    final success = product == null ? await productProvider.addProduct(productToSave) : await productProvider.updateProduct(productToSave);
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
    final allProducts = productProvider.products.where((p) => p.categoryId == widget.category.id).toList();
    final filteredProducts = _searchController.text.isEmpty
        ? allProducts
        : allProducts.where((p) => p.name.toLowerCase().contains(_searchController.text.toLowerCase()) || p.brand.toLowerCase().contains(_searchController.text.toLowerCase())).toList();

    return Scaffold(
      appBar: AppBar(title: Text(widget.category.name)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(labelText: 'Search products', prefixIcon: Icon(Icons.search)),
            ),
          ),
          if (productProvider.isLoading)
            const Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())
          else if (filteredProducts.isEmpty)
            const Expanded(child: Center(child: Padding(padding: EdgeInsets.all(24), child: Text('No products found in this category.'))))
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
                itemCount: filteredProducts.length,
                itemBuilder: (context, index) {
                  final product = filteredProducts[index];
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
