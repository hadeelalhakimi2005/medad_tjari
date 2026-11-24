import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/app_models.dart';
import '../services/app_data.dart';

class PurchasesScreen extends StatelessWidget {
  const PurchasesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appData = AppData.instance;
    final symbol = appData.currencySymbol;

    return ListenableBuilder(
      listenable: appData,
      builder: (context, _) {
        final purchases = appData.purchases;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('سجل المشتريات والفواتير'),
            centerTitle: true,
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddPurchaseDialog(context),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: const Text('فاتورة مشتريات جديدة'),
          ),
          body: purchases.isEmpty
              ? const Center(
                  child: Text(
                    'لا توجد فواتير مشتريات مسجلة',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: purchases.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final p = purchases[index];
                    return _buildPurchaseCard(p, symbol);
                  },
                ),
        );
      },
    );
  }

  Widget _buildPurchaseCard(PurchaseItem p, String symbol) {
    final remaining = p.remainingAmount;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                p.supplierName,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (remaining > 0 ? AppColors.danger : AppColors.success)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  remaining > 0 ? 'متبقي آجل' : 'مسددة بالكامل',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: remaining > 0 ? AppColors.danger : AppColors.success,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'رقم الفاتورة: ${p.invoiceNumber} | التاريخ: ${p.date.year}/${p.date.month}/${p.date.day}',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'الإجمالي: ${p.totalAmount.toStringAsFixed(2)} $symbol',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              Text(
                'المدفوع: ${p.paidAmount.toStringAsFixed(2)} $symbol',
                style: const TextStyle(fontSize: 13, color: AppColors.success),
              ),
              if (remaining > 0)
                Text(
                  'المتبقي: ${remaining.toStringAsFixed(2)} $symbol',
                  style: const TextStyle(fontSize: 13, color: AppColors.danger, fontWeight: FontWeight.bold),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddPurchaseDialog(BuildContext context) {
    final supplierController = TextEditingController();
    final invoiceNoController = TextEditingController();
    final totalController = TextEditingController();
    final paidController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('تسجيل فاتورة مشتريات', textAlign: TextAlign.center),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: supplierController,
                  decoration: const InputDecoration(labelText: 'اسم المورد / الشركة'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: invoiceNoController,
                  decoration: const InputDecoration(labelText: 'رقم الفاتورة الورقية'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: totalController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'إجمالي الفاتورة (${AppData.instance.currencySymbol})',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: paidController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'المبلغ المدفوع كاش (${AppData.instance.currencySymbol})',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                final total = double.tryParse(totalController.text) ?? 0.0;
                final paid = double.tryParse(paidController.text) ?? 0.0;
                if (supplierController.text.trim().isNotEmpty && total > 0) {
                  AppData.instance.addPurchase(
                    supplierName: supplierController.text.trim(),
                    invoiceNumber: invoiceNoController.text.trim().isEmpty
                        ? 'INV-${DateTime.now().millisecond}'
                        : invoiceNoController.text.trim(),
                    totalAmount: total,
                    paidAmount: paid,
                  );
                }
                Navigator.pop(context);
              },
              child: const Text('حفظ الفاتورة'),
            ),
          ],
        );
      },
    );
  }
}
