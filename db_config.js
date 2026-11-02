const mysql = require("mysql2");
const con = mysql.createConnection({
   host: 'localhost',
   user: 'root',
   password: '',
   database: 'db_project',
   charset: 'utf8mb4',
   timezone: 'Z'
});

con.on('error', error => console.error('Database connection error:', error.code));

module.exports = con;