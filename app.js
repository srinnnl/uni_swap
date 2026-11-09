// UniSwap API aligned to the local project_mobile_app MySQL schema.
const express = require('express');
const cors = require('cors');
const jwt = require('jsonwebtoken');
const argon2 = require('@node-rs/argon2');
const con = require('./db_config');

const app = express();
const PORT = Number(process.env.PORT || 3000);
const JWT_KEY = process.env.JWT_KEY || 'uni-swap-local-development-key-change-me';
const zones = ['on_campus', 'off_campus'];
const orderStates = ['pending_payment', 'paid', 'ready_for_meetup', 'completed', 'cancelled', 'expired', 'refund_requested', 'partially_refunded', 'refunded'];

app.use(cors());
app.use(express.json({ limit: '1mb' }));

const db = (sql, values = []) => new Promise((resolve, reject) => con.query(sql, values, (err, rows) => err ? reject(err) : resolve(rows)));
const validId = value => /^[1-9]\d*$/.test(String(value));
const validText = (value, max, required = false) => value === undefined || value === null ? !required : typeof value === 'string' && value.trim().length <= max && (!required || value.trim().length > 0);
const bad = (res, message) => res.status(400).json({ success: false, message });
function dbError(res, err) {
    if (err.code === 'ER_DUP_ENTRY') return res.status(409).json({ success: false, message: 'This record already exists' });
    if ([1452, 1366, 1265, 3819].includes(err.errno)) return bad(res, 'Invalid related record or value');
    console.error(err);
    return res.status(500).json({ success: false, message: 'Database error' });
}
function getPaging(req, res) {
    const page = req.query.page === undefined ? 1 : Number(req.query.page);
    const limit = req.query.limit === undefined ? 20 : Number(req.query.limit);
    if (!Number.isInteger(page) || page < 1 || !Number.isInteger(limit) || limit < 1 || limit > 100) { bad(res, 'page must be >= 1 and limit must be 1-100'); return null; }
    return { page, limit, offset: (page - 1) * limit };
}
function sendPage(res, rows, paging) { return res.json({ success: true, data: rows.slice(0, paging.limit), page: paging.page, limit: paging.limit, has_more: rows.length > paging.limit }); }
async function transaction(work) {
    // mysql2's promise wrapper prevents a callback Query object from being
    // accidentally awaited during the transaction flow.
    const conn = await con.promise().getConnection();
    try {
        await conn.beginTransaction();
        const result = await work(async (sql, values = []) => (await conn.query(sql, values))[0]);
        await conn.commit();
        return result;
    } catch (err) {
        await conn.rollback();
        throw err;
    } finally {
        conn.release();
    }
}
async function auth(req, res, next) {
    const header = req.get('authorization');
    if (!header || !header.startsWith('Bearer ')) return res.status(401).json({ success: false, message: 'Token required' });
    try {
        const token = jwt.verify(header.slice(7), JWT_KEY);
        const users = await db('SELECT user_id,email,display_name,username,role,status FROM users WHERE user_id=?', [token.user_id]);
        if (!users.length || users[0].status !== 'active') return res.status(403).json({ success: false, message: 'Account is not active' });
        req.user = users[0]; return next();
    } catch (_) { return res.status(401).json({ success: false, message: 'Invalid or expired token' }); }
}
const adminOnly = (req, res, next) => req.user.role === 'admin' ? next() : res.status(403).json({ success: false, message: 'Admin only' });
const notFound = (res, message) => res.status(404).json({ success: false, message });

app.get('/api/health', async (_req, res) => { try { await db('SELECT 1'); res.json({ success: true, database: 'connected' }); } catch (err) { dbError(res, err); } });

// ---------- Authentication / profile ----------
app.post('/api/register', async (req, res) => {
    const b = req.body || {};
    const studentId = b.student_id ?? b.studentId;
    const displayName = b.display_name ?? b.displayName ?? b.fullName;
    const zone = b.residence_zone ?? b.residenceZone;
    const locationId = b.residence_location_id ?? b.residenceLocationId;
    const customResidence = b.custom_residence ?? b.customResidence;
    const email = String(b.email || '').trim().toLowerCase();
    if (!/^\d{10}$/.test(String(studentId || '')) || !validText(b.username, 50, true) || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email) || !validText(displayName, 100, true) || typeof b.password !== 'string' || b.password.length < 8 || !zones.includes(zone) || (locationId != null && !validId(locationId)) || !validText(customResidence, 150)) return bad(res, 'Invalid registration details');
    try {
        if (locationId) {
            const locations = await db('SELECT location_id FROM locations WHERE location_id=? AND zone=? AND is_active=1', [locationId, zone]);
            if (!locations.length) return bad(res, 'Residence does not exist or is inactive');
        } else if (!validText(customResidence, 150, true)) return bad(res, 'customResidence is required when residence is not listed');
        const hash = argon2.hashSync(b.password);
        const result = await transaction(async query => {
            const user = await query('INSERT INTO users (student_id,username,email,password_hash,display_name,residence_zone,residence_location_id) VALUES (?,?,?,?,?,?,?)', [studentId, b.username.trim(), email, hash, displayName.trim(), zone, locationId || null]);
            if (!locationId) await query('INSERT INTO location_requests (user_id,name,zone,reason) VALUES (?,?,?,?)', [user.insertId, customResidence.trim(), zone, 'Requested during registration']);
            return user;
        });
        res.status(201).json({ success: true, user_id: result.insertId, status: 'pending', message: 'Registration submitted for admin approval' });
    } catch (err) { dbError(res, err); }
});
app.post('/api/login', async (req, res) => {
    const { email, password } = req.body || {};
    if (!email || !password) return bad(res, 'email and password are required');
    try {
        const rows = await db('SELECT user_id,email,password_hash,display_name,username,role,status,residence_zone,residence_location_id FROM users WHERE email=?', [String(email).trim().toLowerCase()]);
        if (!rows.length || !argon2.verifySync(rows[0].password_hash, String(password))) return res.status(401).json({ success: false, message: 'Invalid email or password' });
        const user = rows[0];
        if (user.status !== 'active') return res.status(403).json({ success: false, message: `Account is ${user.status}` });
        delete user.password_hash;
        res.json({ success: true, token: jwt.sign({ user_id: user.user_id, role: user.role }, JWT_KEY, { expiresIn: '1d' }), user });
    } catch (err) { dbError(res, err); }
});
app.get('/api/profile', auth, async (req, res) => {
    try { const rows = await db('SELECT u.user_id,u.student_id,u.username,u.email,u.display_name,u.residence_zone,u.residence_location_id,u.role,u.status,u.created_at,l.name AS residence_name FROM users u LEFT JOIN locations l ON l.location_id=u.residence_location_id WHERE u.user_id=?', [req.user.user_id]); res.json({ success: true, data: rows[0] }); } catch (err) { dbError(res, err); }
});
app.put('/api/profile', auth, async (req, res) => {
    const b = req.body || {}; const name = b.display_name ?? b.displayName;
    if (!validText(name, 100, true) || (b.username !== undefined && !validText(b.username, 50, true))) return bad(res, 'Invalid display name or username');
    try { await db('UPDATE users SET display_name=?,username=COALESCE(?,username) WHERE user_id=?', [name.trim(), b.username?.trim() || null, req.user.user_id]); res.json({ success: true, message: 'Profile updated' }); } catch (err) { dbError(res, err); }
});

// ---------- Catalogue and member dashboard ----------
app.get('/api/categories', async (_req, res) => { try { res.json({ success: true, data: await db('SELECT category_id,name,emoji FROM categories WHERE is_active=1 ORDER BY name') }); } catch (err) { dbError(res, err); } });
app.get('/api/locations', async (req, res) => {
    if (req.query.zone && !zones.includes(req.query.zone)) return bad(res, 'Invalid zone');
    try { const rows = await db(`SELECT location_id,zone,name FROM locations WHERE is_active=1${req.query.zone ? ' AND zone=?' : ''} ORDER BY zone,name`, req.query.zone ? [req.query.zone] : []); res.json({ success: true, data: rows }); } catch (err) { dbError(res, err); }
});
app.get('/api/dashboard', auth, async (req, res) => {
    const userId = req.user.user_id;
    try {
        const [counts, listings, orders, requests] = await Promise.all([
            db(`SELECT (SELECT COUNT(*) FROM products WHERE seller_id=?) AS my_listings,(SELECT COUNT(*) FROM products WHERE seller_id=? AND status='pending_review') AS listings_to_review,(SELECT COUNT(*) FROM products WHERE seller_id=? AND status='changes_requested') AS listings_to_fix,(SELECT COUNT(*) FROM orders WHERE buyer_id=? AND status IN ('pending_payment','paid','ready_for_meetup')) AS buying_active,(SELECT COUNT(*) FROM orders WHERE seller_id=? AND status IN ('pending_payment','paid','ready_for_meetup')) AS selling_active,(SELECT COUNT(*) FROM refunds WHERE requested_by=? AND refund_status='pending') AS refunds_pending`, [userId,userId,userId,userId,userId,userId]),
            db("SELECT product_id,title,price,status,review_note,created_at FROM products WHERE seller_id=? ORDER BY updated_at DESC,product_id DESC LIMIT 5", [userId]),
            db(`SELECT o.order_id,o.status,o.total_amount,o.meetup_location,o.meetup_datetime,o.created_at,p.title,CASE WHEN o.buyer_id=? THEN 'buying' ELSE 'selling' END AS perspective FROM orders o JOIN products p ON p.product_id=o.product_id WHERE o.buyer_id=? OR o.seller_id=? ORDER BY o.updated_at DESC,o.order_id DESC LIMIT 5`, [userId,userId,userId]),
            db("SELECT request_id,status,name,zone FROM location_requests WHERE user_id=? AND status IN ('pending','reviewing') ORDER BY created_at DESC LIMIT 1", [userId])
        ]);
        res.json({ success: true, data: { user: req.user, counts: counts[0], recent_listings: listings, recent_orders: orders, pending_location_request: requests[0] || null } });
    } catch (err) { dbError(res, err); }
});

app.get('/api/products', async (req, res) => {
    const { keyword, category_id, zone, location_id, sort = 'newest' } = req.query;
    if ((category_id && !validId(category_id)) || (location_id && !validId(location_id)) || (zone && !zones.includes(zone)) || !validText(keyword, 150)) return bad(res, 'Invalid product filter');
    const paging = getPaging(req, res); if (!paging) return;
    const orderBy = { newest: 'p.created_at DESC', price_asc: 'p.price ASC,p.product_id DESC', price_desc: 'p.price DESC,p.product_id DESC', urgent: 'p.urgency_level DESC,p.created_at DESC' }[sort]; if (!orderBy) return bad(res, 'Invalid sort');
    const clauses = ["p.status='available'", "u.status='active'"]; const values = [];
    if (keyword) { clauses.push('(p.title LIKE ? OR p.description LIKE ?)'); values.push(`%${keyword.trim()}%`, `%${keyword.trim()}%`); }
    if (category_id) { clauses.push('p.category_id=?'); values.push(category_id); } if (zone) { clauses.push('p.zone=?'); values.push(zone); } if (location_id) { clauses.push('p.location_id=?'); values.push(location_id); }
    try { const rows = await db(`SELECT p.product_id,p.title,p.description,p.price,p.item_condition,p.urgency_level,p.zone,p.location_name,p.location_id,p.clearance_deadline,p.created_at,p.category_id,COALESCE(c.name,p.category) AS category_name,u.user_id AS seller_id,u.display_name AS seller_name,(SELECT image_url FROM product_images WHERE product_id=p.product_id ORDER BY display_order,image_id LIMIT 1) AS image_url FROM products p JOIN users u ON u.user_id=p.seller_id LEFT JOIN categories c ON c.category_id=p.category_id WHERE ${clauses.join(' AND ')} ORDER BY ${orderBy} LIMIT ? OFFSET ?`, [...values,paging.limit + 1,paging.offset]); sendPage(res, rows, paging); } catch (err) { dbError(res, err); }
});
app.get('/api/products/:product_id', async (req, res) => {
    if (!validId(req.params.product_id)) return bad(res, 'Invalid product_id');
    try { const rows = await db(`SELECT p.*,u.display_name AS seller_name,u.username,COALESCE(c.name,p.category) AS category_name FROM products p JOIN users u ON u.user_id=p.seller_id LEFT JOIN categories c ON c.category_id=p.category_id WHERE p.product_id=? AND p.status='available'`, [req.params.product_id]); if (!rows.length) return notFound(res, 'Product not found'); const images = await db('SELECT image_id,image_url,display_order FROM product_images WHERE product_id=? ORDER BY display_order,image_id', [req.params.product_id]); await db('UPDATE products SET view_count=view_count+1 WHERE product_id=?', [req.params.product_id]); res.json({ success: true, data: { ...rows[0], view_count: Number(rows[0].view_count) + 1, images } }); } catch (err) { dbError(res, err); }
});
function getProductInput(b) {
    const x = b || {}; const locationId = x.location_id ?? x.locationId; const locationName = x.location_name ?? x.locationName;
    if (!validId(x.category_id ?? x.categoryId) || !validText(x.title, 150, true) || !validText(x.description, 5000) || !/^\d+(\.\d{1,2})?$/.test(String(x.price)) || Number(x.price) > 99999999.99 || (x.item_condition != null && !['new','like_new','good','fair'].includes(x.item_condition)) || !['normal','urgent','very_urgent'].includes(x.urgency_level || x.urgencyLevel || 'normal') || !zones.includes(x.zone) || !validId(locationId) || !validText(locationName, 255, true) || !validText(x.location_detail ?? x.locationDetail, 255)) return null;
    return { categoryId: x.category_id ?? x.categoryId, title: x.title.trim(), description: x.description?.trim() || null, price: Number(x.price), condition: x.item_condition || null, urgency: x.urgency_level ?? x.urgencyLevel ?? 'normal', zone: x.zone, locationId, locationName: locationName.trim(), locationDetail: (x.location_detail ?? x.locationDetail)?.trim() || null, deadline: x.clearance_deadline ?? x.clearanceDeadline ?? null };
}
app.post('/api/products', auth, async (req, res) => {
    const x = getProductInput(req.body); if (!x) return bad(res, 'Invalid product details');
    try { const locations = await db('SELECT location_id FROM locations WHERE location_id=? AND zone=? AND is_active=1', [x.locationId,x.zone]); const cats = await db('SELECT name FROM categories WHERE category_id=? AND is_active=1', [x.categoryId]); if (!locations.length || !cats.length) return bad(res, 'Category or pickup location is unavailable'); const result = await db(`INSERT INTO products (seller_id,title,description,category,category_id,price,item_condition,urgency_level,zone,location_name,location_id,location_detail,clearance_deadline,status) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,'pending_review')`, [req.user.user_id,x.title,x.description,cats[0].name,x.categoryId,x.price,x.condition,x.urgency,x.zone,x.locationName,x.locationId,x.locationDetail,x.deadline]); res.status(201).json({ success: true, product_id: result.insertId, status: 'pending_review' }); } catch (err) { dbError(res, err); }
});
app.get('/api/my/listings', auth, async (req, res) => { const paging = getPaging(req, res); if (!paging) return; try { const rows = await db(`SELECT p.*,COALESCE(c.name,p.category) AS category_name,(SELECT image_url FROM product_images WHERE product_id=p.product_id ORDER BY display_order,image_id LIMIT 1) AS image_url FROM products p LEFT JOIN categories c ON c.category_id=p.category_id WHERE p.seller_id=? ORDER BY p.updated_at DESC,p.product_id DESC LIMIT ? OFFSET ?`, [req.user.user_id,paging.limit + 1,paging.offset]); sendPage(res, rows, paging); } catch (err) { dbError(res, err); } });
app.put('/api/products/:product_id', auth, async (req, res) => { if (!validId(req.params.product_id)) return bad(res, 'Invalid product_id'); const x = getProductInput(req.body); if (!x) return bad(res, 'Invalid product details'); try { const result = await db(`UPDATE products SET title=?,description=?,category_id=?,price=?,item_condition=?,urgency_level=?,zone=?,location_name=?,location_id=?,location_detail=?,clearance_deadline=?,status='pending_review',review_note=NULL,reject_reason=NULL WHERE product_id=? AND seller_id=? AND status IN ('pending_review','changes_requested','rejected','available')`, [x.title,x.description,x.categoryId,x.price,x.condition,x.urgency,x.zone,x.locationName,x.locationId,x.locationDetail,x.deadline,req.params.product_id,req.user.user_id]); if (!result.affectedRows) return res.status(409).json({ success: false, message: 'Listing cannot be edited in its current state' }); res.json({ success: true, status: 'pending_review' }); } catch (err) { dbError(res, err); } });
app.post('/api/products/:product_id/images', auth, async (req, res) => { const b = req.body || {}; const url = b.image_url ?? b.imageUrl; const order = b.display_order ?? b.displayOrder ?? 1; if (!validId(req.params.product_id) || !validText(url, 500, true) || !Number.isInteger(Number(order)) || Number(order) < 1) return bad(res, 'Invalid image'); try { const owner = await db('SELECT product_id FROM products WHERE product_id=? AND seller_id=?', [req.params.product_id,req.user.user_id]); if (!owner.length) return notFound(res, 'Product not found'); const result = await db('INSERT INTO product_images (product_id,image_url,display_order) VALUES (?,?,?)', [req.params.product_id,url.trim(),order]); res.status(201).json({ success: true, image_id: result.insertId }); } catch (err) { dbError(res, err); } });

// ---------- Purchase flow ----------
app.post('/api/orders', auth, async (req, res) => {
    const { product_id, meetup_location, meetup_datetime } = req.body || {};
    if (!validId(product_id) || !validText(meetup_location, 255, true) || (meetup_datetime && Number.isNaN(Date.parse(meetup_datetime)))) return bad(res, 'Invalid order details');
    try { const result = await transaction(async query => { const products = await query("SELECT * FROM products WHERE product_id=? AND status='available' FOR UPDATE", [product_id]); if (!products.length) throw Object.assign(new Error('Product not available'), { status: 409 }); const product = products[0]; if (Number(product.seller_id) === Number(req.user.user_id)) throw Object.assign(new Error('Cannot buy your own product'), { status: 400 }); const price = Number(product.price); const order = await query('INSERT INTO orders (product_id,buyer_id,seller_id,seller_price,total_amount,seller_payout,meetup_location,meetup_datetime,payment_deadline) VALUES (?,?,?,?,?,?,?,?,DATE_ADD(UTC_TIMESTAMP(),INTERVAL 24 HOUR))', [product_id,req.user.user_id,product.seller_id,price,price,price,meetup_location.trim(),meetup_datetime ? new Date(meetup_datetime) : null]); await query("UPDATE products SET status='reserved' WHERE product_id=?", [product_id]); return order; }); res.status(201).json({ success: true, order_id: result.insertId, status: 'pending_payment' }); } catch (err) { err.status ? res.status(err.status).json({ success: false, message: err.message }) : dbError(res, err); }
});
app.get('/api/orders', auth, async (req, res) => { const paging = getPaging(req, res); if (!paging) return; try { const rows = await db(`SELECT o.*,p.title,p.location_name,b.display_name AS buyer_name,s.display_name AS seller_name,(SELECT image_url FROM product_images WHERE product_id=o.product_id ORDER BY display_order,image_id LIMIT 1) AS image_url,CASE WHEN o.buyer_id=? THEN 'buying' ELSE 'selling' END AS perspective FROM orders o JOIN products p ON p.product_id=o.product_id JOIN users b ON b.user_id=o.buyer_id JOIN users s ON s.user_id=o.seller_id WHERE o.buyer_id=? OR o.seller_id=? ORDER BY o.updated_at DESC,o.order_id DESC LIMIT ? OFFSET ?`, [req.user.user_id,req.user.user_id,req.user.user_id,paging.limit + 1,paging.offset]); sendPage(res, rows, paging); } catch (err) { dbError(res, err); } });
app.put('/api/orders/:order_id/meetup', auth, async (req, res) => { const { meetup_location, meetup_datetime } = req.body || {}; if (!validId(req.params.order_id) || !validText(meetup_location, 255, true) || (meetup_datetime && Number.isNaN(Date.parse(meetup_datetime)))) return bad(res, 'Invalid meetup'); try { const result = await db("UPDATE orders SET meetup_location=?,meetup_datetime=? WHERE order_id=? AND (buyer_id=? OR seller_id=?) AND status IN ('pending_payment','paid','ready_for_meetup')", [meetup_location.trim(),meetup_datetime ? new Date(meetup_datetime) : null,req.params.order_id,req.user.user_id,req.user.user_id]); if (!result.affectedRows) return res.status(409).json({ success: false, message: 'Order cannot be updated' }); res.json({ success: true, message: 'Meetup updated' }); } catch (err) { dbError(res, err); } });
app.post('/api/orders/:order_id/pay', auth, async (req, res) => { const b = req.body || {}; const method = b.payment_method ?? b.paymentMethod ?? 'gateway'; const reference = b.transaction_ref ?? b.transactionRef; const slip = b.payment_slip_url ?? b.paymentSlipUrl; if (!validId(req.params.order_id) || !['gateway','bank_transfer','cash','free'].includes(method) || !validText(reference,150) || !validText(slip,500)) return bad(res, 'Invalid payment'); try { const result = await transaction(async query => { const orders = await query("SELECT * FROM orders WHERE order_id=? AND buyer_id=? AND status='pending_payment' FOR UPDATE", [req.params.order_id,req.user.user_id]); if (!orders.length) throw Object.assign(new Error('Order is not awaiting payment'), { status: 409 }); const order = orders[0]; await query("INSERT INTO payments (order_id,payment_method,transaction_ref,payment_slip_url,amount,payment_status,seller_transfer_status,paid_at) VALUES (?,?,?,?,?,'paid','held',UTC_TIMESTAMP())", [order.order_id,method,reference || null,slip || null,order.total_amount]); await query("UPDATE orders SET status='ready_for_meetup' WHERE order_id=?", [order.order_id]); return order; }); res.json({ success: true, order_id: result.order_id, status: 'ready_for_meetup' }); } catch (err) { err.status ? res.status(err.status).json({ success: false, message: err.message }) : dbError(res, err); } });
app.post('/api/orders/:order_id/received', auth, async (req, res) => { if (!validId(req.params.order_id)) return bad(res, 'Invalid order_id'); try { const result = await transaction(async query => { const orders = await query("SELECT * FROM orders WHERE order_id=? AND buyer_id=? AND status='ready_for_meetup' FOR UPDATE", [req.params.order_id,req.user.user_id]); if (!orders.length) throw Object.assign(new Error('Order is not ready to complete'), { status: 409 }); const order = orders[0]; await query("UPDATE orders SET status='completed',received_at=UTC_TIMESTAMP() WHERE order_id=?", [order.order_id]); await query("UPDATE products SET status='sold' WHERE product_id=?", [order.product_id]); await query("UPDATE payments SET seller_transfer_status='pending' WHERE order_id=?", [order.order_id]); return order; }); res.json({ success: true, order_id: result.order_id, status: 'completed' }); } catch (err) { err.status ? res.status(err.status).json({ success: false, message: err.message }) : dbError(res, err); } });
app.post('/api/orders/:order_id/cancel', auth, async (req, res) => { if (!validId(req.params.order_id)) return bad(res, 'Invalid order_id'); try { await transaction(async query => { const orders = await query("SELECT * FROM orders WHERE order_id=? AND buyer_id=? AND status='pending_payment' FOR UPDATE", [req.params.order_id,req.user.user_id]); if (!orders.length) throw Object.assign(new Error('Order cannot be cancelled'), { status: 409 }); await query("UPDATE orders SET status='cancelled' WHERE order_id=?", [req.params.order_id]); await query("UPDATE products SET status='available' WHERE product_id=?", [orders[0].product_id]); }); res.json({ success: true, status: 'cancelled' }); } catch (err) { err.status ? res.status(err.status).json({ success: false, message: err.message }) : dbError(res, err); } });
app.post('/api/orders/:order_id/refunds', auth, async (req, res) => { const { reason } = req.body || {}; if (!validId(req.params.order_id) || !validText(reason,5000,true)) return bad(res, 'Invalid refund reason'); try { const result = await db("INSERT INTO refunds (order_id,requested_by,refund_amount,reason) SELECT order_id,?,total_amount,? FROM orders WHERE order_id=? AND buyer_id=? AND status IN ('paid','ready_for_meetup')", [req.user.user_id,reason.trim(),req.params.order_id,req.user.user_id]); if (!result.affectedRows) return res.status(409).json({ success: false, message: 'Refund cannot be requested for this order' }); await db("UPDATE orders SET status='refund_requested' WHERE order_id=?", [req.params.order_id]); res.status(201).json({ success: true, refund_id: result.insertId, status: 'pending' }); } catch (err) { dbError(res, err); } });

// ---------- Reports and residence requests ----------
app.post('/api/reports', auth, async (req, res) => { const b = req.body || {}; const orderId = b.order_id ?? b.orderId; const type = b.report_type ?? b.reportType ?? 'other'; const evidence = b.evidence_url ?? b.evidenceUrl; if (!validId(orderId) || !['product_problem','payment_problem','refund_problem','seller_problem','other'].includes(type) || !validText(b.reason,5000,true) || !validText(evidence,500)) return bad(res, 'Invalid report'); try { const access = await db('SELECT order_id FROM orders WHERE order_id=? AND (buyer_id=? OR seller_id=?)', [orderId,req.user.user_id,req.user.user_id]); if (!access.length) return res.status(403).json({ success: false, message: 'Order access denied' }); const result = await db('INSERT INTO reports (reporter_id,order_id,report_type,reason,evidence_url) VALUES (?,?,?,?,?)', [req.user.user_id,orderId,type,b.reason.trim(),evidence?.trim() || null]); res.status(201).json({ success: true, report_id: result.insertId, status: 'pending' }); } catch (err) { dbError(res, err); } });
app.post('/api/location-requests', auth, async (req, res) => { const { name, zone, address, reason } = req.body || {}; if (!validText(name,150,true) || !zones.includes(zone) || !validText(address,255) || !validText(reason,5000)) return bad(res, 'Invalid location request'); try { const result = await db('INSERT INTO location_requests (user_id,name,zone,address,reason) VALUES (?,?,?,?,?)', [req.user.user_id,name.trim(),zone,address?.trim() || null,reason?.trim() || null]); res.status(201).json({ success: true, request_id: result.insertId, status: 'pending' }); } catch (err) { dbError(res, err); } });

// ---------- Admin dashboard and moderation ----------
app.get('/api/admin/dashboard', auth, adminOnly, async (_req, res) => { try { const [overview,listings,reports,locations] = await Promise.all([db("SELECT (SELECT COUNT(*) FROM users) AS users_total,(SELECT COUNT(*) FROM users WHERE status='pending') AS users_pending,(SELECT COUNT(*) FROM products WHERE status='available') AS items_live,(SELECT COUNT(*) FROM products WHERE status='pending_review') AS items_pending,(SELECT COUNT(*) FROM reports WHERE status IN ('pending','reviewing')) AS reports_open,(SELECT COUNT(*) FROM location_requests WHERE status IN ('pending','reviewing')) AS locations_pending,(SELECT COUNT(*) FROM categories WHERE is_active=1) AS categories_active,(SELECT COUNT(*) FROM refunds WHERE refund_status='pending') AS refunds_pending"),db("SELECT p.product_id,p.title,p.price,p.created_at,u.display_name AS seller_name,c.name AS category_name FROM products p JOIN users u ON u.user_id=p.seller_id LEFT JOIN categories c ON c.category_id=p.category_id WHERE p.status='pending_review' ORDER BY p.created_at LIMIT 5"),db("SELECT r.report_id,r.report_type,r.reason,r.status,r.created_at,p.title,o.order_id FROM reports r LEFT JOIN orders o ON o.order_id=r.order_id LEFT JOIN products p ON p.product_id=o.product_id WHERE r.status IN ('pending','reviewing') ORDER BY r.created_at DESC LIMIT 5"),db("SELECT r.request_id,r.name,r.zone,r.status,r.created_at,u.display_name AS requester_name FROM location_requests r JOIN users u ON u.user_id=r.user_id WHERE r.status IN ('pending','reviewing') ORDER BY r.created_at DESC LIMIT 5")]); res.json({ success: true, data: { overview: overview[0], pending_listings: listings, open_reports: reports, pending_location_requests: locations } }); } catch (err) { dbError(res, err); } });
app.get('/api/admin/users', auth, adminOnly, async (req, res) => { const status = req.query.status; if (status && !['pending','active','suspended','rejected'].includes(status)) return bad(res, 'Invalid status'); const paging = getPaging(req,res); if (!paging) return; try { const rows = await db(`SELECT user_id,student_id,username,email,display_name,residence_zone,residence_location_id,role,status,created_at FROM users${status ? ' WHERE status=?' : ''} ORDER BY created_at DESC LIMIT ? OFFSET ?`, [...(status ? [status] : []),paging.limit + 1,paging.offset]); sendPage(res,rows,paging); } catch (err) { dbError(res,err); } });
app.put('/api/admin/users/:user_id/status', auth, adminOnly, async (req,res) => { const { status } = req.body || {}; if (!validId(req.params.user_id) || !['active','suspended','rejected'].includes(status)) return bad(res,'Invalid user status'); try { const result = await db("UPDATE users SET status=?,verified_by=?,verified_at=UTC_TIMESTAMP() WHERE user_id=? AND role='member'",[status,req.user.user_id,req.params.user_id]); if (!result.affectedRows) return notFound(res,'Member not found'); res.json({success:true,status}); } catch(err) { dbError(res,err); } });
app.get('/api/admin/listings', auth, adminOnly, async (req,res) => { const status = req.query.status || 'pending_review'; if (!['pending_review','changes_requested','rejected','available','reserved','sold','hidden','all'].includes(status)) return bad(res,'Invalid listing status'); const paging=getPaging(req,res); if(!paging)return; try { const rows=await db(`SELECT p.*,u.display_name AS seller_name,c.name AS category_name FROM products p JOIN users u ON u.user_id=p.seller_id LEFT JOIN categories c ON c.category_id=p.category_id${status==='all'?'':' WHERE p.status=?'} ORDER BY p.created_at LIMIT ? OFFSET ?`,[...(status==='all'?[]:[status]),paging.limit+1,paging.offset]);sendPage(res,rows,paging);}catch(err){dbError(res,err);} });
app.put('/api/admin/listings/:product_id/review', auth, adminOnly, async (req,res) => { const b=req.body||{}; const map={approve:'available',changes_requested:'changes_requested',reject:'rejected'}; if(!validId(req.params.product_id)||!map[b.action]||!validText(b.review_note ?? b.reviewNote,5000,b.action!=='approve')||(b.action==='reject'&&!['prohibited_item','misleading','poor_photos','duplicate','other'].includes(b.reject_reason ?? b.rejectReason)))return bad(res,'Invalid review'); try {const result=await db("UPDATE products SET status=?,review_note=?,reject_reason=?,reviewed_by=?,reviewed_at=UTC_TIMESTAMP() WHERE product_id=? AND status='pending_review'",[map[b.action],(b.review_note ?? b.reviewNote)?.trim()||null,b.action==='reject'?(b.reject_reason ?? b.rejectReason):null,req.user.user_id,req.params.product_id]);if(!result.affectedRows)return res.status(409).json({success:false,message:'Listing is not awaiting review'});res.json({success:true,status:map[b.action]});}catch(err){dbError(res,err);} });
app.get('/api/admin/reports', auth, adminOnly, async (req,res) => { const paging=getPaging(req,res);if(!paging)return;try{const rows=await db('SELECT r.*,u.display_name AS reporter_name,o.product_id,p.title AS product_title FROM reports r JOIN users u ON u.user_id=r.reporter_id LEFT JOIN orders o ON o.order_id=r.order_id LEFT JOIN products p ON p.product_id=o.product_id ORDER BY r.created_at DESC LIMIT ? OFFSET ?',[paging.limit+1,paging.offset]);sendPage(res,rows,paging);}catch(err){dbError(res,err);}});
app.put('/api/admin/reports/:report_id', auth, adminOnly, async (req,res) => { const b=req.body||{};if(!validId(req.params.report_id)||!['reviewing','resolved','rejected'].includes(b.status)||!validText(b.admin_note ?? b.adminNote,5000))return bad(res,'Invalid report resolution');try{await transaction(async query=>{const reports=await query('SELECT order_id FROM reports WHERE report_id=? FOR UPDATE',[req.params.report_id]);if(!reports.length)throw Object.assign(new Error('Report not found'),{status:404});await query(`UPDATE reports SET status=?,reviewed_by=?,admin_note=?,resolved_at=${b.status==='reviewing'?'NULL':'UTC_TIMESTAMP()'} WHERE report_id=?`,[b.status,req.user.user_id,(b.admin_note ?? b.adminNote)?.trim()||null,req.params.report_id]);if(b.hide_product===true&&reports[0].order_id)await query("UPDATE products p JOIN orders o ON o.product_id=p.product_id SET p.status='hidden' WHERE o.order_id=?",[reports[0].order_id]);});res.json({success:true,status:b.status});}catch(err){err.status?res.status(err.status).json({success:false,message:err.message}):dbError(res,err);}});

app.get('/api/admin/categories', auth, adminOnly, async (_req, res) => {
    try {
        const rows = await db(`SELECT c.category_id,c.name,c.emoji,c.is_active,c.created_at,
            COUNT(p.product_id) AS product_count FROM categories c
            LEFT JOIN products p ON p.category_id=c.category_id GROUP BY c.category_id ORDER BY c.name`);
        res.json({ success: true, data: rows });
    } catch (err) { dbError(res, err); }
});
app.post('/api/admin/categories', auth, adminOnly, async (req, res) => {
    const { name, emoji = '🏷️', is_active = true } = req.body || {};
    if (!validText(name, 100, true) || !validText(emoji, 16, true) || typeof is_active !== 'boolean') return bad(res, 'Invalid category');
    try { const result = await db('INSERT INTO categories (name,emoji,is_active) VALUES (?,?,?)', [name.trim(), emoji.trim(), is_active]); res.status(201).json({ success: true, category_id: result.insertId }); } catch (err) { dbError(res, err); }
});
app.put('/api/admin/categories/:category_id', auth, adminOnly, async (req, res) => {
    const { name, emoji, is_active } = req.body || {};
    if (!validId(req.params.category_id) || !validText(name, 100, true) || !validText(emoji, 16, true) || typeof is_active !== 'boolean') return bad(res, 'Invalid category');
    try { const result = await db('UPDATE categories SET name=?,emoji=?,is_active=? WHERE category_id=?', [name.trim(), emoji.trim(), is_active, req.params.category_id]); if (!result.affectedRows) return notFound(res, 'Category not found'); res.json({ success: true, message: 'Category updated' }); } catch (err) { dbError(res, err); }
});

app.get('/api/admin/locations', auth, adminOnly, async (req, res) => {
    if (req.query.zone && !zones.includes(req.query.zone)) return bad(res, 'Invalid zone');
    try { const rows = await db(`SELECT location_id,zone,name,is_active,created_at FROM locations${req.query.zone ? ' WHERE zone=?' : ''} ORDER BY zone,name`, req.query.zone ? [req.query.zone] : []); res.json({ success: true, data: rows }); } catch (err) { dbError(res, err); }
});
app.post('/api/admin/locations', auth, adminOnly, async (req, res) => {
    const { name, zone } = req.body || {}; if (!validText(name, 150, true) || !zones.includes(zone)) return bad(res, 'Invalid location');
    try { const result = await db('INSERT INTO locations (name,zone) VALUES (?,?)', [name.trim(), zone]); res.status(201).json({ success: true, location_id: result.insertId }); } catch (err) { dbError(res, err); }
});
app.put('/api/admin/locations/:location_id', auth, adminOnly, async (req, res) => {
    const { name, is_active } = req.body || {}; if (!validId(req.params.location_id) || !validText(name, 150, true) || typeof is_active !== 'boolean') return bad(res, 'Invalid location');
    try { const result = await db('UPDATE locations SET name=?,is_active=? WHERE location_id=?', [name.trim(), is_active, req.params.location_id]); if (!result.affectedRows) return notFound(res, 'Location not found'); res.json({ success: true, message: 'Location updated' }); } catch (err) { dbError(res, err); }
});
app.get('/api/admin/location-requests', auth, adminOnly, async (req, res) => {
    const status = req.query.status; if (status && !['pending','reviewing','approved','merged','rejected'].includes(status)) return bad(res, 'Invalid status');
    const paging = getPaging(req, res); if (!paging) return;
    try { const rows = await db(`SELECT r.*,u.display_name AS requester_name,u.username FROM location_requests r JOIN users u ON u.user_id=r.user_id${status ? ' WHERE r.status=?' : ''} ORDER BY r.created_at DESC LIMIT ? OFFSET ?`, [...(status ? [status] : []), paging.limit + 1, paging.offset]); sendPage(res, rows, paging); } catch (err) { dbError(res, err); }
});
app.put('/api/admin/location-requests/:request_id/review', auth, adminOnly, async (req, res) => {
    const { action, merge_into_location_id } = req.body || {};
    if (!validId(req.params.request_id) || !['reviewing','approve','merge','reject'].includes(action) || (action === 'merge' && !validId(merge_into_location_id))) return bad(res, 'Invalid location review');
    try {
        const result = await transaction(async query => {
            const requests = await query("SELECT * FROM location_requests WHERE request_id=? AND status IN ('pending','reviewing') FOR UPDATE", [req.params.request_id]);
            if (!requests.length) throw Object.assign(new Error('Location request is not open'), { status: 409 });
            const request = requests[0];
            if (action === 'reviewing') { await query("UPDATE location_requests SET status='reviewing',handled_by=? WHERE request_id=?", [req.user.user_id, request.request_id]); return { status: 'reviewing' }; }
            if (action === 'reject') { await query("UPDATE location_requests SET status='rejected',handled_by=?,resolved_at=UTC_TIMESTAMP() WHERE request_id=?", [req.user.user_id, request.request_id]); return { status: 'rejected' }; }
            let locationId;
            if (action === 'approve') {
                const inserted = await query('INSERT INTO locations (name,zone) VALUES (?,?)', [request.name, request.zone]);
                locationId = inserted.insertId;
                await query("UPDATE location_requests SET status='approved',approved_location_id=?,handled_by=?,resolved_at=UTC_TIMESTAMP() WHERE request_id=?", [locationId,req.user.user_id,request.request_id]);
            } else {
                const locations = await query('SELECT location_id FROM locations WHERE location_id=? AND zone=? AND is_active=1', [merge_into_location_id,request.zone]);
                if (!locations.length) throw Object.assign(new Error('Merge target is unavailable'), { status: 400 });
                locationId = locations[0].location_id;
                await query("UPDATE location_requests SET status='merged',merged_into_location_id=?,handled_by=?,resolved_at=UTC_TIMESTAMP() WHERE request_id=?", [locationId,req.user.user_id,request.request_id]);
            }
            await query('UPDATE users SET residence_zone=?,residence_location_id=? WHERE user_id=?', [request.zone,locationId,request.user_id]);
            return { status: action === 'approve' ? 'approved' : 'merged', location_id: locationId };
        });
        res.json({ success: true, ...result });
    } catch (err) { err.status ? res.status(err.status).json({ success: false, message: err.message }) : dbError(res, err); }
});

// Development data is opt-in and never overwrites a database that already has users.
// It makes the two dashboards and the main marketplace flow testable immediately.
app.post('/api/dev/seed', async (_req, res) => {
    if (process.env.NODE_ENV === 'production') return notFound(res, 'API endpoint not found');
    try {
        const result = await transaction(async query => {
            const existing = await query('SELECT COUNT(*) AS total FROM users');
            if (existing[0].total) throw Object.assign(new Error('Database already has users; seed was not applied'), { status: 409 });
            const locations = await query("SELECT location_id,zone,name FROM locations WHERE is_active=1 ORDER BY location_id LIMIT 2");
            const categories = await query('SELECT category_id,name FROM categories WHERE is_active=1 ORDER BY category_id LIMIT 1');
            if (locations.length < 2 || !categories.length) throw Object.assign(new Error('Seed requires active locations and categories'), { status: 409 });
            const hash = argon2.hashSync('Demo12345!');
            const admin = await query("INSERT INTO users (student_id,username,email,password_hash,display_name,residence_zone,residence_location_id,role,status) VALUES ('0000000001','admin_demo','admin@unisw.ap',?,'Admin Demo',? ,?,'admin','active')", [hash,locations[0].zone,locations[0].location_id]);
            const maya = await query("INSERT INTO users (student_id,username,email,password_hash,display_name,residence_zone,residence_location_id,role,status) VALUES ('0000000002','maya_demo','maya@unisw.ap',?,'Maya Demo',? ,?,'member','active')", [hash,locations[0].zone,locations[0].location_id]);
            const niran = await query("INSERT INTO users (student_id,username,email,password_hash,display_name,residence_zone,residence_location_id,role,status) VALUES ('0000000003','niran_demo','niran@unisw.ap',?,'Niran Demo',? ,?,'member','active')", [hash,locations[1].zone,locations[1].location_id]);
            const p = (seller, title, price, status, location) => query('INSERT INTO products (seller_id,title,description,category,category_id,price,zone,location_name,location_id,status) VALUES (?,?,?,?,?,?,?,?,?,?)', [seller,title,`${title} for dashboard testing`,categories[0].name,categories[0].category_id,price,location.zone,location.name,location.location_id,status]);
            const pending = await p(maya.insertId, 'Study desk (pending)', 450, 'pending_review', locations[0]);
            await p(maya.insertId, 'Lamp (needs changes)', 120, 'changes_requested', locations[0]);
            await p(niran.insertId, 'Campus bicycle', 950, 'available', locations[1]);
            const orderedProduct = await p(niran.insertId, 'Textbook bundle', 300, 'reserved', locations[1]);
            const order = await query("INSERT INTO orders (product_id,buyer_id,seller_id,seller_price,total_amount,seller_payout,status,meetup_location,meetup_datetime) VALUES (?,?,?,?,?,?, 'ready_for_meetup', ?, DATE_ADD(UTC_TIMESTAMP(),INTERVAL 1 DAY))", [orderedProduct.insertId,maya.insertId,niran.insertId,300,300,300,locations[0].name]);
            await query("INSERT INTO payments (order_id,payment_method,amount,payment_status,seller_transfer_status,paid_at) VALUES (?,'gateway',300,'paid','held',UTC_TIMESTAMP())", [order.insertId]);
            await query("INSERT INTO reports (reporter_id,order_id,report_type,reason,status) VALUES (?,?,'product_problem','Demo report awaiting review','pending')", [maya.insertId,order.insertId]);
            await query("INSERT INTO location_requests (user_id,name,zone,reason,status) VALUES (?,?,?,'Demo location request','pending')", [maya.insertId,'Demo Residence',locations[0].zone]);
            return { admin: admin.insertId, maya: maya.insertId, niran: niran.insertId, pending_product: pending.insertId, order: order.insertId };
        });
        res.status(201).json({ success: true, message: 'Demo data created', credentials: { admin: 'admin@unisw.ap / Demo12345!', member: 'maya@unisw.ap / Demo12345!' }, data: result });
    } catch (err) { err.status ? res.status(err.status).json({ success: false, message: err.message }) : dbError(res, err); }
});

app.use((err,_req,res,_next)=>err instanceof SyntaxError&&'body'in err?bad(res,'Invalid JSON body'):dbError(res,err));
app.use((_req,res)=>res.status(404).json({success:false,message:'API endpoint not found'}));

function startServer() {
    const server = app.listen(PORT, '0.0.0.0', () => {
        console.log(`UniSwap API running at http://localhost:${PORT}`);
        console.log('Press Ctrl+C to stop the API.');
    });
    server.on('error', err => {
        if (err.code === 'EADDRINUSE') console.error(`Port ${PORT} is already in use. Stop the other Node server or run: $env:PORT=3001; npm start`);
        else console.error('Unable to start API:', err);
        process.exitCode = 1;
    });
    return server;
}

if(require.main===module)startServer();
module.exports=app;