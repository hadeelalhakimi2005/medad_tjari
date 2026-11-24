import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/app_models.dart';
import '../services/app_data.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final appData = AppData.instance;

    return ListenableBuilder(
      listenable: appData,
      builder: (context, _) {
        final products = appData.products;
        final filteredProducts = _selectedFilter == 'low'
            ? products.where((p) => p.isLowStock).toList()
            : products;

        return Scaffold(
          backgroundColor: AppColors.background,

          // 1. الشريط العلوي: كحلي غامق مع أيقونة فلترة
          appBar: AppBar(
            title: const Text('المخزون'),
            centerTitle: true,
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.filter_list_rounded),
                tooltip: 'تصفية المنتجات',
                onSelected: (value) {
                  setState(() {
                    _selectedFilter = value;
                  });
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'all',
                    child: Text('عرض جميع المنتجات'),
                  ),
                  const PopupMenuItem(
                    value: 'low',
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 18),
                        SizedBox(width: 8),
                        Text('نقص المخزون فقط'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // 3. الزر العائم (+) في أسفل اليمين
          floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddNewProductDialog(context),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            tooltip: 'إضافة صنف جديد',
            elevation: 4,
            shape: const CircleBorder(),
            child: const Icon(Icons.add, size: 28),
          ),

          // 2. قائمة كروت المنتجات
          body: filteredProducts.isEmpty
              ? const Center(
                  child: Text(
                    'لا توجد أصناف مطابقة للتصفية',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredProducts.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return _buildProductCard(filteredProducts[index]);
                  },
                ),
        );
      },
    );
  }

  // كرت المنتج
  Widget _buildProductCard(ProductItem product) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: product.isLowStock
              ? AppColors.danger.withValues(alpha: 0.4)
              : AppColors.border,
          width: product.isLowStock ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // اسم الصنف على اليمين
              Expanded(
                child: Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),

              // شارة حمراء مكتوب فيها "نقص المخزون" مع أيقونة تحذير
              if (product.isLowStock)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.danger),
                      SizedBox(width: 4),
                      Text(
                        'نقص المخزون',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.danger,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // الكمية الحالية
              Row(
                children: [
                  const Text(
                    'الكمية: ',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '${product.quantity} ${product.unit}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: product.isLowStock ? AppColors.danger : AppColors.primary,
                    ),
                  ),
                ],
              ),

              // زر "إضافة كمية" على الكرت
              OutlinedButton.icon(
                onPressed: () => _showAddQuantityDialog(product),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('إضافة كمية'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary, width: 1.2),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddQuantityDialog(ProductItem product) {
    int addedAmount = 1;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text('إضافة كمية: ${product.name}', style: const TextStyle(fontSize: 15)),
              content: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () {
                      if (addedAmount > 1) {
                        setDialogState(() => addedAmount--);
                      }
                    },
                    icon: const Icon(Icons.remove_circle_outline, color: AppColors.danger),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '$addedAmount ${product.unit}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setDialogState(() => addedAmount++);
                    },
                    icon: const Icon(Icons.add_circle_outline, color: AppColors.success),
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
                    AppData.instance.addProductQuantity(product.id, addedAmount);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('تمت إضافة $addedAmount ${product.unit} بنجاح!'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  },
                  child: const Text('تأكيد الإضافة'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddNewProductDialog(BuildContext context) {
    final nameController = TextEditingController();
    final qtyController = TextEditingController();
    final unitController = TextEditingController(text: 'حبة');
    final costPriceController = TextEditingController();
    final sellingPriceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('إضافة صنف جديد للمخزون', textAlign: TextAlign.center),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'اسم الصنف (مثال: سكر 50 كيلو)'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: qtyController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'الكمية الأولية'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 1,
                      child: TextField(
                        controller: unitController,
                        decoration: const InputDecoration(labelText: 'الوحدة'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: costPriceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'سعر التكلفة (${AppData.instance.currencySymbol})',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: sellingPriceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'سعر البيع (${AppData.instance.currencySymbol})',
                        ),
                      ),
                    ),
                  ],
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
                if (nameController.text.isNotEmpty && qtyController.text.isNotEmpty) {
                  final newProduct = ProductItem(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameController.text.trim(),
                    quantity: int.tryParse(qtyController.text) ?? 1,
                    unit: unitController.text.trim(),
                    costPrice: double.tryParse(costPriceController.text) ?? 0.0,
                    sellingPrice: double.tryParse(sellingPriceController.text) ?? 0.0,
                  );
                  AppData.instance.addProduct(newProduct);
                }
                Navigator.pop(context);
              },
              child: const Text('حفظ الصنف'),
            ),
          ],
        );
      },
    );
  }
}
