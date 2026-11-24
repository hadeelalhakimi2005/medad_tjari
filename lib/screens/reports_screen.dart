import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/app_models.dart';
import '../services/app_data.dart';
import 'customer_details_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _customerSearchController = TextEditingController();
  String _customerQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _customerSearchController.addListener(() {
      setState(() {
        _customerQuery = _customerSearchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _customerSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appData = AppData.instance;
    final symbol = appData.currencySymbol;

    return ListenableBuilder(
      listenable: appData,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('مركز التقارير والكشوفات'),
            centerTitle: true,
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.success,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              tabs: const [
                Tab(
                  icon: Icon(Icons.people_alt_outlined),
                  text: 'كشوفات حساب العملاء',
                ),
                Tab(
                  icon: Icon(Icons.inventory_2_outlined),
                  text: 'تقرير المخزون',
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.print_outlined),
                tooltip: 'تصدير / طباعة التقرير',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('جاري إعداد تقرير PDF المالي والمخزوني للطباعة والمشاركة...'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                },
              ),
            ],
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              // 1. تقرير كشف حساب العملاء (مدين، دائن، الرصيد)
              _buildCustomersReportTab(appData, symbol),

              // 2. تقرير المخزون (Inventory Report)
              _buildInventoryReportTab(appData, symbol),
            ],
          ),
        );
      },
    );
  }

  // ===========================================================================
  // التبويب الأول: تقرير كشف حساب العملاء (مدين، دائن، الرصيد)
  // ===========================================================================
  Widget _buildCustomersReportTab(AppData appData, String symbol) {
    final customers = appData.customers;
    final filtered = _customerQuery.isEmpty
        ? customers
        : customers.where((c) => c.name.toLowerCase().contains(_customerQuery)).toList();

    final exceededCount = customers.where((c) => c.isCreditLimitExceeded).length;

    return Column(
      children: [
        // كروت المؤشرات الإجمالية
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildReportStat(
                      title: 'إجمالي مدين (عليه)',
                      value: '${appData.totalDebts.toStringAsFixed(2)} $symbol',
                      color: AppColors.danger,
                      icon: Icons.arrow_upward_rounded,
                    ),
                  ),
                  Container(width: 1, height: 40, color: AppColors.border),
                  Expanded(
                    child: _buildReportStat(
                      title: 'إجمالي دائن (له)',
                      value: '${appData.totalCredits.toStringAsFixed(2)} $symbol',
                      color: AppColors.success,
                      icon: Icons.arrow_downward_rounded,
                    ),
                  ),
                ],
              ),
              const Divider(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'صافي ديون السوق: ${appData.netMarketBalance.toStringAsFixed(2)} $symbol',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: appData.netMarketBalance >= 0 ? AppColors.danger : AppColors.success,
                    ),
                  ),
                  if (exceededCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        '$exceededCount تجاوزوا سقف الدين ⚠️',
                        style: const TextStyle(fontSize: 11, color: AppColors.danger, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),

        // حقل البحث في كشوفات الحساب
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _customerSearchController,
            decoration: InputDecoration(
              hintText: 'بحث في كشوفات العملاء...',
              prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
              suffixIcon: _customerQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => _customerSearchController.clear(),
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // قائمة كشوفات حساب كل عميل (مدين، دائن، الرصيد)
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('لا يوجد عملاء مطابقين للبحث', style: TextStyle(color: AppColors.textSecondary)))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final customer = filtered[index];
                    return _buildCustomerStatementCard(customer, symbol);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCustomerStatementCard(Customer customer, String symbol) {
    final net = customer.credit - customer.debt; // الرصيد = له - عليه
    final String balanceLabel;
    final Color balanceColor;

    if (net == 0) {
      balanceLabel = 'الرصيد: 0 $symbol (خالص)';
      balanceColor = AppColors.textSecondary;
    } else if (net < 0) {
      balanceLabel = 'الرصيد: ${(-net).toStringAsFixed(2)} $symbol عليه';
      balanceColor = AppColors.danger;
    } else {
      balanceLabel = 'الرصيد: ${net.toStringAsFixed(2)} $symbol له';
      balanceColor = AppColors.success;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: customer.isCreditLimitExceeded ? AppColors.danger.withValues(alpha: 0.5) : AppColors.border,
          width: customer.isCreditLimitExceeded ? 1.4 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    customer.name,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  if (customer.isCreditLimitExceeded) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 16),
                  ],
                ],
              ),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CustomerDetailsScreen(customer: customer),
                    ),
                  );
                },
                child: const Row(
                  children: [
                    Text(
                      'عرض الحركات',
                      style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                    Icon(Icons.chevron_left_rounded, size: 16, color: AppColors.primary),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMiniColumn('مدين (عليه)', '${customer.debt.toStringAsFixed(2)} $symbol', AppColors.danger),
                Container(width: 1, height: 25, color: AppColors.border),
                _buildMiniColumn('دائن (له)', '${customer.credit.toStringAsFixed(2)} $symbol', AppColors.success),
                Container(width: 1, height: 25, color: AppColors.border),
                _buildMiniColumn('سقف الدين', customer.creditLimit != null ? '${customer.creditLimit!.toStringAsFixed(0)} $symbol' : 'غير محدد', AppColors.textSecondary),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                balanceLabel,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: balanceColor),
              ),
              Text(
                '${customer.transactions.length} حركات مسجلة',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // التبويب الثاني: تقرير المخزون (Inventory Report)
  // ===========================================================================
  Widget _buildInventoryReportTab(AppData appData, String symbol) {
    final products = appData.products;
    final totalItems = products.length;
    final totalUnits = products.fold(0, (sum, p) => sum + p.quantity);
    final lowStock = appData.lowStockProductsCount;
    final totalValue = appData.totalInventoryValue;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // كروت إحصائيات المخزون
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  title: 'إجمالي الأصناف',
                  value: '$totalItems صنف',
                  icon: Icons.category_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricTile(
                  title: 'إجمالي الكميات',
                  value: '$totalUnits قطعة/كيس',
                  icon: Icons.inventory_2_outlined,
                  color: const Color(0xFF2563EB),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  title: 'نقص المخزون',
                  value: '$lowStock أصناف',
                  icon: Icons.warning_amber_rounded,
                  color: AppColors.danger,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricTile(
                  title: 'قيمة بضاعة المخزون',
                  value: '${totalValue.toStringAsFixed(0)} $symbol',
                  icon: Icons.monetization_on_outlined,
                  color: AppColors.success,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // جدول حالة المخزون التفصيلي
          const Text(
            'حالة وتفاصيل المخزون الحالية',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 10),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: products.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final product = products[index];
              final itemValue = product.quantity * (product.sellingPrice > 0 ? product.sellingPrice : product.costPrice);

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: product.isLowStock ? AppColors.danger.withValues(alpha: 0.4) : AppColors.border,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: (product.isLowStock ? AppColors.danger : AppColors.success).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            product.isLowStock ? 'نقص مخزون' : 'متوفر',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: product.isLowStock ? AppColors.danger : AppColors.success,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('الكمية الحالية: ${product.quantity} ${product.unit}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        Text('سعر البيع: ${product.sellingPrice.toStringAsFixed(2)} $symbol', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        Text('إجمالي القيمة: ${itemValue.toStringAsFixed(2)} $symbol', style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReportStat({required String title, required String value, required Color color, required IconData icon}) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildMiniColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildMetricTile({required String title, required String value, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
