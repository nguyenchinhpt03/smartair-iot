const express = require('express');
const router  = express.Router();
const crypto  = require('crypto');
const pool    = require('../db/pool');

// Helper function to hash passwords securely using SHA-256 and a static salt
function hashPassword(password) {
    const salt = 'smartair_salt_secure_2026';
    return crypto.createHash('sha256').update(password + salt).digest('hex');
}

// POST /api/auth/register — Đăng ký tài khoản mới
router.post('/auth/register', async (req, res) => {
    const { username, password, email } = req.body;

    if (!username || !password) {
        return res.status(400).json({ error: 'Vui lòng điền tên đăng nhập và mật khẩu.' });
    }

    try {
        // Kiểm tra username đã tồn tại chưa
        const { rows: existingUser } = await pool.query(
            `SELECT user_id FROM users WHERE username = $1`,
            [username]
        );
        if (existingUser.length > 0) {
            return res.status(400).json({ error: 'Tên đăng nhập đã tồn tại.' });
        }

        // Tạo email mặc định nếu không truyền
        const userEmail = email || `${username}@smartair.local`;

        // Kiểm tra email đã tồn tại chưa
        const { rows: existingEmail } = await pool.query(
            `SELECT user_id FROM users WHERE email = $1`,
            [userEmail]
        );
        if (existingEmail.length > 0) {
            return res.status(400).json({ error: 'Email đã được sử dụng bởi một tài khoản khác.' });
        }

        // Tạo user mới
        const passwordHash = hashPassword(password);
        const { rows: newUser } = await pool.query(
            `INSERT INTO users (username, password_hash, email)
             VALUES ($1, $2, $3)
             RETURNING user_id, username, email`,
            [username, passwordHash, userEmail]
        );

        res.json({
            status: 'ok',
            user_id: newUser[0].user_id,
            username: newUser[0].username,
            email: newUser[0].email
        });
    } catch (err) {
        console.error('[POST /auth/register]', err.message);
        res.status(500).json({ error: 'Lỗi máy chủ trong quá trình đăng ký.' });
    }
});

// POST /api/auth/login — Đăng nhập tài khoản
router.post('/auth/login', async (req, res) => {
    const { username, password } = req.body;

    if (!username || !password) {
        return res.status(400).json({ error: 'Vui lòng điền tên đăng nhập/số điện thoại và mật khẩu.' });
    }

    try {
        // 1. Tìm user theo username/phone/email
        const { rows: users } = await pool.query(
            `SELECT user_id, username, password_hash, email, phone FROM users WHERE username = $1 OR phone = $1 OR email = $1`,
            [username]
        );

        if (users.length > 0) {
            const user = users[0];
            const passwordHash = hashPassword(password);

            if (user.password_hash === passwordHash) {
                // Tìm thiết bị đã liên kết đầu tiên (nếu có)
                const { rows: devices } = await pool.query(
                    `SELECT d.device_id, d.name, d.location
                     FROM devices d
                     JOIN user_devices ud ON ud.device_id = d.device_id
                     WHERE ud.user_id = $1
                     ORDER BY ud.linked_at DESC`,
                    [user.user_id]
                );

                return res.json({
                    user_id: user.user_id,
                    username: user.username,
                    email: user.email,
                    phone: user.phone,
                    device: devices.length > 0 ? devices[0] : null
                });
            }
        }

        // 2. Kiểm tra xem có phải đăng nhập bằng ID + Mật khẩu tạm thiết bị hay không
        const { rows: devices } = await pool.query(
            `SELECT device_id, name, location FROM devices WHERE device_id = $1 AND temp_password = $2`,
            [username, password]
        );

        if (devices.length > 0) {
            return res.json({
                is_temp_login: true,
                device_id: devices[0].device_id,
                device: devices[0]
            });
        }

        return res.status(401).json({ error: 'Thông tin đăng nhập hoặc mật khẩu không chính xác.' });
    } catch (err) {
        console.error('[POST /auth/login]', err.message);
        res.status(500).json({ error: 'Lỗi máy chủ trong quá trình đăng nhập.' });
    }
});

module.exports = router;
