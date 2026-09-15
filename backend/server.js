require('dotenv').config();
const express = require('express');
const axios = require('axios');
const { scheduleJobs } = require('./cron/scheduler');
const pool = require('./db/pool');

// Run database migrations for authentication support
async function runMigrations() {
    try {
        await pool.query(`
            ALTER TABLE users ADD COLUMN IF NOT EXISTS username VARCHAR(100) UNIQUE;
            ALTER TABLE users ADD COLUMN IF NOT EXISTS password_hash TEXT;
            ALTER TABLE users ADD COLUMN IF NOT EXISTS fcm_enabled BOOLEAN NOT NULL DEFAULT TRUE;
            ALTER TABLE users ADD COLUMN IF NOT EXISTS phone VARCHAR(20) UNIQUE;
            ALTER TABLE devices ADD COLUMN IF NOT EXISTS ip_address VARCHAR(100);
            ALTER TABLE devices ADD COLUMN IF NOT EXISTS temp_password VARCHAR(50);
        `);
        console.log('[DB] Database migration completed (auth, phone, ip_address, and temp_password columns validated).');

        // Ensure daily table exists
        await pool.query(`SELECT create_daily_table(CURRENT_DATE)`);
        console.log('[DB] Daily readings table validated.');
    } catch (err) {
        console.error('[DB Error] Migration failed:', err.message);
    }
}
runMigrations();

const app = express();
app.use(express.json({ limit: '10kb' }));

// ── Health check ─────────────────────────────────────────────────
app.get('/health', (req, res) => {
    res.json({ status: 'ok', ts: new Date().toISOString() });
});

// ── Routes ───────────────────────────────────────────────────────
app.use('/api', require('./routes/reading'));
app.use('/api', require('./routes/realtime'));
app.use('/api', require('./routes/history'));
app.use('/api', require('./routes/device'));
app.use('/api', require('./routes/user'));
app.use('/api', require('./routes/alert'));
app.use('/api', require('./routes/chat'));
app.use('/api', require('./routes/auth'));

// ── Global error handler ─────────────────────────────────────────
app.use((err, req, res, _next) => {
    console.error('[Server Error]', err.message);
    res.status(500).json({ error: 'Internal server error' });
});

// ── Cron jobs ────────────────────────────────────────────────────
scheduleJobs();

// ── Bộ mô phỏng chất lượng không khí chu kỳ nhanh ngầm ──────────
function startRapidSimulator() {
    let tick = 0;
    console.log('[Simulator] Rapid simulator started');

    setInterval(async () => {
        tick++;
        const phase = Math.floor((tick % 24) / 6);
        let data = {};

        switch (phase) {
            case 0:
                data = {
                    device_id: 'SA-001',
                    temperature_c: 24.5 + Math.random() * 1.5,
                    humidity_pct: 50.0 + Math.random() * 5,
                    co2_ppm: 400 + Math.floor(Math.random() * 80),
                    co_ppm: 0.1 + Math.random() * 0.4,
                    pm25_ugm3: 5.0 + Math.random() * 6.0,
                    nh3_ppm: 0.5 + Math.random() * 1.0,
                    benzene_ppm: 0.01 + Math.random() * 0.02,
                    pm1_ugm3: 2.0 + Math.random() * 3.0,
                    pm10_ugm3: 8.0 + Math.random() * 5.0,
                    aqi: 10 + Math.floor(Math.random() * 25)
                };
                break;
            case 1:
                data = {
                    device_id: 'SA-001',
                    temperature_c: 25.5 + Math.random() * 1.5,
                    humidity_pct: 55.0 + Math.random() * 5,
                    co2_ppm: 1200 + Math.floor(Math.random() * 500),
                    co_ppm: 12.0 + Math.random() * 12.0,
                    pm25_ugm3: 65.0 + Math.random() * 80.0,
                    nh3_ppm: 5.0 + Math.random() * 3.0,
                    benzene_ppm: 0.25 + Math.random() * 0.5,
                    pm1_ugm3: 30.0 + Math.random() * 25.0,
                    pm10_ugm3: 85.0 + Math.random() * 45.0,
                    aqi: 155 + Math.floor(Math.random() * 70)
                };
                break;
            case 2:
                data = {
                    device_id: 'SA-001',
                    temperature_c: 29.5 + Math.random() * 2.5,
                    humidity_pct: 70.0 + Math.random() * 10,
                    co2_ppm: 2200 + Math.floor(Math.random() * 900),
                    co_ppm: 0.5 + Math.random() * 0.7,
                    pm25_ugm3: 15.0 + Math.random() * 10.0,
                    nh3_ppm: 1.0 + Math.random() * 1.0,
                    benzene_ppm: 0.02 + Math.random() * 0.03,
                    pm1_ugm3: 6.0 + Math.random() * 4.0,
                    pm10_ugm3: 18.0 + Math.random() * 8.0,
                    aqi: 105 + Math.floor(Math.random() * 35)
                };
                break;
            case 3:
                data = {
                    device_id: 'SA-001',
                    temperature_c: 26.0 + Math.random() * 2.0,
                    humidity_pct: 55.0 + Math.random() * 10,
                    co2_ppm: 700 + Math.floor(Math.random() * 200),
                    co_ppm: 1.0 + Math.random() * 1.5,
                    pm25_ugm3: 18.0 + Math.random() * 14.0,
                    nh3_ppm: 1.5 + Math.random() * 2.0,
                    benzene_ppm: 0.04 + Math.random() * 0.06,
                    pm1_ugm3: 8.5 + Math.random() * 5.0,
                    pm10_ugm3: 22.0 + Math.random() * 10.0,
                    aqi: 55 + Math.floor(Math.random() * 35)
                };
                break;
        }

        try {
            await pool.query(
                `SELECT insert_reading($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12)`,
                [
                    data.device_id, data.aqi,
                    data.co2_ppm, data.nh3_ppm,
                    data.benzene_ppm, data.co_ppm,
                    data.pm1_ugm3, data.pm25_ugm3,
                    data.pm10_ugm3, data.temperature_c,
                    data.humidity_pct, 1013.2
                ]
            );

            const today = new Date().toISOString().slice(0, 10);
            const tbl = 'readings_' + today.replace(/-/g, '_');
            await pool.query(
                `INSERT INTO ${tbl}
                    (device_id, recorded_at,
                     co2_ppm, nh3_ppm, benzene_ppm, co_ppm,
                     pm1_ugm3, pm25_ugm3, pm10_ugm3,
                     temperature_c, humidity_pct, pressure_hpa, aqi)
                 VALUES ($1, NOW(), $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)`,
                [
                    data.device_id,
                    data.co2_ppm, data.nh3_ppm,
                    data.benzene_ppm, data.co_ppm,
                    data.pm1_ugm3, data.pm25_ugm3,
                    data.pm10_ugm3, data.temperature_c,
                    data.humidity_pct, 1013.2,
                    data.aqi
                ]
            );

            (async () => {
                try {
                    let isAnomaly = false;
                    const { rows: recentReadings } = await pool.query(
                        `SELECT aqi, pm25_ugm3 FROM ${tbl}
                         WHERE device_id = $1
                         ORDER BY recorded_at DESC
                         LIMIT 10`,
                        [data.device_id]
                    );
                    if (recentReadings.length >= 5) {
                        const readingsChronological = recentReadings.reverse();
                        try {
                            const aiRes = await axios.post(`${process.env.AI_ENGINE_URL}/realtime_anomaly`, {
                                readings: readingsChronological
                            }, { timeout: 3000 });
                            isAnomaly = !!aiRes.data.is_anomaly;
                        } catch (err) {
                        }
                    }

                    const { sendUnifiedAlert } = require('./notifications/fcm');
                    await sendUnifiedAlert(data.device_id, data, isAnomaly);
                } catch (err) {
                    console.error('[Simulator Unified Alert] failed:', err.message);
                }
            })();

            console.log(`[Simulator] Active Phase: ${phase}, AQI: ${data.aqi}, PM2.5: ${data.pm25_ugm3.toFixed(1)}, CO2: ${data.co2_ppm}`);
        } catch (err) {
            console.error('[Simulator Error]', err.message);
        }
    }, 10000);
}
// startRapidSimulator();
const PORT = process.env.PORT || 3000;
app.listen(PORT, '0.0.0.0', () => {
    console.log(`[SmartAir] Backend running on port ${PORT} (bound to 0.0.0.0)`);
    console.log(`[SmartAir] Health check: http://localhost:${PORT}/health`);
});
