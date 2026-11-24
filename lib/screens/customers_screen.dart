import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/app_models.dart';
import '../services/app_data.dart';
import 'customer_details_screen.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appData = AppData.instance;

    return ListenableBuilder(
      listenable: appData,
      builder: (context, _) {
        final allCustomers = appData.customers;
        final filteredCustomers = _searchQuery.isEmpty
            ? allCustomers
            : allCustomers
                .where((c) => c.name.toLowerCase().contains(_searchQuery))
                .toList();

        return Scaffold(
          backgroundColor: AppColors.background,

          // 1. الشريط العلوي: كحلي غامق وعنوانه "العملاء" مع أيقونة بحث
          appBar: AppBar(
            title: const Text('العملاء'),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                tooltip: 'بحث عن عميل',
                onPressed: () {},
              ),
            ],
          ),

          // الزر العائم في أسفل اليمين (startFloat في RTL)
          floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddCustomerDialog(context),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            tooltip: 'إضافة عميل جديد',
            elevation: 4,
            shape: const CircleBorder(),
            child: const Icon(Icons.add, size: 28),
          ),

          // محتوى الشاشة
          body: Column(
            children: [
              // 2. شريط البحث أعلى القائمة
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'ابحث عن عميل...',
                    prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => _searchController.clear(),
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
              ),

              // 3. قائمة كروت العملاء
              Expanded(
                child: filteredCustomers.isEmpty
                    ? const Center(
                        child: Text(
                          'لا يوجد عملاء مطابقين للبحث',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        itemCount: filteredCustomers.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          return _buildCustomerCard(filteredCustomers[index], appData.currencySymbol);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  // كرت العميل الواحد (مع الرصيد المحسوب بدقة وتنبيه سقف المديونية)
  Widget _buildCustomerCard(Customer customer, String currencySymbol) {
    // حساب معادلة الرصيد بدقة: (الرصيد = له - عليه)
    final double net = customer.credit - customer.debt;

    // تحديد نص الرصيد ولونه وفق المتطلبات:
    // 1. إذا كان صفر: "الرصيد: 0" بلون رمادي هادئ
    // 2. إذا كان عليه ديون (net < 0): "الرصيد: [المبلغ] عليه" بالأحمر
    // 3. إذا كان له رصيد (net > 0): "الرصيد: [المبلغ] له" بالأخضر
    final String balanceText;
    final Color balanceColor;

    if (net == 0) {
      balanceText = 'الرصيد: 0 $currencySymbol (خالص)';
      balanceColor = AppColors.textSecondary;
    } else if (net < 0) {
      final debtAmount = (-net).toStringAsFixed(2);
      balanceText = 'الرصيد: $debtAmount $currencySymbol عليه';
      balanceColor = AppColors.danger;
    } else {
      final creditAmount = net.toStringAsFixed(2);
      balanceText = 'الرصيد: $creditAmount $currencySymbol له';
      balanceColor = AppColors.success;
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
                ? AppColors.danger.withValues(alpha: 0.5)
                : AppColors.border,
            width: customer.isCreditLimitExceeded ? 1.4 : 1.0,
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
            // اسم العميل + تنبيه سقف المديونية (⚠️) + الرصيد المحسوب
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          customer.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // ⚠️ ميزة سقف المديونية: إظهار أيقونة تحذير حمراء عند بلوغ أو تجاوز السقف
                      if (customer.isCreditLimitExceeded) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 14),
                              const SizedBox(width: 3),
                              Text(
                                'تجاوز السقف (${customer.creditLimit?.toStringAsFixed(0)} $currencySymbol)',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.danger,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else if (customer.isOverdue) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.danger,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 5),

                  // عرض الرصيد الدقيق وفق الحساب المالي (له - عليه)
                  Text(
                    balanceText,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: balanceColor,
                    ),
                  ),
                ],
              ),
            ),

            // أيقونة فتح كشف الحساب
            const Icon(
              Icons.chevron_left_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 8),

            // أيقونة واتساب خضراء لإرسال تذكير سريع
            InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('إرسال تذكير واتساب إلى العميل: ${customer.name}'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              },
              borderRadius: BorderRadius.circular(30),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF25D366).withValues(alpha: 0.4)),
                ),
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: Color(0xFF25D366),
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCustomerDialog(BuildContext context) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final limitController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('إضافة عميل جديد', textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'اسم العميل'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'رقم الهاتف (واتساب)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: limitController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'سقف المديونية (${AppData.instance.currencySymbol}) - اختياري',
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
                if (nameController.text.trim().isNotEmpty) {
                  final limit = double.tryParse(limitController.text);
                  AppData.instance.getOrCreateCustomer(
                    name: nameController.text.trim(),
                    phone: phoneController.text.trim(),
                    creditLimit: limit,
                  );
                }
                Navigator.pop(context);
              },
              child: const Text('حفظ العميل'),
            ),
          ],
        );
      },
    );
  }
}
