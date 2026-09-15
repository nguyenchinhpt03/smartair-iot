const express = require('express');
const router  = express.Router();
const pool    = require('../db/pool');
const axios   = require('axios');
const { sendAlertIfNeeded, sendAnomalyAlertIfNeeded, sendUnifiedAlert } = require('../notifications/fcm');

// POST /api/reading — ESP32 gửi lên mỗi 1 phút
router.post('/reading', async (req, res) => {
    const d = req.body;

    if (!d.device_id || d.aqi === undefined) {
        return res.status(400).json({ error: 'Missing device_id or aqi' });
    }

    // Kiểm tra device_id tồn tại
    const { rows: devRows } = await pool.query(
        'SELECT device_id FROM devices WHERE device_id = $1', [d.device_id]
    ).catch(() => ({ rows: [] }));

    if (!devRows.length) {
        return res.status(404).json({ error: `Device ${d.device_id} not found` });
    }

    console.log(`[SmartAir IoT] Nhận gói tin từ ${d.device_id}: AQI=${d.aqi}, Temp=${d.temperature_c.toFixed(1)}°C, CO2=${d.co2_ppm}ppm`);

    try {
        // Cập nhật trạng thái online, last_seen, IP và Wi-Fi SSID của thiết bị
        pool.query(
            `UPDATE devices
             SET is_online = TRUE,
                 last_seen = NOW(),
                 ip_address = COALESCE($1, ip_address),
                 wifi_ssid = COALESCE($2, wifi_ssid)
             WHERE device_id = $3`,
            [d.ip_address || req.ip || null, d.wifi_ssid || null, d.device_id]
        ).catch(() => {});

        // Lớp 1: buffer 10 slot xoay vòng
        await pool.query(
            `SELECT insert_reading($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12)`,
            [
                d.device_id,     d.aqi,
                d.co2_ppm     ?? null,
                d.nh3_ppm     ?? null,
                d.benzene_ppm ?? null,
                d.co_ppm      ?? null,
                d.pm1_ugm3    ?? null,
                d.pm25_ugm3   ?? null,
                d.pm10_ugm3   ?? null,
                d.temperature_c ?? null,
                d.humidity_pct  ?? null,
                d.pressure_hpa  ?? null,
            ]
        );

        // Lớp 2: bảng ngày — ghi ~1440 bản ghi/ngày để biểu đồ 24h
        const today = new Date().toLocaleDateString('sv');
        const tbl   = 'readings_' + today.replace(/-/g, '_');
        await pool.query(
            `INSERT INTO ${tbl}
                (device_id, recorded_at,
                 co2_ppm, nh3_ppm, benzene_ppm, co_ppm,
                 pm1_ugm3, pm25_ugm3, pm10_ugm3,
                 temperature_c, humidity_pct, pressure_hpa, aqi)
             VALUES ($1, NOW(), $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)`,
            [
                d.device_id,
                d.co2_ppm     ?? null,
                d.nh3_ppm     ?? null,
                d.benzene_ppm ?? null,
                d.co_ppm      ?? null,
                d.pm1_ugm3    ?? null,
                d.pm25_ugm3   ?? null,
                d.pm10_ugm3   ?? null,
                d.temperature_c ?? null,
                d.humidity_pct  ?? null,
                d.pressure_hpa  ?? null,
                d.aqi,
            ]
        );

        // Chạy kiểm tra dị thường Isolation Forest qua AI Engine và gộp thông báo (không block response)
        (async () => {
            try {
                let isAnomaly = false;
                const { rows: recentReadings } = await pool.query(
                    `SELECT aqi, pm25_ugm3 FROM ${tbl}
                     WHERE device_id = $1
                     ORDER BY recorded_at DESC
                     LIMIT 10`,
                    [d.device_id]
                );
                if (recentReadings.length >= 5) {
                    const readingsChronological = recentReadings.reverse();
                    try {
                        const aiRes = await axios.post(`${process.env.AI_ENGINE_URL}/realtime_anomaly`, {
                            readings: readingsChronological
                        }, { timeout: 5000 });
                        isAnomaly = !!aiRes.data.is_anomaly;
                    } catch (err) {
                        console.error('[AI Anomaly Check] API failed:', err.message);
                    }
                }

                // Gửi thông báo hợp nhất (gộp cả chỉ số vượt ngưỡng và dị thường AI)
                await sendUnifiedAlert(d.device_id, d, isAnomaly);
            } catch (err) {
                console.error('[FCM Unified Alert] failed:', err.message);
            }
        })();

        res.json({ status: 'ok' });
    } catch (err) {
        console.error('[POST /reading]', err.message);
        res.status(500).json({ error: 'Database error' });
    }
});

module.exports = router;
