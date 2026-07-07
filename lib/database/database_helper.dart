import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = p.join(databasesPath, 'grocery_billing_app.db');

    return openDatabase(
      path,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE shop_settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        shopName TEXT NOT NULL,
        ownerName TEXT,
        phoneNumber TEXT,
        shopAddress TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        imagePath TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        categoryId INTEGER NOT NULL,
        brand TEXT NOT NULL,
        name TEXT NOT NULL,
        unitType TEXT NOT NULL,
        pricePerUnit REAL NOT NULL,
        imagePath TEXT,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (categoryId) REFERENCES categories(id) ON DELETE RESTRICT
      )
    ''');

    await db.execute('''
      CREATE TABLE bills (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        billNumber TEXT NOT NULL UNIQUE,
        customerName TEXT,
        customerPhone TEXT,
        subtotal REAL NOT NULL,
        total REAL NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE billItems (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        billId INTEGER NOT NULL,
        productId INTEGER NOT NULL,
        productName TEXT NOT NULL,
        brand TEXT NOT NULL,
        unitType TEXT NOT NULL,
        quantity REAL NOT NULL,
        pricePerUnit REAL NOT NULL,
        lineTotal REAL NOT NULL,
        FOREIGN KEY (billId) REFERENCES bills(id) ON DELETE CASCADE,
        FOREIGN KEY (productId) REFERENCES products(id) ON DELETE RESTRICT
      )
    ''');

    await db.execute('CREATE INDEX IF NOT EXISTS idx_categories_name ON categories(name)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_products_category_id ON products(categoryId)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_products_brand_name ON products(brand, name)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_bills_created_at ON bills(createdAt)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_bill_items_bill_id ON billItems(billId)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 4) {
      await db.execute('CREATE INDEX IF NOT EXISTS idx_categories_name ON categories(name)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_products_category_id ON products(categoryId)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_products_brand_name ON products(brand, name)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_bills_created_at ON bills(createdAt)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_bill_items_bill_id ON billItems(billId)');
    }

    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS shop_settings (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          shopName TEXT NOT NULL,
          ownerName TEXT,
          phoneNumber TEXT,
          shopAddress TEXT,
          createdAt TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS bills (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          billNumber TEXT NOT NULL UNIQUE,
          customerName TEXT,
          customerPhone TEXT,
          subtotal REAL NOT NULL,
          total REAL NOT NULL,
          createdAt TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS billItems (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          billId INTEGER NOT NULL,
          productId INTEGER NOT NULL,
          productName TEXT NOT NULL,
          brand TEXT NOT NULL,
          unitType TEXT NOT NULL,
          quantity REAL NOT NULL,
          pricePerUnit REAL NOT NULL,
          lineTotal REAL NOT NULL,
          FOREIGN KEY (billId) REFERENCES bills(id) ON DELETE CASCADE,
          FOREIGN KEY (productId) REFERENCES products(id) ON DELETE RESTRICT
        )
      ''');
    }
  }
}
