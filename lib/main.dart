import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/app_constants.dart';
import 'core/app_theme.dart';
import 'providers/bill_provider.dart';
import 'providers/category_provider.dart';
import 'providers/product_provider.dart';
import 'providers/shop_settings_provider.dart';
import 'screens/bill_details_screen.dart';
import 'screens/bill_history_screen.dart';
import 'screens/billing_screen.dart';
import 'screens/categories_screen.dart';
import 'screens/home_screen.dart';
import 'screens/products_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => BillProvider()),
        ChangeNotifierProvider(create: (_) => ShopSettingsProvider()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme(),
        initialRoute: AppConstants.routeHome,
        routes: {
          AppConstants.routeHome: (context) => const HomeScreen(),
          AppConstants.routeBilling: (context) => const BillingScreen(),
          AppConstants.routeBillHistory: (context) => const BillHistoryScreen(),
          AppConstants.routeBillDetails: (context) {
            final args = ModalRoute.of(context)?.settings.arguments;
            if (args is int) {
              return BillDetailsScreen(billId: args);
            }
            return const HomeScreen();
          },
          AppConstants.routeCategories: (context) => const CategoriesScreen(),
          AppConstants.routeProducts: (context) => const ProductsScreen(),
          AppConstants.routeSettings: (context) => const SettingsScreen(),
        },
      ),
    );
  }
}
