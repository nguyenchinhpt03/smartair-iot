const express = require('express');
const router  = express.Router();
const pool    = require('../db/pool');

// GET /api/history/:device_id?date=YYYY-MM-DD — Biểu đồ 24h (Lớp 2)
router.get('/history/:device_id', async (req, res) => {
    const date = req.query.date || new Date().toLocaleDateString('sv');

    // Validate format YYYY-MM-DD — tránh SQL injection tên bảng
    if (!/^\d{4}-\d{2}-\d{2}$/.test(date)) {
        return res.status(400).json({ error: 'Invalid date format. Use YYYY-MM-DD' });
    }

    const tbl = 'readings_' + date.replace(/-/g, '_');
    try {
        const { rows } = await pool.query(
            `SELECT * FROM ${tbl}
             WHERE  device_id = $1
             ORDER  BY recorded_at ASC`,
            [req.params.device_id]
        );
        res.json(rows);
    } catch {
        // Bảng không tồn tại = ngày ngoài phạm vi lưu trữ
        res.json([]);
    }
});

module.exports = router;
