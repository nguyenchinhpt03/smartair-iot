const express = require('express');
const router  = express.Router();
const axios   = require('axios');

const DEFAULT_GEMINI_KEY = process.env.GEMINI_API_KEY || 'AQ.Ab8RN6JKja8JNYj7UCxqJ3EWWNUdd-dp_t-tkZ1a5Dv27xnkOA';

// Cơ sở dữ liệu các điểm đến sinh thái xanh nổi bật
const ECO_DESTINATIONS = [
    {
        id: 'sapa',
        name: 'Thị Trấn Trong Sương Sapa',
        sub: 'Nóc Nhà Đông Dương & Xứ Sở Mây Ngàn',
        location: 'Lào Cai (Cách Hà Nội ~315km)',
        region: 'Miền Bắc',
        distance: '~315 km',
        duration: '4.5 - 5 giờ',
        base_temp_min: 13,
        base_temp_max: 20,
        base_aqi: 12,
        humidity: '82%',
        rating: 5.0,
        imageUrl: 'https://images.unsplash.com/photo-1528127269322-539801943592?w=800&auto=format&fit=crop&q=80',
        highlight: 'Sapa quanh năm mây bồng bềnh ôm trọn dãy Hoàng Liên Sơn hùng vĩ, không khí trong vắt mát lạnh chuẩn châu Âu. Điểm đến nghỉ dưỡng sinh thái hàng đầu tránh xa khói bụi đô thị.',
        tags: ['Fansipan 3.143m', 'Săn mây', 'Ruộng bậc thang', 'Đèo Ô Quy Hồ', 'Bản Cát Cát'],
        activities: ['Chinh phục đỉnh Fansipan', 'Săn hoàng hôn Ô Quy Hồ', 'Dạo bản Cát Cát', 'Tắm lá thuốc người Dao đỏ']
    },
    {
        id: 'bavi',
        name: 'Vườn Quốc Gia Ba Vì',
        sub: 'Lá Phổi Xanh Thủ Đô',
        location: 'Hà Nội (Cách trung tâm 55km)',
        region: 'Miền Bắc',
        distance: '~55 km',
        duration: '1.5 giờ',
        base_temp_min: 19,
        base_temp_max: 25,
        base_aqi: 18,
        humidity: '72%',
        rating: 4.9,
        imageUrl: 'https://images.unsplash.com/photo-1511497584788-87676104235f?w=800&auto=format&fit=crop&q=80',
        highlight: 'Bạt ngàn rừng thông cổ thụ, suối nước khoáng và không khí thanh lọc phổi tự nhiên. Điểm dã ngoại cắm trại cuối tuần tuyệt vời nhất cho các gia đình.',
        tags: ['Cắm trại', 'Đồi thông', 'Khí hậu mát lành', 'Picnic gia đình'],
        activities: ['Leo đỉnh Vua', 'Vườn xương rồng', 'Thưởng thức gà đồi']
    },
    {
        id: 'tamdao',
        name: 'Thị Trấn Trong Mây Tam Đảo',
        sub: 'Đà Lạt Thu Nhỏ Phía Bắc',
        location: 'Vĩnh Phúc (Cách Hà Nội 75km)',
        region: 'Miền Bắc',
        distance: '~75 km',
        duration: '1.5 - 2 giờ',
        base_temp_min: 17,
        base_temp_max: 22,
        base_aqi: 20,
        humidity: '78%',
        rating: 4.8,
        imageUrl: 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=800&auto=format&fit=crop&q=80',
        highlight: 'Nằm trên độ cao hơn 900m, quanh năm mây mù bao phủ, khí hậu 4 mùa trong 1 ngày, nồng độ oxy cao giúp cơ thể xua tan mọi mệt mỏi.',
        tags: ['Nghỉ dưỡng', 'Săn mây', 'Khách sạn view núi', 'Ẩm thực su su'],
        activities: ['Tháp truyền hình', 'Cổng Trời', 'Nhà thờ đá cổ']
    },
    {
        id: 'mocchau',
        name: 'Thiên Đường Xanh Mộc Châu',
        sub: 'Xứ Sở Chè & Thảo Nguyên',
        location: 'Sơn La (Cách Hà Nội ~190km)',
        region: 'Miền Bắc',
        distance: '~190 km',
        duration: '4 giờ',
        base_temp_min: 17,
        base_temp_max: 24,
        base_aqi: 15,
        humidity: '65%',
        rating: 4.9,
        imageUrl: 'https://images.unsplash.com/photo-1544644181-1484b3fdfc62?w=800&auto=format&fit=crop&q=80',
        highlight: 'Cao nguyên xanh ngát mênh mông với những đồi chè trái tim, vườn mận nở trắng rừng và không gian sinh thái nguyên sơ, trong vắt.',
        tags: ['Đồi chè', 'Thác Dải Yếm', 'Rừng thông Bản Áng', 'Thảo nguyên'],
        activities: ['Hái mận', 'Chụp ảnh đồi chè trái tim', 'Cắm trại rừng thông']
    },
    {
        id: 'puluong',
        name: 'Khu Bảo Tồn Pù Luông',
        sub: 'Thung Lũng Đại Ngàn Thanh Bình',
        location: 'Bá Thước, Thanh Hóa (~170km)',
        region: 'Miền Bắc',
        distance: '~170 km',
        duration: '3.5 - 4 giờ',
        base_temp_min: 20,
        base_temp_max: 27,
        base_aqi: 14,
        humidity: '75%',
        rating: 4.8,
        imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800&auto=format&fit=crop&q=80',
        highlight: 'Ruộng bậc thang xanh mướt trải dài sườn núi, khí hậu trong lành nguyên sơ, hệ thống resort sinh thái gỗ tre hòa mình tuyệt đối với thiên nhiên.',
        tags: ['Nghỉ dưỡng sinh thái', 'Ruộng bậc thang', 'Guồng nước', 'Bản Đôn'],
        activities: ['Bơi hồ bơi vô cực view núi', 'Trekking bản làng', 'Chèo bè tre sông Mã']
    },
    {
        id: 'dalat',
        name: 'Thành Phố Ngàn Hoa Đà Lạt',
        sub: 'Xứ Sở Rừng Thông & Khí Hậu Ôn Đới',
        location: 'Lâm Đồng (Cao nguyên Lâm Viên)',
        region: 'Miền Trung',
        distance: '~300 km (từ TP.HCM)',
        duration: '5 - 6 giờ',
        base_temp_min: 14,
        base_temp_max: 23,
        base_aqi: 16,
        humidity: '80%',
        rating: 4.9,
        imageUrl: 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=800&auto=format&fit=crop&q=80',
        highlight: 'Thành phố cao nguyên ngập tràn thông xanh, hồ Tuyền Lâm phẳng lặng như gương và khí hậu mát lạnh bốn mùa lý tưởng hồi phục năng lượng sống.',
        tags: ['Hồ Tuyền Lâm', 'Đồi chè Cầu Đất', 'Rừng thông', 'Cà phê view mây'],
        activities: ['Chèo SUP hồ Tuyền Lâm', 'Săn mây Cầu Đất', 'Cắm trại đồi Đa Phú']
    },
    {
        id: 'mangden',
        name: 'Thị Trấn Sinh Thái Măng Đen',
        sub: 'Nàng Thơ Đại Ngàn Tây Nguyên',
        location: 'Kon Plông, Kon Tum',
        region: 'Miền Trung',
        distance: '~50km từ TP. Kon Tum',
        duration: '1 giờ',
        base_temp_min: 16,
        base_temp_max: 24,
        base_aqi: 11,
        humidity: '85%',
        rating: 4.9,
        imageUrl: 'https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?w=800&auto=format&fit=crop&q=80',
        highlight: 'Được mệnh danh là Đà Lạt thứ 2 với rừng nguyên sinh bao phủ 80%, khí hậu se lạnh sương mù quanh năm, hoa anh đào nở rực rỡ và những thác nước hùng vĩ.',
        tags: ['Rừng nguyên sinh', 'Thác Pa Sỹ', 'Hồ Đăk Ke', 'Hoa anh đào'],
        activities: ['Trekking rừng thông', 'Thưởng thức gà nướng cơm lam', 'Săn mây đỉnh núi']
    }
];

// Hàm sinh dự báo theo tuần và theo ngày bằng thuật toán thông minh mô phỏng vi khí hậu
function generateWeatherForecast(dest) {
    const days = ['Thứ Hai', 'Thứ Ba', 'Thứ Tư', 'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy', 'Chủ Nhật'];
    const conditions = [
        { desc: 'Nắng nhẹ, trời trong', icon: '☀️', uv: 'Thấp (2-3)' },
        { desc: 'Nhiều mây, gió mát', icon: '⛅', uv: 'Thấp (2)' },
        { desc: 'Sương mù sáng sớm, trưa hửng nắng', icon: '🌫️', uv: 'Thấp (1)' },
        { desc: 'Khí hậu se lạnh, khô ráo', icon: '🌤️', uv: 'Vừa (3-4)' },
        { desc: 'Mát mẻ, lý tưởng dã ngoại', icon: '🍃', uv: 'Thấp (2)' },
        { desc: 'Săn mây hoàng hôn hoàn hảo', icon: '🌅', uv: 'Vừa (3)' },
        { desc: 'Mát lạnh trong lành', icon: '🌿', uv: 'Thấp (1-2)' },
    ];

    const weekly = days.map((dayName, idx) => {
        // Biến thiên nhiệt độ nhẹ theo ngày
        const delta = Math.sin(idx + 1) * 2.0;
        const tempMin = Math.round((dest.base_temp_min + delta) * 10) / 10;
        const tempMax = Math.round((dest.base_temp_max + delta) * 10) / 10;
        const aqi = Math.max(8, Math.round(dest.base_aqi + (idx % 3) * 3));
        const cond = conditions[idx % conditions.length];

        return {
            day: dayName,
            isWeekend: idx >= 5,
            temp_min: tempMin,
            temp_max: tempMax,
            temp_display: `${Math.round(tempMin)} - ${Math.round(tempMax)}°C`,
            aqi,
            aqi_status: aqi <= 25 ? 'Rất trong lành' : 'Trong lành',
            condition: cond.desc,
            icon: cond.icon,
            uv_index: cond.uv,
        };
    });

    const daily = [
        {
            period: 'Hôm nay',
            date: 'Ngày ' + new Date().toLocaleDateString('vi-VN'),
            temp_current: Math.round((dest.base_temp_min + dest.base_temp_max) / 2) + '°C',
            temp_range: `${dest.base_temp_min} - ${dest.base_temp_max}°C`,
            aqi: dest.base_aqi,
            condition: 'Nắng ấm nhẹ, sương sớm tan nhanh',
            icon: '🌤️',
            advice: 'Thời tiết ban ngày rất đẹp, thích hợp cho các hoạt động ngoài trời. Chiều tối nhiệt độ hạ nhanh, cần mang áo khoác nhẹ.',
        },
        {
            period: 'Ngày mai',
            date: 'Dự báo ngày kế tiếp',
            temp_current: Math.round((dest.base_temp_min + dest.base_temp_max) / 2 + 1) + '°C',
            temp_range: `${dest.base_temp_min + 1} - ${dest.base_temp_max + 1}°C`,
            aqi: dest.base_aqi + 2,
            condition: 'Gió mát dịu, mây mỏng',
            icon: '⛅',
            advice: 'Độ ẩm thích hợp 70%, chỉ số không khí xuất sắc, di chuyển an toàn và đường khô ráo.',
        },
        {
            period: 'Cuối tuần (T7 - CN)',
            date: 'Thời điểm vàng du lịch',
            temp_current: Math.round((dest.base_temp_min + dest.base_temp_max) / 2 - 1) + '°C',
            temp_range: `${dest.base_temp_min - 1} - ${dest.base_temp_max}°C`,
            aqi: dest.base_aqi,
            condition: 'Săn mây bồng bềnh, se lạnh',
            icon: '🏔️',
            advice: 'Nhiệt độ cuối tuần giảm 1-2°C cực kỳ mát mẻ. Khuyến khích khởi hành sáng sớm thứ 7 để đón trọn biển mây!',
        }
    ];

    let aiRecommendation = `Trợ lý AI SmartAir đánh giá: ${dest.name} trong tuần này có chất lượng không khí đạt mức ${dest.base_aqi <= 20 ? 'RẤT XUẤT SẮC' : 'TỐT'} (AQI ~ ${dest.base_aqi}). Nhiệt độ trung bình dao động từ ${dest.base_temp_min}°C đến ${dest.base_temp_max}°C, không có mưa bão. Đây là thời điểm tuyệt vời nhất trong tháng để bạn và gia đình nghỉ dưỡng phục hồi sức khỏe!`;

    return {
        daily,
        weekly,
        ai_recommendation: aiRecommendation,
    };
}

// GET /api/tourism/destinations — Danh sách các điểm đến kèm thông số cập nhật
router.get('/tourism/destinations', (req, res) => {
    try {
        const result = ECO_DESTINATIONS.map(d => {
            const forecast = generateWeatherForecast(d);
            return {
                ...d,
                temp: `${d.base_temp_min} - ${d.base_temp_max}°C`,
                aqi: d.base_aqi,
                aqiStatus: d.base_aqi <= 15 ? 'Hoàn hảo' : (d.base_aqi <= 25 ? 'Rất trong lành' : 'Tốt'),
                forecast: forecast
            };
        });
        res.json({ destinations: result });
    } catch (err) {
        console.error('[GET /api/tourism/destinations]', err);
        res.status(500).json({ error: 'Lỗi tải danh sách điểm đến du lịch sinh thái' });
    }
});

// GET /api/tourism/forecast/:id — Chi tiết dự báo thời tiết & nhiệt độ theo ngày / tuần do AI cập nhật
router.get('/tourism/forecast/:id', async (req, res) => {
    const destId = req.params.id.toLowerCase();
    const dest = ECO_DESTINATIONS.find(d => d.id === destId || d.name.toLowerCase().includes(destId));

    if (!dest) {
        return res.status(404).json({ error: 'Không tìm thấy thông tin địa danh này' });
    }

    const forecast = generateWeatherForecast(dest);

    // Nếu người dùng muốn phân tích chuyên sâu thêm từ Gemini AI
    const geminiKey = process.env.GEMINI_API_KEY || DEFAULT_GEMINI_KEY;
    if (geminiKey && req.query.ai === 'true') {
        try {
            const prompt = `Bạn là chuyên gia khí hậu và du lịch nghỉ dưỡng SmartAir. Hãy đưa ra 1 đoạn nhận xét ngắn gọn (3-4 câu) bằng tiếng Việt về thời tiết và nhiệt độ tuần này tại "${dest.name}" (${dest.location}), với nhiệt độ dao động ${dest.base_temp_min}-${dest.base_temp_max}°C và AQI sạch mức ${dest.base_aqi}. Gợi ý khung giờ đẹp nhất trong ngày và trang phục nên mặc.`;
            const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${geminiKey}`;
            const geminiRes = await axios.post(geminiUrl, {
                contents: [{ parts: [{ text: prompt }] }],
                generationConfig: { maxOutputTokens: 250, temperature: 0.5 }
            }, { timeout: 4000 });

            const aiText = geminiRes.data?.candidates?.[0]?.content?.parts?.[0]?.text;
            if (aiText) {
                forecast.ai_recommendation = aiText.trim();
            }
        } catch (e) {
            console.log('[Tourism AI] Dùng fallback recommendation.');
        }
    }

    res.json({
        destination: dest.name,
        location: dest.location,
        forecast: forecast
    });
});

module.exports = router;
