const express = require('express');
const router  = express.Router();
const pool    = require('../db/pool');

// PUT /api/user/fcm-token — Cập nhật FCM token khi app khởi động
router.put('/user/fcm-token', async (req, res) => {
    const { user_id, fcm_token } = req.body;

    if (!user_id || !fcm_token) {
        return res.status(400).json({ error: 'Missing user_id or fcm_token' });
    }

    try {
        const { rowCount } = await pool.query(
            `UPDATE users SET fcm_token = $1 WHERE user_id = $2`,
            [fcm_token, user_id]
        );
        if (!rowCount) return res.status(404).json({ error: 'User not found' });
        res.json({ status: 'ok' });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// GET /api/user/:user_id — Thông tin user (bao gồm cả trạng thái fcm_enabled)
router.get('/user/:user_id', async (req, res) => {
    try {
        const { rows } = await pool.query(
            `SELECT user_id, email, fcm_enabled, created_at FROM users WHERE user_id = $1`,
            [req.params.user_id]
        );
        if (!rows.length) return res.status(404).json({ error: 'User not found' });
        res.json(rows[0]);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// PUT /api/user/fcm-enabled — Bật/tắt nhận thông báo đẩy
router.put('/user/fcm-enabled', async (req, res) => {
    const { user_id, fcm_enabled } = req.body;

    if (user_id === undefined || fcm_enabled === undefined) {
        return res.status(400).json({ error: 'Missing user_id or fcm_enabled' });
    }

    try {
        const { rowCount } = await pool.query(
            `UPDATE users SET fcm_enabled = $1 WHERE user_id = $2`,
            [fcm_enabled, user_id]
        );
        if (!rowCount) return res.status(404).json({ error: 'User not found' });
        res.json({ status: 'ok' });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// GET /api/user/notifications/:user_id — Lấy lịch sử thông báo đã gửi cho user
router.get('/user/notifications/:user_id', async (req, res) => {
    try {
        const { rows } = await pool.query(
            `SELECT id, device_id, metric, value, message, sent_at
             FROM notifications
             WHERE user_id = $1
             ORDER BY sent_at DESC
             LIMIT 50`,
            [req.params.user_id]
        );
        res.json(rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

module.exports = router;
