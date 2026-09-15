const express = require('express');
const router  = express.Router();
const pool    = require('../db/pool');

// GET /api/realtime/:device_id — Dashboard đọc mỗi 60 giây (Lớp 1)
router.get('/realtime/:device_id', async (req, res) => {
    console.log(`[API Get Realtime] App di động đang đọc số liệu của thiết bị: ${req.params.device_id}`);
    try {
        const { rows } = await pool.query(
            `SELECT r.*, d.wifi_ssid, d.ip_address as dev_ip, d.is_online as dev_online, d.name as dev_name
             FROM readings_buffer r
             LEFT JOIN devices d ON d.device_id = r.device_id
             WHERE r.device_id = $1
             ORDER BY r.recorded_at DESC
             LIMIT 1`,
            [req.params.device_id]
        ).catch(() => pool.query(
            `SELECT * FROM readings_buffer
             WHERE device_id = $1
             ORDER BY recorded_at DESC
             LIMIT 1`,
            [req.params.device_id]
        ));
        if (!rows.length) {
            return res.status(404).json({ error: 'No data found for this device' });
        }
        res.json(rows[0]);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// GET /api/hourly/:device_id?days=7 — Biểu đồ 7 ngày (Lớp 3)
router.get('/hourly/:device_id', async (req, res) => {
    const days = Math.min(parseInt(req.query.days) || 7, 7);
    try {
        const { rows } = await pool.query(
            `SELECT * FROM hourly_summary
             WHERE  device_id  = $1
               AND  hour_start >= NOW() - ($2 || ' days')::INTERVAL
             ORDER  BY hour_start ASC`,
            [req.params.device_id, days]
        );
        res.json(rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// GET /api/daily/:device_id — Báo cáo AI 7 ngày gần nhất (Lớp 4)
router.get('/daily/:device_id', async (req, res) => {
    try {
        const { rows } = await pool.query(
            `SELECT * FROM daily_summary
             WHERE  device_id   = $1
             ORDER  BY report_date DESC
             LIMIT  7`,
            [req.params.device_id]
        );
        res.json(rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

module.exports = router;
