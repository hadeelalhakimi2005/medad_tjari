import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/app_models.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // دعم تشغيل SQLite على ويندوز وديسكتوب مع الأندرويد والآيفون
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'medad_tjari.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. جدول العملاء
    await db.execute('''
      CREATE TABLE customers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT,
        debt REAL DEFAULT 0.0,
        credit REAL DEFAULT 0.0,
        credit_limit REAL,
        is_overdue INTEGER DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    // 2. جدول حركات كشف الحساب (فواتير آجل وسندات قبض)
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        customer_id TEXT NOT NULL,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        type TEXT NOT NULL,
        notes TEXT,
        FOREIGN KEY (customer_id) REFERENCES customers (id) ON DELETE CASCADE
      )
    ''');

    // 3. جدول المنتجات والمخزون
    await db.execute('''
      CREATE TABLE products (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        quantity INTEGER DEFAULT 0,
        unit TEXT DEFAULT 'حبة',
        low_stock_threshold INTEGER DEFAULT 5,
        cost_price REAL DEFAULT 0.0,
        selling_price REAL DEFAULT 0.0
      )
    ''');

    // 4. جدول المبيعات النقدية للعملاء العابرين
    await db.execute('''
      CREATE TABLE cash_sales (
        id TEXT PRIMARY KEY,
        items_description TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL
      )
    ''');

    // 5. جدول الموردين
    await db.execute('''
      CREATE TABLE suppliers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT,
        balance REAL DEFAULT 0.0
      )
    ''');

    // 6. جدول المشتريات
    await db.execute('''
      CREATE TABLE purchases (
        id TEXT PRIMARY KEY,
        supplier_name TEXT NOT NULL,
        invoice_number TEXT NOT NULL,
        total_amount REAL NOT NULL,
        paid_amount REAL NOT NULL,
        date TEXT NOT NULL
      )
    ''');

    // 7. جدول إعدادات التطبيق
    await db.execute('''
      CREATE TABLE app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // زرع البيانات الأولية للمحل فور إنشاء قاعدة البيانات
    await _seedInitialData(db);
  }

  Future<void> _seedInitialData(Database db) async {
    final now = DateTime.now();

    // عملاء أوليين
    final initialCustomers = [
      {
        'id': '1',
        'name': 'عبدالرحمن باحاج',
        'phone': '966501234567',
        'debt': 620.0,
        'credit': 0.0,
        'credit_limit': 500.0,
        'is_overdue': 1,
        'created_at': now.subtract(const Duration(days: 10)).toIso8601String(),
      },
      {
        'id': '2',
        'name': 'سالم أحمد العمودي',
        'phone': '966507654321',
        'debt': 250.0,
        'credit': 100.0,
        'credit_limit': 600.0,
        'is_overdue': 0,
        'created_at': now.subtract(const Duration(days: 8)).toIso8601String(),
      },
      {
        'id': '3',
        'name': 'مطعم ومخبز الشام',
        'phone': '966555112233',
        'debt': 2450.0,
        'credit': 0.0,
        'credit_limit': 2000.0,
        'is_overdue': 1,
        'created_at': now.subtract(const Duration(days: 15)).toIso8601String(),
      },
      {
        'id': '4',
        'name': 'عمر خالد السقاف',
        'phone': '966544998877',
        'debt': 85.0,
        'credit': 0.0,
        'credit_limit': 300.0,
        'is_overdue': 0,
        'created_at': now.subtract(const Duration(days: 4)).toIso8601String(),
      },
      {
        'id': '5',
        'name': 'أبو فهد (ورشة النور)',
        'phone': '966500112244',
        'debt': 1100.0,
        'credit': 0.0,
        'credit_limit': 1000.0,
        'is_overdue': 1,
        'created_at': now.subtract(const Duration(days: 6)).toIso8601String(),
      },
      {
        'id': '6',
        'name': 'خالد سعيد باوزير (حساب خالص)',
        'phone': '966522334455',
        'debt': 0.0,
        'credit': 0.0,
        'credit_limit': 500.0,
        'is_overdue': 0,
        'created_at': now.subtract(const Duration(days: 2)).toIso8601String(),
      },
      {
        'id': '7',
        'name': 'ياسين أحمد المنصوري (رصيد له)',
        'phone': '966566778899',
        'debt': 0.0,
        'credit': 180.0,
        'credit_limit': 1000.0,
        'is_overdue': 0,
        'created_at': now.subtract(const Duration(days: 1)).toIso8601String(),
      },
    ];

    for (var c in initialCustomers) {
      await db.insert('customers', c);
    }

    // حركات أولية
    final initialTx = [
      {
        'id': 't1',
        'customer_id': '1',
        'title': 'فاتورة مواد غذائية #1042',
        'amount': 820.0,
        'date': now.subtract(const Duration(days: 4)).toIso8601String(),
        'type': 'debit',
        'notes': 'أرز وسكر وزيت',
      },
      {
        'id': 't2',
        'customer_id': '1',
        'title': 'سند قبض - دفعة نقدية',
        'amount': 200.0,
        'date': now.subtract(const Duration(days: 2)).toIso8601String(),
        'type': 'credit',
        'notes': 'دفعة عبر المحل',
      },
      {
        'id': 't3',
        'customer_id': '2',
        'title': 'فاتورة مشتريات #1055',
        'amount': 250.0,
        'date': now.subtract(const Duration(days: 1)).toIso8601String(),
        'type': 'debit',
        'notes': null,
      },
      {
        'id': 't4',
        'customer_id': '2',
        'title': 'رصيد دائن مسبق',
        'amount': 100.0,
        'date': now.subtract(const Duration(days: 1)).toIso8601String(),
        'type': 'credit',
        'notes': null,
      },
    ];

    for (var tx in initialTx) {
      await db.insert('transactions', tx);
    }

    // منتجات أولية
    final initialProducts = [
      {
        'id': '1',
        'name': 'سكر الأسرة (50 كيلو)',
        'quantity': 3,
        'unit': 'شوال',
        'low_stock_threshold': 5,
        'cost_price': 180.0,
        'selling_price': 205.0,
      },
      {
        'id': '2',
        'name': 'أرز بسمتي الشعلان (10 كيلو)',
        'quantity': 14,
        'unit': 'كيس',
        'low_stock_threshold': 5,
        'cost_price': 65.0,
        'selling_price': 78.0,
      },
      {
        'id': '3',
        'name': 'زيت دوار الشمس عافية (1.5 لتر)',
        'quantity': 2,
        'unit': 'كرتون',
        'low_stock_threshold': 4,
        'cost_price': 110.0,
        'selling_price': 128.0,
      },
      {
        'id': '4',
        'name': 'حليب نيدو مجفف (2500 جرام)',
        'quantity': 8,
        'unit': 'حبة',
        'low_stock_threshold': 3,
        'cost_price': 72.0,
        'selling_price': 85.0,
      },
      {
        'id': '5',
        'name': 'شاي الربيع الأصلي (100 كيس)',
        'quantity': 1,
        'unit': 'كرتون',
        'low_stock_threshold': 3,
        'cost_price': 140.0,
        'selling_price': 162.0,
      },
      {
        'id': '6',
        'name': 'معجون طماطم لونا',
        'quantity': 25,
        'unit': 'كرتون',
        'low_stock_threshold': 6,
        'cost_price': 38.0,
        'selling_price': 46.0,
      },
    ];

    for (var p in initialProducts) {
      await db.insert('products', p);
    }

    // مبيعات نقدية
    final initialSales = [
      {
        'id': 'cs1',
        'items_description': '2 كيس حليب نيدو + 1 شاي الربيع',
        'amount': 85.0,
        'date': now.subtract(const Duration(minutes: 25)).toIso8601String(),
      },
      {
        'id': 'cs2',
        'items_description': 'مشروبات غازية وحلويات أطفال',
        'amount': 42.5,
        'date': now.subtract(const Duration(hours: 1, minutes: 10)).toIso8601String(),
      },
    ];

    for (var s in initialSales) {
      await db.insert('cash_sales', s);
    }

    // موردين أوليين
    final initialSuppliers = [
      {
        'id': 's1',
        'name': 'مؤسسة باحمدين لتوزيع الأرز والسكر',
        'phone': '966512344321',
        'balance': 14500.0,
      },
      {
        'id': 's2',
        'name': 'شركة المراعي للمنتجات الطازجة',
        'phone': '966588990011',
        'balance': 3200.0,
      },
      {
        'id': 's3',
        'name': 'وكالة الشرق للمنظفات والبلاستيك',
        'phone': '966533221100',
        'balance': 1850.0,
      },
    ];

    for (var sup in initialSuppliers) {
      await db.insert('suppliers', sup);
    }

    // إعدادات افتراضية
    await db.insert('app_settings', {'key': 'currency', 'value': 'SAR'});
    await db.insert('app_settings', {'key': 'pin_code', 'value': '1234'});
  }

  // ===========================================================================
  // العمليات على العملاء والحركات (Customers & Transactions)
  // ===========================================================================
  Future<List<Customer>> getAllCustomers() async {
    final db = await database;
    final customerMaps = await db.query('customers', orderBy: 'rowid DESC');
    final List<Customer> customers = [];

    for (var map in customerMaps) {
      final customerId = map['id'] as String;
      final txMaps = await db.query(
        'transactions',
        where: 'customer_id = ?',
        whereArgs: [customerId],
        orderBy: 'date DESC',
      );

      final transactions = txMaps.map((t) => CustomerTransaction(
        id: t['id'] as String,
        title: t['title'] as String,
        amount: (t['amount'] as num).toDouble(),
        date: DateTime.parse(t['date'] as String),
        type: t['type'] as String,
        notes: t['notes'] as String?,
      )).toList();

      customers.add(Customer(
        id: customerId,
        name: map['name'] as String,
        phone: (map['phone'] as String?) ?? 'غير محدد',
        debt: (map['debt'] as num).toDouble(),
        credit: (map['credit'] as num).toDouble(),
        creditLimit: map['credit_limit'] != null ? (map['credit_limit'] as num).toDouble() : null,
        isOverdue: (map['is_overdue'] as int) == 1,
        transactions: transactions,
      ));
    }

    return customers;
  }

  Future<void> saveCustomer(Customer c) async {
    final db = await database;
    await db.insert(
      'customers',
      {
        'id': c.id,
        'name': c.name,
        'phone': c.phone,
        'debt': c.debt,
        'credit': c.credit,
        'credit_limit': c.creditLimit,
        'is_overdue': c.isOverdue ? 1 : 0,
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateCustomerBalances(Customer c) async {
    final db = await database;
    await db.update(
      'customers',
      {
        'debt': c.debt,
        'credit': c.credit,
        'credit_limit': c.creditLimit,
        'is_overdue': c.isOverdue ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [c.id],
    );
  }

  Future<void> saveTransaction(String customerId, CustomerTransaction tx) async {
    final db = await database;
    await db.insert(
      'transactions',
      {
        'id': tx.id,
        'customer_id': customerId,
        'title': tx.title,
        'amount': tx.amount,
        'date': tx.date.toIso8601String(),
        'type': tx.type,
        'notes': tx.notes,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ===========================================================================
  // العمليات على المخزون (Products)
  // ===========================================================================
  Future<List<ProductItem>> getAllProducts() async {
    final db = await database;
    final maps = await db.query('products', orderBy: 'rowid DESC');
    return maps.map((p) => ProductItem(
      id: p['id'] as String,
      name: p['name'] as String,
      quantity: p['quantity'] as int,
      unit: (p['unit'] as String?) ?? 'حبة',
      lowStockThreshold: (p['low_stock_threshold'] as int?) ?? 5,
      costPrice: (p['cost_price'] as num?)?.toDouble() ?? 0.0,
      sellingPrice: (p['selling_price'] as num?)?.toDouble() ?? 0.0,
    )).toList();
  }

  Future<void> saveProduct(ProductItem p) async {
    final db = await database;
    await db.insert(
      'products',
      {
        'id': p.id,
        'name': p.name,
        'quantity': p.quantity,
        'unit': p.unit,
        'low_stock_threshold': p.lowStockThreshold,
        'cost_price': p.costPrice,
        'selling_price': p.sellingPrice,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateProductQuantity(String id, int newQuantity) async {
    final db = await database;
    await db.update(
      'products',
      {'quantity': newQuantity},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ===========================================================================
  // العمليات على المبيعات النقدية (Cash Sales)
  // ===========================================================================
  Future<List<CashSale>> getAllCashSales() async {
    final db = await database;
    final maps = await db.query('cash_sales', orderBy: 'date DESC');
    return maps.map((s) => CashSale(
      id: s['id'] as String,
      itemsDescription: s['items_description'] as String,
      amount: (s['amount'] as num).toDouble(),
      date: DateTime.parse(s['date'] as String),
    )).toList();
  }

  Future<void> saveCashSale(CashSale sale) async {
    final db = await database;
    await db.insert(
      'cash_sales',
      {
        'id': sale.id,
        'items_description': sale.itemsDescription,
        'amount': sale.amount,
        'date': sale.date.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ===========================================================================
  // العمليات على الموردين والمشتريات (Suppliers & Purchases)
  // ===========================================================================
  Future<List<Supplier>> getAllSuppliers() async {
    final db = await database;
    final maps = await db.query('suppliers', orderBy: 'rowid DESC');
    return maps.map((s) => Supplier(
      id: s['id'] as String,
      name: s['name'] as String,
      phone: (s['phone'] as String?) ?? 'غير محدد',
      balance: (s['balance'] as num).toDouble(),
    )).toList();
  }

  Future<void> saveSupplier(Supplier s) async {
    final db = await database;
    await db.insert(
      'suppliers',
      {
        'id': s.id,
        'name': s.name,
        'phone': s.phone,
        'balance': s.balance,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateSupplierBalance(String id, double newBalance) async {
    final db = await database;
    await db.update(
      'suppliers',
      {'balance': newBalance},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<PurchaseItem>> getAllPurchases() async {
    final db = await database;
    final maps = await db.query('purchases', orderBy: 'date DESC');
    return maps.map((p) => PurchaseItem(
      id: p['id'] as String,
      supplierName: p['supplier_name'] as String,
      invoiceNumber: p['invoice_number'] as String,
      totalAmount: (p['total_amount'] as num).toDouble(),
      paidAmount: (p['paid_amount'] as num).toDouble(),
      date: DateTime.parse(p['date'] as String),
    )).toList();
  }

  Future<void> savePurchase(PurchaseItem p) async {
    final db = await database;
    await db.insert(
      'purchases',
      {
        'id': p.id,
        'supplier_name': p.supplierName,
        'invoice_number': p.invoiceNumber,
        'total_amount': p.totalAmount,
        'paid_amount': p.paidAmount,
        'date': p.date.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ===========================================================================
  // الإعدادات
  // ===========================================================================
  Future<String?> getSetting(String key) async {
    final db = await database;
    final maps = await db.query('app_settings', where: 'key = ?', whereArgs: [key]);
    if (maps.isNotEmpty) {
      return maps.first['value'] as String?;
    }
    return null;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'app_settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
