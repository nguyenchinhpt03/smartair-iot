const express = require('express');
const router  = express.Router();
const axios   = require('axios');
const pool    = require('../db/pool');

// POST /api/chat — Chatbox gọi AI Engine
router.post('/chat', async (req, res) => {
    const { device_id, question } = req.body;

    if (!device_id || !question) {
        return res.status(400).json({ error: 'Missing device_id or question' });
    }
    if (question.length > 500) {
        return res.status(400).json({ error: 'Question too long (max 500 chars)' });
    }

    try {
        // Lấy context từ 3 lớp cùng lúc để gửi cho AI
        const [bufResult, hourlyResult, dailyResult] = await Promise.all([
            pool.query(
                `SELECT * FROM readings_buffer
                 WHERE device_id = $1
                 ORDER BY recorded_at DESC LIMIT 1`,
                [device_id]
            ),
            pool.query(
                `SELECT hour_start, aqi_avg, pm25_avg, co2_avg, co_avg, temp_avg, hum_avg
                 FROM hourly_summary
                 WHERE device_id = $1
                 ORDER BY hour_start DESC LIMIT 24`,
                [device_id]
            ),
            pool.query(
                `SELECT report_date, aqi_avg, aqi_max, pm25_avg, co2_avg,
                        pollution_level, main_pollutant, anomaly_count,
                        ai_summary, ai_advice
                 FROM daily_summary
                 WHERE device_id = $1
                 ORDER BY report_date DESC LIMIT 1`,
                [device_id]
            ),
        ]);

        const aiRes = await axios.post(
            `${process.env.AI_ENGINE_URL}/chat`,
            {
                question,
                context: {
                    current: bufResult.rows[0]    || {},
                    hourly:  hourlyResult.rows,
                    daily:   dailyResult.rows[0]  || {},
                },
            },
            { timeout: 15000 }
        );

        res.json({ answer: aiRes.data.answer });
    } catch (err) {
        console.error('[POST /chat]', err.message);
        if (err.code === 'ECONNREFUSED' || err.code === 'ECONNABORTED') {
            return res.status(503).json({ error: 'AI Engine không phản hồi. Thử lại sau.' });
        }
        res.status(500).json({ error: 'Đã xảy ra lỗi khi xử lý câu hỏi.' });
    }
});

module.exports = router;
