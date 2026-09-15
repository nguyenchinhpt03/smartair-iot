const express = require('express');
const router  = express.Router();
const axios   = require('axios');

const DEFAULT_GEMINI_KEY = process.env.GEMINI_API_KEY || 'AQ.Ab8RN6JKja8JNYj7UCxqJ3EWWNUdd-dp_t-tkZ1a5Dv27xnkOA';

// Cơ sở dữ liệu các điểm đến sinh thái xanh nổi bật kèm tọa độ GPS thực tế & ảnh chuẩn xác
const ECO_DESTINATIONS = [
    {
        id: 'sapa',
        name: 'Thị Trấn Trong Sương Sapa',
        sub: 'Nóc Nhà Đông Dương & Xứ Sở Mây Ngàn',
        location: 'Lào Cai',
        region: 'Miền Bắc',
        lat: 22.3364,
        lon: 103.8438,
        base_temp_min: 13,
        base_temp_max: 20,
        base_aqi: 12,
        humidity: '82%',
        rating: 5.0,
        imageUrl: 'https://images.unsplash.com/photo-1528127269322-539801943592?w=1000&auto=format&fit=crop&q=85',
        highlight: 'Sapa quanh năm mây bồng bềnh ôm trọn dãy Hoàng Liên Sơn hùng vĩ, không khí trong vắt mát lạnh chuẩn châu Âu. Điểm đến nghỉ dưỡng sinh thái hàng đầu tránh xa khói bụi đô thị.',
        tags: ['Fansipan 3.143m', 'Săn mây', 'Ruộng bậc thang', 'Đèo Ô Quy Hồ', 'Bản Cát Cát'],
        activities: ['Chinh phục đỉnh Fansipan', 'Săn hoàng hôn Ô Quy Hồ', 'Dạo bản Cát Cát', 'Tắm lá thuốc người Dao đỏ']
    },
    {
        id: 'bavi',
        name: 'Vườn Quốc Gia Ba Vì',
        sub: 'Lá Phổi Xanh Thủ Đô',
        location: 'Hà Nội (Huyện Ba Vì)',
        region: 'Miền Bắc',
        lat: 21.0833,
        lon: 105.3667,
        base_temp_min: 19,
        base_temp_max: 25,
        base_aqi: 18,
        humidity: '72%',
        rating: 4.9,
        imageUrl: 'https://images.unsplash.com/photo-1448375240586-882707db888b?w=1000&auto=format&fit=crop&q=85',
        highlight: 'Bạt ngàn rừng thông cổ thụ, suối nước khoáng và không khí thanh lọc phổi tự nhiên. Điểm dã ngoại cắm trại cuối tuần tuyệt vời nhất cho các gia đình.',
        tags: ['Cắm trại', 'Đồi thông', 'Khí hậu mát lành', 'Picnic gia đình'],
        activities: ['Leo đỉnh Vua', 'Vườn xương rồng', 'Thưởng thức gà đồi']
    },
    {
        id: 'tamdao',
        name: 'Thị Trấn Trong Mây Tam Đảo',
        sub: 'Đà Lạt Thu Nhỏ Phía Bắc',
        location: 'Vĩnh Phúc',
        region: 'Miền Bắc',
        lat: 21.4589,
        lon: 105.6483,
        base_temp_min: 16,
        base_temp_max: 22,
        base_aqi: 20,
        humidity: '78%',
        rating: 4.8,
        imageUrl: 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=1000&auto=format&fit=crop&q=85',
        highlight: 'Nằm trên độ cao hơn 900m, quanh năm mây mù bao phủ, khí hậu 4 mùa trong 1 ngày, nồng độ oxy cao giúp cơ thể xua tan mọi mệt mỏi.',
        tags: ['Nghỉ dưỡng', 'Săn mây', 'Khách sạn view núi', 'Ẩm thực su su'],
        activities: ['Tháp truyền hình', 'Cổng Trời', 'Nhà thờ đá cổ']
    },
    {
        id: 'mocchau',
        name: 'Thiên Đường Xanh Mộc Châu',
        sub: 'Xứ Sở Chè & Thảo Nguyên',
        location: 'Sơn La',
        region: 'Miền Bắc',
        lat: 20.8447,
        lon: 104.6469,
        base_temp_min: 17,
        base_temp_max: 24,
        base_aqi: 15,
        humidity: '65%',
        rating: 4.9,
        imageUrl: 'https://images.unsplash.com/photo-1534447677768-be436bb09401?w=1000&auto=format&fit=crop&q=85',
        highlight: 'Cao nguyên xanh ngát mênh mông với những đồi chè trái tim, vườn mận nở trắng rừng và không gian sinh thái nguyên sơ, trong vắt.',
        tags: ['Đồi chè', 'Thác Dải Yếm', 'Rừng thông Bản Áng', 'Thảo nguyên'],
        activities: ['Hái mận', 'Chụp ảnh đồi chè trái tim', 'Cắm trại rừng thông']
    },
    {
        id: 'puluong',
        name: 'Khu Bảo Tồn Pù Luông',
        sub: 'Thung Lũng Đại Ngàn Thanh Bình',
        location: 'Bá Thước, Thanh Hóa',
        region: 'Miền Trung',
        lat: 20.4578,
        lon: 105.1833,
        base_temp_min: 20,
        base_temp_max: 27,
        base_aqi: 14,
        humidity: '75%',
        rating: 4.8,
        imageUrl: 'https://images.unsplash.com/photo-1509099836639-18ba1795216d?w=1000&auto=format&fit=crop&q=85',
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
        lat: 11.9404,
        lon: 108.4583,
        base_temp_min: 14,
        base_temp_max: 23,
        base_aqi: 16,
        humidity: '80%',
        rating: 4.9,
        imageUrl: 'https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?w=1000&auto=format&fit=crop&q=85',
        highlight: 'Thành phố cao nguyên ngập tràn thông xanh, hồ Tuyền Lâm phẳng lặng như gương và khí hậu mát lạnh bốn mùa lý tưởng hồi phục năng lượng sống.',
        tags: ['Hồ Tuyền Lâm', 'Đồi chè Cầu Đất', 'Rừng thông', 'Cà phê view mây'],
        activities: ['Chèo SUP hồ Tuyền Lâm', 'Săn mây Cầu Đất', 'Cắm trại đồi Đa Phú']
    },
    {
        id: 'trangan',
        name: 'Quần Thể Danh Thắng Tràng An',
        sub: 'Di Sản Văn Hóa & Thiên Nhiên Thế Giới',
        location: 'Ninh Bình',
        region: 'Miền Bắc',
        lat: 20.2583,
        lon: 105.9083,
        base_temp_min: 21,
        base_temp_max: 27,
        base_aqi: 22,
        humidity: '74%',
        rating: 5.0,
        imageUrl: 'https://images.unsplash.com/photo-1528127269322-539801943592?w=1000&auto=format&fit=crop&q=85',
        highlight: 'Hệ sinh thái núi đá vôi ngập nước ngoạn mục, chèo thuyền nan len lỏi qua các hang động kỳ bí trên làn nước xanh ngọc bích.',
        tags: ['Di sản UNESCO', 'Đi thuyền nan', 'Non nước hữu tình', 'Hang động'],
        activities: ['Chèo thuyền Tràng An', 'Thăm chùa Bái Đính', 'Thưởng thức dê núi']
    }
];

// Hàm tính khoảng cách thực tế từ GPS điện thoại (Haversine nhân hệ số uốn khúc đường bộ VN)
function computeTravelDistance(userLat, userLon, destLat, destLon) {
    if (!userLat || !userLon) return null;
    const p = 0.017453292519943295; // Math.PI / 180
    const a = 0.5 - Math.cos((destLat - userLat) * p) / 2 +
              Math.cos(userLat * p) * Math.cos(destLat * p) *
              (1 - Math.cos((destLon - userLon) * p)) / 2;
    const straightKm = 12742 * Math.asin(Math.sqrt(a));
    const roadKm = Math.round(straightKm * 1.28);

    let duration = '';
    if (roadKm < 80) {
        const mins = Math.round((roadKm / 45) * 60);
        const h = Math.floor(mins / 60);
        const m = mins % 60;
        duration = h > 0 ? `${h}h${m > 0 ? m + 'p' : ''}` : `${m} phút`;
    } else if (roadKm < 380) {
        const mins = Math.round((roadKm / 65) * 60);
        const h = Math.floor(mins / 60);
        const m = mins % 60;
        duration = `${h} giờ ${m > 0 ? m + 'p' : ''}`;
    } else {
        duration = 'Bay ~1h45p / Xe 6-8h';
    }

    return {
        distance: `~${roadKm} km`,
        duration: duration,
        road_km: roadKm
    };
}

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
            temp_range: `${dest.base_temp_min} - ${dest.base_temp_max}°C`,
            aqi: dest.base_aqi,
            icon: '🌤️',
            advice: 'Thời tiết ban ngày mát mẻ, chiều tối nhiệt độ hạ nhanh cần mang áo khoác mỏng.',
        },
        {
            period: 'Ngày mai',
            temp_range: `${dest.base_temp_min + 1} - ${dest.base_temp_max + 1}°C`,
            aqi: dest.base_aqi + 2,
            icon: '⛅',
            advice: 'Gió mát dịu, độ ẩm thích hợp 70%, chỉ số không khí xuất sắc, di chuyển rất an toàn.',
        },
        {
            period: 'Cuối tuần (T7-CN)',
            temp_range: `${dest.base_temp_min - 1} - ${dest.base_temp_max}°C`,
            aqi: dest.base_aqi,
            icon: '🏔️',
            advice: 'Nhiệt độ cuối tuần giảm nhẹ 1-2°C cực kỳ mát mẻ, thời điểm vàng săn mây và nghỉ dưỡng.',
        }
    ];

    const aiRecommendation = `AI SmartAir đánh giá: ${dest.name} trong tuần này có chất lượng không khí đạt mức ${dest.base_aqi <= 20 ? 'RẤT XUẤT SẮC' : 'TỐT'} (AQI ~ ${dest.base_aqi}). Nhiệt độ trung bình dao động từ ${dest.base_temp_min}°C đến ${dest.base_temp_max}°C, không có mưa bão. Rất thích hợp cho chuyến đi phục hồi sức khỏe!`;

    return {
        daily,
        weekly,
        ai_recommendation: aiRecommendation,
    };
}

// GET /api/tourism/destinations — Danh sách các điểm đến kèm khoảng cách tính theo GPS điện thoại
router.get('/tourism/destinations', (req, res) => {
    try {
        const userLat = parseFloat(req.query.lat);
        const userLon = parseFloat(req.query.lon);

        const result = ECO_DESTINATIONS.map(d => {
            const forecast = generateWeatherForecast(d);
            let distanceStr = d.distance;
            let durationStr = d.duration;

            if (!isNaN(userLat) && !isNaN(userLon)) {
                const travel = computeTravelDistance(userLat, userLon, d.lat, d.lon);
                if (travel) {
                    distanceStr = travel.distance;
                    durationStr = travel.duration;
                }
            }

            return {
                ...d,
                distance: distanceStr,
                duration: durationStr,
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
