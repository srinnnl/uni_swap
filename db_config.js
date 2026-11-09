
const mysql = require("mysql2");

const pool = mysql.createPool({
    host: 'localhost',
    user: 'root',
    password: '',
    database: 'project_mobile_app',
    charset: 'utf8mb4',
    timezone: 'Z',
    waitForConnections: true,
    connectionLimit: 10
});

// Set MySQL session timezone to UTC
pool.on('connection', connection => {
    connection.query("SET time_zone = '+00:00'", error => {
        if (error) {
            console.error('Failed to set session time zone:', error.code);
        }
    });
});

module.exports = pool;
