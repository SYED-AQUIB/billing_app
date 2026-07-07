import 'package:flutter/material.dart';

import '../core/app_constants.dart';
import '../widgets/home_action_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Grocery Billing'),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).pushNamed(AppConstants.routeSettings),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Manage products and categories for your shop.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.05,
                children: [
                  HomeActionCard(
                    title: 'New Bill',
                    icon: Icons.receipt_long_outlined,
                    onTap: () => Navigator.of(context).pushNamed(AppConstants.routeBilling),
                  ),
                  HomeActionCard(
                    title: 'Products',
                    icon: Icons.inventory_2_outlined,
                    onTap: () => Navigator.of(context).pushNamed(AppConstants.routeProducts),
                  ),
                  HomeActionCard(
                    title: 'Categories',
                    icon: Icons.category_outlined,
                    onTap: () => Navigator.of(context).pushNamed(AppConstants.routeCategories),
                  ),
                  HomeActionCard(
                    title: 'Bill History',
                    icon: Icons.history_outlined,
                    onTap: () => Navigator.of(context).pushNamed(AppConstants.routeBillHistory),
                  ),
                  HomeActionCard(
                    title: 'Settings',
                    icon: Icons.tune_outlined,
                    onTap: () => Navigator.of(context).pushNamed(AppConstants.routeSettings),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
