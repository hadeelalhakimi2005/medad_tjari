import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/app_data.dart';
import '../services/backup_service.dart';
import 'suppliers_screen.dart';
import 'purchases_screen.dart';
import 'cash_sales_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _storeName = 'بقالة ومحمص البركة';
  String _storePhone = '+966 50 123 4567';
  bool _pinLockEnabled = true;

  @override
  Widget build(BuildContext context) {
    final appData = AppData.instance;
    final backupService = BackupService.instance;

    return ListenableBuilder(
      listenable: Listenable.merge([appData, backupService]),
      builder: (context, _) {
        final currentCurr = appData.currentCurrency;
        final lastBackup = backupService.lastBackupTime;
        final lastBackupStr = lastBackup != null
            ? '${lastBackup.year}/${lastBackup.month}/${lastBackup.day} الساعة ${lastBackup.hour}:${lastBackup.minute.toString().padLeft(2, '0')}'
            : 'لم يتم أخذ نسخة احتياطية بعد';

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('الإعدادات'),
            centerTitle: true,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 1. اختيار العملة (Dropdown رئيسي تفاعلي)
              _buildSettingsSection(
                title: 'إعدادات العملة والنظام المالي',
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.monetization_on_outlined, color: AppColors.primary, size: 20),
                            ),
                            const SizedBox(width: 12),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'العملة المعتمدة',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  'تغيير العملة لجميع الشاشات والفواتير',
                                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // قائمة منسدلة (Dropdown) لاختيار العملة
                        DropdownButtonHideUnderline(
                          child: DropdownButton<CurrencyOption>(
                            value: appData.availableCurrencies.firstWhere(
                              (c) => c.code == currentCurr.code,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
                            items: appData.availableCurrencies.map((curr) {
                              return DropdownMenuItem<CurrencyOption>(
                                value: curr,
                                child: Text(
                                  '${curr.nameAr} (${curr.symbol})',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (selected) {
                              if (selected != null) {
                                appData.setCurrency(selected);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('تم تغيير العملة إلى: ${selected.nameAr} (${selected.symbol})'),
                                    backgroundColor: AppColors.primary,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 2. إعدادات المحل
              _buildSettingsSection(
                title: 'بيانات المحل والبقالة',
                children: [
                  _buildSettingsTile(
                    icon: Icons.store_rounded,
                    title: 'اسم المحل / البقالة',
                    subtitle: _storeName,
                    onTap: () => _editStoreNameDialog(),
                  ),
                  _buildSettingsTile(
                    icon: Icons.phone_android_rounded,
                    title: 'رقم هاتف المتجر',
                    subtitle: _storePhone,
                    onTap: () => _editStorePhoneDialog(),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 3. إدارة العمليات التجارية الإضافية (الموردين، المشتريات، المبيعات النقدية)
              _buildSettingsSection(
                title: 'إدارة المبيعات والتوريد',
                children: [
                  _buildSettingsTile(
                    icon: Icons.point_of_sale_rounded,
                    title: 'المبيعات النقدية (الكاش)',
                    subtitle: 'مبيعات العملاء العابرين دون فتح حسابات ديون',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CashSalesScreen()),
                      );
                    },
                  ),
                  _buildSettingsTile(
                    icon: Icons.local_shipping_outlined,
                    title: 'قائمة الموردين (Suppliers)',
                    subtitle: 'إدارة حسابات الشركات والموردين ومستحقاتهم',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SuppliersScreen()),
                      );
                    },
                  ),
                  _buildSettingsTile(
                    icon: Icons.receipt_long_outlined,
                    title: 'سجل المشتريات (Purchases)',
                    subtitle: 'فواتير البضاعة والمشتريات الآجلة والنقدية',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const PurchasesScreen()),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 4. النسخ الاحتياطي التلقائي والسحابي
              _buildSettingsSection(
                title: 'النسخ الاحتياطي والأمان المالي',
                children: [
                  // النسخ الاحتياطي التلقائي المحلي
                  _buildSettingsTile(
                    icon: Icons.sync_rounded,
                    title: 'النسخ الاحتياطي التلقائي (محلي)',
                    subtitle: 'حفظ فوري في ذاكرة الجهاز عند تسجيل أي فاتورة أو حركة',
                    trailing: Switch(
                      value: backupService.isAutoBackupEnabled,
                      activeThumbColor: AppColors.primary,
                      onChanged: (val) {
                        backupService.toggleAutoBackup(val);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(val
                                ? 'تم تفعيل النسخ الاحتياطي التلقائي'
                                : 'تم إيقاف النسخ التلقائي'),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                      },
                    ),
                    onTap: () {
                      backupService.toggleAutoBackup(!backupService.isAutoBackupEnabled);
                    },
                  ),

                  // حالة آخر نسخة احتياطية
                  _buildSettingsTile(
                    icon: Icons.backup_rounded,
                    title: 'حالة آخر نسخة احتياطية',
                    subtitle: lastBackupStr,
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'محفوظة محلياً',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                    onTap: () {
                      _showBackupDetailsDialog(context, backupService);
                    },
                  ),

                  // النسخ الاحتياطي السحابي (Cloud Sync Service)
                  _buildSettingsTile(
                    icon: Icons.cloud_done_outlined,
                    title: 'النسخ الاحتياطي السحابي (Cloud Sync)',
                    subtitle: backupService.cloudStatus,
                    trailing: backupService.isCloudSyncing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : TextButton.icon(
                            onPressed: () async {
                              final ok = await backupService.uploadBackupToCloud();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(ok
                                        ? 'تمت المزامنة السحابية للنسخة الاحتياطية بنجاح!'
                                        : 'تعذر الاتصال بالسحابة'),
                                    backgroundColor: ok ? AppColors.success : AppColors.danger,
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.cloud_upload_outlined, size: 16),
                            label: const Text('رفع للسحابة', style: TextStyle(fontSize: 11)),
                          ),
                    onTap: () async {
                      await backupService.uploadBackupToCloud();
                    },
                  ),

                  // زر إنشاء نسخة يدوية الآن
                  _buildSettingsTile(
                    icon: Icons.save_alt_rounded,
                    title: 'إنشاء نسخة احتياطية يدوية الآن',
                    subtitle: 'حفظ وتصدير ملف JSON فوري لكامل حسابات المحل',
                    onTap: () async {
                      final res = await backupService.triggerAutoBackup(appData.exportStateJson());
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(res != null
                                ? 'تم إنشاء نسخة احتياطية فورية (${res.fileSizeKb.toStringAsFixed(1)} KB) بنجاح!'
                                : 'تم الحفظ بنجاح'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    },
                  ),

                  // قفل التطبيق برقم سري وبصمة
                  _buildSettingsTile(
                    icon: Icons.fingerprint_rounded,
                    title: 'قفل التطبيق برقم سري وبصمة (PIN & Biometrics)',
                    subtitle: 'الرمز الافتراضي: 1234 (يدعم بصمة الإصبع)',
                    trailing: Switch(
                      value: _pinLockEnabled,
                      activeThumbColor: AppColors.primary,
                      onChanged: (val) {
                        setState(() => _pinLockEnabled = val);
                      },
                    ),
                    onTap: () {
                      setState(() => _pinLockEnabled = !_pinLockEnabled);
                    },
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 5. حول التطبيق
              _buildSettingsSection(
                title: 'عن التطبيق',
                children: [
                  _buildSettingsTile(
                    icon: Icons.info_outline_rounded,
                    title: 'تطبيق مِداد تجاري (Medad Tjari)',
                    subtitle: 'الإصدار 1.0.0 - نظام إدارة الديون والمخزون',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('مِداد تجاري (Medad Tjari) - حلول مالية وتجارية متكاملة')),
                      );
                    },
                  ),
                  _buildSettingsTile(
                    icon: Icons.support_agent_rounded,
                    title: 'الدعم والمساعدة',
                    subtitle: 'تواصل مع الدعم الفني للاستفسارات',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('يمكنك التواصل مع الدعم الفني عبر الواتساب')),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSettingsSection({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, right: 4),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            )
          : null,
      trailing: trailing ??
          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSecondary),
    );
  }

  void _editStoreNameDialog() {
    final controller = TextEditingController(text: _storeName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('تعديل اسم المحل'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'اسم المحل'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() => _storeName = controller.text.trim());
              }
              Navigator.pop(context);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _editStorePhoneDialog() {
    final controller = TextEditingController(text: _storePhone);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('تعديل رقم هاتف المحل'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'رقم الهاتف'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() => _storePhone = controller.text.trim());
              }
              Navigator.pop(context);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _showBackupDetailsDialog(BuildContext context, BackupService backupService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('تفاصيل النسخ الاحتياطي المحلي', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'مسار ملف النسخ الاحتياطي في ذاكرة الهاتف:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            SelectableText(
              backupService.lastBackupPath ?? 'مسار تخزين التطبيق الداخلي (Application Documents)',
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            const Text(
              'سجل النسخ الأخيرة المحفوظة:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            ...backupService.backupHistory.take(3).map((b) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    '• ${b.fileName} (${b.fileSizeKb.toStringAsFixed(1)} KB)',
                    style: const TextStyle(fontSize: 11, color: AppColors.primary),
                  ),
                )),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }
}
