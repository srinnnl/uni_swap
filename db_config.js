const mysql = require("mysql2");

// A pool, not a single connection: orders and cancel use transactions, and each
// transaction must run on its own connection (see app.js: con.getConnection).
const pool = mysql.createPool({
   host: 'localhost',
   user: 'root',
   password: '',
   database: 'db_project',
   charset: 'utf8mb4',
   timezone: 'Z',
   waitForConnections: true,
   connectionLimit: 10
});

// uniswap.sql stores every DATETIME in UTC and has
// CHECK (payment_due_at = created_at + 30 min) on orders. created_at uses
// DEFAULT CURRENT_TIMESTAMP, which follows the session time zone, while app.js
// writes payment_due_at with UTC_TIMESTAMP(). Force UTC on every pooled connection
// so the two always agree. (`timezone: 'Z'` above only affects Date parsing in Node.)
pool.on('connection', connection => {
   connection.query("SET time_zone = '+00:00'", error => {
      if (error) console.error('Failed to set session time zone:', error.code);
   });
});

module.exports = pool;