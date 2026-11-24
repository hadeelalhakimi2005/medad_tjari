const sqlite3 = require('sqlite3').verbose();
const path = require('path');
const fs = require('fs');

// مسار قاعدة البيانات السحابية المحلية
const dbPath = process.env.DATABASE_PATH || path.join(__dirname, 'medad_cloud.db');
const db = new sqlite3.Database(dbPath, (err) => {
  if (err) {
    console.error('❌ خطأ في الاتصال بقاعدة البيانات السحابية:', err.message);
  } else {
    console.log('✅ تم الاتصال بقاعدة البيانات السحابية بنجاح:', dbPath);
    initTables();
  }
});

// تهيئة جداول السحابة
function initTables() {
  db.serialize(() => {
    // 1. جدول العملاء السحابي
    db.run(`
      CREATE TABLE IF NOT EXISTS customers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT,
        debt REAL DEFAULT 0.0,
        credit REAL DEFAULT 0.0,
        credit_limit REAL,
        is_overdue INTEGER DEFAULT 0,
        updated_at TEXT
      )
    `);

    // 2. جدول الحركات وكشف الحساب السحابي
    db.run(`
      CREATE TABLE IF NOT EXISTS transactions (
        id TEXT PRIMARY KEY,
        customer_id TEXT NOT NULL,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        type TEXT NOT NULL,
        notes TEXT,
        FOREIGN KEY (customer_id) REFERENCES customers (id) ON DELETE CASCADE
      )
    `);

    // 3. جدول المخزون السحابي
    db.run(`
      CREATE TABLE IF NOT EXISTS products (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        quantity INTEGER DEFAULT 0,
        unit TEXT DEFAULT 'حبة',
        low_stock_threshold INTEGER DEFAULT 5,
        cost_price REAL DEFAULT 0.0,
        selling_price REAL DEFAULT 0.0,
        updated_at TEXT
      )
    `);

    // 4. جدول المبيعات النقدية
    db.run(`
      CREATE TABLE IF NOT EXISTS cash_sales (
        id TEXT PRIMARY KEY,
        items_description TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL
      )
    `);

    // 5. جدول النسخ الاحتياطية السحابية الشاملة
    db.run(`
      CREATE TABLE IF NOT EXISTS cloud_backups (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        device_id TEXT,
        backup_json TEXT NOT NULL,
        record_count INTEGER,
        created_at TEXT NOT NULL
      )
    `);
  });
}

module.exports = db;
