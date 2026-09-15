require('dotenv').config();
const { Pool } = require('pg');

let connectionString = process.env.DATABASE_URL;
let host = process.env.DB_HOST || 'localhost';
let port = parseInt(process.env.DB_PORT) || 5432;
let user = process.env.DB_USER || 'postgres';
let password = process.env.DB_PASS;
let database = process.env.DB_NAME || 'postgres';

// Tự động chuyển đổi IPv6 direct host sang IPv4 pooler của Supabase (khắc phục lỗi ENETUNREACH trên Render/Cloud)
if (host && host.includes('db.reiseyupequryljqcvqj.supabase.co')) {
    host = 'aws-0-ap-northeast-2.pooler.supabase.com';
    user = 'postgres.reiseyupequryljqcvqj';
    port = 5432;
}

if (connectionString && connectionString.includes('db.reiseyupequryljqcvqj.supabase.co')) {
    connectionString = connectionString
        .replace('db.reiseyupequryljqcvqj.supabase.co', 'aws-0-ap-northeast-2.pooler.supabase.com')
        .replace('postgres:Chinh25072003!', 'postgres.reiseyupequryljqcvqj:Chinh25072003!')
        .replace('postgres.reiseyupequryljqcvqj.reiseyupequryljqcvqj:', 'postgres.reiseyupequryljqcvqj:');
}

const isRemote = (host && host !== 'localhost' && host !== '127.0.0.1') || 
                 (connectionString && !connectionString.includes('localhost') && !connectionString.includes('127.0.0.1'));

const poolConfig = connectionString
    ? {
        connectionString,
        ssl: isRemote ? { rejectUnauthorized: false } : false,
        max: 10,
        idleTimeoutMillis: 30000,
        connectionTimeoutMillis: 10000,
      }
    : {
        host,
        port,
        database,
        user,
        password,
        ssl: isRemote ? { rejectUnauthorized: false } : false,
        max: 10,
        idleTimeoutMillis: 30000,
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
