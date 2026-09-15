const express = require('express');
const router  = express.Router();
const pool    = require('../db/pool');

// GET /api/alert-settings/:device_id?user_id=N — Lấy ngưỡng cảnh báo
// Trả về object { co2_ppm: 1000, pm25_ugm3: 35, ... }
router.get('/alert-settings/:device_id', async (req, res) => {
    const user_id = parseInt(req.query.user_id);
    if (!user_id) return res.status(400).json({ error: 'Missing user_id query param' });

    try {
        const { rows } = await pool.query(
            `SELECT metric, threshold
             FROM alert_settings
             WHERE device_id = $1 AND user_id = $2 AND is_active = TRUE`,
            [req.params.device_id, user_id]
        );

        // Chuyển mảng → object cho Flutter dễ dùng
        const result = {};
        for (const row of rows) result[row.metric] = row.threshold;
        res.json(result);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// PUT /api/alert-settings/:device_id — Cập nhật ngưỡng cảnh báo
// Body: { user_id: 1, co2_ppm: 1000, pm25_ugm3: 35, aqi: 100, ... }
router.put('/alert-settings/:device_id', async (req, res) => {
    const device_id        = req.params.device_id;
    const { user_id, ...metrics } = req.body;

    if (!user_id) return res.status(400).json({ error: 'Missing user_id in body' });

    const ALLOWED_METRICS = [
        'aqi', 'co2_ppm', 'co_ppm', 'pm25_ugm3',
        'nh3_ppm', 'benzene_ppm', 'pm10_ugm3',
        'temperature_c', 'humidity_pct',
    ];

    try {
        for (const [metric, threshold] of Object.entries(metrics)) {
            if (!ALLOWED_METRICS.includes(metric)) continue;
            await pool.query(
                `INSERT INTO alert_settings (device_id, user_id, metric, threshold)
                 VALUES ($1, $2, $3, $4)
                 ON CONFLICT (device_id, user_id, metric)
                 DO UPDATE SET threshold = $4, is_active = TRUE, updated_at = NOW()`,
                [device_id, user_id, metric, threshold]
            );
        }
        res.json({ status: 'ok' });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// DELETE /api/alert-settings/:device_id/:metric?user_id=N — Vô hiệu hoá 1 ngưỡng
router.delete('/alert-settings/:device_id/:metric', async (req, res) => {
    const user_id = parseInt(req.query.user_id);
    if (!user_id) return res.status(400).json({ error: 'Missing user_id' });

    try {
        await pool.query(
            `UPDATE alert_settings SET is_active = FALSE
             WHERE device_id = $1 AND user_id = $2 AND metric = $3`,
            [req.params.device_id, user_id, req.params.metric]
        );
        res.json({ status: 'ok' });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

module.exports = router;
