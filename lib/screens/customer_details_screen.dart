import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/app_models.dart';
import '../services/app_data.dart';

class CustomerDetailsScreen extends StatefulWidget {
  final Customer customer;

  const CustomerDetailsScreen({super.key, required this.customer});

  @override
  State<CustomerDetailsScreen> createState() => _CustomerDetailsScreenState();
}

class _CustomerDetailsScreenState extends State<CustomerDetailsScreen> {
  late Customer _customer;

  @override
  void initState() {
    super.initState();
    _customer = widget.customer;
  }

  @override
  Widget build(BuildContext context) {
    final appData = AppData.instance;
    final symbol = appData.currencySymbol;

    return ListenableBuilder(
      listenable: appData,
      builder: (context, _) {
        // العثور على أحدث نسخة من بيانات العميل
        final currentCustomer = appData.customers.firstWhere(
          (c) => c.id == _customer.id,
          orElse: () => _customer,
        );

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(currentCustomer.name),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF25D366)),
                tooltip: 'إرسال تذكير واتساب',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('إرسال كشف الحساب عبر الواتساب إلى ${currentCustomer.name}'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.phone_outlined),
                tooltip: 'اتصال بالعميل',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('الاتصال بالرقم: ${currentCustomer.phone}'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                },
              ),
            ],
          ),
          body: Column(
            children: [
              // تنبيه سقف المديونية إذا تجاوزه العميل
              if (currentCustomer.isCreditLimitExceeded)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.danger, width: 1.2),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 24),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'تنبيه: العميل تجاوز سقف المديونية المحدد (${currentCustomer.creditLimit?.toStringAsFixed(2)} $symbol)! يُرجى تسوية الحساب قبل تسجيل ديون جديدة.',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.danger,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // 1. بطاقات ملخص الحساب: له، عليه، الرصيد الصافي
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // كرت "له" (أخضر)
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.arrow_downward_rounded, color: AppColors.success, size: 18),
                                    SizedBox(width: 4),
                                    Text(
                                      'لــه',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.success,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    '${currentCustomer.credit.toStringAsFixed(2)} $symbol',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.success,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        // كرت "عليه" (أحمر)
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.danger.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.arrow_upward_rounded, color: AppColors.danger, size: 18),
                                    SizedBox(width: 4),
                                    Text(
                                      'عليـــه',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.danger,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    '${currentCustomer.debt.toStringAsFixed(2)} $symbol',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.danger,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),
                    const Divider(height: 1),
                    const SizedBox(height: 14),

                    // الرصيد الصافي (معادلة: له - عليه)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.account_balance_wallet_outlined, size: 20, color: AppColors.primary),
                            SizedBox(width: 8),
                            Text(
                              'صافي الرصيد:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          (currentCustomer.credit - currentCustomer.debt) == 0
                              ? 'الرصيد: 0 $symbol (خالص)'
                              : ((currentCustomer.credit - currentCustomer.debt) < 0
                                  ? 'الرصيد: ${(currentCustomer.debt - currentCustomer.credit).toStringAsFixed(2)} $symbol عليه'
                                  : 'الرصيد: ${(currentCustomer.credit - currentCustomer.debt).toStringAsFixed(2)} $symbol له'),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: (currentCustomer.credit - currentCustomer.debt) == 0
                                ? AppColors.textSecondary
                                : ((currentCustomer.credit - currentCustomer.debt) < 0
                                    ? AppColors.danger
                                    : AppColors.success),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // سقف المديونية مع زر التعديل
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.speed_rounded, size: 18, color: AppColors.textSecondary),
                            const SizedBox(width: 8),
                            const Text(
                              'سقف المديونية:',
                              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.primary),
                              tooltip: 'تحديد أو تعديل سقف الدين',
                              onPressed: () => _showEditCreditLimitDialog(context, currentCustomer),
                            ),
                          ],
                        ),
                        Text(
                          currentCustomer.creditLimit != null && currentCustomer.creditLimit! > 0
                              ? '${currentCustomer.creditLimit!.toStringAsFixed(2)} $symbol'
                              : 'غير محدد',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: currentCustomer.isCreditLimitExceeded
                                ? AppColors.danger
                                : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 2. أزرار العمليات السريعة للعميل
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    // زر قبض دفعة (سند قبض)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showPaymentDialog(context, currentCustomer),
                        icon: const Icon(Icons.payments_outlined, size: 18),
                        label: const Text('قبض دفعة'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // زر تسجيل دين جديد
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showAddDebtDialog(context, currentCustomer),
                        icon: const Icon(Icons.add_shopping_cart_outlined, size: 18),
                        label: const Text('تسجيل دين'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 3. عنوان كشف الحساب والحركات
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'كشف الحساب وسجل الحركات',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${currentCustomer.transactions.length} حركة',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // 4. قائمة الحركات (الفواتير والمدفوعات)
              Expanded(
                child: currentCustomer.transactions.isEmpty
                    ? const Center(
                        child: Text(
                          'لا توجد حركات مسجلة لهذا العميل بعد',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: currentCustomer.transactions.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final tx = currentCustomer.transactions[index];
                          final isDebit = tx.type == 'debit'; // فاتورة/دين (عليه)

                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                // أيقونة نوع الحركة (سهم أحمر لدين أو أخضر لدفعة)
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: (isDebit ? AppColors.danger : AppColors.success)
                                        .withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isDebit ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                                    size: 18,
                                    color: isDebit ? AppColors.danger : AppColors.success,
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // تفاصيل الحركة
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tx.title,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        _formatDate(tx.date),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      if (tx.notes != null && tx.notes!.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          tx.notes!,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textSecondary,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),

                                // المبلغ
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${isDebit ? '+' : '-'}${tx.amount.toStringAsFixed(2)} $symbol',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: isDebit ? AppColors.danger : AppColors.success,
                                      ),
                                    ),
                                    Text(
                                      isDebit ? 'قيد دين (عليه)' : 'دفعة نقدية (له)',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDebit ? AppColors.danger : AppColors.success,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')} - ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  // نافذة قبض دفعة (سند قبض)
  void _showPaymentDialog(BuildContext context, Customer customer) {
    final amountController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('قبض دفعة من: ${customer.name}', style: const TextStyle(fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'المبلغ المقبوض (${AppData.instance.currencySymbol})',
                  prefixIcon: const Icon(Icons.attach_money_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'ملاحظات أو رقم السند (اختياري)',
                  prefixIcon: Icon(Icons.note_alt_outlined),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(amountController.text) ?? 0.0;
                if (amount > 0) {
                  AppData.instance.recordCustomerPayment(
                    customerId: customer.id,
                    paymentAmount: amount,
                    notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('تم تسجيل دفعة بقيمة $amount ${AppData.instance.currencySymbol} بنجاح'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
              child: const Text('تأكيد القبض'),
            ),
          ],
        );
      },
    );
  }

  // نافذة تسجيل دين إضافي
  void _showAddDebtDialog(BuildContext context, Customer customer) {
    final amountController = TextEditingController();
    final titleController = TextEditingController(text: 'فاتورة مواد غذائية');
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('تسجيل دين على: ${customer.name}', style: const TextStyle(fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'بيان الفاتورة / الأصناف'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'مبلغ الدين (${AppData.instance.currencySymbol})',
                  prefixIcon: const Icon(Icons.monetization_on_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(labelText: 'ملاحظات إضافية'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(amountController.text) ?? 0.0;
                if (amount > 0) {
                  AppData.instance.recordCustomerDebt(
                    customerId: customer.id,
                    debtAmount: amount,
                    title: titleController.text.trim(),
                    notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('تم قيد دين جديد بقيمة $amount ${AppData.instance.currencySymbol} بنجاح'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                }
              },
              child: const Text('تسجيل الدين'),
            ),
          ],
        );
      },
    );
  }

  // نافذة تعديل سقف المديونية
  void _showEditCreditLimitDialog(BuildContext context, Customer customer) {
    final limitController = TextEditingController(
      text: customer.creditLimit != null && customer.creditLimit! > 0
          ? customer.creditLimit!.toStringAsFixed(0)
          : '',
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('تحديد سقف الدين: ${customer.name}', style: const TextStyle(fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'عند وصول ديون العميل إلى هذا الحد أو تجاوزها، سيظهر تنبيه أحمر ⚠️ في القوائم ولوحة التحكم.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: limitController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'الحد الأقصى للمديونية (${AppData.instance.currencySymbol})',
                  hintText: 'مثال: 500',
                  prefixIcon: const Icon(Icons.speed_rounded),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                final newLimit = double.tryParse(limitController.text);
                AppData.instance.updateCustomerCreditLimit(customer.id, newLimit);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(newLimit != null
                        ? 'تم ضبط سقف المديونية إلى $newLimit ${AppData.instance.currencySymbol}'
                        : 'تمت إزالة سقف المديونية'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              },
              child: const Text('حفظ السقف'),
            ),
          ],
        );
      },
    );
  }
}
