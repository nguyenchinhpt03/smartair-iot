require('dotenv').config();
const { Pool } = require('pg');

const pool = new Pool({
    host:               process.env.DB_HOST     || 'localhost',
    port:               parseInt(process.env.DB_PORT) || 5432,
    database:           process.env.DB_NAME     || 'smartair',
    user:               process.env.DB_USER     || 'smartair_user',
    password:           process.env.DB_PASS,
    max:                10,
    idleTimeoutMillis:  30000,
    connectionTimeoutMillis: 5000,
});

pool.on('error', (err) => {
    console.error('[DB Pool] Unexpected error:', err.message);
});

pool.on('connect', () => {
    console.log('[DB Pool] New client connected');
});

module.exports = pool;
