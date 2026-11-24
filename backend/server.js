require('dotenv').config();
const express = require('express');
const cors = require('cors');
const db = require('./db');

const app = express();
const PORT = process.env.PORT || 5000;

// Middleware
app.use(cors());
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));

// 1. فحص صحة الخادم السحابي (Health Check)
app.get('/', (req, res) => {
  res.json({
    status: 'online',
    appName: 'مِداد تجاري (Medad Tjari Cloud Backend)',
    version: '1.0.0',
    timestamp: new Date().toISOString(),
    message: 'الخادم السحابي وقاعدة البيانات قيد العمل وجاهزة للمزامنة 🚀'
  });
});

// 2. استقبال وحفظ النسخة الاحتياطية السحابية من الجوال (Cloud Backup & Sync)
app.post('/api/backup', (req, res) => {
  try {
    const backupData = req.body;
    if (!backupData) {
      return res.status(400).json({ success: false, message: 'لم يتم إرسال بيانات النسخ الاحتياطي' });
    }

    const jsonString = JSON.stringify(backupData);
    const customersCount = backupData.customers ? backupData.customers.length : 0;
    const productsCount = backupData.products ? backupData.products.length : 0;
    const totalRecords = customersCount + productsCount;
    const now = new Date().toISOString();

    db.run(
      `INSERT INTO cloud_backups (device_id, backup_json, record_count, created_at) VALUES (?, ?, ?, ?)`,
      ['mobile_app', jsonString, totalRecords, now],
      function (err) {
        if (err) {
          console.error('❌ خطأ حفظ النسخة السحابية:', err.message);
          return res.status(500).json({ success: false, error: err.message });
        }

        // مزامنة العملاء في قاعدة البيانات السحابية
        if (Array.isArray(backupData.customers)) {
          backupData.customers.forEach((c) => {
            db.run(
              `INSERT OR REPLACE INTO customers (id, name, phone, debt, credit, credit_limit, is_overdue, updated_at) 
               VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
              [c.id, c.name, c.phone, c.debt || 0, c.credit || 0, c.creditLimit || null, c.isOverdue ? 1 : 0, now]
            );

            // مزامنة الحركات
            if (Array.isArray(c.transactions)) {
              c.transactions.forEach((t) => {
                db.run(
                  `INSERT OR REPLACE INTO transactions (id, customer_id, title, amount, date, type, notes)
                   VALUES (?, ?, ?, ?, ?, ?, ?)`,
                  [t.id, c.id, t.title, t.amount, t.date, t.type, t.notes || '']
                );
              });
            }
          });
        }

        // مزامنة المنتجات والمخزون
        if (Array.isArray(backupData.products)) {
          backupData.products.forEach((p) => {
            db.run(
              `INSERT OR REPLACE INTO products (id, name, quantity, unit, low_stock_threshold, cost_price, selling_price, updated_at)
               VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
              [p.id, p.name, p.quantity, p.unit, p.lowStockThreshold || 5, p.costPrice || 0, p.sellingPrice || 0, now]
            );
          });
        }

        console.log(`✅ تم استقبال ومزامنة نسخة سحابية جديدة: ${totalRecords} سجل في ${now}`);
        res.json({
          success: true,
          backupId: this.lastID,
          message: 'تم حفظ ومزامنة النسخة السحابية بنجاح!',
          syncedRecords: totalRecords,
          timestamp: now
        });
      }
    );
  } catch (error) {
    console.error('❌ خطأ في معالجة النسخة السحابية:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// 3. جلب آخر نسخة احتياطية سحابية (Restore from Cloud)
app.get('/api/backup/latest', (req, res) => {
  db.get(`SELECT * FROM cloud_backups ORDER BY id DESC LIMIT 1`, [], (err, row) => {
    if (err) {
      return res.status(500).json({ success: false, error: err.message });
    }
    if (!row) {
      return res.status(404).json({ success: false, message: 'لا توجد نسخ احتياطية سحابية محفوظة بعد' });
    }
    res.json({
      success: true,
      backupId: row.id,
      createdAt: row.created_at,
      recordCount: row.record_count,
      data: JSON.parse(row.backup_json)
    });
  });
});

// 4. جلب قائمة العملاء من السحابة
app.get('/api/customers', (req, res) => {
  db.all(`SELECT * FROM customers ORDER BY debt DESC`, [], (err, rows) => {
    if (err) {
      return res.status(500).json({ success: false, error: err.message });
    }
    res.json({ success: true, count: rows.length, customers: rows });
  });
});

// 5. جلب المخزون من السحابة
app.get('/api/products', (req, res) => {
  db.all(`SELECT * FROM products ORDER BY name ASC`, [], (err, rows) => {
    if (err) {
      return res.status(500).json({ success: false, error: err.message });
    }
    res.json({ success: true, count: rows.length, products: rows });
  });
});

// 6. لوحة مؤشرات التقارير السحابية (Cloud Reports Summary)
app.get('/api/reports/summary', (req, res) => {
  db.get(
    `SELECT 
      COALESCE(SUM(debt), 0) as totalDebts,
      COALESCE(SUM(credit), 0) as totalCredits,
      COUNT(id) as totalCustomers
     FROM customers`,
    [],
    (err, customerStats) => {
      if (err) {
        return res.status(500).json({ success: false, error: err.message });
      }

      db.get(
        `SELECT 
          COUNT(id) as totalProducts,
          COALESCE(SUM(quantity), 0) as totalUnits,
          COUNT(CASE WHEN quantity <= low_stock_threshold THEN 1 END) as lowStockCount
         FROM products`,
        [],
        (err2, productStats) => {
          if (err2) {
            return res.status(500).json({ success: false, error: err2.message });
          }

          res.json({
            success: true,
            summary: {
              totalDebts: customerStats.totalDebts,
              totalCredits: customerStats.totalCredits,
              netMarketBalance: customerStats.totalDebts - customerStats.totalCredits,
              totalCustomers: customerStats.totalCustomers,
              totalProducts: productStats.totalProducts,
              totalUnits: productStats.totalUnits,
              lowStockCount: productStats.lowStockCount
            }
          });
        }
      );
    }
  );
});

// تشغيل الخادم
app.listen(PORT, () => {
  console.log(`
  ══════════════════════════════════════════════════════════════════
  🚀 خادم قاعدة البيانات السحابية - مِداد تجاري (Medad Tjari)
  📡 العنوان المحلي: http://localhost:${PORT}
  🔗 فحص الصحة:     http://localhost:${PORT}/
  💾 نقطة النسخ:    POST http://localhost:${PORT}/api/backup
  👥 قائمة العملاء:  GET http://localhost:${PORT}/api/customers
  📦 قائمة المخزون:  GET http://localhost:${PORT}/api/products
  ══════════════════════════════════════════════════════════════════
  `);
});
