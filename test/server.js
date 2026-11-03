// // UniSwap API - teacher-style Express + mysql2 callbacks
// // Install: npm install express cors mysql2 @node-rs/argon2 jsonwebtoken
// // Run: node server.js
// // IMPORTANT: Set JWT_KEY in your environment before deployment.
// // This is a teaching/demo API baseline. Review payment/order state transitions
// // and add production email + file-storage services before real deployment.

// const express = require('express');
// const cors = require('cors');
// const con = require('../db_config');
// const argon2 = require('@node-rs/argon2');
// const jwt = require('jsonwebtoken');

// const app = express();
// app.use(cors());
// app.use(express.json());

// const JWT_KEY = process.env.JWT_KEY || 'CHANGE_THIS_UNSAFE_DEMO_KEY';
// const PORT = 3000;

// // ---------- Common helpers ----------
// function auth(req, res, next) {
//     const header = req.headers.authorization;
//     if (!header || !header.startsWith('Bearer ')) {
//         return res.status(401).json({ success: false, message: 'Token required' });
//     }

//     const token = header.substring(7);
//     jwt.verify(token, JWT_KEY, (err, decoded) => {
//         if (err) return res.status(401).json({ success: false, message: 'Invalid or expired token' });
//         req.user = decoded;
//         next();
//     });
// }

// function adminOnly(req, res, next) {
//     if (!req.user || req.user.role !== 'admin') {
//         return res.status(403).json({ success: false, message: 'Admin only' });
//     }
//     next();
// }

// function queryError(res, err) {
//     console.error(err);
//     return res.status(500).json({ success: false, message: 'Database error' });
// }

// function isPositiveId(value) {
//     return Number.isInteger(Number(value)) && Number(value) > 0;
// }

// // ---------- Health ----------
// app.get('/api/health', (req, res) => {
//     con.query('SELECT 1 AS ok', (err, result) => {
//         if (err) return queryError(res, err);
//         res.json({ success: true, message: 'API is running', database: result[0].ok });
//     });
// });

// // ---------- Authentication ----------
// app.post('/api/register', (req, res) => {
//     const { university_id, student_id, email, password, display_name } = req.body;

//     if (!university_id || !student_id || !email || !password || !display_name) {
//         return res.status(400).json({ success: false, message: 'Missing required fields' });
//     }
//     if (!/^[0-9]{10}$/.test(String(student_id))) {
//         return res.status(400).json({ success: false, message: 'student_id must be 10 digits' });
//     }
//     if (String(password).length < 8) {
//         return res.status(400).json({ success: false, message: 'Password must be at least 8 characters' });
//     }

//     const cleanEmail = String(email).trim().toLowerCase();
//     const hash = argon2.hashSync(String(password));

//     const universitySql = 'SELECT university_id FROM universities WHERE university_id = ? AND is_active = 1';
//     con.query(universitySql, [university_id], (err, universityResult) => {
//         if (err) return queryError(res, err);
//         if (universityResult.length === 0) {
//             return res.status(400).json({ success: false, message: 'Invalid university_id' });
//         }

//         const sql = `INSERT INTO users
//             (university_id, student_id, email, password_hash, display_name, role, status)
//             VALUES (?, ?, ?, ?, ?, 'member', 'pending_verification')`;
//         con.query(sql, [university_id, student_id, cleanEmail, hash, String(display_name).trim()], (err, result) => {
//             if (err) {
//                 if (err.code === 'ER_DUP_ENTRY') return res.status(409).json({ success: false, message: 'Email or student ID already exists' });
//                 return queryError(res, err);
//             }

//             // Demo behavior: account remains pending until email verification is implemented.
//             res.status(201).json({
//                 success: true,
//                 message: 'Registered. Email verification is required before login.',
//                 user_id: result.insertId,
//                 status: 'pending_verification'
//             });
//         });
//     });
// });

// // Development-only verification endpoint. Replace with emailed one-time token in production.
// app.post('/api/dev/verify-user/:user_id', (req, res) => {
//     if (!isPositiveId(req.params.user_id)) return res.status(400).json({ success: false, message: 'Invalid user_id' });

//     con.query(
//         `UPDATE users SET status = 'active', email_verified_at = UTC_TIMESTAMP(3)
//          WHERE user_id = ? AND status = 'pending_verification'`,
//         [req.params.user_id],
//         (err, result) => {
//             if (err) return queryError(res, err);
//             if (result.affectedRows === 0) return res.status(404).json({ success: false, message: 'Pending user not found' });
//             res.json({ success: true, message: 'User verified (development only)' });
//         }
//     );
// });

// app.post('/api/login', (req, res) => {
//     const { email, password } = req.body;
//     if (!email || !password) {
//         return res.status(400).json({ success: false, message: 'Email and password are required' });
//     }

//     const sql = 'SELECT user_id, email, password_hash, display_name, role, status, email_verified_at FROM users WHERE email = ?';
//     con.query(sql, [String(email).trim().toLowerCase()], (err, result) => {
//         if (err) return queryError(res, err);
//         if (result.length === 0) return res.status(401).json({ success: false, message: 'Invalid email or password' });

//         const user = result[0];
//         let samePassword = false;
//         try {
//             samePassword = argon2.verifySync(user.password_hash, String(password));
//         } catch (e) {
//             console.error(e);
//             return res.status(500).json({ success: false, message: 'Password verification error' });
//         }

//         if (!samePassword) return res.status(401).json({ success: false, message: 'Invalid email or password' });
//         if (user.status !== 'active' || !user.email_verified_at) {
//             return res.status(403).json({ success: false, message: 'Account is not active or email is not verified' });
//         }

//         const payload = { user_id: user.user_id, email: user.email, role: user.role };
//         const token = jwt.sign(payload, JWT_KEY, { expiresIn: '1d' });

//         res.json({
//             success: true,
//             message: 'Login successful',
//             token,
//             user: {
//                 user_id: user.user_id,
//                 email: user.email,
//                 display_name: user.display_name,
//                 role: user.role
//             }
//         });
//     });
// });

// // ---------- User profile ----------
// app.get('/api/profile', auth, (req, res) => {
//     con.query(
//         `SELECT user_id, university_id, student_id, email, display_name, avatar_storage_key, role, status, created_at
//          FROM users WHERE user_id = ?`,
//         [req.user.user_id],
//         (err, result) => {
//             if (err) return queryError(res, err);
//             if (result.length === 0) return res.status(404).json({ success: false, message: 'User not found' });
//             res.json({ success: true, data: result[0] });
//         }
//     );
// });

// app.put('/api/profile', auth, (req, res) => {
//     const { display_name, avatar_storage_key } = req.body;
//     if (!display_name || !String(display_name).trim()) {
//         return res.status(400).json({ success: false, message: 'display_name is required' });
//     }

//     con.query(
//         'UPDATE users SET display_name = ?, avatar_storage_key = ? WHERE user_id = ? AND status = ?',
//         [String(display_name).trim(), avatar_storage_key || null, req.user.user_id, 'active'],
//         (err, result) => {
//             if (err) return queryError(res, err);
//             if (result.affectedRows === 0) return res.status(404).json({ success: false, message: 'User not found' });
//             res.json({ success: true, message: 'Profile updated' });
//         }
//     );
// });

// // ---------- Categories ----------
// app.get('/api/categories', (req, res) => {
//     con.query('SELECT category_id, name FROM categories WHERE is_active = 1 ORDER BY category_id', (err, result) => {
//         if (err) return queryError(res, err);
//         res.json({ success: true, data: result });
//     });
// });

// // ---------- Products ----------
// app.get('/api/products', (req, res) => {
//     const { keyword, category_id, min_price, max_price, sort } = req.query;
//     let sql = `SELECT p.product_id, p.seller_id, u.display_name AS seller_name,
//                       p.category_id, c.name AS category_name, p.title, p.description,
//                       p.price, p.item_condition, p.visibility, p.clearance_deadline,
//                       p.is_urgent, p.created_at
//                FROM products p
//                JOIN users u ON p.seller_id = u.user_id
//                JOIN categories c ON p.category_id = c.category_id
//                WHERE p.visibility = 'active'`;
//     const values = [];

//     if (keyword) {
//         sql += ' AND (p.title LIKE ? OR p.description LIKE ?)';
//         values.push('%' + keyword + '%', '%' + keyword + '%');
//     }
//     if (category_id) {
//         if (!isPositiveId(category_id)) return res.status(400).json({ success: false, message: 'Invalid category_id' });
//         sql += ' AND p.category_id = ?';
//         values.push(category_id);
//     }
//     if (min_price !== undefined) {
//         if (isNaN(Number(min_price)) || Number(min_price) < 0) return res.status(400).json({ success: false, message: 'Invalid min_price' });
//         sql += ' AND p.price >= ?';
//         values.push(Number(min_price));
//     }
//     if (max_price !== undefined) {
//         if (isNaN(Number(max_price)) || Number(max_price) < 0) return res.status(400).json({ success: false, message: 'Invalid max_price' });
//         sql += ' AND p.price <= ?';
//         values.push(Number(max_price));
//     }

//     if (sort === 'price_asc') sql += ' ORDER BY p.price ASC';
//     else if (sort === 'price_desc') sql += ' ORDER BY p.price DESC';
//     else if (sort === 'urgent') sql += ' ORDER BY p.is_urgent DESC, p.created_at DESC';
//     else sql += ' ORDER BY p.created_at DESC';

//     con.query(sql, values, (err, result) => {
//         if (err) return queryError(res, err);
//         res.json({ success: true, count: result.length, data: result });
//     });
// });

// app.get('/api/products/:product_id', (req, res) => {
//     if (!isPositiveId(req.params.product_id)) return res.status(400).json({ success: false, message: 'Invalid product_id' });

//     const sql = `SELECT p.*, u.display_name AS seller_name, c.name AS category_name
//                  FROM products p
//                  JOIN users u ON p.seller_id = u.user_id
//                  JOIN categories c ON p.category_id = c.category_id
//                  WHERE p.product_id = ? AND p.visibility = 'active'`;
//     con.query(sql, [req.params.product_id], (err, result) => {
//         if (err) return queryError(res, err);
//         if (result.length === 0) return res.status(404).json({ success: false, message: 'Product not found' });

//         con.query('SELECT image_id, storage_key, sort_order FROM product_images WHERE product_id = ? ORDER BY sort_order', [req.params.product_id], (err, images) => {
//             if (err) return queryError(res, err);
//             res.json({ success: true, data: result[0], images });
//         });
//     });
// });

// app.post('/api/products', auth, (req, res) => {
//     const { category_id, title, description, price, item_condition, clearance_deadline, is_urgent } = req.body;
//     const allowed = ['new', 'like_new', 'good', 'fair'];

//     if (!category_id || !title || !description || price === undefined || !item_condition) {
//         return res.status(400).json({ success: false, message: 'Missing required fields' });
//     }
//     if (!isPositiveId(category_id) || Number(price) <= 0 || isNaN(Number(price)) || !allowed.includes(item_condition)) {
//         return res.status(400).json({ success: false, message: 'Invalid category, price or item_condition' });
//     }

//     const sql = `INSERT INTO products
//         (seller_id, category_id, title, description, price, item_condition, clearance_deadline, is_urgent)
//         VALUES (?, ?, ?, ?, ?, ?, ?, ?)`;
//     con.query(sql, [
//         req.user.user_id, category_id, String(title).trim(), description,
//         Number(price), item_condition, clearance_deadline || null, is_urgent ? 1 : 0
//     ], (err, result) => {
//         if (err) {
//             if (err.code === 'ER_NO_REFERENCED_ROW_2') return res.status(400).json({ success: false, message: 'Category not found' });
//             return queryError(res, err);
//         }
//         res.status(201).json({ success: true, message: 'Product created', product_id: result.insertId });
//     });
// });

// app.put('/api/products/:product_id', auth, (req, res) => {
//     const { category_id, title, description, price, item_condition, visibility, clearance_deadline, is_urgent } = req.body;
//     const allowedCondition = ['new', 'like_new', 'good', 'fair'];
//     const allowedVisibility = ['active', 'hidden', 'removed'];

//     if (!isPositiveId(req.params.product_id)) return res.status(400).json({ success: false, message: 'Invalid product_id' });
//     if (!category_id || !title || !description || price === undefined || !allowedCondition.includes(item_condition) || !allowedVisibility.includes(visibility)) {
//         return res.status(400).json({ success: false, message: 'Invalid or missing product fields' });
//     }
//     if (Number(price) <= 0 || isNaN(Number(price))) return res.status(400).json({ success: false, message: 'Price must be greater than 0' });

//     const sql = `UPDATE products SET category_id=?, title=?, description=?, price=?,
//                  item_condition=?, visibility=?, clearance_deadline=?, is_urgent=?
//                  WHERE product_id=? AND seller_id=?`;
//     con.query(sql, [
//         category_id, String(title).trim(), description, Number(price), item_condition,
//         visibility, clearance_deadline || null, is_urgent ? 1 : 0,
//         req.params.product_id, req.user.user_id
//     ], (err, result) => {
//         if (err) return queryError(res, err);
//         if (result.affectedRows === 0) return res.status(404).json({ success: false, message: 'Product not found or not owned by you' });
//         res.json({ success: true, message: 'Product updated' });
//     });
// });

// app.delete('/api/products/:product_id', auth, (req, res) => {
//     if (!isPositiveId(req.params.product_id)) return res.status(400).json({ success: false, message: 'Invalid product_id' });
//     con.query(
//         `UPDATE products SET visibility = 'removed' WHERE product_id = ? AND seller_id = ?`,
//         [req.params.product_id, req.user.user_id],
//         (err, result) => {
//             if (err) return queryError(res, err);
//             if (result.affectedRows === 0) return res.status(404).json({ success: false, message: 'Product not found or not owned by you' });
//             res.json({ success: true, message: 'Product removed' });
//         }
//     );
// });

// // Product images store storage keys only; actual upload/storage is a separate implementation.
// app.post('/api/products/:product_id/images', auth, (req, res) => {
//     const { storage_key, sort_order } = req.body;
//     if (!storage_key) return res.status(400).json({ success: false, message: 'storage_key is required' });

//     con.query('SELECT product_id FROM products WHERE product_id = ? AND seller_id = ?', [req.params.product_id, req.user.user_id], (err, rows) => {
//         if (err) return queryError(res, err);
//         if (rows.length === 0) return res.status(404).json({ success: false, message: 'Product not found or not owned by you' });

//         con.query(
//             'INSERT INTO product_images (product_id, storage_key, sort_order) VALUES (?, ?, ?)',
//             [req.params.product_id, storage_key, sort_order || 0],
//             (err, result) => {
//                 if (err) return queryError(res, err);
//                 res.status(201).json({ success: true, image_id: result.insertId });
//             }
//         );
//     });
// });

// app.delete('/api/product-images/:image_id', auth, (req, res) => {
//     const sql = `DELETE pi FROM product_images pi
//                  JOIN products p ON pi.product_id = p.product_id
//                  WHERE pi.image_id = ? AND p.seller_id = ?`;
//     con.query(sql, [req.params.image_id, req.user.user_id], (err, result) => {
//         if (err) return queryError(res, err);
//         if (result.affectedRows === 0) return res.status(404).json({ success: false, message: 'Image not found or not owned by you' });
//         res.json({ success: true, message: 'Image deleted' });
//     });
// });

// // ---------- Conversations and messages ----------
// app.post('/api/conversations', auth, (req, res) => {
//     const { product_id } = req.body;
//     if (!isPositiveId(product_id)) return res.status(400).json({ success: false, message: 'Valid product_id is required' });

//     con.query(`SELECT product_id, seller_id FROM products WHERE product_id = ? AND visibility = 'active'`, [product_id], (err, products) => {
//         if (err) return queryError(res, err);
//         if (products.length === 0) return res.status(404).json({ success: false, message: 'Product not found' });
//         if (Number(products[0].seller_id) === Number(req.user.user_id)) return res.status(400).json({ success: false, message: 'Seller cannot start a buyer conversation with own product' });

//         con.query(
//             'INSERT INTO conversations (product_id, buyer_id) VALUES (?, ?) ON DUPLICATE KEY UPDATE conversation_id = LAST_INSERT_ID(conversation_id)',
//             [product_id, req.user.user_id],
//             (err, result) => {
//                 if (err) return queryError(res, err);
//                 res.status(201).json({ success: true, conversation_id: result.insertId });
//             }
//         );
//     });
// });

// app.get('/api/conversations', auth, (req, res) => {
//     const sql = `SELECT DISTINCT c.conversation_id, c.product_id, c.buyer_id, p.title
//                  FROM conversations c
//                  JOIN products p ON c.product_id = p.product_id
//                  LEFT JOIN messages m ON m.conversation_id = c.conversation_id
//                  WHERE c.buyer_id = ? OR p.seller_id = ?
//                  ORDER BY c.created_at DESC`;
//     con.query(sql, [req.user.user_id, req.user.user_id], (err, result) => {
//         if (err) return queryError(res, err);
//         res.json({ success: true, data: result });
//     });
// });

// app.get('/api/conversations/:conversation_id/messages', auth, (req, res) => {
//     const accessSql = `SELECT c.conversation_id FROM conversations c
//                        JOIN products p ON c.product_id = p.product_id
//                        WHERE c.conversation_id = ? AND (c.buyer_id = ? OR p.seller_id = ?)`;
//     con.query(accessSql, [req.params.conversation_id, req.user.user_id, req.user.user_id], (err, access) => {
//         if (err) return queryError(res, err);
//         if (access.length === 0) return res.status(403).json({ success: false, message: 'Conversation access denied' });

//         const sql = `SELECT message_id, conversation_id, sender_id, body, read_at, created_at
//                      FROM messages WHERE conversation_id = ? AND deleted_at IS NULL
//                      ORDER BY created_at, message_id`;
//         con.query(sql, [req.params.conversation_id], (err, result) => {
//             if (err) return queryError(res, err);
//             res.json({ success: true, data: result });
//         });
//     });
// });

// app.post('/api/conversations/:conversation_id/messages', auth, (req, res) => {
//     const { body } = req.body;
//     if (!body || !String(body).trim()) return res.status(400).json({ success: false, message: 'Message body is required' });

//     const accessSql = `SELECT c.conversation_id FROM conversations c
//                        JOIN products p ON c.product_id = p.product_id
//                        WHERE c.conversation_id = ? AND (c.buyer_id = ? OR p.seller_id = ?)`;
//     con.query(accessSql, [req.params.conversation_id, req.user.user_id, req.user.user_id], (err, access) => {
//         if (err) return queryError(res, err);
//         if (access.length === 0) return res.status(403).json({ success: false, message: 'Conversation access denied' });

//         con.query(
//             'INSERT INTO messages (conversation_id, sender_id, body) VALUES (?, ?, ?)',
//             [req.params.conversation_id, req.user.user_id, String(body).trim()],
//             (err, result) => {
//                 if (err) return queryError(res, err);
//                 res.status(201).json({ success: true, message_id: result.insertId });
//             }
//         );
//     });
// });

// // ---------- Orders (safe basic claim; payment workflow intentionally not implemented here) ----------
// app.post('/api/orders', auth, (req, res) => {
//     const { product_id, platform_bank_account_id } = req.body;
//     if (!isPositiveId(product_id) || !isPositiveId(platform_bank_account_id)) {
//         return res.status(400).json({ success: false, message: 'product_id and platform_bank_account_id are required' });
//     }

//     con.beginTransaction((err) => {
//         if (err) return queryError(res, err);

//         const productSql = `SELECT p.product_id, p.seller_id, p.title, p.price
//                             FROM products p WHERE p.product_id = ? AND p.visibility = 'active' FOR UPDATE`;
//         con.query(productSql, [product_id], (err, products) => {
//             if (err) return con.rollback(() => queryError(res, err));
//             if (products.length === 0) return con.rollback(() => res.status(404).json({ success: false, message: 'Product not available' }));

//             const p = products[0];
//             if (Number(p.seller_id) === Number(req.user.user_id)) {
//                 return con.rollback(() => res.status(400).json({ success: false, message: 'Cannot buy your own product' }));
//             }

//             con.query('SELECT platform_bank_account_id FROM platform_bank_accounts WHERE platform_bank_account_id = ? AND is_active = 1', [platform_bank_account_id], (err, banks) => {
//                 if (err) return con.rollback(() => queryError(res, err));
//                 if (banks.length === 0) return con.rollback(() => res.status(400).json({ success: false, message: 'Platform bank account not found or inactive' }));

//                 const insertSql = `INSERT INTO orders
//                     (product_id, buyer_id, platform_bank_account_id, product_title_snapshot,
//                      total_amount, receiving_bank_name_snapshot, receiving_bank_number_snapshot,
//                      receiving_bank_holder_snapshot, payment_due_at)
//                     SELECT ?, ?, ?, ?, ?, bank_name, account_number, account_holder_name,
//                            DATE_ADD(UTC_TIMESTAMP(3), INTERVAL 30 MINUTE)
//                     FROM platform_bank_accounts WHERE platform_bank_account_id = ?`;
//                 con.query(insertSql, [product_id, req.user.user_id, platform_bank_account_id, p.title, p.price, platform_bank_account_id], (err, result) => {
//                     if (err) {
//                         return con.rollback(() => {
//                             if (err.code === 'ER_DUP_ENTRY') return res.status(409).json({ success: false, message: 'Product already has an active order' });
//                             queryError(res, err);
//                         });
//                     }

//                     con.query(
//                         `INSERT INTO order_status_history (order_id, actor_id, from_status, to_status, reason)
//                          VALUES (?, ?, NULL, 'awaiting_payment', 'Order created')`,
//                         [result.insertId, req.user.user_id],
//                         (err) => {
//                             if (err) return con.rollback(() => queryError(res, err));
//                             con.commit((err) => {
//                                 if (err) return con.rollback(() => queryError(res, err));
//                                 res.status(201).json({ success: true, message: 'Order created; payment workflow must be completed separately', order_id: result.insertId });
//                             });
//                         }
//                     );
//                 });
//             });
//         });
//     });
// });

// app.get('/api/orders', auth, (req, res) => {
//     const sql = `SELECT order_id, product_id, product_title_snapshot, total_amount, status,
//                         payment_due_at, buyer_received_at, created_at
//                  FROM orders WHERE buyer_id = ? ORDER BY created_at DESC`;
//     con.query(sql, [req.user.user_id], (err, result) => {
//         if (err) return queryError(res, err);
//         res.json({ success: true, data: result });
//     });
// });

// app.get('/api/orders/:order_id', auth, (req, res) => {
//     const sql = `SELECT o.* FROM orders o
//                  JOIN products p ON o.product_id = p.product_id
//                  WHERE o.order_id = ? AND (o.buyer_id = ? OR p.seller_id = ?)`;
//     con.query(sql, [req.params.order_id, req.user.user_id, req.user.user_id], (err, result) => {
//         if (err) return queryError(res, err);
//         if (result.length === 0) return res.status(404).json({ success: false, message: 'Order not found' });
//         res.json({ success: true, data: result[0] });
//     });
// });

// app.post('/api/orders/:order_id/cancel', auth, (req, res) => {
//     con.beginTransaction((err) => {
//         if (err) return queryError(res, err);
//         con.query(
//             `SELECT order_id, status FROM orders WHERE order_id = ? AND buyer_id = ? FOR UPDATE`,
//             [req.params.order_id, req.user.user_id],
//             (err, rows) => {
//                 if (err) return con.rollback(() => queryError(res, err));
//                 if (rows.length === 0) return con.rollback(() => res.status(404).json({ success: false, message: 'Order not found' }));
//                 if (!['awaiting_payment', 'slip_submitted'].includes(rows[0].status)) {
//                     return con.rollback(() => res.status(409).json({ success: false, message: 'Order cannot be cancelled in current status' }));
//                 }

//                 con.query(
//                     `UPDATE orders SET status='cancelled', closed_at=UTC_TIMESTAMP(3), close_reason='Cancelled by buyer'
//                      WHERE order_id = ?`,
//                     [req.params.order_id],
//                     (err) => {
//                         if (err) return con.rollback(() => queryError(res, err));
//                         con.query(
//                             `INSERT INTO order_status_history (order_id, actor_id, from_status, to_status, reason)
//                              VALUES (?, ?, ?, 'cancelled', 'Cancelled by buyer')`,
//                             [req.params.order_id, req.user.user_id, rows[0].status],
//                             (err) => {
//                                 if (err) return con.rollback(() => queryError(res, err));
//                                 con.commit((err) => {
//                                     if (err) return con.rollback(() => queryError(res, err));
//                                     res.json({ success: true, message: 'Order cancelled' });
//                                 });
//                             }
//                         );
//                     }
//                 );
//             }
//         );
//     });
// });

// // ---------- Meetups ----------
// app.post('/api/orders/:order_id/meetup', auth, (req, res) => {
//     const { place_name, place_details, scheduled_at } = req.body;
//     if (!place_name || !scheduled_at || isNaN(Date.parse(scheduled_at))) {
//         return res.status(400).json({ success: false, message: 'place_name and valid scheduled_at are required' });
//     }

//     const accessSql = `SELECT o.order_id, p.seller_id, o.buyer_id
//                        FROM orders o JOIN products p ON o.product_id = p.product_id
//                        WHERE o.order_id = ? AND (o.buyer_id = ? OR p.seller_id = ?)
//                          AND o.status IN ('payment_held','ready_for_meetup')`;
//     con.query(accessSql, [req.params.order_id, req.user.user_id, req.user.user_id], (err, rows) => {
//         if (err) return queryError(res, err);
//         if (rows.length === 0) return res.status(403).json({ success: false, message: 'Order not accessible or not ready for meetup' });

//         con.query(
//             `INSERT INTO meetups (order_id, proposed_by, place_name, place_details, scheduled_at)
//              VALUES (?, ?, ?, ?, ?)`,
//             [req.params.order_id, req.user.user_id, place_name, place_details || null, scheduled_at],
//             (err, result) => {
//                 if (err) {
//                     if (err.code === 'ER_DUP_ENTRY') return res.status(409).json({ success: false, message: 'Meetup already exists for this order' });
//                     return queryError(res, err);
//                 }
//                 res.status(201).json({ success: true, meetup_id: result.insertId, status: 'proposed' });
//             }
//         );
//     });
// });

// app.put('/api/meetups/:meetup_id/confirm', auth, (req, res) => {
//     const sql = `UPDATE meetups m
//                  JOIN orders o ON m.order_id = o.order_id
//                  JOIN products p ON o.product_id = p.product_id
//                  SET m.status='confirmed', m.seller_confirmed_at=UTC_TIMESTAMP(3)
//                  WHERE m.meetup_id = ? AND p.seller_id = ? AND m.status='proposed'`;
//     con.query(sql, [req.params.meetup_id, req.user.user_id], (err, result) => {
//         if (err) return queryError(res, err);
//         if (result.affectedRows === 0) return res.status(404).json({ success: false, message: 'Meetup not found, not yours to confirm, or not proposed' });
//         res.json({ success: true, message: 'Meetup confirmed' });
//     });
// });

// // ---------- Reviews ----------
// app.post('/api/reviews', auth, (req, res) => {
//     const { order_id, rating, comment } = req.body;
//     if (!isPositiveId(order_id) || !Number.isInteger(Number(rating)) || Number(rating) < 1 || Number(rating) > 5) {
//         return res.status(400).json({ success: false, message: 'Valid order_id and rating 1-5 are required' });
//     }

//     con.query(
//         `SELECT order_id FROM orders WHERE order_id = ? AND buyer_id = ? AND status = 'completed'`,
//         [order_id, req.user.user_id],
//         (err, rows) => {
//             if (err) return queryError(res, err);
//             if (rows.length === 0) return res.status(403).json({ success: false, message: 'Only buyer of completed order can review' });

//             con.query(
//                 'INSERT INTO reviews (order_id, rating, comment) VALUES (?, ?, ?)',
//                 [order_id, Number(rating), comment || null],
//                 (err, result) => {
//                     if (err) {
//                         if (err.code === 'ER_DUP_ENTRY') return res.status(409).json({ success: false, message: 'Review already exists for this order' });
//                         return queryError(res, err);
//                     }
//                     res.status(201).json({ success: true, review_id: result.insertId });
//                 }
//             );
//         }
//     );
// });

// app.get('/api/products/:product_id/reviews', (req, res) => {
//     const sql = `SELECT r.review_id, r.order_id, r.rating, r.comment, r.created_at,
//                         o.buyer_id
//                  FROM reviews r JOIN orders o ON r.order_id = o.order_id
//                  WHERE o.product_id = ? AND r.visibility = 'visible'
//                  ORDER BY r.created_at DESC`;
//     con.query(sql, [req.params.product_id], (err, result) => {
//         if (err) return queryError(res, err);
//         res.json({ success: true, data: result });
//     });
// });

// // ---------- Reports ----------
// app.post('/api/reports', auth, (req, res) => {
//     const { reported_user_id, reported_product_id, reported_message_id, reported_review_id, reason } = req.body;
//     const targets = [reported_user_id, reported_product_id, reported_message_id, reported_review_id].filter(v => v !== undefined && v !== null && v !== '');
//     if (targets.length !== 1 || !reason || !String(reason).trim()) {
//         return res.status(400).json({ success: false, message: 'Provide exactly one report target and a reason' });
//     }

//     const sql = `INSERT INTO reports
//         (reporter_id, reported_user_id, reported_product_id, reported_message_id, reported_review_id, reason)
//         VALUES (?, ?, ?, ?, ?, ?)`;
//     con.query(sql, [
//         req.user.user_id,
//         reported_user_id || null,
//         reported_product_id || null,
//         reported_message_id || null,
//         reported_review_id || null,
//         String(reason).trim()
//     ], (err, result) => {
//         if (err) {
//             if (err.code === 'ER_NO_REFERENCED_ROW_2') return res.status(400).json({ success: false, message: 'Report target does not exist' });
//             return queryError(res, err);
//         }
//         res.status(201).json({ success: true, report_id: result.insertId, status: 'open' });
//     });
// });

// app.get('/api/admin/reports', auth, adminOnly, (req, res) => {
//     con.query('SELECT * FROM reports ORDER BY created_at DESC', (err, result) => {
//         if (err) return queryError(res, err);
//         res.json({ success: true, data: result });
//     });
// });

// app.put('/api/admin/reports/:report_id', auth, adminOnly, (req, res) => {
//     const { status, resolution_note } = req.body;
//     const allowed = ['reviewing', 'resolved', 'dismissed'];
//     if (!allowed.includes(status)) return res.status(400).json({ success: false, message: 'Invalid report status' });

//     const sql = `UPDATE reports SET status = ?,
//                  resolved_by = CASE WHEN ? IN ('resolved','dismissed') THEN ? ELSE NULL END,
//                  resolved_at = CASE WHEN ? IN ('resolved','dismissed') THEN UTC_TIMESTAMP(3) ELSE NULL END,
//                  resolution_note = ?
//                  WHERE report_id = ?`;
//     con.query(sql, [status, status, req.user.user_id, status, resolution_note || null, req.params.report_id], (err, result) => {
//         if (err) return queryError(res, err);
//         if (result.affectedRows === 0) return res.status(404).json({ success: false, message: 'Report not found' });
//         res.json({ success: true, message: 'Report updated' });
//     });
// });

// // ---------- 404 ----------
// app.use((req, res) => {
//     res.status(404).json({ success: false, message: 'API endpoint not found' });
// });

// app.listen(PORT, () => {
//     console.log('UniSwap API running at http://localhost:' + PORT);
// });
