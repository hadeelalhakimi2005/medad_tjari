import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../database/db_helper.dart';
import 'backup_service.dart';

class CurrencyOption {
  final String code;
  final String nameAr;
  final String symbol;

  const CurrencyOption({
    required this.code,
    required this.nameAr,
    required this.symbol,
  });
}

class AppData extends ChangeNotifier {
  static final AppData instance = AppData._internal();
  AppData._internal() {
    _initApp();
  }

  // خيارات العملات المتاحة
  final List<CurrencyOption> availableCurrencies = const [
    CurrencyOption(code: 'YER', nameAr: 'ريال يمني', symbol: 'YER'),
    CurrencyOption(code: 'SAR', nameAr: 'ريال سعودي', symbol: 'SAR'),
    CurrencyOption(code: 'USD', nameAr: 'دولار أمريكي', symbol: 'USD'),
  ];

  late CurrencyOption _currentCurrency = availableCurrencies[1];
  CurrencyOption get currentCurrency => _currentCurrency;
  String get currencySymbol => _currentCurrency.symbol;

  void setCurrency(CurrencyOption newCurrency) {
    _currentCurrency = newCurrency;
    DatabaseHelper.instance.setSetting('currency', newCurrency.code);
    _onDataChanged();
  }

  // القوائم الحية في الذاكرة لسرعة الاستجابة
  final List<Customer> _customers = [];
  List<Customer> get customers => List.unmodifiable(_customers);

  final List<ProductItem> _products = [];
  List<ProductItem> get products => List.unmodifiable(_products);

  final List<CashSale> _cashSales = [];
  List<CashSale> get cashSales => List.unmodifiable(_cashSales);

  final List<Supplier> _suppliers = [];
  List<Supplier> get suppliers => List.unmodifiable(_suppliers);

  final List<PurchaseItem> _purchases = [];
  List<PurchaseItem> get purchases => List.unmodifiable(_purchases);

  // إحصائيات مالية عامة ومؤشرات التقارير
  double get totalDebts => _customers.fold(0.0, (sum, c) => sum + c.debt);
  double get totalCredits => _customers.fold(0.0, (sum, c) => sum + c.credit);
  double get netMarketBalance => totalDebts - totalCredits;
  double get todayCashSalesTotal => _cashSales.fold(0.0, (sum, s) => sum + s.amount);
  int get lowStockProductsCount => _products.where((p) => p.isLowStock).length;
  double get totalInventoryValue =>
      _products.fold(0.0, (sum, p) => sum + (p.quantity * (p.costPrice > 0 ? p.costPrice : p.sellingPrice)));

  // دالة الحفظ والنسخ الاحتياطي التلقائي
  void _onDataChanged() {
    notifyListeners();
    BackupService.instance.triggerAutoBackup(exportStateJson());
  }

  // تهيئة قاعدة بيانات SQLite وتحميل البيانات المسجلة منها
  Future<void> _initApp() async {
    await loadFromDatabase();
  }

  Future<void> loadFromDatabase() async {
    try {
      final dbHelper = DatabaseHelper.instance;

      final loadedCustomers = await dbHelper.getAllCustomers();
      final loadedProducts = await dbHelper.getAllProducts();
      final loadedSales = await dbHelper.getAllCashSales();
      final loadedSuppliers = await dbHelper.getAllSuppliers();
      final loadedPurchases = await dbHelper.getAllPurchases();
      final savedCurrency = await dbHelper.getSetting('currency');

      _customers.clear();
      _customers.addAll(loadedCustomers);

      _products.clear();
      _products.addAll(loadedProducts);

      _cashSales.clear();
      _cashSales.addAll(loadedSales);

      _suppliers.clear();
      _suppliers.addAll(loadedSuppliers);

      _purchases.clear();
      _purchases.addAll(loadedPurchases);

      if (savedCurrency != null) {
        final match = availableCurrencies.where((c) => c.code == savedCurrency);
        if (match.isNotEmpty) {
          _currentCurrency = match.first;
        }
      }

      notifyListeners();

      // تشغيل نسخة احتياطية أولية فور التحميل
      BackupService.instance.triggerAutoBackup(exportStateJson());
    } catch (e) {
      debugPrint('Error loading from SQLite: $e');
    }
  }

  // ===========================================================================
  // العمليات على العملاء والديون مع حفظ فوري في SQLite
  // ===========================================================================
  Customer getOrCreateCustomer({
    required String name,
    String phone = '',
    double? creditLimit,
  }) {
    final existingIndex = _customers.indexWhere(
      (c) => c.name.trim().toLowerCase() == name.trim().toLowerCase(),
    );

    if (existingIndex != -1) {
      if (creditLimit != null) {
        _customers[existingIndex].creditLimit = creditLimit;
        DatabaseHelper.instance.updateCustomerBalances(_customers[existingIndex]);
      }
      return _customers[existingIndex];
    } else {
      final newCustomer = Customer(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name.trim(),
        phone: phone.trim().isEmpty ? 'غير محدد' : phone.trim(),
        debt: 0.0,
        credit: 0.0,
        creditLimit: creditLimit,
      );
      _customers.insert(0, newCustomer);
      DatabaseHelper.instance.saveCustomer(newCustomer);
      _onDataChanged();
      return newCustomer;
    }
  }

  void updateCustomerCreditLimit(String customerId, double? limit) {
    final index = _customers.indexWhere((c) => c.id == customerId);
    if (index != -1) {
      _customers[index].creditLimit = limit;
      DatabaseHelper.instance.updateCustomerBalances(_customers[index]);
      _onDataChanged();
    }
  }

  void addCustomer(Customer customer) {
    _customers.insert(0, customer);
    DatabaseHelper.instance.saveCustomer(customer);
    _onDataChanged();
  }

  // عملية الفاتورة السريعة
  void processQuickInvoice({
    required String customerName,
    String customerPhone = '',
    required double totalAmount,
    required double paidAmount,
    String? invoiceNotes,
  }) {
    final customer = getOrCreateCustomer(
      name: customerName,
      phone: customerPhone,
    );

    final remaining = totalAmount - paidAmount;

    final invoiceTx = CustomerTransaction(
      id: 'inv_${DateTime.now().millisecondsSinceEpoch}',
      title: 'فاتورة سريعة (إجمالي: ${totalAmount.toStringAsFixed(2)} $currencySymbol)',
      amount: totalAmount,
      date: DateTime.now(),
      type: 'debit',
      notes: invoiceNotes ?? 'تم دفع كاش: ${paidAmount.toStringAsFixed(2)} $currencySymbol',
    );
    customer.transactions.insert(0, invoiceTx);
    DatabaseHelper.instance.saveTransaction(customer.id, invoiceTx);

    if (paidAmount > 0) {
      final paymentTx = CustomerTransaction(
        id: 'pay_${DateTime.now().millisecondsSinceEpoch}',
        title: 'دفعة كاش فورية مع الفاتورة',
        amount: paidAmount,
        date: DateTime.now(),
        type: 'credit',
      );
      customer.transactions.insert(0, paymentTx);
      DatabaseHelper.instance.saveTransaction(customer.id, paymentTx);
    }

    if (remaining > 0) {
      customer.debt += remaining;
    } else if (remaining < 0) {
      customer.credit += (-remaining);
    }

    DatabaseHelper.instance.updateCustomerBalances(customer);
    _onDataChanged();
  }

  // تسجيل دفعة (سند قبض) لعميل
  void recordCustomerPayment({
    required String customerId,
    required double paymentAmount,
    String? notes,
  }) {
    final customer = _customers.firstWhere((c) => c.id == customerId);

    final tx = CustomerTransaction(
      id: 'pay_${DateTime.now().millisecondsSinceEpoch}',
      title: 'سند قبض نقدية',
      amount: paymentAmount,
      date: DateTime.now(),
      type: 'credit',
      notes: notes,
    );

    customer.transactions.insert(0, tx);
    DatabaseHelper.instance.saveTransaction(customer.id, tx);

    if (customer.debt >= paymentAmount) {
      customer.debt -= paymentAmount;
    } else {
      final excess = paymentAmount - customer.debt;
      customer.debt = 0.0;
      customer.credit += excess;
    }

    DatabaseHelper.instance.updateCustomerBalances(customer);
    _onDataChanged();
  }

  // تسجيل دين إضافي لعميل
  void recordCustomerDebt({
    required String customerId,
    required double debtAmount,
    String? title,
    String? notes,
  }) {
    final customer = _customers.firstWhere((c) => c.id == customerId);

    final tx = CustomerTransaction(
      id: 'deb_${DateTime.now().millisecondsSinceEpoch}',
      title: title ?? 'قيد دين آجل',
      amount: debtAmount,
      date: DateTime.now(),
      type: 'debit',
      notes: notes,
    );

    customer.transactions.insert(0, tx);
    DatabaseHelper.instance.saveTransaction(customer.id, tx);

    customer.debt += debtAmount;
    DatabaseHelper.instance.updateCustomerBalances(customer);
    _onDataChanged();
  }

  // ===========================================================================
  // العمليات على المخزون والمبيعات والموردين مع حفظ فوري في SQLite
  // ===========================================================================
  void addProduct(ProductItem product) {
    _products.insert(0, product);
    DatabaseHelper.instance.saveProduct(product);
    _onDataChanged();
  }

  void addProductQuantity(String productId, int quantityToAdd) {
    final index = _products.indexWhere((p) => p.id == productId);
    if (index != -1) {
      _products[index].quantity += quantityToAdd;
      DatabaseHelper.instance.updateProductQuantity(productId, _products[index].quantity);
      _onDataChanged();
    }
  }

  void addCashSale({
    required String itemsDescription,
    required double amount,
  }) {
    final sale = CashSale(
      id: 'cs_${DateTime.now().millisecondsSinceEpoch}',
      itemsDescription: itemsDescription,
      amount: amount,
      date: DateTime.now(),
    );
    _cashSales.insert(0, sale);
    DatabaseHelper.instance.saveCashSale(sale);
    _onDataChanged();
  }

  void addSupplier({
    required String name,
    required String phone,
    double initialBalance = 0.0,
  }) {
    final supplier = Supplier(
      id: 'sup_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      phone: phone,
      balance: initialBalance,
    );
    _suppliers.insert(0, supplier);
    DatabaseHelper.instance.saveSupplier(supplier);
    _onDataChanged();
  }

  void addPurchase({
    required String supplierName,
    required String invoiceNumber,
    required double totalAmount,
    required double paidAmount,
  }) {
    final purchase = PurchaseItem(
      id: 'pur_${DateTime.now().millisecondsSinceEpoch}',
      supplierName: supplierName,
      invoiceNumber: invoiceNumber,
      totalAmount: totalAmount,
      paidAmount: paidAmount,
      date: DateTime.now(),
    );
    _purchases.insert(0, purchase);
    DatabaseHelper.instance.savePurchase(purchase);

    final remaining = purchase.remainingAmount;
    final supplierIndex = _suppliers.indexWhere((s) => s.name == supplierName);
    if (supplierIndex != -1 && remaining > 0) {
      _suppliers[supplierIndex].balance += remaining;
      DatabaseHelper.instance.updateSupplierBalance(_suppliers[supplierIndex].id, _suppliers[supplierIndex].balance);
    }

    _onDataChanged();
  }

  // تصدير كل بيانات التطبيق للنسخ الاحتياطي
  Map<String, dynamic> exportStateJson() {
    return {
      'appName': 'مِداد تجاري (MEDAD TJARI)',
      'exportedAt': DateTime.now().toIso8601String(),
      'currency': _currentCurrency.code,
      'currencySymbol': _currentCurrency.symbol,
      'statistics': {
        'totalDebts': totalDebts,
        'totalCredits': totalCredits,
        'netMarketBalance': netMarketBalance,
        'todayCashSales': todayCashSalesTotal,
        'totalProducts': _products.length,
        'lowStockCount': lowStockProductsCount,
      },
      'customers': _customers.map((c) => {
        'id': c.id,
        'name': c.name,
        'phone': c.phone,
        'debt': c.debt,
        'credit': c.credit,
        'netBalance': c.balance,
        'creditLimit': c.creditLimit,
        'isOverdue': c.isOverdue,
        'transactions': c.transactions.map((t) => {
          'id': t.id,
          'title': t.title,
          'amount': t.amount,
          'date': t.date.toIso8601String(),
          'type': t.type,
          'notes': t.notes,
        }).toList(),
      }).toList(),
      'products': _products.map((p) => {
        'id': p.id,
        'name': p.name,
        'quantity': p.quantity,
        'unit': p.unit,
        'lowStockThreshold': p.lowStockThreshold,
        'costPrice': p.costPrice,
        'sellingPrice': p.sellingPrice,
      }).toList(),
      'cashSales': _cashSales.map((s) => {
        'id': s.id,
        'items': s.itemsDescription,
        'amount': s.amount,
        'date': s.date.toIso8601String(),
      }).toList(),
      'suppliers': _suppliers.map((s) => {
        'id': s.id,
        'name': s.name,
        'phone': s.phone,
        'balance': s.balance,
      }).toList(),
      'purchases': _purchases.map((p) => {
        'id': p.id,
        'supplier': p.supplierName,
        'invoiceNumber': p.invoiceNumber,
        'total': p.totalAmount,
        'paid': p.paidAmount,
        'date': p.date.toIso8601String(),
      }).toList(),
    };
  }
}
