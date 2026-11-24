// نماذج البيانات لجميع أقسام التطبيق

class CustomerTransaction {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final String type; // 'debit' = عليه (فاتورة/دين), 'credit' = له (سند قبض/دفعة)
  final String? notes;

  CustomerTransaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.type,
    this.notes,
  });
}

class Customer {
  final String id;
  String name;
  String phone;
  double debt; // عليه (المبالغ المستحقة على العميل)
  double credit; // له (المبالغ المدفوعة مقدماً أو رصيد دائن)
  double? creditLimit; // سقف المديونية المحدد من التاجر
  bool isOverdue;
  List<CustomerTransaction> transactions;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    this.debt = 0.0,
    this.credit = 0.0,
    this.creditLimit,
    this.isOverdue = false,
    List<CustomerTransaction>? transactions,
  }) : transactions = transactions ?? [];

  // معادلة الرصيد: (الرصيد = له - عليه)
  double get balance => credit - debt;
  double get netBalance => balance;

  // صافي الدين المستحق على العميل (عليه - له)
  double get netDebt => debt - credit;

  // هل تجاوز العميل سقف المديونية المحدد؟
  bool get isCreditLimitExceeded =>
      creditLimit != null && creditLimit! > 0 && netDebt >= creditLimit!;
}

class CashSale {
  final String id;
  final String itemsDescription;
  final double amount;
  final DateTime date;

  CashSale({
    required this.id,
    required this.itemsDescription,
    required this.amount,
    required this.date,
  });
}

class Supplier {
  final String id;
  String name;
  String phone;
  double balance; // مستحقات المورد علينا

  Supplier({
    required this.id,
    required this.name,
    required this.phone,
    this.balance = 0.0,
  });
}

class PurchaseItem {
  final String id;
  final String supplierName;
  final String invoiceNumber;
  final double totalAmount;
  final double paidAmount;
  final DateTime date;

  PurchaseItem({
    required this.id,
    required this.supplierName,
    required this.invoiceNumber,
    required this.totalAmount,
    required this.paidAmount,
    required this.date,
  });

  double get remainingAmount => totalAmount - paidAmount;
}

class ProductItem {
  final String id;
  final String name;
  int quantity;
  final String unit;
  final int lowStockThreshold;
  final double costPrice;
  final double sellingPrice;

  ProductItem({
    required this.id,
    required this.name,
    required this.quantity,
    this.unit = 'حبة',
    this.lowStockThreshold = 5,
    this.costPrice = 0.0,
    this.sellingPrice = 0.0,
  });

  bool get isLowStock => quantity <= lowStockThreshold;
  bool get isOutOfStock => quantity <= 0;
}
