import 'package:flutter/material.dart';

import '../core/app_constants.dart';
import '../widgets/home_action_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    const greeting = 'Hello Sanaulla!';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Grocery Billing'),
        actions: [
          IconButton(
            onPressed: () =>
                Navigator.of(context).pushNamed(AppConstants.routeSettings),
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
              greeting,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 24),

            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.0,
                children: [
                  HomeActionCard(
                    title: 'SET CATEGORIES',
                    icon: Icons.category_outlined,
                    onTap: () => Navigator.of(context)
                        .pushNamed(AppConstants.routeCategories),
                  ),

                  HomeActionCard(
                    title: 'NEW BILL',
                    icon: Icons.receipt_long_outlined,
                    onTap: () => Navigator.of(context)
                        .pushNamed(AppConstants.routeBilling),
                  ),

                  HomeActionCard(
                    title: 'BILL HISTORY',
                    icon: Icons.history_outlined,
                    onTap: () => Navigator.of(context)
                        .pushNamed(AppConstants.routeBillHistory),
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