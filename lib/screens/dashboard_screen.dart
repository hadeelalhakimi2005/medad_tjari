import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/app_models.dart';
import '../services/app_data.dart';
import 'customer_details_screen.dart';
import 'cash_sales_screen.dart';
import 'suppliers_screen.dart';
import 'reports_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final appData = AppData.instance;

    return ListenableBuilder(
      listenable: appData,
      builder: (context, _) {
        final symbol = appData.currencySymbol;
        final customers = appData.customers;

        return Scaffold(
          backgroundColor: AppColors.background,

          // 1. الشريط العلوي: كحلي غامق وعنوانه "مِداد تجاري"
          appBar: AppBar(
            title: const Text('مِداد تجاري'),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.person_outline, size: 26),
                tooltip: 'الملف الشخصي',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('ملف التاجر الشخصي')),
                  );
                },
              ),
            ],
          ),

          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // زر "فاتورة جديدة" المتميز والأبرز في أعلى الشاشة
                _buildQuickInvoiceBanner(context),

                const SizedBox(height: 16),

                // 2. الكروت الإحصائية الثلاثة في الأعلى
                _buildSummaryCards(appData, symbol),

                const SizedBox(height: 16),

                // أزرار وصول سريع للعمليات اليومية
                _buildQuickActionButtons(context),

                const SizedBox(height: 20),

                // 3. قسم "آخر ديون العملاء"
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'آخر ديون العملاء',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${customers.length} عميل مسجل',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // قائمة كروت العملاء
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: customers.length > 5 ? 5 : customers.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final customer = customers[index];
                    return _buildCustomerDebtCard(customer, symbol);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // لافتة وزر "فاتورة جديدة" السريعة
  Widget _buildQuickInvoiceBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تسجيل فاتورة جديدة',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'اختيار عميل أو كتابة جديد وحساب المتبقي تلقائياً',
                  style: TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _openQuickInvoiceBottomSheet(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text(
              'فاتورة جديدة +',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // الكروت الإحصائية الثلاثة
  Widget _buildSummaryCards(AppData appData, String symbol) {
    return Row(
      children: [
        // الكرت الأول: إجمالي الديون (أزرق)
        Expanded(
          child: _buildMetricCard(
            title: 'إجمالي الديون',
            value: appData.totalDebts.toStringAsFixed(0),
            subValue: symbol,
            valueColor: const Color(0xFF2563EB),
            icon: Icons.account_balance_wallet_outlined,
          ),
        ),
        const SizedBox(width: 8),

        // الكرت الثاني: مبيعات اليوم النقدية (أخضر زمردي)
        Expanded(
          child: _buildMetricCard(
            title: 'مبيعات الكاش',
            value: '+${appData.todayCashSalesTotal.toStringAsFixed(0)}',
            subValue: symbol,
            valueColor: AppColors.success,
            icon: Icons.trending_up,
          ),
        ),
        const SizedBox(width: 8),

        // الكرت الثالث: تنبيهات المخزون (أحمر مرجاني)
        Expanded(
          child: _buildMetricCard(
            title: 'تنبيهات المخزون',
            value: '3',
            subValue: 'أصناف قاربت النفاد',
            valueColor: AppColors.danger,
            icon: Icons.warning_amber_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subValue,
    required Color valueColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 22, color: valueColor),
          const SizedBox(height: 6),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
            ),
          ),
          Text(
            subValue,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // أزرار سريعة للوصول للعمليات التجارية والتقارير
  Widget _buildQuickActionButtons(BuildContext context) {
    return Row(
      children: [
        // زر المبيعات النقدية
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CashSalesScreen()),
              );
            },
            icon: const Icon(Icons.point_of_sale_rounded, size: 16),
            label: const Text('مبيعات كاش', style: TextStyle(fontSize: 11)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        const SizedBox(width: 6),

        // زر الموردين
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SuppliersScreen()),
              );
            },
            icon: const Icon(Icons.local_shipping_outlined, size: 16),
            label: const Text('الموردين', style: TextStyle(fontSize: 11)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        const SizedBox(width: 6),

        // زر التقارير
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ReportsScreen()),
              );
            },
            icon: const Icon(Icons.bar_chart_rounded, size: 16, color: AppColors.success),
            label: const Text('التقارير', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }

  // كرت العميل في لوحة التحكم (حساب الرصيد الدقيق وسقف الدين)
  Widget _buildCustomerDebtCard(Customer customer, String symbol) {
    final double net = customer.credit - customer.debt;
    final String displayAmount;
    final String statusLabel;
    final Color statusColor;

    if (net == 0) {
      displayAmount = '0 $symbol';
      statusLabel = 'خالص';
      statusColor = AppColors.textSecondary;
    } else if (net < 0) {
      displayAmount = '${(-net).toStringAsFixed(2)} $symbol';
      statusLabel = 'عليـه';
      statusColor = AppColors.danger;
    } else {
      displayAmount = '${net.toStringAsFixed(2)} $symbol';
      statusLabel = 'لــه';
      statusColor = AppColors.success;
    }

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CustomerDetailsScreen(customer: customer),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: customer.isCreditLimitExceeded
                ? AppColors.danger.withValues(alpha: 0.4)
                : AppColors.border,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // الجهة اليمنى: اسم العميل وتنبيه سقف الدين
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          customer.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (customer.isCreditLimitExceeded) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 16),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    customer.phone.isNotEmpty ? customer.phone : 'عميل مسجل',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // الوسط: مبلغ الرصيد
            Expanded(
              flex: 3,
              child: Center(
                child: Text(
                  displayAmount,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: net < 0
                        ? AppColors.danger
                        : (net > 0 ? AppColors.success : AppColors.textSecondary),
                  ),
                ),
              ),
            ),

            // الجهة اليسرى: شارة الحالة الصافية (عليه / له / خالص)
            Expanded(
              flex: 3,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // نافذة "فاتورة جديدة" السريعة (Modal Bottom Sheet)
  // -------------------------------------------------------------
  void _openQuickInvoiceBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const QuickInvoiceSheet(),
    );
  }
}

// ويجت الفاتورة السريعة مع حساب المتبقي تلقائياً
class QuickInvoiceSheet extends StatefulWidget {
  const QuickInvoiceSheet({super.key});

  @override
  State<QuickInvoiceSheet> createState() => _QuickInvoiceSheetState();
}

class _QuickInvoiceSheetState extends State<QuickInvoiceSheet> {
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _totalAmountController = TextEditingController();
  final TextEditingController _paidAmountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  double _total = 0.0;
  double _paid = 0.0;
  double get _remaining => (_total - _paid).clamp(0.0, double.infinity);

  @override
  void initState() {
    super.initState();
    _totalAmountController.addListener(() {
      setState(() {
        _total = double.tryParse(_totalAmountController.text) ?? 0.0;
      });
    });
    _paidAmountController.addListener(() {
      setState(() {
        _paid = double.tryParse(_paidAmountController.text) ?? 0.0;
      });
    });
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _phoneController.dispose();
    _totalAmountController.dispose();
    _paidAmountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final symbol = AppData.instance.currencySymbol;
    final allCustomers = AppData.instance.customers;

    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // مقبض السحب والعنوان
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.flash_on_rounded, color: AppColors.success),
                    SizedBox(width: 6),
                    Text(
                      'فاتورة جديدة سريعة',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 1. اختيار عميل موجود أو كتابة عميل جديد
            Autocomplete<Customer>(
              displayStringForOption: (Customer c) => c.name,
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return const Iterable<Customer>.empty();
                }
                return allCustomers.where((c) =>
                    c.name.toLowerCase().contains(textEditingValue.text.toLowerCase()));
              },
              onSelected: (Customer selection) {
                _customerNameController.text = selection.name;
                _phoneController.text = selection.phone;
              },
              fieldViewBuilder: (context, fieldTextEditingController, fieldFocusNode, onFieldSubmitted) {
                // مزامنة حقل الإدخال
                fieldTextEditingController.addListener(() {
                  _customerNameController.text = fieldTextEditingController.text;
                });
                return TextField(
                  controller: fieldTextEditingController,
                  focusNode: fieldFocusNode,
                  decoration: const InputDecoration(
                    labelText: 'اسم العميل (اختر عميل أو اكتب اسماً جديداً)',
                    prefixIcon: Icon(Icons.person_search_rounded),
                    hintText: 'مثال: محمد العمري',
                  ),
                );
              },
            ),

            const SizedBox(height: 10),

            // رقم الهاتف (اختياري للعميل الجديد)
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'رقم هاتف العميل (واتساب - اختياري)',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),

            const SizedBox(height: 16),

            // 2. إجمالي الفاتورة والمدفوع كاش
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _totalAmountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'إجمالي الفاتورة ($symbol)',
                      prefixIcon: const Icon(Icons.receipt_outlined),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _paidAmountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'المدفوع كاش ($symbol)',
                      prefixIcon: const Icon(Icons.payments_outlined),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // 3. كرت حساب المتبقي التلقائي
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _remaining > 0
                    ? AppColors.danger.withValues(alpha: 0.08)
                    : AppColors.success.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _remaining > 0
                      ? AppColors.danger.withValues(alpha: 0.3)
                      : AppColors.success.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        _remaining > 0 ? Icons.error_outline_rounded : Icons.check_circle_outline,
                        color: _remaining > 0 ? AppColors.danger : AppColors.success,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _remaining > 0 ? 'المتبقي (يضاف كدين على العميل):' : 'الفاتورة مسددة بالكامل كاش:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: _remaining > 0 ? AppColors.danger : AppColors.success,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${_remaining.toStringAsFixed(2)} $symbol',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: _remaining > 0 ? AppColors.danger : AppColors.success,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ملاحظات الفاتورة (اختياري)
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'ملاحظات الفاتورة / الأصناف (اختياري)',
                prefixIcon: Icon(Icons.edit_note_rounded),
              ),
            ),

            const SizedBox(height: 18),

            // زر الحفظ السريع
            ElevatedButton(
              onPressed: () {
                final customerName = _customerNameController.text.trim();
                if (customerName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('الرجاء إدخال اسم العميل أولاً')),
                  );
                  return;
                }

                if (_total <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('الرجاء إدخال مبلغ صحيح للفاتورة')),
                  );
                  return;
                }

                // حفظ الفاتورة وتحديث الدين وحساب العميل تلقائياً
                AppData.instance.processQuickInvoice(
                  customerName: customerName,
                  customerPhone: _phoneController.text.trim(),
                  totalAmount: _total,
                  paidAmount: _paid,
                  invoiceNotes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
                );

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'تم حفظ الفاتورة للعميل ($customerName)، والمتبقي (${_remaining.toStringAsFixed(2)} $symbol) أضيف لحسابه فوراً!',
                    ),
                    backgroundColor: AppColors.success,
                    duration: const Duration(seconds: 3),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                'حفظ الفاتورة وترحيل الحساب فوراً',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
