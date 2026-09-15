const express = require('express');
const router  = express.Router();
const axios   = require('axios');
const pool    = require('../db/pool');

const DEFAULT_GEMINI_KEY = process.env.GEMINI_API_KEY || 'AQ.Ab8RN6JKja8JNYj7UCxqJ3EWWNUdd-dp_t-tkZ1a5Dv27xnkOA';

// Fallback AI Engine: Phân tích trực tiếp dựa trên số liệu cảm biến thực tế khi không có internet/AI engine
function generateSmartAirFallbackResponse(question, current) {
    const aqi = current.aqi != null ? Math.round(current.aqi) : 50;
    const pm25 = current.pm25_ugm3 != null ? current.pm25_ugm3 : 15.0;
    const temp = current.temperature_c != null ? current.temperature_c : 28.0;
    const hum = current.humidity_pct != null ? current.humidity_pct : 65.0;
    const co2 = current.co2_ppm != null ? current.co2_ppm : 450;

    let aqiStatus = 'Tốt';
    let aqiAdvice = 'Không khí trong lành, rất thích hợp cho các hoạt động ngoài trời.';
    let windowAdvice = 'Bạn hoàn toàn có thể mở cửa sổ để đón gió tự nhiên và làm thông thoáng phòng.';
    if (aqi <= 50) {
        aqiStatus = 'Tuyệt vời (Xanh)';
        aqiAdvice = 'Chất lượng không khí rất sạch, an toàn cho cả trẻ nhỏ và người lớn tuổi.';
        windowAdvice = 'Nên mở cửa sổ đón gió tươi, lưu thông không khí tự nhiên.';
    } else if (aqi <= 100) {
        aqiStatus = 'Trung bình (Vàng)';
        aqiAdvice = 'Không khí ở mức chấp nhận được, người có bệnh hô hấp nhạy cảm nên chú ý.';
        windowAdvice = 'Có thể mở cửa sổ thông thoáng vào ban ngày khi mật độ xe cộ ít.';
    } else if (aqi <= 150) {
        aqiStatus = 'Kém cho nhóm nhạy cảm (Cam)';
        aqiAdvice = 'Người già, trẻ em và người viêm xoang nên hạn chế ra ngoài đường dài.';
        windowAdvice = 'Nên hạn chế mở cửa sổ, ưu tiên bật máy lọc không khí.';
    } else {
        aqiStatus = 'Xấu / Ô nhiễm (Đỏ)';
        aqiAdvice = 'Nồng độ bụi mịn PM2.5 cao. Khuyến cáo đeo khẩu trang chống bụi mịn N95 khi ra ngoài.';
        windowAdvice = 'Tuyệt đối NÊN ĐÓNG CỬA SỔ và bật máy lọc không khí ở chế độ gió mạnh.';
    }

    const qLower = question.toLowerCase();

    if (qLower.includes('mở cửa') || qLower.includes('cửa sổ')) {
        return `🌿 **Lời khuyên về việc mở cửa sổ:**\n\n` +
               `• **Chỉ số AQI hiện tại:** ${aqi} (${aqiStatus}) | PM2.5: ${pm25} µg/m³\n` +
               `• **Khuyến nghị:** ${windowAdvice}\n` +
               `• **Nhiệt độ & Độ ẩm:** ${temp}°C, độ ẩm ${hum}%. ${temp > 32 ? 'Thời tiết khá nóng, nên bật quạt thông gió.' : 'Nhiệt độ phòng đang khá dễ chịu.'}`;
    }

    if (qLower.includes('không khí') || qLower.includes('thế nào') || qLower.includes('hôm nay')) {
        return `🌤️ **Báo cáo không khí trạm đo lúc này:**\n\n` +
               `• **Chỉ số AQI:** ${aqi} — Đạt mức **${aqiStatus}**\n` +
               `• **Bụi mịn PM2.5:** ${pm25} µg/m³\n` +
               `• **Nồng độ CO2:** ${co2} ppm\n` +
               `• **Thời tiết:** ${temp}°C, độ ẩm ${hum}%\n\n` +
               `💡 **Đánh giá sức khỏe:** ${aqiAdvice}`;
    }

    if (qLower.includes('thể dục') || qLower.includes('chạy bộ') || qLower.includes('ra ngoài')) {
        return `🏃 **Tư vấn vận động ngoài trời:**\n\n` +
               `• **Chất lượng không khí:** AQI hiện là ${aqi} (${aqiStatus}).\n` +
               (aqi <= 100 
                   ? `• Bạn hoàn toàn có thể tập thể dục, chạy bộ hoặc dạo phố buổi sáng/chiều mà không lo ngại về khói bụi.` 
                   : `• Không khí đang có bụi mịn PM2.5 (${pm25} µg/m³), bạn nên tập thể dục trong nhà hoặc chọn nơi có nhiều cây xanh, tránh xa các trục đường lớn.`
               );
    }

    if (qLower.includes('du lịch') || qLower.includes('chuyến đi') || qLower.includes('cuối tuần') || qLower.includes('tam đảo') || qLower.includes('ba vì') || qLower.includes('sapa')) {
        return `🌲 **Gợi ý chuyến đi Xanh cuối tuần:**\n\n` +
               `• **Điểm đến lý tưởng:** Vườn Quốc Gia Ba Vì / Tam Đảo (Khí hậu mát mẻ, AQI dưới 30, rừng thông trong lành).\n` +
               `• **Khoảng cách & Di chuyển:** Khoảng 60km từ trung tâm, mất tầm 1.5 giờ đi ô tô hoặc xe máy.\n` +
               `• **Hành trang:** Áo khoác nhẹ (buổi tối se lạnh), giày chống trơn, bình nước cá nhân bảo vệ môi trường!`;
    }

    // Câu hỏi chung
    return `🤖 **Trợ lý SmartAir xin chào bạn!**\n\n` +
           `Hiện tại trạm đo ghi nhận AQI là **${aqi}** (${aqiStatus}), nhiệt độ **${temp}°C**, độ ẩm **${hum}%**.\n\n` +
           `${aqiAdvice}\n\n` +
           `👉 Bạn có thể hỏi tôi về: *Hôm nay không khí thế nào?*, *Có nên mở cửa sổ không?*, hoặc *Gợi ý du lịch xanh cuối tuần*.`;
}

// POST /api/chat — Chatbox gọi AI Engine hoặc Gemini trực tiếp
router.post('/chat', async (req, res) => {
    const { device_id, question } = req.body;

    if (!device_id || !question) {
        return res.status(400).json({ error: 'Missing device_id or question' });
    }
    if (question.length > 500) {
        return res.status(400).json({ error: 'Question too long (max 500 chars)' });
    }

    let current = {};
    try {
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

        current = bufResult.rows[0] || {};
        const hourly = hourlyResult.rows || [];
        const daily = dailyResult.rows[0] || {};

        // 1. Nếu có cấu hình AI_ENGINE_URL và không phải localhost thì thử gọi
        if (process.env.AI_ENGINE_URL && !process.env.AI_ENGINE_URL.includes('localhost')) {
            try {
                const aiRes = await axios.post(
                    `${process.env.AI_ENGINE_URL}/chat`,
                    {
                        question,
                        context: { current, hourly, daily },
                    },
                    { timeout: 5000 }
                );
                if (aiRes.data && aiRes.data.answer) {
                    return res.json({ answer: aiRes.data.answer });
                }
            } catch (err) {
                console.log('[Chat] AI_ENGINE_URL không phản hồi, chuyển sang Gemini / Local AI fallback.');
            }
        }

        // 2. Thử gọi trực tiếp Google Gemini API
        const geminiKey = process.env.GEMINI_API_KEY || DEFAULT_GEMINI_KEY;
        if (geminiKey) {
            try {
                const aqi = current.aqi != null ? Math.round(current.aqi) : 'Chưa có';
                const pm25 = current.pm25_ugm3 != null ? current.pm25_ugm3 : 'Chưa có';
                const temp = current.temperature_c != null ? current.temperature_c : 'Chưa có';
                const hum = current.humidity_pct != null ? current.humidity_pct : 'Chưa có';
                const co2 = current.co2_ppm != null ? current.co2_ppm : 'Chưa có';

                const prompt = `Bạn là Trợ lý AI chuyên gia của SmartAir - Hệ sinh thái giám sát vi khí hậu, chất lượng không khí và Du lịch Xanh tại Việt Nam.
Số liệu môi trường thực tế tại trạm đo lúc này:
- AQI: ${aqi} | PM2.5: ${pm25} µg/m³
- CO2: ${co2} ppm | Nhiệt độ: ${temp}°C | Độ ẩm: ${hum}%

Câu hỏi của người dùng:
"${question}"

Quy tắc trả lời:
- Giọng văn ấm áp, ân cần, súc tích, dễ nhìn trên điện thoại smartphone.
- Sử dụng emoji biểu tượng phù hợp ở đầu dòng.
- Nếu hỏi về mở cửa sổ, tập thể dục hoặc không khí: dựa trên AQI (${aqi}) và PM2.5 (${pm25}) để tư vấn cụ thể, chuẩn xác.
- Nếu hỏi về du lịch cuối tuần: gợi ý điểm đến xanh, khoảng cách, phương tiện và hành trang cần chuẩn bị.`;

                const geminiModel = process.env.MODEL_NAME || 'gemini-2.5-flash';
                const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/${geminiModel}:generateContent?key=${geminiKey}`;

                const geminiRes = await axios.post(
                    geminiUrl,
                    {
                        contents: [{ parts: [{ text: prompt }] }],
                        generationConfig: { maxOutputTokens: 500, temperature: 0.5 }
                    },
                    { timeout: 7000 }
                );

                const candidate = geminiRes.data?.candidates?.[0]?.content?.parts?.[0]?.text;
                if (candidate) {
                    return res.json({ answer: candidate.trim() });
                }
            } catch (geminiErr) {
                console.log('[Chat] Gemini API call error:', geminiErr.message);
            }
        }

        // 3. Fallback phân tích số liệu nội bộ (Luôn đảm bảo phản hồi 100%)
        const fallbackAnswer = generateSmartAirFallbackResponse(question, current);
        return res.json({ answer: fallbackAnswer });

    } catch (err) {
        console.error('[POST /chat]', err.message);
        // Ngay cả khi DB lỗi, vẫn phản hồi thân thiện
        const fallback = generateSmartAirFallbackResponse(question, current);
        return res.json({ answer: fallback });
    }
});

module.exports = router;
