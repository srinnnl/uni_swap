# UniSwap API Test Cases (Liteclient)

Base URL: `http://localhost:3000`
Header for protected routes: `Authorization: Bearer <token>`
JSON header: `Content-Type: application/json`

## ก่อนเริ่มทดสอบ
1. Import `uniswap.sql` เข้า MariaDB/XAMPP ให้ครบ
2. ตรวจว่ามี university อย่างน้อย 1 แถวใน `universities` และ category seed rows
3. สร้าง/เตรียมบัญชีทดสอบ 2 บัญชี: buyer และ seller; ต้องเป็น `status='active'` และ `email_verified_at` ไม่เป็น NULL
4. เริ่ม API: `node server.js`
5. Login ด้วยบัญชีทดสอบเพื่อรับ token
6. เก็บ `user_id`, `product_id`, `category_id`, `platform_bank_account_id`, `order_id` ที่ได้จาก Response ไว้ใช้ในเคสต่อไป

> หมายเหตุ: Register สร้างบัญชีเป็น `pending_verification`; สำหรับทดสอบในเครื่องเท่านั้น ให้เรียก `/api/dev/verify-user/:user_id` ก่อน Login. ห้ามเปิด dev verification endpoint ใน production.

## A. Health
| Method | Endpoint | Request | Expected |
|---|---|---|---|
| GET | `/api/health` | none | 200, `success=true` |
| GET | `/api/not-found` | none | 404 |

## B. Authentication
### Register
`POST /api/register`
```json
{"university_id":1,"student_id":"6731501099","email":"buyer.test@example.com","password":"Testpass123","display_name":"Buyer Test"}
```
- PASS: 201, ได้ `user_id`, status `pending_verification`.
- FAIL: ไม่ส่ง email/password/display_name/university_id/student_id -> 400.
- FAIL: student_id ไม่ครบ 10 หลัก -> 400.
- FAIL: password สั้นกว่า 8 ตัว -> 400.
- FAIL: university_id ไม่มีจริง/ไม่ active -> 400.
- FAIL: email หรือ student_id ซ้ำ -> 409.

### Development verify
`POST /api/dev/verify-user/{user_id}` body ว่าง
- PASS: 200 และบัญชีเปลี่ยนเป็น active พร้อม email_verified_at.
- FAIL: user_id ไม่ใช่ตัวเลขบวก -> 400.
- FAIL: ไม่มี pending user -> 404.

### Login
`POST /api/login`
```json
{"email":"buyer.test@example.com","password":"Testpass123"}
```
- PASS: 200, ได้ token และ user.
- FAIL: ไม่ส่ง email/password -> 400.
- FAIL: email ไม่มีจริงหรือ password ผิด -> 401.
- FAIL: บัญชียัง pending/suspended/deleted หรือยังไม่ verify -> 403.

## C. Profile
| Method | Endpoint | PASS | FAIL |
|---|---|---|---|
| GET | `/api/profile` | token ถูกต้อง -> 200, ได้ข้อมูลตัวเอง | ไม่มี token/Token ผิด -> 401 |
| PUT | `/api/profile` | `{"display_name":"Buyer New","avatar_storage_key":"avatars/buyer.png"}` -> 200 | ไม่มี display_name -> 400; ไม่มี token -> 401 |

## D. Categories
`GET /api/categories`
- PASS: 200 และแสดงเฉพาะ `is_active=1`.
- FAIL: database error -> 500.

## E. Products
### List/search/filter
`GET /api/products`
- PASS: แสดงเฉพาะ visibility=active.
- PASS: `?keyword=book`
- PASS: `?category_id=1`
- PASS: `?min_price=10&max_price=500`
- PASS: `?sort=price_asc`, `?sort=price_desc`, `?sort=urgent`
- FAIL: `?category_id=abc` -> 400.
- FAIL: `?min_price=-1` -> 400.

### Product detail
`GET /api/products/{product_id}`
- PASS: product active -> 200 และ images.
- FAIL: product_id ไม่ถูกต้อง -> 400.
- FAIL: ไม่มีสินค้า/hidden/removed -> 404.

### Create product
`POST /api/products` (seller token)
```json
{"category_id":1,"title":"Used textbook","description":"Good condition","price":150,"item_condition":"good","clearance_deadline":"2026-12-31","is_urgent":true}
```
- PASS: 201 และได้ product_id.
- FAIL: ไม่มี token -> 401.
- FAIL: field บังคับหาย -> 400.
- FAIL: price <= 0 หรือ item_condition ไม่ใช่ new/like_new/good/fair -> 400.
- FAIL: category ไม่มีจริง -> 400.

### Update product
`PUT /api/products/{product_id}`
```json
{"category_id":1,"title":"Updated textbook","description":"Updated detail","price":120,"item_condition":"good","visibility":"active","clearance_deadline":null,"is_urgent":false}
```
- PASS: เจ้าของสินค้าแก้ได้ -> 200.
- FAIL: ไม่ใช่เจ้าของ/ไม่มีสินค้า -> 404.
- FAIL: field ไม่ครบหรือ visibility ไม่ใช่ active/hidden/removed -> 400.
- FAIL: ไม่มี token -> 401.

### Delete product (soft delete)
`DELETE /api/products/{product_id}`
- PASS: เจ้าของเรียกแล้ว visibility เปลี่ยนเป็น removed -> 200.
- FAIL: ไม่ใช่เจ้าของ/ไม่มีสินค้า -> 404.
- FAIL: ไม่มี token -> 401.

### Product image metadata
`POST /api/products/{product_id}/images`
```json
{"storage_key":"products/demo-1.jpg","sort_order":0}
```
- PASS: เจ้าของสินค้าเพิ่ม storage key ได้ -> 201.
- FAIL: ไม่มี storage_key -> 400.
- FAIL: ไม่ใช่เจ้าของ/ไม่มีสินค้า -> 404.
- `DELETE /api/product-images/{image_id}` PASS: เจ้าของลบ metadata ได้ -> 200; คนอื่น/ไม่มีภาพ -> 404.
> API นี้บันทึก storage_key เท่านั้น ยังไม่ได้อัปโหลดไฟล์ภาพจริง.

## F. Conversations / Messages
| Method | Endpoint | Request | Expected |
|---|---|---|---|
| POST | `/api/conversations` | `{"product_id":PRODUCT_ID}` | buyer เปิดแชตกับสินค้าคนอื่นได้ 201 |
| GET | `/api/conversations` | none | ผู้ซื้อ/ผู้ขายเห็น conversation ที่เกี่ยวข้อง 200 |
| GET | `/api/conversations/{id}/messages` | none | สมาชิกในบทสนทนาเห็นข้อความ 200 |
| POST | `/api/conversations/{id}/messages` | `{"body":"ยังมีสินค้าหรือไม่ครับ"}` | สมาชิกส่งข้อความได้ 201 |

Negative tests:
- ไม่มี token -> 401.
- product_id ไม่ถูกต้อง -> 400.
- สินค้าไม่มี/ไม่ active -> 404.
- seller เปิด conversation ซื้อสินค้าตัวเอง -> 400.
- user นอกบทสนทนาอ่าน/ส่งข้อความ -> 403.
- body ว่าง -> 400.

## G. Orders
### Create order
`POST /api/orders` (buyer token)
```json
{"product_id":PRODUCT_ID,"platform_bank_account_id":PLATFORM_BANK_ID}
```
- PASS: 201, ได้ order_id และสถานะ awaiting_payment.
- FAIL: ไม่มี token -> 401.
- FAIL: product_id หรือ platform_bank_account_id ไม่ถูกต้อง -> 400.
- FAIL: สินค้าไม่ active/ไม่มี -> 404.
- FAIL: ซื้อสินค้าตัวเอง -> 400.
- FAIL: มี active/completed order claim สินค้านั้นแล้ว -> 409.

### List/detail
- `GET /api/orders`: buyer เห็น orders ของตัวเอง -> 200; ไม่มี token -> 401.
- `GET /api/orders/{order_id}`: buyer หรือ seller ของ order เห็น -> 200; user อื่น/ไม่มี order -> 404.

### Cancel
`POST /api/orders/{order_id}/cancel`
- PASS: buyer ยกเลิก order awaiting_payment หรือ slip_submitted -> 200; status cancelled.
- FAIL: ไม่ใช่ buyer/ไม่มี order -> 404.
- FAIL: status อื่น เช่น payment_held/completed -> 409.
- FAIL: ไม่มี token -> 401.

## H. Meetup
`POST /api/orders/{order_id}/meetup`
```json
{"place_name":"MFU Library entrance","place_details":"In front of the main entrance","scheduled_at":"2026-12-10T10:00:00"}
```
- PASS: ผู้ซื้อหรือผู้ขายของ order ที่ payment_held/ready_for_meetup สร้างนัดได้ -> 201.
- FAIL: place_name/scheduled_at หายหรือเวลาไม่ถูกต้อง -> 400.
- FAIL: order ไม่เกี่ยวข้องหรือยังไม่พร้อมนัด -> 403.
- FAIL: order มี meetup แล้ว -> 409.

`PUT /api/meetups/{meetup_id}/confirm`
- PASS: seller ของ order ยืนยัน meetup ที่ proposed -> 200.
- FAIL: ไม่ใช่ seller/ไม่พบ/สถานะไม่ใช่ proposed -> 404.
- FAIL: ไม่มี token -> 401.

## I. Reviews
`POST /api/reviews`
```json
{"order_id":ORDER_ID,"rating":5,"comment":"Good seller"}
```
- PASS: buyer ของ order ที่ completed เพิ่ม review -> 201.
- FAIL: rating นอกช่วง 1-5 หรือ order_id ไม่ถูกต้อง -> 400.
- FAIL: ไม่ใช่ buyer หรือ order ยังไม่ completed -> 403.
- FAIL: order มี review แล้ว -> 409.
- FAIL: ไม่มี token -> 401.

`GET /api/products/{product_id}/reviews`
- PASS: 200, แสดงเฉพาะ review visibility=visible.

## J. Reports / Admin
`POST /api/reports`
```json
{"reported_product_id":PRODUCT_ID,"reason":"Misleading product information"}
```
- PASS: ส่ง target เพียง 1 รายการและ reason -> 201.
- FAIL: ไม่ส่ง target หรือ reason -> 400.
- FAIL: ส่ง target มากกว่า 1 ประเภท -> 400.
- FAIL: target ไม่มีจริง -> 400.
- FAIL: ไม่มี token -> 401.

`GET /api/admin/reports`
- PASS: admin token -> 200.
- FAIL: member token -> 403.
- FAIL: ไม่มี token -> 401.

`PUT /api/admin/reports/{report_id}`
```json
{"status":"resolved","resolution_note":"Reviewed and action taken"}
```
- PASS: admin เปลี่ยนเป็น reviewing/resolved/dismissed -> 200.
- FAIL: status ไม่อยู่ในตัวเลือก -> 400.
- FAIL: report ไม่มี -> 404.
- FAIL: member -> 403.

## K. ตรวจสอบผลในฐานข้อมูล (phpMyAdmin)
```sql
SELECT user_id, email, status, email_verified_at FROM users ORDER BY user_id DESC;
SELECT product_id, seller_id, title, price, visibility FROM products ORDER BY product_id DESC;
SELECT * FROM product_images ORDER BY image_id DESC;
SELECT order_id, product_id, buyer_id, status, payment_due_at FROM orders ORDER BY order_id DESC;
SELECT * FROM order_status_history ORDER BY history_id DESC;
SELECT * FROM meetups ORDER BY meetup_id DESC;
SELECT * FROM conversations ORDER BY conversation_id DESC;
SELECT * FROM messages ORDER BY message_id DESC;
SELECT * FROM reviews ORDER BY review_id DESC;
SELECT * FROM reports ORDER BY report_id DESC;
```

## L. สิ่งที่ยังไม่รวม / ต้องพัฒนาต่อก่อนส่ง Production
- Email verification จริง (ส่ง token ทางอีเมล, hash token, expiry, consume token). `/api/dev/verify-user` เป็นทางลัดเฉพาะเครื่องทดสอบ.
- Refresh-token session persistence (`auth_sessions`).
- Payment slip upload/review, escrow, seller payout, refund, disbursement และ state-machine ที่สมบูรณ์.
- Meetup completion และการยืนยันรับสินค้าจาก buyer.
- Message read/delete endpoints.
- Review/report moderation เพิ่มเติม.
- File upload จริง; `product_images` เก็บแค่ storage_key.
- Location/zone filtering: schema ปัจจุบันยังไม่มี location/zone columns หรือ table.
- เพิ่ม rate limiting, validation library, logging, secure secrets, HTTPS, CORS allowlist และทดสอบ authorization เพิ่มก่อน production.
