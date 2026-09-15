const express = require('express');
const router  = express.Router();
const pool    = require('../db/pool');

// POST /api/device/register — Quét QR đăng nhập, tạo/cập nhật user, liên kết thiết bị
router.post('/device/register', async (req, res) => {
    const { qr_code, user_email, fcm_token, user_id: req_user_id } = req.body;

    if (!qr_code) {
        return res.status(400).json({ error: 'Missing qr_code' });
    }

    try {
        // Tìm thiết bị qua QR
        const { rows: devices } = await pool.query(
            `SELECT device_id, name, location FROM devices WHERE qr_code = $1`,
            [qr_code]
        );
        if (!devices.length) {
            return res.status(404).json({ error: 'Không tìm thấy thiết bị. Kiểm tra lại mã QR.' });
        }
        const device = devices[0];

        let user_id = req_user_id;

        if (!user_id) {
            // Tạo hoặc cập nhật user ẩn danh/QR, đồng thời cập nhật FCM token
            const email = user_email || 'anonymous@smartair.local';
            const { rows: users } = await pool.query(
                `INSERT INTO users (email, fcm_token)
                 VALUES ($1, $2)
                 ON CONFLICT (email)
                 DO UPDATE SET fcm_token = $2
                 RETURNING user_id, email`,
                [email, fcm_token || null]
            );
            user_id = users[0].user_id;
        } else {
            // Nếu đã có user_id, chỉ cập nhật FCM token nếu có
            if (fcm_token) {
                await pool.query(
                    `UPDATE users SET fcm_token = $1 WHERE user_id = $2`,
                    [fcm_token, user_id]
                );
            }
        }

        // Liên kết user ↔ thiết bị
        await pool.query(
            `INSERT INTO user_devices (user_id, device_id) VALUES ($1, $2)
             ON CONFLICT DO NOTHING`,
            [user_id, device.device_id]
        );

        res.json({ user_id, device });
    } catch (err) {
        console.error('[POST /device/register]', err.message);
        res.status(500).json({ error: err.message });
    }
});

// GET /api/device/:device_id — Thông tin thiết bị
router.get('/device/:device_id', async (req, res) => {
    try {
        const { rows } = await pool.query(
            `SELECT device_id, name, location, is_online, last_seen, created_at
             FROM devices WHERE device_id = $1`,
            [req.params.device_id]
        );
        if (!rows.length) return res.status(404).json({ error: 'Device not found' });
        res.json(rows[0]);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// GET /api/devices/user/:user_id — Danh sách thiết bị của 1 user
router.get('/devices/user/:user_id', async (req, res) => {
    try {
        const { rows } = await pool.query(
            `SELECT d.device_id, d.name, d.location, d.is_online, d.last_seen, d.ip_address
             FROM devices d
             JOIN user_devices ud ON ud.device_id = d.device_id
             WHERE ud.user_id = $1
             ORDER BY d.name`,
            [req.params.user_id]
        );
        res.json(rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

const crypto = require('crypto');

function hashPassword(password) {
    const salt = 'smartair_salt_secure_2026';
    return crypto.createHash('sha256').update(password + salt).digest('hex');
}

// POST /api/device/:device_id/share — Sinh mật khẩu tạm để chia sẻ thiết bị
router.post('/device/:device_id/share', async (req, res) => {
    const { device_id } = req.params;
    try {
        // Sinh 6 số ngẫu nhiên làm mật khẩu tạm
        const temp_password = Math.floor(100000 + Math.random() * 900000).toString();
        
        const { rowCount } = await pool.query(
            `UPDATE devices SET temp_password = $1 WHERE device_id = $2`,
            [temp_password, device_id]
        );
        if (!rowCount) {
            return res.status(404).json({ error: 'Không tìm thấy thiết bị.' });
        }
        res.json({ status: 'ok', temp_password });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// POST /api/device/setup-owner — Liên kết SĐT & Đổi mật khẩu mới (chủ sở hữu hoặc chia sẻ)
router.post('/device/setup-owner', async (req, res) => {
    const { device_id, phone, password } = req.body;

    if (!device_id || !phone || !password) {
        return res.status(400).json({ error: 'Thiếu thông tin thiết bị, số điện thoại hoặc mật khẩu.' });
    }

    try {
        // Kiểm tra thiết bị có tồn tại hay không
        const { rows: devRows } = await pool.query(
            'SELECT device_id FROM devices WHERE device_id = $1',
            [device_id]
        );
        if (devRows.length === 0) {
            return res.status(404).json({ error: 'Thiết bị không tồn tại trên hệ thống.' });
        }

        const passwordHash = hashPassword(password);
        const email = `${phone}@smartair.local`;

        // 1. Tạo hoặc cập nhật tài khoản người dùng theo SĐT
        let user_id;
        const { rows: existingUsers } = await pool.query(
            `SELECT user_id FROM users WHERE phone = $1 OR email = $2`,
            [phone, email]
        );

        if (existingUsers.length > 0) {
            user_id = existingUsers[0].user_id;
            // Cập nhật mật khẩu cho tài khoản cũ
            await pool.query(
                `UPDATE users SET password_hash = $1 WHERE user_id = $2`,
                [passwordHash, user_id]
            );
        } else {
            // Tạo tài khoản mới
            const { rows: newUsers } = await pool.query(
                `INSERT INTO users (username, password_hash, email, phone)
                 VALUES ($1, $2, $3, $4)
                 RETURNING user_id`,
                [phone, passwordHash, email, phone]
            );
            user_id = newUsers[0].user_id;
        }

        // 2. Liên kết tài khoản với thiết bị
        await pool.query(
            `INSERT INTO user_devices (user_id, device_id)
             VALUES ($1, $2)
             ON CONFLICT DO NOTHING`,
            [user_id, device_id]
        );

        // 3. Vô hiệu hóa mật khẩu tạm thời của thiết bị
        await pool.query(
            `UPDATE devices SET temp_password = NULL WHERE device_id = $1`,
            [device_id]
        );

        // Lấy thông tin thiết bị vừa liên kết
        const { rows: updatedDevs } = await pool.query(
            `SELECT device_id, name, location, ip_address FROM devices WHERE device_id = $1`,
            [device_id]
        );

        res.json({
            status: 'ok',
            user_id,
            phone,
            email,
            device: updatedDevs[0]
        });
    } catch (err) {
        console.error('[POST /device/setup-owner]', err.message);
        res.status(500).json({ error: 'Lỗi máy chủ trong quá trình liên kết thiết bị.' });
    }
});

// POST /api/device/add — Thêm thiết bị thủ công
router.post('/device/add', async (req, res) => {
    const { device_id, name, location, ip_address, user_id } = req.body;
    if (!device_id || !user_id) {
        return res.status(400).json({ error: 'Thiếu device_id hoặc user_id.' });
    }
    try {
        // Upsert thiết bị
        await pool.query(
            `INSERT INTO devices (device_id, name, location, ip_address)
             VALUES ($1, $2, $3, $4)
             ON CONFLICT (device_id) 
             DO UPDATE SET name = COALESCE(EXCLUDED.name, devices.name), 
                           location = COALESCE(EXCLUDED.location, devices.location), 
                           ip_address = COALESCE(EXCLUDED.ip_address, devices.ip_address)`,
            [device_id, name || 'SmartAir Device', location || 'indoor', ip_address || null]
        );
        // Liên kết thiết bị
        await pool.query(
            `INSERT INTO user_devices (user_id, device_id) VALUES ($1, $2)
             ON CONFLICT DO NOTHING`,
            [user_id, device_id]
        );
        res.json({ status: 'ok', device: { device_id, name, location, ip_address } });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// PUT /api/device/:device_id — Cập nhật thiết bị
router.put('/device/:device_id', async (req, res) => {
    const { name, location, ip_address } = req.body;
    const { device_id } = req.params;
    try {
        const { rowCount } = await pool.query(
            `UPDATE devices 
             SET name = COALESCE($1, name), 
                 location = COALESCE($2, location), 
                 ip_address = COALESCE($3, ip_address) 
             WHERE device_id = $4`,
            [name, location, ip_address, device_id]
        );
        if (!rowCount) return res.status(404).json({ error: 'Device not found' });
        res.json({ status: 'ok' });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// DELETE /api/device/:device_id/user/:user_id — Hủy liên kết thiết bị
router.delete('/device/:device_id/user/:user_id', async (req, res) => {
    const { device_id, user_id } = req.params;
    try {
        const { rowCount } = await pool.query(
            `DELETE FROM user_devices WHERE user_id = $1 AND device_id = $2`,
            [user_id, device_id]
        );
        if (!rowCount) return res.status(404).json({ error: 'Liên kết không tồn tại.' });
        res.json({ status: 'ok' });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

module.exports = router;
