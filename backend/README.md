# 🌐 مِداد تجاري - الخادم السحابي وقاعدة البيانات (Medad Tjari Cloud Backend)

خادم سحابي متكامل وقاعدة بيانات سحابية لتطبيق **مِداد تجاري (Medad Tjari)**، يقوم بمزامنة واستقبال النسخ الاحتياطية وإدارة حسابات الديون والمخزون سحابياً.

---

## 🚀 التشغيل السريع محلياً (Local Run)

1. الدخول إلى مجلد الخادم:
   ```bash
   cd backend
   ```

2. تثبيت الحزم:
   ```bash
   npm install
   ```

3. تشغيل الخادم:
   ```bash
   npm start
   ```
   سيعمل الخادم على المنفذ: `http://localhost:5000`

---

## ☁️ النشر المجاني على السحابة (Free Cloud Deployment)

يمكنك نشر هذا الخادم مجاناً بضغطة زر واحدة على المنصات السحابية:

### 1. النشر على Render.com (مجاني 100%):
1. اذهب إلى [Render.com](https://render.com) وسجل دخول بحسابك في GitHub.
2. اختر **New +** ثم **Web Service**.
3. اربط مستودع المشروع `medad_tjari`.
4. حدد مسار المجلد الأساسي (Root Directory): `backend`.
5. ضع أوامر التشغيل:
   - **Build Command**: `npm install`
   - **Start Command**: `node server.js`
6. اضغط **Create Web Service**، وستحصل على رابط سحابي مباشر مثل:
   `https://medad-tjari-api.onrender.com`

---

## 📡 نقاط النهاية للـ API (Endpoints):
- `GET /`: فحص حالة السحابة والاتصال.
- `POST /api/backup`: استقبال وتخزين النسخة الاحتياطية الشاملة من الجوال.
- `GET /api/backup/latest`: استرجاع آخر نسخة سحابية محفوظة.
- `GET /api/customers`: عرض العملاء والديون المحفوظة في السحابة.
- `GET /api/products`: عرض المخزون والكميات المسجلة سحابياً.
- `GET /api/reports/summary`: إحصائيات مالية مجمعة للتاجر.
