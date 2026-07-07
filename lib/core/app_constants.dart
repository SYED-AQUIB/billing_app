class AppConstants {
  AppConstants._();

  static const String appName = 'Grocery Billing App';
  static const String appVersion = '1.0.0+1';
  static const String defaultUnitType = 'Kg';
  static const int databaseVersion = 4;
  static const String unknownCategoryName = 'Unknown';

  static const String routeHome = '/';
  static const String routeBilling = '/billing';
  static const String routeBillHistory = '/bill-history';
  static const String routeSettings = '/settings';
  static const String routeCategories = '/categories';
  static const String routeProducts = '/products';
  static const String routeBillDetails = '/bill-details';

  static const String filterAll = 'All';
  static const String filterToday = 'Today';
  static const String filterLast7Days = 'Last 7 Days';
  static const String filterLast30Days = 'Last 30 Days';
  static const String filterCustomDate = 'Custom Date';

  static const List<String> weightedUnits = <String>['Kg', 'Gram', 'Litre', 'ml'];
}
