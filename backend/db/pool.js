require('dotenv').config();
const { Pool } = require('pg');

const isRemote = (process.env.DB_HOST && process.env.DB_HOST !== 'localhost' && process.env.DB_HOST !== '127.0.0.1') || 
                 (process.env.DATABASE_URL && !process.env.DATABASE_URL.includes('localhost') && !process.env.DATABASE_URL.includes('127.0.0.1'));

const poolConfig = process.env.DATABASE_URL
    ? {
        connectionString: process.env.DATABASE_URL,
        ssl: isRemote ? { rejectUnauthorized: false } : false,
        max: 10,
        idleTimeoutMillis: 30000,
        connectionTimeoutMillis: 10000,
      }
    : {
        host:               process.env.DB_HOST     || 'localhost',
        port:               parseInt(process.env.DB_PORT) || 5432,
        database:           process.env.DB_NAME     || 'postgres',
        user:               process.env.DB_USER     || 'postgres',
        password:           process.env.DB_PASS,
        ssl:                isRemote ? { rejectUnauthorized: false } : false,
        max:                10,
        idleTimeoutMillis:  30000,
        connectionTimeoutMillis: 10000,
      };

const pool = new Pool(poolConfig);

pool.on('error', (err) => {
    console.error('[DB Pool] Unexpected error:', err.message);
});

pool.on('connect', () => {
    console.log('[DB Pool] New client connected');
});

module.exports = pool;
