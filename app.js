// UniSwap API - teacher-style Express + mysql2 callbacks
// Install: npm install express cors mysql2 @node-rs/argon2 jsonwebtoken
// Run: node server.js
// IMPORTANT: Set JWT_KEY in your environment before deployment.
// This is a teaching/demo API baseline. Review payment/order state transitions
// and add production email + file-storage services before real deployment.

const express = require('express');
const cors = require('cors');
const con = require('./db_config');
const argon2 = require('@node-rs/argon2');
const jwt = require('jsonwebtoken');

const app = express();
app.use(cors());
app.use(express.json());

const JWT_KEY = process.env.JWT_KEY || require('node:crypto').randomBytes(48).toString('hex');
const PORT = 3000;

// ---------- Common helpers ----------
function auth(req, res, next) {
    const header = req.headers.authorization;
    if (!header || !header.startsWith('Bearer ')) {
        return res.status(401).json({ success: false, message: 'Token required' });
    }

    const token = header.substring(7);
    jwt.verify(token, JWT_KEY, (err, decoded) => {
        if (err) return res.status(401).json({ success: false, message: 'Invalid or expired token' });

        // The token alone is not enough: a suspended/deleted user, or a changed role,
        // must take effect immediately instead of when the 1-day token expires.
        con.query('SELECT role, status FROM users WHERE user_id = ?', [decoded.user_id], (err, rows) => {
            if (err) return queryError(res, err);
            if (rows.length === 0 || rows[0].status !== 'active') {
                return res.status(403).json({ success: false, message: 'Account is not active' });
            }
            req.user = { ...decoded, role: rows[0].role };
            next();
        });
    });
}

function adminOnly(req, res, next) {
    if (!req.user || req.user.role !== 'admin') {
        return res.status(403).json({ success: false, message: 'Admin only' });
    }
    next();
}

function queryError(res, err) {
    if ([1452,4025,1406,1292,1264].includes(err.errno)) return res.status(400).json({success:false,message:'Invalid data or state'});
    if(err.code==='ER_DUP_ENTRY')return res.status(409).json({success:false,message:'Duplicate record'});
    console.error(err);
    return res.status(500).json({ success: false, message: 'Database error' });
}

function isPositiveId(value) {
    return Number.isInteger(Number(value)) && Number(value) > 0;
}

// ---------- Health ----------
app.get('/api/health', (req, res) => {
    con.query('SELECT 1 AS ok', (err, result) => {
        if (err) return queryError(res, err);
        res.json({ success: true, message: 'API is running', database: result[0].ok });
    });
});

// ---------- Authentication ----------
app.post('/api/register', (req, res) => {
    const { university_id, student_id, email, password, display_name, username, zone_id, location_id } = req.body || {};
    if ((username !== undefined && (!featureText(username,50,true) || username.length<3 || /\s/.test(username))) || (zone_id !== undefined && !featureZone(zone_id)) || (location_id != null && (!featureId(location_id) || !featureZone(zone_id)))) return res.status(400).json({success:false,message:'Invalid username or residence'});

    if (!university_id || !student_id || !email || !password || !display_name) {
        return res.status(400).json({ success: false, message: 'Missing required fields' });
    }
    if (!/^[0-9]{10}$/.test(String(student_id))) {
        return res.status(400).json({ success: false, message: 'student_id must be 10 digits' });
    }
    if (String(password).length < 8) {
        return res.status(400).json({ success: false, message: 'Password must be at least 8 characters' });
    }

    const cleanEmail = String(email).trim().toLowerCase();
    if (cleanEmail.length > 254 || !/^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$/.test(cleanEmail)) {
        return res.status(400).json({ success: false, message: 'Invalid email format' });
    }
    const cleanName = String(display_name).trim();
    if (!cleanName) {
        return res.status(400).json({ success: false, message: 'display_name must not be blank' });
    }
    const hash = argon2.hashSync(String(password));

    const universitySql = 'SELECT university_id FROM universities WHERE university_id = ? AND is_active = 1';
    con.query(universitySql, [university_id], (err, universityResult) => {
        if (err) return queryError(res, err);
        if (universityResult.length === 0) {
            return res.status(400).json({ success: false, message: 'Invalid university_id' });
        }

        const sql = `INSERT INTO users
            (university_id, student_id, email, password_hash, display_name, username, residence_zone_id, residence_location_id, role, status)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'member', 'pending_verification')`;
        con.query(sql, [university_id, student_id, cleanEmail, hash, cleanName, username || null, zone_id || null, location_id || null], (err, result) => {
            if (err) {
                if (err.code === 'ER_DUP_ENTRY') return res.status(409).json({ success: false, message: 'Email or student ID already exists' });
                return queryError(res, err);
            }

            // Demo behavior: account remains pending until email verification is implemented.
            res.status(201).json({
                success: true,
                message: 'Registered. Email verification is required before login.',
                user_id: result.insertId,
                status: 'pending_verification'
            });
        });
    });
});

// Development-only verification endpoint. Replace with emailed one-time token in production.
app.post('/api/dev/verify-user/:user_id', auth, adminOnly, (req, res) => {
    if (!isPositiveId(req.params.user_id)) return res.status(400).json({ success: false, message: 'Invalid user_id' });

    con.query(
        `UPDATE users SET status = 'active', email_verified_at = UTC_TIMESTAMP(3)
         WHERE user_id = ? AND status = 'pending_verification'`,
        [req.params.user_id],
        (err, result) => {
            if (err) return queryError(res, err);
            if (result.affectedRows === 0) return res.status(404).json({ success: false, message: 'Pending user not found' });
            res.json({ success: true, message: 'User verified (development only)' });
        }
    );
});

app.post('/api/login', (req, res) => {
    const { email, password } = req.body;
    if (!email || !password) {
        return res.status(400).json({ success: false, message: 'Email and password are required' });
    }

    const sql = 'SELECT user_id, email, password_hash, display_name, username, residence_zone_id, residence_location_id, role, status, email_verified_at FROM users WHERE email = ?';
    con.query(sql, [String(email).trim().toLowerCase()], (err, result) => {
        if (err) return queryError(res, err);
        if (result.length === 0) return res.status(401).json({ success: false, message: 'Invalid email or password' });

        const user = result[0];
        let samePassword = false;
        try {
            samePassword = argon2.verifySync(user.password_hash, String(password));
        } catch (e) {
            console.error(e);
            return res.status(500).json({ success: false, message: 'Password verification error' });
        }

        if (!samePassword) return res.status(401).json({ success: false, message: 'Invalid email or password' });
        if (user.status !== 'active' || !user.email_verified_at) {
            return res.status(403).json({ success: false, message: 'Account is not active or email is not verified' });
        }

        const payload = { user_id: user.user_id, email: user.email, role: user.role };
        const token = jwt.sign(payload, JWT_KEY, { expiresIn: '1d' });

        res.json({
            success: true,
            message: 'Login successful',
            token,
            user: {
                user_id: user.user_id,
                email: user.email,
                display_name: user.display_name,
                username: user.username, residence_zone_id: user.residence_zone_id, residence_location_id: user.residence_location_id,
                role: user.role
            }
        });
    });
});

// ---------- User profile ----------
app.get('/api/profile', auth, (req, res) => {
    con.query(
        `SELECT user_id, university_id, student_id, email, display_name, avatar_storage_key, username, residence_zone_id, residence_location_id, student_verification_status, role, status, created_at
         FROM users WHERE user_id = ?`,
        [req.user.user_id],
        (err, result) => {
            if (err) return queryError(res, err);
            if (result.length === 0) return res.status(404).json({ success: false, message: 'User not found' });
            res.json({ success: true, data: result[0] });
        }
    );
});

app.put('/api/profile', auth, (req, res) => {
    const { display_name, avatar_storage_key, username } = req.body || {};
    if (username !== undefined && (!featureText(username,50,true) || username.length<3 || /\s/.test(username))) return res.status(400).json({success:false,message:'Invalid username'});
    if (!display_name || !String(display_name).trim()) {
        return res.status(400).json({ success: false, message: 'display_name is required' });
    }

    con.query(
        'UPDATE users SET display_name = ?, avatar_storage_key = ?,username=COALESCE(?,username) WHERE user_id = ? AND status = ?',
        [String(display_name).trim(), avatar_storage_key || null, username || null, req.user.user_id, 'active'],
        (err, result) => {
            if (err) return queryError(res, err);
            if (result.affectedRows === 0) return res.status(404).json({ success: false, message: 'User not found' });
            res.json({ success: true, message: 'Profile updated' });
        }
    );
});

// ---------- Categories ----------
app.get('/api/categories', (req, res) => {
    con.query('SELECT category_id, name, emoji FROM categories WHERE is_active = 1 ORDER BY category_id', (err, result) => {
        if (err) return queryError(res, err);
        res.json({ success: true, data: result });
    });
});

// ---------- Products ----------
app.get('/api/products', (req, res) => {
    const { keyword, category_id, min_price, max_price, sort, university_id, zone_id, location_id } = req.query;
    if ((university_id!==undefined && !featureId(university_id)) || (zone_id!==undefined && !featureZone(zone_id)) || (location_id!==undefined && !featureId(location_id))) return res.status(400).json({success:false,message:'Invalid location filter'});
    let sql = `SELECT p.product_id, p.seller_id, u.display_name AS seller_name,
                      p.category_id, c.name AS category_name, p.title, p.description,
                      p.price, p.item_condition, p.visibility, p.clearance_deadline,
                      p.is_urgent, p.created_at
               FROM products p
               JOIN users u ON p.seller_id = u.user_id
               JOIN categories c ON p.category_id = c.category_id
               WHERE p.visibility = 'active' AND p.review_status='approved' AND u.status='active' AND c.is_active=1 AND NOT EXISTS (SELECT 1 FROM orders o WHERE o.claimed_product_id=p.product_id)`;
    const values = [];
    if(university_id!==undefined){sql+=' AND u.university_id=?';values.push(university_id);}
    if(zone_id!==undefined){sql+=' AND p.zone_id=?';values.push(zone_id);}
    if(location_id!==undefined){sql+=' AND p.location_id=?';values.push(location_id);}

    if (keyword) {
        sql += ' AND (p.title LIKE ? OR p.description LIKE ?)';
        values.push('%' + keyword + '%', '%' + keyword + '%');
    }
    if (category_id) {
        if (!isPositiveId(category_id)) return res.status(400).json({ success: false, message: 'Invalid category_id' });
        sql += ' AND p.category_id = ?';
        values.push(category_id);
    }
    if (min_price !== undefined) {
        if (!Number.isFinite(Number(min_price)) || Number(min_price) < 0) return res.status(400).json({ success: false, message: 'Invalid min_price' });
        sql += ' AND p.price >= ?';
        values.push(Number(min_price));
    }
    if (max_price !== undefined) {
        if (!Number.isFinite(Number(max_price)) || Number(max_price) < 0) return res.status(400).json({ success: false, message: 'Invalid max_price' });
        sql += ' AND p.price <= ?';
        values.push(Number(max_price));
    }

    if (sort === 'price_asc') sql += ' ORDER BY p.price ASC';
    else if (sort === 'price_desc') sql += ' ORDER BY p.price DESC';
    else if (sort === 'urgent') sql += ' ORDER BY p.is_urgent DESC, p.created_at DESC';
    else sql += ' ORDER BY p.created_at DESC';

    con.query(sql, values, (err, result) => {
        if (err) return queryError(res, err);
        res.json({ success: true, count: result.length, data: result });
    });
});

app.get('/api/products/:product_id', (req, res) => {
    if (!isPositiveId(req.params.product_id)) return res.status(400).json({ success: false, message: 'Invalid product_id' });

    const sql = `SELECT p.*, u.display_name AS seller_name, c.name AS category_name
                 FROM products p
                 JOIN users u ON p.seller_id = u.user_id
                 JOIN categories c ON p.category_id = c.category_id
                 WHERE p.product_id = ? AND p.visibility = 'active' AND p.review_status='approved'`;
    con.query(sql, [req.params.product_id], (err, result) => {
        if (err) return queryError(res, err);
        if (result.length === 0) return res.status(404).json({ success: false, message: 'Product not found' });

        con.query('SELECT image_id, storage_key, sort_order FROM product_images WHERE product_id = ? ORDER BY sort_order', [req.params.product_id], (err, images) => {
            if (err) return queryError(res, err);
            con.query('UPDATE products SET view_count=view_count+1 WHERE product_id=?',[req.params.product_id],err=>{
                if(err)return queryError(res,err);
                result[0].view_count=Number(result[0].view_count)+1;
                res.json({ success: true, data: result[0], images });
            });
        });
    });
});

app.post('/api/products', auth, (req, res) => {
    const { category_id, title, description, price, item_condition, clearance_deadline, is_urgent, zone_id, location_id } = req.body || {};
    const allowed = ['new', 'like_new', 'good', 'fair', 'unspecified'];

    if (!category_id || !title || price === undefined) {
        return res.status(400).json({ success: false, message: 'Missing required fields' });
    }
    if (!isPositiveId(category_id) || Number(price) < 0 || !Number.isFinite(Number(price)) || !allowed.includes(item_condition || 'unspecified')) {
        return res.status(400).json({ success: false, message: 'Invalid category, price or item_condition' });
    }

    if (!featureText(title,200,true) || !featureText(description,65535) || !/^\d+(\.\d{1,2})?$/.test(String(price)) || Number(price)>9999999999.99) return res.status(400).json({success:false,message:'Invalid title, description or amount'});
    const cleanTitle = String(title).trim();
    if (!cleanTitle) {
        return res.status(400).json({ success: false, message: 'title must not be blank' });
    }

    const sql = `INSERT INTO products
        (seller_id, category_id, title, description, price, item_condition, clearance_deadline, is_urgent,zone_id,location_id)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`;
    const save=(zone,location)=>con.query(sql, [
        req.user.user_id, category_id, cleanTitle, description || null,
        Number(price), item_condition || 'unspecified', clearance_deadline || null, (clearance_deadline || is_urgent === true) ? 1 : 0,zone,location
    ], (err, result) => {
        if (err) {
            if (err.code === 'ER_NO_REFERENCED_ROW_2') return res.status(400).json({ success: false, message: 'Category not found' });
            return queryError(res, err);
        }
        res.status(201).json({ success: true, message: 'Product created', product_id: result.insertId });
    });
    if ((zone_id!==undefined && !featureZone(zone_id)) || (location_id!=null && !featureId(location_id))) return res.status(400).json({success:false,message:'Invalid product location'});
    con.query('SELECT university_id,residence_zone_id,residence_location_id FROM users WHERE user_id=?',[req.user.user_id],(err,owners)=>{
        if(err)return queryError(res,err);
        const owner=owners[0],zone=zone_id===undefined?owner.residence_zone_id:zone_id;
        const location=location_id===undefined?(zone_id===undefined?owner.residence_location_id:null):location_id;
        if(!location)return save(zone,null);
        con.query('SELECT location_id FROM locations WHERE location_id=? AND zone_id=? AND university_id=? AND is_active=1',[location,zone,owner.university_id],(err,rows)=>{
            if(err)return queryError(res,err);
            if(!rows.length)return res.status(400).json({success:false,message:'Location must match university and zone'});
            save(zone,location);
        });
    });
});

app.put('/api/products/:product_id', auth, (req, res) => {
    const { category_id, title, description, price, item_condition, visibility, clearance_deadline, is_urgent } = req.body;
    const allowedCondition = ['new', 'like_new', 'good', 'fair', 'unspecified'];
    const allowedVisibility = ['active', 'hidden', 'removed'];

    if (!isPositiveId(req.params.product_id)) return res.status(400).json({ success: false, message: 'Invalid product_id' });
    if (!isPositiveId(category_id) || !title || price === undefined || !allowedCondition.includes(item_condition || 'unspecified') || !allowedVisibility.includes(visibility)) {
        return res.status(400).json({ success: false, message: 'Invalid or missing product fields' });
    }
    if (Number(price) < 0 || !Number.isFinite(Number(price))) return res.status(400).json({ success: false, message: 'Price must be zero or greater' });
    if (!featureText(title,200,true) || !featureText(description,65535) || !/^\d+(\.\d{1,2})?$/.test(String(price)) || Number(price)>9999999999.99) return res.status(400).json({success:false,message:'Invalid title, description or amount'});
    const cleanTitle = String(title).trim();
    if (!cleanTitle) return res.status(400).json({ success: false, message: 'title must not be blank' });

    const sql = `UPDATE products SET category_id=?, title=?, description=?, price=?,
                 item_condition=?, visibility=?, clearance_deadline=?, is_urgent=?, review_status=CASE WHEN review_status='approved' THEN 'pending_review' ELSE review_status END
                 WHERE product_id=? AND seller_id=? AND NOT EXISTS (SELECT 1 FROM orders o WHERE o.claimed_product_id=products.product_id)`;
    con.query(sql, [
        category_id, cleanTitle, description || null, Number(price), item_condition || 'unspecified',
        visibility, clearance_deadline || null, (clearance_deadline || is_urgent===true) ? 1 : 0,
        req.params.product_id, req.user.user_id
    ], (err, result) => {
        if (err) {
            if (err.code === 'ER_NO_REFERENCED_ROW_2') return res.status(400).json({ success: false, message: 'Category not found' });
            return queryError(res, err);
        }
        if (result.affectedRows === 0) return res.status(404).json({ success: false, message: 'Product not found or not owned by you' });
        res.json({ success: true, message: 'Product updated' });
    });
});

app.delete('/api/products/:product_id', auth, (req, res) => {
    if (!isPositiveId(req.params.product_id)) return res.status(400).json({ success: false, message: 'Invalid product_id' });
    con.query(
        `UPDATE products SET visibility = 'removed' WHERE product_id = ? AND seller_id = ?`,
        [req.params.product_id, req.user.user_id],
        (err, result) => {
            if (err) return queryError(res, err);
            if (result.affectedRows === 0) return res.status(404).json({ success: false, message: 'Product not found or not owned by you' });
            res.json({ success: true, message: 'Product removed' });
        }
    );
});

// Product images store storage keys only; actual upload/storage is a separate implementation.
app.post('/api/products/:product_id/images', auth, (req, res) => {
    const { storage_key, sort_order } = req.body;
    if (!storage_key) return res.status(400).json({ success: false, message: 'storage_key is required' });

    const hasOrder = sort_order !== undefined && sort_order !== null && sort_order !== '';
    if (hasOrder && (!Number.isInteger(Number(sort_order)) || Number(sort_order) < 0 || Number(sort_order) > 65535)) {
        return res.status(400).json({ success: false, message: 'sort_order must be an integer between 0 and 65535' });
    }

    con.query('SELECT product_id FROM products WHERE product_id = ? AND seller_id = ?', [req.params.product_id, req.user.user_id], (err, rows) => {
        if (err) return queryError(res, err);
        if (rows.length === 0) return res.status(404).json({ success: false, message: 'Product not found or not owned by you' });

        // product_images has UNIQUE (product_id, sort_order), so when the client sends no
        // sort_order, append after the current last image instead of always using 0.
        con.query('SELECT COALESCE(MAX(sort_order) + 1, 0) AS next_order FROM product_images WHERE product_id = ?', [req.params.product_id], (err, next) => {
            if (err) return queryError(res, err);
            const order = hasOrder ? Number(sort_order) : Number(next[0].next_order);

            con.query(
                'INSERT INTO product_images (product_id, storage_key, sort_order) VALUES (?, ?, ?)',
                [req.params.product_id, storage_key, order],
                (err, result) => {
                    if (err) {
                        if (err.code === 'ER_DUP_ENTRY') return res.status(409).json({ success: false, message: 'sort_order already used for this product' });
                        return queryError(res, err);
                    }
                    res.status(201).json({ success: true, image_id: result.insertId });
                }
            );
        });
    });
});

app.delete('/api/product-images/:image_id', auth, (req, res) => {
    const sql = `DELETE pi FROM product_images pi
                 JOIN products p ON pi.product_id = p.product_id
                 WHERE pi.image_id = ? AND p.seller_id = ?`;
    con.query(sql, [req.params.image_id, req.user.user_id], (err, result) => {
        if (err) return queryError(res, err);
        if (result.affectedRows === 0) return res.status(404).json({ success: false, message: 'Image not found or not owned by you' });
        res.json({ success: true, message: 'Image deleted' });
    });
});

// ---------- Conversations and messages ----------
app.post('/api/conversations', auth, (req, res) => {
    const { product_id } = req.body;
    if (!isPositiveId(product_id)) return res.status(400).json({ success: false, message: 'Valid product_id is required' });

    con.query(`SELECT product_id, seller_id FROM products WHERE product_id = ? AND visibility = 'active'`, [product_id], (err, products) => {
        if (err) return queryError(res, err);
        if (products.length === 0) return res.status(404).json({ success: false, message: 'Product not found' });
        if (Number(products[0].seller_id) === Number(req.user.user_id)) return res.status(400).json({ success: false, message: 'Seller cannot start a buyer conversation with own product' });

        con.query(
            'INSERT INTO conversations (product_id, buyer_id) VALUES (?, ?) ON DUPLICATE KEY UPDATE conversation_id = LAST_INSERT_ID(conversation_id)',
            [product_id, req.user.user_id],
            (err, result) => {
                if (err) return queryError(res, err);
                res.status(201).json({ success: true, conversation_id: result.insertId });
            }
        );
    });
});

app.get('/api/conversations', auth, (req, res) => {
    const sql = `SELECT DISTINCT c.conversation_id, c.product_id, c.buyer_id, p.title
                 FROM conversations c
                 JOIN products p ON c.product_id = p.product_id
                 LEFT JOIN messages m ON m.conversation_id = c.conversation_id
                 WHERE c.buyer_id = ? OR p.seller_id = ?
                 ORDER BY c.created_at DESC`;
    con.query(sql, [req.user.user_id, req.user.user_id], (err, result) => {
        if (err) return queryError(res, err);
        res.json({ success: true, data: result });
    });
});

app.get('/api/conversations/:conversation_id/messages', auth, (req, res) => {
    const accessSql = `SELECT c.conversation_id FROM conversations c
                       JOIN products p ON c.product_id = p.product_id
                       WHERE c.conversation_id = ? AND (c.buyer_id = ? OR p.seller_id = ?)`;
    con.query(accessSql, [req.params.conversation_id, req.user.user_id, req.user.user_id], (err, access) => {
        if (err) return queryError(res, err);
        if (access.length === 0) return res.status(403).json({ success: false, message: 'Conversation access denied' });

        const sql = `SELECT message_id, conversation_id, sender_id, body, read_at, created_at
                     FROM messages WHERE conversation_id = ? AND deleted_at IS NULL
                     ORDER BY created_at, message_id`;
        con.query(sql, [req.params.conversation_id], (err, result) => {
            if (err) return queryError(res, err);
            res.json({ success: true, data: result });
        });
    });
});

app.post('/api/conversations/:conversation_id/messages', auth, (req, res) => {
    const { body } = req.body;
    if (!body || !String(body).trim()) return res.status(400).json({ success: false, message: 'Message body is required' });

    const accessSql = `SELECT c.conversation_id FROM conversations c
                       JOIN products p ON c.product_id = p.product_id
                       WHERE c.conversation_id = ? AND (c.buyer_id = ? OR p.seller_id = ?)`;
    con.query(accessSql, [req.params.conversation_id, req.user.user_id, req.user.user_id], (err, access) => {
        if (err) return queryError(res, err);
        if (access.length === 0) return res.status(403).json({ success: false, message: 'Conversation access denied' });

        con.query(
            'INSERT INTO messages (conversation_id, sender_id, body) VALUES (?, ?, ?)',
            [req.params.conversation_id, req.user.user_id, String(body).trim()],
            (err, result) => {
                if (err) return queryError(res, err);
                res.status(201).json({ success: true, message_id: result.insertId });
            }
        );
    });
});

// ---------- Orders: request first, seller accepts before payment ----------
app.post('/api/orders', auth, (req, res) => {
    const { product_id } = req.body || {};
    if (!featureId(product_id)) return res.status(400).json({success:false,message:'Valid product_id required'});
    featureTransaction(res,(conn,abort,commit)=>{
        conn.query(`SELECT p.*,u.university_id FROM products p JOIN users u ON u.user_id=p.seller_id
                    WHERE p.product_id=? AND p.visibility='active' AND p.review_status='approved' AND u.status='active' FOR UPDATE`,[product_id],(err,rows)=>{
            if(err)return abort(500,null,err);
            if(!rows.length)return abort(404,'Product not available');
            const product=rows[0];
            if(Number(product.seller_id)===Number(req.user.user_id))return abort(400,'Cannot buy your own product');
            conn.query('SELECT university_id FROM users WHERE user_id=?',[req.user.user_id],(err,buyers)=>{
                if(err)return abort(500,null,err);
                if(!buyers.length||Number(buyers[0].university_id)!==Number(product.university_id))return abort(403,'University mismatch');
                conn.query(`INSERT INTO orders (product_id,buyer_id,product_title_snapshot,total_amount,status) VALUES (?,?,?,?,'requested')`,
                    [product_id,req.user.user_id,product.title,product.price],(err,result)=>{
                        if(err)return abort(500,null,err);
                        conn.query("INSERT INTO order_status_history (order_id,actor_id,to_status,reason) VALUES (?,?,'requested','Buyer request')",[result.insertId,req.user.user_id],err=>{
                            if(err)return abort(500,null,err);
                            commit(201,{success:true,order_id:result.insertId,status:'requested'});
                        });
                    });
            });
        });
    });
});

app.post('/api/orders/:order_id/accept',auth,(req,res)=>{
    if(!featureId(req.params.order_id))return res.status(400).json({success:false,message:'Invalid order ID'});
    featureTransaction(res,(conn,abort,commit)=>{
        conn.query(`SELECT o.* FROM orders o JOIN products p ON p.product_id=o.product_id WHERE o.order_id=? AND p.seller_id=? FOR UPDATE`,[req.params.order_id,req.user.user_id],(err,rows)=>{
            if(err)return abort(500,null,err);
            if(!rows.length)return abort(404,'Order not found');
            const order=rows[0];if(order.status!=='requested')return abort(409,'Order is not requested');
            const free=Number(order.total_amount)===0;
            const finish=(bank)=>{
                const status=free?'ready_for_meetup':'awaiting_payment';
                conn.query(`UPDATE orders SET status=?,seller_accepted_at=UTC_TIMESTAMP(3),payment_started_at=${free?'NULL':'UTC_TIMESTAMP(3)'},
                    payment_due_at=${free?'NULL':'DATE_ADD(UTC_TIMESTAMP(3),INTERVAL 30 MINUTE)'},platform_bank_account_id=?,
                    receiving_bank_name_snapshot=?,receiving_bank_number_snapshot=?,receiving_bank_holder_snapshot=? WHERE order_id=?`,
                    [status,bank?.platform_bank_account_id||null,bank?.bank_name||null,bank?.account_number||null,bank?.account_holder_name||null,order.order_id],err=>{
                        if(err)return abort(500,null,err);
                        conn.query("INSERT INTO order_status_history (order_id,actor_id,from_status,to_status) VALUES (?,?,'requested',?)",[order.order_id,req.user.user_id,status],err=>{
                            if(err)return abort(500,null,err);commit(200,{success:true,status});
                        });
                    });
            };
            if(free)return finish(null);
            const bankId=(req.body||{}).platform_bank_account_id;
            if(!featureId(bankId))return abort(400,'Valid platform_bank_account_id required');
            conn.query('SELECT * FROM platform_bank_accounts WHERE platform_bank_account_id=? AND is_active=1 LOCK IN SHARE MODE',[bankId],(err,banks)=>{
                if(err)return abort(500,null,err);if(!banks.length)return abort(400,'Platform bank inactive or missing');finish(banks[0]);
            });
        });
    });
});

app.post('/api/orders/:order_id/received',auth,(req,res)=>{
    if(!featureId(req.params.order_id))return res.status(400).json({success:false,message:'Invalid order ID'});
    featureTransaction(res,(conn,abort,commit)=>{
        conn.query('SELECT * FROM orders WHERE order_id=? AND buyer_id=? FOR UPDATE',[req.params.order_id,req.user.user_id],(err,rows)=>{
            if(err)return abort(500,null,err);if(!rows.length)return abort(404,'Order not found');
            const order=rows[0];if(!['payment_held','ready_for_meetup'].includes(order.status))return abort(409,'Order not ready for receipt');
            const finish=()=>conn.query("UPDATE orders SET status='completed',buyer_received_at=UTC_TIMESTAMP(3) WHERE order_id=?",[order.order_id],err=>{
                if(err)return abort(500,null,err);
                conn.query("INSERT INTO order_status_history (order_id,actor_id,from_status,to_status) VALUES (?,?,?,'completed')",[order.order_id,req.user.user_id,order.status],err=>{
                    if(err)return abort(500,null,err);commit(200,{success:true,status:'completed'});
                });
            });
            if(Number(order.total_amount)===0)return finish();
            conn.query("SELECT payment_id FROM payments WHERE order_id=? AND purpose='order_payment' AND status='held' FOR UPDATE",[order.order_id],(err,payments)=>{
                if(err)return abort(500,null,err);if(!payments.length)return abort(409,'Verified held payment required');finish();
            });
        });
    });
});

app.get('/api/orders', auth, (req, res) => {
    const sql = `SELECT order_id, product_id, product_title_snapshot, total_amount, status,
                        payment_due_at, buyer_received_at, created_at
                 FROM orders WHERE buyer_id = ? ORDER BY created_at DESC`;
    con.query(sql, [req.user.user_id], (err, result) => {
        if (err) return queryError(res, err);
        res.json({ success: true, data: result });
    });
});

app.get('/api/orders/:order_id', auth, (req, res) => {
    const sql = `SELECT o.* FROM orders o
                 JOIN products p ON o.product_id = p.product_id
                 WHERE o.order_id = ? AND (o.buyer_id = ? OR p.seller_id = ?)`;
    con.query(sql, [req.params.order_id, req.user.user_id, req.user.user_id], (err, result) => {
        if (err) return queryError(res, err);
        if (result.length === 0) return res.status(404).json({ success: false, message: 'Order not found' });
        res.json({ success: true, data: result[0] });
    });
});

app.post('/api/orders/:order_id/cancel', auth, (req, res) => {
    con.getConnection((err, conn) => {
        if (err) return queryError(res, err);

        const finish = (send) => { conn.release(); send(); };
        const abort = (send) => conn.rollback(() => finish(send));

        conn.beginTransaction((err) => {
            if (err) return finish(() => queryError(res, err));
            conn.query(
                `SELECT order_id, status FROM orders WHERE order_id = ? AND buyer_id = ? FOR UPDATE`,
                [req.params.order_id, req.user.user_id],
                (err, rows) => {
                    if (err) return abort(() => queryError(res, err));
                    if (rows.length === 0) return abort(() => res.status(404).json({ success: false, message: 'Order not found' }));
                    if (!['requested', 'awaiting_payment'].includes(rows[0].status)) {
                        return abort(() => res.status(409).json({ success: false, message: 'Order cannot be cancelled in current status' }));
                    }

                    conn.query(
                        `UPDATE orders SET status='cancelled', closed_at=UTC_TIMESTAMP(3), close_reason='Cancelled by buyer'
                         WHERE order_id = ?`,
                        [req.params.order_id],
                        (err) => {
                            if (err) return abort(() => queryError(res, err));
                            conn.query(
                                `INSERT INTO order_status_history (order_id, actor_id, from_status, to_status, reason)
                                 VALUES (?, ?, ?, 'cancelled', 'Cancelled by buyer')`,
                                [req.params.order_id, req.user.user_id, rows[0].status],
                                (err) => {
                                    if (err) return abort(() => queryError(res, err));
                                    conn.commit((err) => {
                                        if (err) return abort(() => queryError(res, err));
                                        finish(() => res.json({ success: true, message: 'Order cancelled' }));
                                    });
                                }
                            );
                        }
                    );
                }
            );
        });
    });
});

// ---------- Meetups ----------
app.post('/api/orders/:order_id/meetup', auth, (req, res) => {
    const { place_name, place_details, scheduled_at } = req.body;
    if (!place_name || !scheduled_at || isNaN(Date.parse(scheduled_at))) {
        return res.status(400).json({ success: false, message: 'place_name and valid scheduled_at are required' });
    }

    const accessSql = `SELECT o.order_id, p.seller_id, o.buyer_id
                       FROM orders o JOIN products p ON o.product_id = p.product_id
                       WHERE o.order_id = ? AND (o.buyer_id = ? OR p.seller_id = ?)
                         AND o.status IN ('requested','awaiting_payment','payment_held','ready_for_meetup')`;
    con.query(accessSql, [req.params.order_id, req.user.user_id, req.user.user_id], (err, rows) => {
        if (err) return queryError(res, err);
        if (rows.length === 0) return res.status(403).json({ success: false, message: 'Order not accessible or not ready for meetup' });

        con.query(
            `INSERT INTO meetups (order_id, proposed_by, place_name, place_details, scheduled_at)
             VALUES (?, ?, ?, ?, ?)`,
            [req.params.order_id, req.user.user_id, place_name, place_details || null, new Date(scheduled_at).toISOString().slice(0,23).replace('T',' ')],
            (err, result) => {
                if (err) {
                    if (err.code === 'ER_DUP_ENTRY') return res.status(409).json({ success: false, message: 'Meetup already exists for this order' });
                    return queryError(res, err);
                }
                res.status(201).json({ success: true, meetup_id: result.insertId, status: 'proposed' });
            }
        );
    });
});

app.put('/api/meetups/:meetup_id/confirm', auth, (req, res) => {
    const sql = `UPDATE meetups m
                 JOIN orders o ON m.order_id = o.order_id
                 JOIN products p ON o.product_id = p.product_id
                 SET m.status='confirmed', m.seller_confirmed_at=UTC_TIMESTAMP(3)
                 WHERE m.meetup_id = ? AND p.seller_id = ? AND m.status='proposed' AND o.status IN ('requested','awaiting_payment','payment_held','ready_for_meetup')`;
    con.query(sql, [req.params.meetup_id, req.user.user_id], (err, result) => {
        if (err) return queryError(res, err);
        if (result.affectedRows === 0) return res.status(404).json({ success: false, message: 'Meetup not found, not yours to confirm, or not proposed' });
        res.json({ success: true, message: 'Meetup confirmed' });
    });
});

// ---------- Reviews ----------
app.post('/api/reviews', auth, (req, res) => {
    const { order_id, rating, comment } = req.body;
    if (!isPositiveId(order_id) || !Number.isInteger(Number(rating)) || Number(rating) < 1 || Number(rating) > 5) {
        return res.status(400).json({ success: false, message: 'Valid order_id and rating 1-5 are required' });
    }

    con.query(
        `SELECT order_id FROM orders WHERE order_id = ? AND buyer_id = ? AND status = 'completed'`,
        [order_id, req.user.user_id],
        (err, rows) => {
            if (err) return queryError(res, err);
            if (rows.length === 0) return res.status(403).json({ success: false, message: 'Only buyer of completed order can review' });

            con.query(
                'INSERT INTO reviews (order_id, rating, comment) VALUES (?, ?, ?)',
                [order_id, Number(rating), comment || null],
                (err, result) => {
                    if (err) {
                        if (err.code === 'ER_DUP_ENTRY') return res.status(409).json({ success: false, message: 'Review already exists for this order' });
                        return queryError(res, err);
                    }
                    res.status(201).json({ success: true, review_id: result.insertId });
                }
            );
        }
    );
});

app.get('/api/products/:product_id/reviews', (req, res) => {
    const sql = `SELECT r.review_id, r.order_id, r.rating, r.comment, r.created_at,
                        o.buyer_id
                 FROM reviews r JOIN orders o ON r.order_id = o.order_id
                 WHERE o.product_id = ? AND r.visibility = 'visible'
                 ORDER BY r.created_at DESC`;
    con.query(sql, [req.params.product_id], (err, result) => {
        if (err) return queryError(res, err);
        res.json({ success: true, data: result });
    });
});

// ---------- Reports ----------
app.post('/api/reports', auth, (req, res) => {
    const { reported_user_id, reported_product_id, reported_message_id, reported_review_id, reason } = req.body;
    const targets = [reported_user_id, reported_product_id, reported_message_id, reported_review_id].filter(v => v !== undefined && v !== null && v !== '');
    if (targets.length !== 1 || !reason || !String(reason).trim()) {
        return res.status(400).json({ success: false, message: 'Provide exactly one report target and a reason' });
    }
    if (!isPositiveId(targets[0])) {
        return res.status(400).json({ success: false, message: 'Report target id must be a positive integer' });
    }

    const sql = `INSERT INTO reports
        (reporter_id, reported_user_id, reported_product_id, reported_message_id, reported_review_id, reason)
        VALUES (?, ?, ?, ?, ?, ?)`;
    con.query(sql, [
        req.user.user_id,
        reported_user_id || null,
        reported_product_id || null,
        reported_message_id || null,
        reported_review_id || null,
        String(reason).trim()
    ], (err, result) => {
        if (err) {
            if (err.code === 'ER_NO_REFERENCED_ROW_2') return res.status(400).json({ success: false, message: 'Report target does not exist' });
            return queryError(res, err);
        }
        res.status(201).json({ success: true, report_id: result.insertId, status: 'open' });
    });
});

app.get('/api/admin/reports', auth, adminOnly, (req, res) => {
    con.query('SELECT * FROM reports ORDER BY created_at DESC', (err, result) => {
        if (err) return queryError(res, err);
        res.json({ success: true, data: result });
    });
});

app.put('/api/admin/reports/:report_id', auth, adminOnly, (req, res) => {
    const { status, resolution_note } = req.body;
    const allowed = ['reviewing', 'resolved', 'dismissed'];
    if (!allowed.includes(status)) return res.status(400).json({ success: false, message: 'Invalid report status' });

    const sql = `UPDATE reports SET status = ?,
                 resolved_by = CASE WHEN ? IN ('resolved','dismissed') THEN ? ELSE NULL END,
                 resolved_at = CASE WHEN ? IN ('resolved','dismissed') THEN UTC_TIMESTAMP(3) ELSE NULL END,
                 resolution_note = ?
                 WHERE report_id = ?`;
    con.query(sql, [status, status, req.user.user_id, status, resolution_note || null, req.params.report_id], (err, result) => {
        if (err) return queryError(res, err);
        if (result.affectedRows === 0) return res.status(404).json({ success: false, message: 'Report not found' });
        res.json({ success: true, message: 'Report updated' });
    });
});

// ---------- Helpers used only by the additional routes ----------
function featureId(value) {
    return ['string', 'number'].includes(typeof value)
        && /^[1-9][0-9]*$/.test(String(value))
        && Number.isSafeInteger(Number(value));
}

function featureZone(value) {
    return featureId(value) && [1, 2].includes(Number(value));
}

function featureText(value, maxLength, required = false) {
    if (value === undefined || value === null) return !required;
    return typeof value === 'string'
        && Array.from(value.trim()).length <= maxLength
        && (!required || value.trim().length > 0);
}

function featureOptionalText(value) {
    return value === undefined || value === null ? null : value.trim() || null;
}

function featurePage(req, res) {
    const page = req.query.page === undefined ? 1 : req.query.page;
    const limit = req.query.limit === undefined ? 20 : req.query.limit;
    const offset = (Number(page) - 1) * Number(limit);
    if (!featureId(page) || !featureId(limit) || Number(limit) > 100 || !Number.isSafeInteger(offset)) {
        res.status(400).json({ success: false, message: 'Invalid page or limit (maximum 100)' });
        return null;
    }
    return { page: Number(page), limit: Number(limit), offset };
}

function featurePageResponse(res, rows, paging) {
    const hasMore = rows.length > paging.limit;
    const data = rows.slice(0, paging.limit);
    return res.json({ success: true, page: paging.page, limit: paging.limit,
        count: data.length, has_more: hasMore, data });
}

function featureDbError(res, err) {
    if (err.code === 'ER_DUP_ENTRY') {
        return res.status(409).json({ success: false, message: 'Record already exists or state changed. Refresh and retry.' });
    }
    if (err.errno === 1452 || err.errno === 4025 || err.errno === 1406) {
        return res.status(400).json({ success: false, message: 'Invalid reference or field value' });
    }
    if ([1205, 1213].includes(err.errno)) {
        return res.status(409).json({ success: false, message: 'Concurrent change. Refresh and retry.' });
    }
    return queryError(res, err);
}

// Each transaction owns a connection; respond only after commit/rollback + release.
function featureTransaction(res, work) {
    con.getConnection((err, conn) => {
        if (err) return featureDbError(res, err);
        conn.beginTransaction(err => {
            if (err) { conn.release(); return featureDbError(res, err); }
            const abort = (status, message, error) => conn.rollback(() => {
                conn.release();
                if (error) return featureDbError(res, error);
                return res.status(status).json({ success: false, message });
            });
            const commit = (status, payload) => conn.commit(err => {
                if (err) return abort(500, null, err);
                conn.release();
                return res.status(status).json(payload);
            });
            try { work(conn, abort, commit); }
            catch (error) { abort(500, null, error); }
        });
    });
}

app.get('/api/location-zones', (req, res) => {
    con.query('SELECT zone_id, code, name FROM location_zones ORDER BY zone_id', (err, rows) => {
        if (err) return featureDbError(res, err);
        res.json({ success: true, data: rows });
    });
});

app.get('/api/locations', (req, res) => {
    const { university_id, zone_id, keyword } = req.query;
    if (!featureId(university_id) || (zone_id !== undefined && !featureZone(zone_id))
        || !featureText(keyword, 200)) {
        return res.status(400).json({ success: false, message: 'Valid university_id, zone_id (1/2) and keyword required' });
    }
    const paging = featurePage(req, res);
    if (!paging) return;
    let sql = `SELECT l.location_id, l.university_id, l.zone_id, z.name AS zone_name,
                      l.name, l.address FROM locations l
               JOIN location_zones z ON z.zone_id=l.zone_id
               JOIN universities u ON u.university_id=l.university_id
               WHERE l.university_id=? AND l.is_active=1 AND u.is_active=1`;
    const values = [university_id];
    if (zone_id !== undefined) { sql += ' AND l.zone_id=?'; values.push(zone_id); }
    if (keyword) { sql += ' AND l.name LIKE ?'; values.push('%' + keyword.trim() + '%'); }
    sql += ' ORDER BY l.name,l.location_id LIMIT ? OFFSET ?';
    values.push(paging.limit + 1, paging.offset);
    con.query(sql, values, (err, rows) => {
        if (err) return featureDbError(res, err);
        featurePageResponse(res, rows, paging);
    });
});

app.get('/api/profile/residence', auth, (req, res) => {
    const sql = `SELECT u.university_id, u.residence_zone_id, z.name AS zone_name,
                        u.residence_location_id, l.name AS location_name, l.is_active AS location_is_active,
                        r.request_id AS pending_request_id, r.location_name AS requested_location_name,
                        r.status AS request_status
                 FROM users u LEFT JOIN location_zones z ON z.zone_id=u.residence_zone_id
                 LEFT JOIN locations l ON l.location_id=u.residence_location_id
                 LEFT JOIN location_requests r ON r.pending_requester_id=u.user_id
                 WHERE u.user_id=?`;
    con.query(sql, [req.user.user_id], (err, rows) => {
        if (err) return featureDbError(res, err);
        if (!rows.length) return res.status(404).json({ success: false, message: 'User not found' });
        res.json({ success: true, data: rows[0] });
    });
});

// location_id may be null for zone-only selection. Pending requests must resolve first.
app.put('/api/profile/residence', auth, (req, res) => {
    const { zone_id, location_id } = req.body || {};
    if (!featureZone(zone_id) || (location_id !== undefined && location_id !== null && !featureId(location_id))) {
        return res.status(400).json({ success: false, message: 'zone_id must be 1/2; location_id must be a positive ID or null' });
    }
    featureTransaction(res, (conn, abort, commit) => {
        conn.query('SELECT university_id FROM users WHERE user_id=? FOR UPDATE', [req.user.user_id], (err, users) => {
            if (err) return abort(500, null, err);
            if (!users.length) return abort(404, 'User not found');
            conn.query('SELECT request_id FROM location_requests WHERE pending_requester_id=? FOR UPDATE', [req.user.user_id], (err, pending) => {
                if (err) return abort(500, null, err);
                if (pending.length) return abort(409, 'A residence request is still under review');
                const save = () => conn.query(
                    'UPDATE users SET residence_zone_id=?,residence_location_id=? WHERE user_id=?',
                    [zone_id, location_id || null, req.user.user_id], err => {
                        if (err) return abort(500, null, err);
                        commit(200, { success: true, message: 'Residence updated' });
                    });
                if (location_id === undefined || location_id === null) return save();
                conn.query('SELECT location_id FROM locations WHERE location_id=? AND zone_id=? AND university_id=? AND is_active=1 LOCK IN SHARE MODE',
                    [location_id, zone_id, users[0].university_id], (err, locations) => {
                        if (err) return abort(500, null, err);
                        if (!locations.length) return abort(400, 'Dormitory is inactive or does not match your university and zone');
                        save();
                    });
            });
        });
    });
});

app.post('/api/location-requests', auth, (req, res) => {
    const { zone_id, location_name, address, reason } = req.body || {};
    if (!featureZone(zone_id) || !featureText(location_name, 200, true)
        || !featureText(address, 500) || !featureText(reason, 1000)) {
        return res.status(400).json({ success: false, message: 'Invalid zone, location_name, address or reason' });
    }
    featureTransaction(res, (conn, abort, commit) => {
        conn.query('SELECT university_id FROM users WHERE user_id=? FOR UPDATE', [req.user.user_id], (err, users) => {
            if (err) return abort(500, null, err);
            if (!users.length) return abort(404, 'User not found');
            conn.query('SELECT location_id FROM locations WHERE university_id=? AND zone_id=? AND name=?',
                [users[0].university_id, zone_id, location_name.trim()], (err, existing) => {
                    if (err) return abort(500, null, err);
                    if (existing.length) return abort(409, 'Dormitory already exists; select it or ask Admin to reactivate it');
                    conn.query('INSERT INTO location_requests (requested_by,zone_id,location_name,address,reason) VALUES (?,?,?,?,?)',
                        [req.user.user_id, zone_id, location_name.trim(), featureOptionalText(address), featureOptionalText(reason)], (err, result) => {
                            if (err) return abort(500, null, err);
                            conn.query('UPDATE users SET residence_zone_id=?,residence_location_id=NULL WHERE user_id=?',
                                [zone_id, req.user.user_id], err => {
                                    if (err) return abort(500, null, err);
                                    commit(201, { success: true, request_id: result.insertId, status: 'pending' });
                                });
                        });
                });
        });
    });
});

app.get('/api/location-requests/my', auth, (req, res) => {
    const paging = featurePage(req, res);
    if (!paging) return;
    con.query(`SELECT r.request_id,r.zone_id,z.name AS zone_name,r.location_name,r.address,r.reason,
                      r.status,r.resolved_location_id,l.name AS resolved_location_name,r.review_note,r.reviewed_at,r.created_at
               FROM location_requests r JOIN location_zones z ON z.zone_id=r.zone_id
               LEFT JOIN locations l ON l.location_id=r.resolved_location_id
               WHERE r.requested_by=? ORDER BY r.created_at DESC,r.request_id DESC LIMIT ? OFFSET ?`,
        [req.user.user_id, paging.limit + 1, paging.offset], (err, rows) => {
            if (err) return featureDbError(res, err);
            featurePageResponse(res, rows, paging);
        });
});

app.get('/api/admin/locations', auth, adminOnly, (req, res) => {
    const { university_id, zone_id, is_active } = req.query;
    if ((university_id !== undefined && !featureId(university_id))
        || (zone_id !== undefined && !featureZone(zone_id))
        || (is_active !== undefined && !['0', '1'].includes(is_active))) {
        return res.status(400).json({ success: false, message: 'Invalid university, zone or is_active filter' });
    }
    const paging = featurePage(req, res);
    if (!paging) return;
    let sql = `SELECT l.*,u.name AS university_name,z.name AS zone_name FROM locations l
               JOIN universities u ON u.university_id=l.university_id
               JOIN location_zones z ON z.zone_id=l.zone_id WHERE 1=1`;
    const values = [];
    if (university_id !== undefined) { sql += ' AND l.university_id=?'; values.push(university_id); }
    if (zone_id !== undefined) { sql += ' AND l.zone_id=?'; values.push(zone_id); }
    if (is_active !== undefined) { sql += ' AND l.is_active=?'; values.push(is_active); }
    sql += ' ORDER BY l.university_id,l.zone_id,l.name,l.location_id LIMIT ? OFFSET ?';
    values.push(paging.limit + 1, paging.offset);
    con.query(sql, values, (err, rows) => {
        if (err) return featureDbError(res, err);
        featurePageResponse(res, rows, paging);
    });
});

app.post('/api/admin/locations', auth, adminOnly, (req, res) => {
    const { university_id, zone_id, name, address } = req.body || {};
    if (!featureId(university_id) || !featureZone(zone_id) || !featureText(name, 200, true) || !featureText(address, 500)) {
        return res.status(400).json({ success: false, message: 'Invalid university_id, zone_id, name or address' });
    }
    con.query(`INSERT INTO locations (university_id,zone_id,name,address)
               SELECT university_id,?,?,? FROM universities WHERE university_id=? AND is_active=1`,
        [zone_id, name.trim(), featureOptionalText(address), university_id], (err, result) => {
            if (err) return featureDbError(res, err);
            if (!result.affectedRows) return res.status(400).json({ success: false, message: 'University not found or inactive' });
            res.status(201).json({ success: true, location_id: result.insertId });
        });
});

// Full replacement of editable fields; zone/university IDs remain stable for existing references.
app.put('/api/admin/locations/:location_id', auth, adminOnly, (req, res) => {
    const { name, address, is_active } = req.body || {};
    if (!featureId(req.params.location_id) || !featureText(name, 200, true)
        || !featureText(address, 500) || typeof is_active !== 'boolean') {
        return res.status(400).json({ success: false, message: 'Provide name, optional address and boolean is_active' });
    }
    con.query('UPDATE locations SET name=?,address=?,is_active=? WHERE location_id=?',
        [name.trim(), featureOptionalText(address), is_active ? 1 : 0, req.params.location_id], (err, result) => {
            if (err) return featureDbError(res, err);
            if (!result.affectedRows) return res.status(404).json({ success: false, message: 'Dormitory not found' });
            res.json({ success: true, message: 'Dormitory updated' });
        });
});

app.get('/api/admin/location-requests', auth, adminOnly, (req, res) => {
    const { status, university_id } = req.query;
    const states = ['pending', 'reviewing', 'approved', 'merged', 'rejected'];
    if ((status !== undefined && !states.includes(status)) || (university_id !== undefined && !featureId(university_id))) {
        return res.status(400).json({ success: false, message: 'Invalid status or university filter' });
    }
    const paging = featurePage(req, res);
    if (!paging) return;
    let sql = `SELECT r.*,u.display_name AS requester_name,u.university_id,
                      un.name AS university_name,z.name AS zone_name,l.name AS resolved_location_name
               FROM location_requests r JOIN users u ON u.user_id=r.requested_by
               JOIN universities un ON un.university_id=u.university_id
               JOIN location_zones z ON z.zone_id=r.zone_id
               LEFT JOIN locations l ON l.location_id=r.resolved_location_id WHERE 1=1`;
    const values = [];
    if (status !== undefined) { sql += ' AND r.status=?'; values.push(status); }
    if (university_id !== undefined) { sql += ' AND u.university_id=?'; values.push(university_id); }
    sql += ' ORDER BY r.created_at DESC,r.request_id DESC LIMIT ? OFFSET ?';
    values.push(paging.limit + 1, paging.offset);
    con.query(sql, values, (err, rows) => {
        if (err) return featureDbError(res, err);
        featurePageResponse(res, rows, paging);
    });
});

// action: reviewing | approve | merge | reject
// approve creates the requested dorm; merge requires resolved_location_id.
app.put('/api/admin/location-requests/:request_id/review', auth, adminOnly, (req, res) => {
    const { action, resolved_location_id, review_note } = req.body || {};
    if (!featureId(req.params.request_id) || !['reviewing', 'approve', 'merge', 'reject'].includes(action)
        || !featureText(review_note, 1000, action === 'reject')
        || (action === 'merge' && !featureId(resolved_location_id))) {
        return res.status(400).json({ success: false, message: 'Invalid action, merge target or review note' });
    }
    featureTransaction(res, (conn, abort, commit) => {
        // Read requester first, then lock user -> request in the same order as member routes.
        conn.query('SELECT requested_by FROM location_requests WHERE request_id=?', [req.params.request_id], (err, found) => {
            if (err) return abort(500, null, err);
            if (!found.length) return abort(404, 'Location request not found');
            conn.query('SELECT university_id,residence_zone_id,residence_location_id FROM users WHERE user_id=? FOR UPDATE',
                [found[0].requested_by], (err, users) => {
                    if (err) return abort(500, null, err);
                    if (!users.length) return abort(404, 'Requester not found');
                    conn.query('SELECT * FROM location_requests WHERE request_id=? FOR UPDATE', [req.params.request_id], (err, requests) => {
                        if (err) return abort(500, null, err);
                        const request = requests[0];
                        if (!request) return abort(404, 'Location request not found');
                        if (!['pending', 'reviewing'].includes(request.status)) return abort(409, 'Location request is already closed');
                        const user = users[0];
                        const finishReview = (status, locationId) => {
                            conn.query(`UPDATE location_requests SET status=?,resolved_location_id=?,
                                        reviewed_by=?,reviewed_at=UTC_TIMESTAMP(3),review_note=? WHERE request_id=?`,
                                [status, locationId, req.user.user_id, featureOptionalText(review_note), request.request_id], err => {
                                    if (err) return abort(500, null, err);
                                    const reply = () => commit(200, { success: true, request_id: request.request_id,
                                        status, resolved_location_id: locationId });
                                    if (!locationId) return reply();
                                    conn.query('UPDATE users SET residence_zone_id=?,residence_location_id=? WHERE user_id=?',
                                        [request.zone_id, locationId, request.requested_by], err => {
                                            if (err) return abort(500, null, err);
                                            reply();
                                        });
                                });
                        };
                        if (action === 'reviewing') return finishReview('reviewing', null);
                        if (action === 'reject') return finishReview('rejected', null);
                        if (Number(user.residence_zone_id) !== Number(request.zone_id) || user.residence_location_id !== null) {
                            return abort(409, 'Requester residence changed; refresh before resolving the request');
                        }
                        if (action === 'merge') {
                            return conn.query(`SELECT location_id FROM locations WHERE location_id=? AND university_id=?
                                               AND zone_id=? AND is_active=1 LOCK IN SHARE MODE`,
                                [resolved_location_id, user.university_id, request.zone_id], (err, locations) => {
                                    if (err) return abort(500, null, err);
                                    if (!locations.length) return abort(400, 'Merge target must be active and match requester university and zone');
                                    finishReview('merged', locations[0].location_id);
                                });
                        }
                        conn.query('INSERT INTO locations (university_id,zone_id,name,address) VALUES (?,?,?,?)',
                            [user.university_id, request.zone_id, request.location_name, request.address], (err, result) => {
                                if (err) return abort(500, null, err);
                                finishReview('approved', result.insertId);
                            });
                    });
                });
        });
    });
});

// ---------- Favorites ----------
app.get('/api/favorites', auth, (req, res) => {
    const paging = featurePage(req, res);
    if (!paging) return;
    const sql = `SELECT f.product_id,f.created_at AS saved_at,p.title,p.price,p.visibility,p.review_status,
                        p.zone_id,p.location_id,u.display_name AS seller_name,
                        (SELECT storage_key FROM product_images WHERE product_id=p.product_id ORDER BY sort_order LIMIT 1) AS image_storage_key,
                        (p.visibility='active' AND p.review_status='approved' AND u.status='active' AND c.is_active=1
                         AND NOT EXISTS (SELECT 1 FROM orders o WHERE o.claimed_product_id=p.product_id)) AS is_available
                 FROM favorites f JOIN products p ON p.product_id=f.product_id
                 JOIN users u ON u.user_id=p.seller_id JOIN categories c ON c.category_id=p.category_id
                 WHERE f.user_id=? ORDER BY f.created_at DESC,f.product_id DESC LIMIT ? OFFSET ?`;
    con.query(sql, [req.user.user_id, paging.limit + 1, paging.offset], (err, rows) => {
        if (err) return featureDbError(res, err);
        featurePageResponse(res, rows, paging);
    });
});

app.post('/api/favorites', auth, (req, res) => {
    const { product_id } = req.body || {};
    if (!featureId(product_id)) return res.status(400).json({ success: false, message: 'Valid product_id required' });
    con.query(`SELECT p.product_id FROM products p JOIN users seller ON seller.user_id=p.seller_id
               JOIN users buyer ON buyer.user_id=? JOIN categories c ON c.category_id=p.category_id
               WHERE p.product_id=? AND p.visibility='active' AND p.review_status='approved'
                 AND seller.status='active' AND seller.university_id=buyer.university_id AND c.is_active=1`,
        [req.user.user_id, product_id], (err, rows) => {
            if (err) return featureDbError(res, err);
            if (!rows.length) return res.status(404).json({ success: false, message: 'Published product not found in your university' });
            con.query('INSERT INTO favorites (user_id,product_id) VALUES (?,?)', [req.user.user_id, product_id], err => {
                if (err && err.code !== 'ER_DUP_ENTRY') return featureDbError(res, err);
                res.status(err ? 200 : 201).json({ success: true, product_id, is_favorite: true });
            });
        });
});

app.delete('/api/favorites/:product_id', auth, (req, res) => {
    if (!featureId(req.params.product_id)) return res.status(400).json({ success: false, message: 'Invalid product_id' });
    con.query('DELETE FROM favorites WHERE user_id=? AND product_id=?', [req.user.user_id, req.params.product_id], err => {
        if (err) return featureDbError(res, err);
        res.json({ success: true, is_favorite: false });
    });
});

// ---------- Seller listing status and resubmission ----------
app.get('/api/my/listings', auth, (req, res) => {
    const { review_status } = req.query;
    if (review_status !== undefined && !['pending_review', 'approved', 'changes_requested', 'rejected'].includes(review_status)) {
        return res.status(400).json({ success: false, message: 'Invalid review_status' });
    }
    const paging = featurePage(req, res);
    if (!paging) return;
    let sql = `SELECT p.product_id,p.title,p.price,p.visibility,p.review_status,p.review_note,p.rejection_code,
                      p.reviewed_at,p.view_count,p.zone_id,p.location_id,p.is_urgent,p.clearance_deadline,p.created_at,
                      (SELECT storage_key FROM product_images WHERE product_id=p.product_id ORDER BY sort_order LIMIT 1) AS image_storage_key,
                      EXISTS(SELECT 1 FROM orders o WHERE o.claimed_product_id=p.product_id) AS is_claimed,
                      EXISTS(SELECT 1 FROM orders o WHERE o.product_id=p.product_id AND o.status='completed') AS is_sold
               FROM products p WHERE p.seller_id=?`;
    const values = [req.user.user_id];
    if (review_status !== undefined) { sql += ' AND p.review_status=?'; values.push(review_status); }
    sql += ' ORDER BY p.created_at DESC,p.product_id DESC LIMIT ? OFFSET ?';
    values.push(paging.limit + 1, paging.offset);
    con.query(sql, values, (err, rows) => {
        if (err) return featureDbError(res, err);
        featurePageResponse(res, rows, paging);
    });
});

app.post('/api/products/:product_id/resubmit', auth, (req, res) => {
    if (!featureId(req.params.product_id)) return res.status(400).json({ success: false, message: 'Invalid product_id' });
    featureTransaction(res, (conn, abort, commit) => {
        conn.query('SELECT product_id,review_status,visibility FROM products WHERE product_id=? AND seller_id=? FOR UPDATE',
            [req.params.product_id, req.user.user_id], (err, rows) => {
                if (err) return abort(500, null, err);
                if (!rows.length) return abort(404, 'Product not found or not owned by you');
                if (rows[0].visibility === 'removed' || !['changes_requested', 'rejected'].includes(rows[0].review_status)) {
                    return abort(409, 'Only changes_requested/rejected listings can be resubmitted');
                }
                conn.query('SELECT order_id FROM orders WHERE claimed_product_id=?', [req.params.product_id], (err, orders) => {
                    if (err) return abort(500, null, err);
                    if (orders.length) return abort(409, 'Claimed or sold listing cannot be resubmitted');
                    // Preserve the last review note/reviewer/time as previous feedback.
                    conn.query("UPDATE products SET review_status='pending_review',rejection_code=NULL WHERE product_id=?",
                        [req.params.product_id], err => {
                            if (err) return abort(500, null, err);
                            commit(200, { success: true, review_status: 'pending_review' });
                        });
                });
            });
    });
});

// ---------- Admin listing moderation ----------
app.get('/api/admin/listings', auth, adminOnly, (req, res) => {
    const { university_id, review_status = 'pending_review' } = req.query;
    if ((university_id !== undefined && !featureId(university_id))
        || !['all', 'pending_review', 'approved', 'changes_requested', 'rejected'].includes(review_status)) {
        return res.status(400).json({ success: false, message: 'Invalid university or review status filter' });
    }
    const paging = featurePage(req, res);
    if (!paging) return;
    let sql = `SELECT p.product_id,p.title,p.price,p.review_status,p.visibility,p.review_note,p.rejection_code,p.created_at,
                      p.seller_id,u.display_name AS seller_name,u.username,u.university_id,c.name AS category_name,
                      z.name AS zone_name,l.name AS location_name,
                      (SELECT storage_key FROM product_images WHERE product_id=p.product_id ORDER BY sort_order LIMIT 1) AS image_storage_key
               FROM products p JOIN users u ON u.user_id=p.seller_id JOIN categories c ON c.category_id=p.category_id
               LEFT JOIN location_zones z ON z.zone_id=p.zone_id LEFT JOIN locations l ON l.location_id=p.location_id WHERE 1=1`;
    const values = [];
    if (university_id !== undefined) { sql += ' AND u.university_id=?'; values.push(university_id); }
    if (review_status !== 'all') { sql += ' AND p.review_status=?'; values.push(review_status); }
    sql += ' ORDER BY p.created_at,p.product_id LIMIT ? OFFSET ?';
    values.push(paging.limit + 1, paging.offset);
    con.query(sql, values, (err, rows) => {
        if (err) return featureDbError(res, err);
        featurePageResponse(res, rows, paging);
    });
});

app.get('/api/admin/listings/:product_id', auth, adminOnly, (req, res) => {
    if (!featureId(req.params.product_id)) return res.status(400).json({ success: false, message: 'Invalid product_id' });
    con.query(`SELECT p.*,u.display_name AS seller_name,u.username,u.university_id,c.name AS category_name,
                      z.name AS zone_name,l.name AS location_name
               FROM products p JOIN users u ON u.user_id=p.seller_id JOIN categories c ON c.category_id=p.category_id
               LEFT JOIN location_zones z ON z.zone_id=p.zone_id LEFT JOIN locations l ON l.location_id=p.location_id
               WHERE p.product_id=?`, [req.params.product_id], (err, rows) => {
        if (err) return featureDbError(res, err);
        if (!rows.length) return res.status(404).json({ success: false, message: 'Product not found' });
        con.query('SELECT image_id,storage_key,sort_order FROM product_images WHERE product_id=? ORDER BY sort_order',
            [req.params.product_id], (err, images) => {
                if (err) return featureDbError(res, err);
                res.json({ success: true, data: rows[0], images });
            });
    });
});

// action: approve | changes_requested | reject
// A decision closes this review; seller must resubmit before another decision.
app.put('/api/admin/listings/:product_id/review', auth, adminOnly, (req, res) => {
    const { action, review_note, rejection_code } = req.body || {};
    const codes = ['prohibited_item', 'misleading', 'poor_photos', 'duplicate', 'other'];
    if (!featureId(req.params.product_id) || !['approve', 'changes_requested', 'reject'].includes(action)
        || !featureText(review_note, 1000, action !== 'approve')
        || (action === 'reject' && !codes.includes(rejection_code))) {
        return res.status(400).json({ success: false, message: 'Invalid action, review note or rejection_code' });
    }
    featureTransaction(res, (conn, abort, commit) => {
        conn.query(`SELECT p.product_id,p.review_status,p.visibility,u.status AS seller_status,c.is_active AS category_is_active
                    FROM products p JOIN users u ON u.user_id=p.seller_id JOIN categories c ON c.category_id=p.category_id
                    WHERE p.product_id=? FOR UPDATE`, [req.params.product_id], (err, rows) => {
            if (err) return abort(500, null, err);
            if (!rows.length) return abort(404, 'Product not found');
            const product = rows[0];
            if (product.review_status !== 'pending_review' || product.visibility === 'removed') {
                return abort(409, 'Only a pending, non-removed listing can be reviewed');
            }
            if (action === 'approve' && (product.seller_status !== 'active' || !product.category_is_active)) {
                return abort(409, 'Seller or category is inactive');
            }
            conn.query('SELECT order_id FROM orders WHERE claimed_product_id=?', [product.product_id], (err, orders) => {
                if (err) return abort(500, null, err);
                if (orders.length) return abort(409, 'Claimed or sold listing cannot change review status');
                const status = action === 'approve' ? 'approved' : action === 'reject' ? 'rejected' : 'changes_requested';
                conn.query(`UPDATE products SET review_status=?,reviewed_by=?,reviewed_at=UTC_TIMESTAMP(3),
                            review_note=?,rejection_code=? WHERE product_id=?`,
                    [status, req.user.user_id, featureOptionalText(review_note), action === 'reject' ? rejection_code : null, product.product_id], err => {
                        if (err) return abort(500, null, err);
                        commit(200, { success: true, product_id: product.product_id, review_status: status });
                    });
            });
        });
    });
});
// Error handling and fallback must follow every registered route.
app.use((err,req,res,next)=>{
    if(res.headersSent)return next(err);
    console.error(err);
    res.status(err.status===400?400:500).json({success:false,message:err.status===400?'Invalid JSON body':'Internal server error'});
});
app.use((req,res)=>res.status(404).json({success:false,message:'API endpoint not found'}));
app.listen(PORT,()=>console.log('UniSwap API running at http://localhost:'+PORT));
