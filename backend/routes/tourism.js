const express = require('express');
const router  = express.Router();
const axios   = require('axios');

const DEFAULT_GEMINI_KEY = process.env.GEMINI_API_KEY || 'AQ.Ab8RN6JKja8JNYj7UCxqJ3EWWNUdd-dp_t-tkZ1a5Dv27xnkOA';

// Cơ sở dữ liệu hơn 30 khu du lịch sinh thái & danh lam thắng cảnh nổi bật khắp Việt Nam
const ECO_DESTINATIONS = [
    // ── MIỀN BẮC ──
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
        sub: 'Xứ Sở Chè & Thảo Nguyên Bao La',
        location: 'Sơn La',
        region: 'Miền Bắc',
        lat: 20.8447,
        lon: 104.6469,
        base_temp_min: 17,
        base_temp_max: 24,
        base_aqi: 14,
        humidity: '65%',
        rating: 4.9,
        imageUrl: 'https://images.unsplash.com/photo-1534447677768-be436bb09401?w=1000&auto=format&fit=crop&q=85',
        highlight: 'Cao nguyên xanh ngát mênh mông với những đồi chè trái tim, vườn mận nở trắng rừng và không gian sinh thái nguyên sơ, trong vắt.',
        tags: ['Đồi chè', 'Thác Dải Yếm', 'Rừng thông Bản Áng', 'Thảo nguyên'],
        activities: ['Hái mận', 'Chụp ảnh đồi chè trái tim', 'Cắm trại rừng thông']
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
        imageUrl: 'https://images.unsplash.com/photo-1570789210967-2cac24afeb00?w=1000&auto=format&fit=crop&q=85',
        highlight: 'Hệ sinh thái núi đá vôi ngập nước ngoạn mục, chèo thuyền nan len lỏi qua các hang động kỳ bí trên làn nước xanh ngọc bích.',
        tags: ['Di sản UNESCO', 'Đi thuyền nan', 'Non nước hữu tình', 'Hang động'],
        activities: ['Chèo thuyền Tràng An', 'Thăm chùa Bái Đính', 'Thưởng thức dê núi']
    },
    {
        id: 'halong',
        name: 'Vịnh Hạ Long & Vịnh Lan Hạ',
        sub: 'Kỳ Quan Thiên Nhiên Thế Giới UNESCO',
        location: 'Quảng Ninh',
        region: 'Miền Bắc',
        lat: 20.9101,
        lon: 107.1839,
        base_temp_min: 22,
        base_temp_max: 28,
        base_aqi: 18,
        humidity: '76%',
        rating: 5.0,
        imageUrl: 'https://images.unsplash.com/photo-1528127269322-539801943592?w=1000&auto=format&fit=crop&q=85',
        highlight: 'Hàng ngàn đảo đá vôi kỳ vĩ nổi trên mặt biển xanh ngọc, không khí biển thanh mát cùng trải nghiệm du thuyền ngủ đêm 5 sao đẳng cấp thế giới.',
        tags: ['Kỳ quan UNESCO', 'Du thuyền', 'Hang Sửng Sốt', 'Chèo Kayak'],
        activities: ['Ngủ đêm trên du thuyền', 'Chèo kayak luồn hang Luồn', 'Tắm biển đảo Ti Tốp']
    },
    {
        id: 'catba',
        name: 'Quần Đảo Sinh Thái Cát Bà',
        sub: 'Khu Dự Trữ Sinh Quyển Thế Giới',
        location: 'Hải Phòng',
        region: 'Miền Bắc',
        lat: 20.7275,
        lon: 107.0469,
        base_temp_min: 21,
        base_temp_max: 27,
        base_aqi: 16,
        humidity: '79%',
        rating: 4.8,
        imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=1000&auto=format&fit=crop&q=85',
        highlight: 'Hòa quyện giữa rừng nguyên sinh nhiệt đới và biển cả mênh mông, bãi cát trắng mịn và làng chài cổ Cái Bèo bình yên.',
        tags: ['Vườn Quốc Gia', 'Vịnh Lan Hạ', 'Làng chài Cái Bèo', 'Trekking'],
        activities: ['Trekking đỉnh Ngự Lâm', 'Chèo thuyền vịnh Lan Hạ', 'Thăm làng Việt Hải']
    },
    {
        id: 'hagiang',
        name: 'Cao Nguyên Đá Đồng Văn - Hà Giang',
        sub: 'Công Viên Địa Chất Toàn Cầu UNESCO',
        location: 'Hà Giang',
        region: 'Miền Bắc',
        lat: 23.2789,
        lon: 105.3611,
        base_temp_min: 14,
        base_temp_max: 21,
        base_aqi: 10,
        humidity: '70%',
        rating: 5.0,
        imageUrl: 'https://images.unsplash.com/photo-1534447677768-be436bb09401?w=1000&auto=format&fit=crop&q=85',
        highlight: 'Đệ nhất hùng quan đèo Mã Pí Lèng, dòng sông Nho Quế xanh ngọc bích và những vách đá tai mèo trùng điệp hùng vĩ tột cùng.',
        tags: ['Mã Pí Lèng', 'Sông Nho Quế', 'Cột cờ Lũng Cú', 'Hoa tam giác mạch'],
        activities: ['Đi thuyền hẻm Tu Sản', 'Chinh phục Mã Pí Lèng', 'Thăm Dinh Vua Mèo']
    },
    {
        id: 'taxua',
        name: 'Thiên Đường Mây Tà Xùa',
        sub: 'Sống Lưng Khủng Long & Biển Mây Đại Ngàn',
        location: 'Bắc Yên, Sơn La',
        region: 'Miền Bắc',
        lat: 21.2667,
        lon: 104.4500,
        base_temp_min: 12,
        base_temp_max: 18,
        base_aqi: 9,
        humidity: '85%',
        rating: 4.9,
        imageUrl: 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=1000&auto=format&fit=crop&q=85',
        highlight: 'Điểm săn mây đẹp nhất miền Bắc với biển mây cuồn cuộn bao phủ sống lưng khủng long, khí hậu lạnh tinh khiết quanh năm.',
        tags: ['Sống lưng khủng long', 'Biển mây', 'Cây cô đơn', 'Cà phê ngắm mây'],
        activities: ['Săn mây sớm 5h sáng', 'Check-in mỏm cá heo', 'Cắm trại sườn núi']
    },
    {
        id: 'maichau',
        name: 'Thung Lũng Xanh Mai Châu',
        sub: 'Bản Làng Thái Bình Yên Giữa Núi Rừng',
        location: 'Hòa Bình',
        region: 'Miền Bắc',
        lat: 20.6667,
        lon: 105.0833,
        base_temp_min: 19,
        base_temp_max: 26,
        base_aqi: 15,
        humidity: '71%',
        rating: 4.8,
        imageUrl: 'https://images.unsplash.com/photo-1509099836639-18ba1795216d?w=1000&auto=format&fit=crop&q=85',
        highlight: 'Thung lũng đồng lúa mênh mông, nhà sàn gỗ cổ truyền người Thái, đạp xe qua cánh đồng lộng gió và thưởng thức cơm lam thịt nướng.',
        tags: ['Bản Lác', 'Đạp xe đồng lúa', 'Nghỉ dưỡng homestay', 'Văn hóa Thái'],
        activities: ['Đạp xe dạo Bản Lác', 'Múa sạp uống rượu cần', 'Tắm suối khoáng nóng']
    },
    {
        id: 'cucphuong',
        name: 'Vườn Quốc Gia Cúc Phương',
        sub: 'Rừng Nguyên Sinh Đầu Tiên Của Việt Nam',
        location: 'Ninh Bình',
        region: 'Miền Bắc',
        lat: 20.3167,
        lon: 105.6167,
        base_temp_min: 20,
        base_temp_max: 26,
        base_aqi: 11,
        humidity: '80%',
        rating: 4.9,
        imageUrl: 'https://images.unsplash.com/photo-1448375240586-882707db888b?w=1000&auto=format&fit=crop&q=85',
        highlight: 'Hệ sinh thái rừng mưa nhiệt đới bạt ngàn với cây chò ngàn năm, mùa bướm bay rợp trời và trung tâm cứu hộ linh trưởng quý hiếm.',
        tags: ['Mùa bướm', 'Cây chò ngàn năm', 'Trekking rừng', 'Trung tâm linh trưởng'],
        activities: ['Trekking xuyên rừng', 'Xem bướm mùa hạ', 'Cắm trại đêm trong rừng']
    },
    {
        id: 'coto',
        name: 'Thiên Đường Biển Đảo Cô Tô',
        sub: 'Hòn Ngọc Xanh Vịnh Bắc Bộ',
        location: 'Quảng Ninh',
        region: 'Miền Bắc',
        lat: 20.9833,
        lon: 107.7667,
        base_temp_min: 23,
        base_temp_max: 29,
        base_aqi: 12,
        humidity: '77%',
        rating: 4.8,
        imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=1000&auto=format&fit=crop&q=85',
        highlight: 'Nước biển trong vắt nhìn thấu đáy, bãi đá Cầu Mỵ sóng vỗ rì rào và hải sản tươi sống đánh bắt ngay tại bờ biển.',
        tags: ['Bãi đá Cầu Mỵ', 'Bãi tắm Hồng Vàn', 'Hải đăng Cô Tô', 'Đảo Cô Tô Con'],
        activities: ['Đón bình minh Cầu Mỵ', 'Tắm biển Vàn Chảy', 'Cắm trại biển đảo']
    },
    {
        id: 'babe',
        name: 'Vườn Quốc Gia & Hồ Ba Bể',
        sub: 'Viên Ngọc Xanh Giữa Lòng Đại Ngàn',
        location: 'Bắc Kạn',
        region: 'Miền Bắc',
        lat: 22.4083,
        lon: 105.6167,
        base_temp_min: 18,
        base_temp_max: 25,
        base_aqi: 11,
        humidity: '76%',
        rating: 4.8,
        imageUrl: 'https://images.unsplash.com/photo-1528127269322-539801943592?w=1000&auto=format&fit=crop&q=85',
        highlight: 'Hồ nước ngọt tự nhiên trên núi đá vôi lớn nhất Việt Nam, mặt nước phẳng lặng như gương được bao bọc bởi rừng nguyên sinh cổ thụ.',
        tags: ['Hồ Ba Bể', 'Thác Đầu Đẳng', 'Động Puông', 'Chèo thuyền Kayak'],
        activities: ['Đi thuyền độc mộc ngắm hồ', 'Chèo kayak sông Năng', 'Khám phá Động Hua Mạ']
    },
    {
        id: 'bangioc',
        name: 'Thác Bản Giốc & Động Ngườm Ngao',
        sub: 'Thác Nước Tự Nhiên Hùng Vĩ Nhất Đông Nam Á',
        location: 'Trùng Khánh, Cao Bằng',
        region: 'Miền Bắc',
        lat: 22.8539,
        lon: 106.7236,
        base_temp_min: 17,
        base_temp_max: 24,
        base_aqi: 10,
        humidity: '73%',
        rating: 5.0,
        imageUrl: 'https://images.unsplash.com/photo-1534447677768-be436bb09401?w=1000&auto=format&fit=crop&q=85',
        highlight: 'Thác nước ba tầng tung bọt trắng xóa giữa cảnh quan núi non biên cương hùng vĩ, dòng sông Quây Sơn xanh biếc tuyệt mỹ.',
        tags: ['Thác Bản Giốc', 'Sông Quây Sơn', 'Động Ngườm Ngao', 'Hồ Thang Hen'],
        activities: ['Đi bè tre chân thác', 'Khám phá thạch nhũ Ngườm Ngao', 'Chèo SUP sông Quây Sơn']
    },

    // ── MIỀN TRUNG & TÂY NGUYÊN ──
    {
        id: 'puluong',
        name: 'Khu Bảo Tồn Pù Luông',
        sub: 'Thung Lũng Đại Ngàn & Ruộng Bậc Thang',
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
        id: 'phongnha',
        name: 'Vườn Quốc Gia Phong Nha - Kẻ Bàng',
        sub: 'Vương Quốc Hang Động Thế Giới UNESCO',
        location: 'Quảng Bình',
        region: 'Miền Trung',
        lat: 17.5833,
        lon: 106.2833,
        base_temp_min: 22,
        base_temp_max: 29,
        base_aqi: 12,
        humidity: '78%',
        rating: 5.0,
        imageUrl: 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=1000&auto=format&fit=crop&q=85',
        highlight: 'Di sản thiên nhiên thế giới chứa hang Sơn Đoòng lớn nhất hành tinh, động Thiên Đường tráng lệ và sông Chày xanh ngọc bích.',
        tags: ['Hang Sơn Đoòng', 'Động Thiên Đường', 'Sông Chày - Hang Tối', 'Zipline'],
        activities: ['Thám hiểm động Thiên Đường', 'Zipline tắm bùn Hang Tối', 'Chèo thuyền Kayak sông Chày']
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
        id: 'banahills',
        name: 'Khu Sinh Thái Bà Nà Hills & Núi Chúa',
        sub: 'Đường Lên Tiên Cảnh & Cầu Vàng Bàn Tay',
        location: 'Đà Nẵng',
        region: 'Miền Trung',
        lat: 15.9983,
        lon: 107.9867,
        base_temp_min: 17,
        base_temp_max: 24,
        base_aqi: 15,
        humidity: '74%',
        rating: 4.9,
        imageUrl: 'https://images.unsplash.com/photo-1528127269322-539801943592?w=1000&auto=format&fit=crop&q=85',
        highlight: 'Khí hậu ôn đới 4 mùa trong 1 ngày trên đỉnh Núi Chúa cao 1.487m, cây Cầu Vàng vươn mây nổi tiếng toàn cầu.',
        tags: ['Cầu Vàng', 'Cáp treo kỷ lục', 'Làng Pháp', 'Hầm rượu Debay'],
        activities: ['Đi cáp treo ngắm rừng nguyên sinh', 'Check-in Cầu Vàng bình minh', 'Dạo làng Pháp cổ kính']
    },
    {
        id: 'mangden',
        name: 'Thiên Đường Sinh Thái Măng Đen',
        sub: 'Đà Lạt Thứ Hai Của Vùng Đất Tây Nguyên',
        location: 'Kon Plông, Kon Tum',
        region: 'Miền Trung',
        lat: 14.6000,
        lon: 108.2833,
        base_temp_min: 15,
        base_temp_max: 22,
        base_aqi: 10,
        humidity: '82%',
        rating: 4.9,
        imageUrl: 'https://images.unsplash.com/photo-1448375240586-882707db888b?w=1000&auto=format&fit=crop&q=85',
        highlight: 'Cao nguyên rừng thông bạt ngàn hoang sơ, hồ Đăk Ke thơ mộng và thác Pa Sỹ ngập tràn ion âm thanh lọc cơ thể.',
        tags: ['Thác Pa Sỹ', 'Hồ Đăk Ke', 'Rừng thông', 'Vườn hoa anh đào'],
        activities: ['Tản bộ hồ Đăk Ke', 'Thăm thác Pa Sỹ', 'Thưởng thức cơm lam gà nướng']
    },
    {
        id: 'sontra',
        name: 'Bán Đảo Sơn Trà & Đỉnh Bàn Cờ',
        sub: 'Lá Phổi Xanh Của Thành Phố Biển Đà Nẵng',
        location: 'Đà Nẵng',
        region: 'Miền Trung',
        lat: 16.1167,
        lon: 108.2833,
        base_temp_min: 23,
        base_temp_max: 29,
        base_aqi: 14,
        humidity: '72%',
        rating: 4.8,
        imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=1000&auto=format&fit=crop&q=85',
        highlight: 'Rừng nguyên sinh giáp biển bảo tồn loài Voọc chà vá chân nâu quý hiếm, ngắm toàn cảnh vịnh Đà Nẵng từ Đỉnh Bàn Cờ cao vút.',
        tags: ['Voọc chà vá', 'Đỉnh Bàn Cờ', 'Chùa Linh Ứng', 'Cây đa nghìn năm'],
        activities: ['Ngắm Voọc chân nâu', 'Đón hoàng hôn Đỉnh Bàn Cờ', 'Lặn biển Bãi Bụt']
    },
    {
        id: 'culaocham',
        name: 'Khu Dự Trữ Sinh Quyển Cù Lao Chàm',
        sub: 'Hòn Đảo Xanh Không Túi Nilon',
        location: 'Hội An, Quảng Nam',
        region: 'Miền Trung',
        lat: 15.9583,
        lon: 108.5167,
        base_temp_min: 24,
        base_temp_max: 30,
        base_aqi: 11,
        humidity: '75%',
        rating: 4.8,
        imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=1000&auto=format&fit=crop&q=85',
        highlight: 'Đảo biển sinh thái nói không với túi nilon, rạn san hô nguyên sơ đầy sắc màu và hải sản mực một nắng trứ danh.',
        tags: ['Lặn ngắm san hô', 'Đảo sinh thái', 'Bãi Ông', 'Bãi Chồng'],
        activities: ['Đi cano cao tốc vượt sóng', 'Lặn biển ngắm rạn san hô', 'Thăm giếng cổ Chăm Pa']
    },
    {
        id: 'ghenhdadia',
        name: 'Ghềnh Đá Đĩa & Bãi Xép Phú Yên',
        sub: 'Tuyệt Tác Kiến Tạo Địa Chất Độc Nhất Vô Nhị',
        location: 'Tuy An, Phú Yên',
        region: 'Miền Trung',
        lat: 13.3667,
        lon: 109.3000,
        base_temp_min: 24,
        base_temp_max: 31,
        base_aqi: 13,
        humidity: '73%',
        rating: 4.9,
        imageUrl: 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=1000&auto=format&fit=crop&q=85',
        highlight: 'Khối đá bazan hình lục giác xếp lớp đều tăm tắp như tổ ong khổng lồ vươn ra đại dương xanh thẳm, bãi cỏ ngắm hoa vàng trên cỏ xanh.',
        tags: ['Đá đĩa núi lửa', 'Bãi Xép', 'Hải đăng Mũi Điện', 'Đón bình minh sớm nhất'],
        activities: ['Đón bình minh Mũi Đại Lãnh', 'Chụp ảnh Ghềnh Đá Đĩa', 'Thưởng thức mắt cá ngừ đại dương']
    },
    {
        id: 'quynhon',
        name: 'Kỳ Co & Eo Gió Quy Nhơn',
        sub: 'Nơi Ngắm Hoàng Hôn Đẹp Nhất Việt Nam',
        location: 'Quy Nhơn, Bình Định',
        region: 'Miền Trung',
        lat: 13.8833,
        lon: 109.2833,
        base_temp_min: 25,
        base_temp_max: 31,
        base_aqi: 14,
        humidity: '74%',
        rating: 4.8,
        imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=1000&auto=format&fit=crop&q=85',
        highlight: 'Eo biển lộng gió với cung đường đi bộ ven vách núi ngoạn mục, bãi biển Kỳ Co hai màu nước xanh biếc như Maldives thu nhỏ.',
        tags: ['Eo Gió', 'Bãi Kỳ Co', 'Tịnh xá Ngọc Hòa', 'Cano đảo'],
        activities: ['Dạo bước cung đường ven biển Eo Gió', 'Lặn biển Kỳ Co', 'Cắm trại bãi Trung Lương']
    },
    {
        id: 'nhatrang',
        name: 'Vịnh Biển Nha Trang & Vịnh Ninh Vân',
        sub: 'Một Trong Những Vịnh Biển Đẹp Nhất Thế Giới',
        location: 'Khánh Hòa',
        region: 'Miền Trung',
        lat: 12.2388,
        lon: 109.1967,
        base_temp_min: 24,
        base_temp_max: 31,
        base_aqi: 16,
        humidity: '76%',
        rating: 4.9,
        imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=1000&auto=format&fit=crop&q=85',
        highlight: 'Nắng ấm quanh năm, vịnh biển kín gió phẳng lặng, những khu resort sinh thái ẩn mình giữa vách đá và rừng nhiệt đới Ninh Vân.',
        tags: ['Vịnh Ninh Vân', 'Hòn Mun', 'Tắm bùn khoáng', 'Lặn san hô'],
        activities: ['Đi tàu đáy kính ngắm san hô', 'Tắm bùn khoáng nóng I-Resort', 'Nghỉ dưỡng vịnh Ninh Vân']
    },
    {
        id: 'muine',
        name: 'Đồi Cát Bay & Suối Tiên Mũi Né',
        sub: 'Sa Mạc Cát Đỏ Bên Bờ Biển Đông',
        location: 'Phan Thiết, Bình Thuận',
        region: 'Miền Trung',
        lat: 10.9333,
        lon: 108.2833,
        base_temp_min: 25,
        base_temp_max: 32,
        base_aqi: 18,
        humidity: '69%',
        rating: 4.7,
        imageUrl: 'https://images.unsplash.com/photo-1509099836639-18ba1795216d?w=1000&auto=format&fit=crop&q=85',
        highlight: 'Những triền cát mênh mông đổi màu theo từng cơn gió, lướt ván diều trên biển và dòng Suối Tiên cam đỏ kỳ ảo.',
        tags: ['Bàu Trắng', 'Suối Tiên', 'Lướt ván diều', 'Làng chài Mũi Né'],
        activities: ['Lái xe jeep vượt đồi cát Bàu Trắng', 'Lội Suối Tiên', 'Đón bình minh đồi cát đỏ']
    },

    // ── MIỀN NAM & BIỂN ĐẢO ──
    {
        id: 'phuquoc',
        name: 'Đảo Ngọc Sinh Thái Phú Quốc',
        sub: 'Bãi Sao & Vườn Quốc Gia Rừng Nguyên Sinh',
        location: 'Kiên Giang',
        region: 'Miền Nam',
        lat: 10.2899,
        lon: 103.9840,
        base_temp_min: 25,
        base_temp_max: 31,
        base_aqi: 12,
        humidity: '75%',
        rating: 5.0,
        imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=1000&auto=format&fit=crop&q=85',
        highlight: 'Bãi biển cát trắng mịn như kem, làn nước trong vắt cùng rừng quốc gia nguyên sinh chiếm hơn 60% diện tích đảo, bảo tồn hệ sinh thái rừng - biển hoàn hảo.',
        tags: ['Bãi Sao', 'Bãi Kem', 'Hoàng hôn Bãi Trường', 'Cáp treo Hòn Thơm'],
        activities: ['Ngắm sao biển Bãi Rạch Vẹm', 'Lặn ngắm san hô hòn Mây Rút', 'Trekking suối Tranh']
    },
    {
        id: 'condao',
        name: 'Quần Đảo Sinh Thái Côn Đảo',
        sub: 'Khu Bảo Tồn Rùa Biển Lớn Nhất Việt Nam',
        location: 'Bà Rịa - Vũng Tàu',
        region: 'Miền Nam',
        lat: 8.6833,
        lon: 106.6000,
        base_temp_min: 24,
        base_temp_max: 30,
        base_aqi: 8,
        humidity: '77%',
        rating: 5.0,
        imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=1000&auto=format&fit=crop&q=85',
        highlight: 'Chỉ số không khí sạch nhất Việt Nam (AQI ~ 8), biển hoang sơ tuyệt đối, rừng nguyên sinh rậm rạp và trải nghiệm thả rùa con về biển.',
        tags: ['Bảo tồn rùa biển', 'Bãi Nhát', 'Bãi Đầm Trầu', 'Vườn quốc gia Côn Đảo'],
        activities: ['Xem rùa đẻ trứng ban đêm', 'Tắm biển Bãi Đầm Trầu', 'Lặn ngắm rạn san hô Côn Đảo']
    },
    {
        id: 'cangio',
        name: 'Khu Sinh Quyển Rừng Ngập Mặn Cần Giờ',
        sub: 'Lá Phổi Xanh Của Siêu Đô Thị TP. Hồ Chí Minh',
        location: 'TP. Hồ Chí Minh',
        region: 'Miền Nam',
        lat: 10.4167,
        lon: 106.9500,
        base_temp_min: 25,
        base_temp_max: 32,
        base_aqi: 22,
        humidity: '78%',
        rating: 4.7,
        imageUrl: 'https://images.unsplash.com/photo-1448375240586-882707db888b?w=1000&auto=format&fit=crop&q=85',
        highlight: 'Hệ sinh thái rừng đước ngập mặn trù phú được UNESCO công nhận, không khí trong lành chỉ cách trung tâm Sài Gòn hơn 1 giờ di chuyển.',
        tags: ['Rừng sác', 'Đảo khỉ', 'Chiến khu Rừng Sác', 'Chợ hải sản Hàng Dương'],
        activities: ['Đi xuồng máy xuyên rừng đước', 'Thăm đàn khỉ hoang dã', 'Thưởng thức hải sản tươi sống']
    },
    {
        id: 'nuibaden',
        name: 'Khu Du Lịch Núi Bà Đen',
        sub: 'Nóc Nhà Nam Bộ & Quần Thể Tâm Linh Hùng Vĩ',
        location: 'Tây Ninh',
        region: 'Miền Nam',
        lat: 11.3789,
        lon: 106.1667,
        base_temp_min: 22,
        base_temp_max: 29,
        base_aqi: 18,
        humidity: '72%',
        rating: 4.9,
        imageUrl: 'https://images.unsplash.com/photo-1528127269322-539801943592?w=1000&auto=format&fit=crop&q=85',
        highlight: 'Ngọn núi cao nhất miền Nam (986m) với khí hậu mát mẻ trên đỉnh, biển mây cuồn cuộn buổi sớm và tượng Phật Bà bằng đồng kỷ lục châu Á.',
        tags: ['Núi cao 986m', 'Cáp treo hiện đại', 'Săn mây nóc nhà Nam Bộ', 'Tượng Phật Bà'],
        activities: ['Đi cáp treo ngắm biển mây', 'Chiêm bái tượng Phật Bà Tây Bổ Đà Sơn', 'Săn hoàng hôn đỉnh núi']
    },
    {
        id: 'trasu',
        name: 'Rừng Tràm Sinh Thái Trà Sư',
        sub: 'Thảm Bèo Xanh Mướt Mùa Nước Nổi Miền Tây',
        location: 'Thị xã Tịnh Biên, An Giang',
        region: 'Miền Nam',
        lat: 10.5167,
        lon: 105.0500,
        base_temp_min: 25,
        base_temp_max: 32,
        base_aqi: 16,
        humidity: '80%',
        rating: 4.8,
        imageUrl: 'https://images.unsplash.com/photo-1509099836639-18ba1795216d?w=1000&auto=format&fit=crop&q=85',
        highlight: 'Rừng tràm ngập nước đặc trưng Tây Nam Bộ với thảm bèo cám phủ kín mặt nước như tấm thảm nhung khổng lồ, tiếng chim hót rộn ràng.',
        tags: ['Rừng tràm', 'Mùa nước nổi', 'Cầu tre vạn bước', 'Hàng ngàn cánh chim'],
        activities: ['Đi xuồng chèo len lỏi thảm bèo', 'Lên tháp vọng cảnh ngắm chim', 'Thưởng thức lẩu cá linh bông điên điển']
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

// Hàm sinh dự báo theo tuần và theo ngày bằng thuật toán vi khí hậu
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

    const minT = dest.base_temp_min || 20;
    const maxT = dest.base_temp_max || 27;
    const aqiBase = dest.base_aqi || 18;

    const weekly = days.map((dayName, idx) => {
        const delta = Math.sin(idx + 1) * 2.0;
        const tempMin = Math.round((minT + delta) * 10) / 10;
        const tempMax = Math.round((maxT + delta) * 10) / 10;
        const aqi = Math.max(8, Math.round(aqiBase + (idx % 3) * 3));
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
            temp_range: `${minT} - ${maxT}°C`,
            aqi: aqiBase,
            icon: '🌤️',
            advice: 'Thời tiết ban ngày mát mẻ, chiều tối nhiệt độ hạ nhẹ, không khí rất dễ chịu.',
        },
        {
            period: 'Ngày mai',
            temp_range: `${minT + 1} - ${maxT + 1}°C`,
            aqi: aqiBase + 2,
            icon: '⛅',
            advice: 'Gió mát dịu, độ ẩm thích hợp 70%, chỉ số không khí xuất sắc, di chuyển rất an toàn.',
        },
        {
            period: 'Cuối tuần (T7-CN)',
            temp_range: `${minT - 1} - ${maxT}°C`,
            aqi: aqiBase,
            icon: '🏔️',
            advice: 'Nhiệt độ cuối tuần ổn định, thời điểm vàng để dã ngoại và nghỉ dưỡng sinh thái.',
        }
    ];

    const aiRecommendation = `AI SmartAir đánh giá: ${dest.name} có chất lượng không khí đạt mức ${aqiBase <= 20 ? 'RẤT XUẤT SẮC' : 'TỐT'} (AQI ~ ${aqiBase}). Nhiệt độ dao động từ ${minT}°C đến ${maxT}°C, thời tiết ổn định, rất lý tưởng cho chuyến đi trải nghiệm thiên nhiên!`;

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
            let distanceStr = '~150 km';
            let durationStr = 'Xe 2-3h';

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

// GET /api/tourism/search — Tìm kiếm mọi khu du lịch & địa danh như trên bản đồ (OpenStreetMap Geocoding + Danh mục)
router.get('/tourism/search', async (req, res) => {
    try {
        const query = (req.query.q || '').trim();
        const userLat = parseFloat(req.query.lat);
        const userLon = parseFloat(req.query.lon);

        if (!query) {
            return res.json({ destinations: [] });
        }

        const lowerQ = query.toLowerCase();

        // 1. Tìm kiếm trong danh sách cơ sở dữ liệu phong phú
        const matchedLocal = ECO_DESTINATIONS.filter(d => {
            return d.name.toLowerCase().includes(lowerQ) ||
                   d.location.toLowerCase().includes(lowerQ) ||
                   d.sub.toLowerCase().includes(lowerQ) ||
                   d.region.toLowerCase().includes(lowerQ) ||
                   d.tags.some(t => t.toLowerCase().includes(lowerQ));
        });

        const formattedLocal = matchedLocal.map(d => {
            const forecast = generateWeatherForecast(d);
            let distanceStr = '~150 km';
            let durationStr = 'Xe 2-3h';
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
                forecast: forecast,
                is_map_result: false,
            };
        });

        // 2. Nếu danh sách nội bộ có ít hơn 3 kết quả: Tìm kiếm trực tiếp trên Bản đồ OpenStreetMap Nominatim
        let mapResults = [];
        if (formattedLocal.length < 5) {
            try {
                const osmUrl = `https://nominatim.openstreetmap.org/search?q=${encodeURIComponent(query + ' du lịch Việt Nam')}&format=json&countrycodes=vn&limit=5&addressdetails=1`;
                const osmRes = await axios.get(osmUrl, {
                    headers: { 'User-Agent': 'SmartAir-IoT-Environmental-App/2.0' },
                    timeout: 4000,
                });

                if (Array.isArray(osmRes.data)) {
                    for (const place of osmRes.data) {
                        const pLat = parseFloat(place.lat);
                        const pLon = parseFloat(place.lon);
                        if (isNaN(pLat) || isNaN(pLon)) continue;

                        // Kiểm tra nếu tọa độ đã gần với địa điểm nào trong formattedLocal thì bỏ qua
                        const isDuplicate = formattedLocal.some(loc => 
                            Math.abs(loc.lat - pLat) < 0.05 && Math.abs(loc.lon - pLon) < 0.05
                        );
                        if (isDuplicate) continue;

                        const cleanName = (place.name || place.display_name.split(',')[0]).trim();
                        const addressCity = place.address?.state || place.address?.city || place.address?.county || 'Việt Nam';

                        // Ước tính vi khí hậu theo vĩ độ địa lý
                        const isNorth = pLat >= 19.5;
                        const isHighland = pLat >= 11.5 && pLat <= 15.5 && pLon >= 107.5;
                        const baseMin = isNorth ? (isHighland ? 15 : 19) : (isHighland ? 16 : 24);
                        const baseMax = isNorth ? (isHighland ? 22 : 26) : (isHighland ? 23 : 31);
                        const baseAqi = 15;

                        const destObj = {
                            id: `map_${place.osm_id || Math.round(pLat * 1000)}`,
                            name: cleanName,
                            sub: `Địa danh khám phá trên bản đồ: ${addressCity}`,
                            location: place.display_name.split(',').slice(0, 3).join(', '),
                            region: isNorth ? 'Miền Bắc' : (pLat >= 15.0 ? 'Miền Trung' : 'Miền Nam'),
                            lat: pLat,
                            lon: pLon,
                            base_temp_min: baseMin,
                            base_temp_max: baseMax,
                            base_aqi: baseAqi,
                            humidity: '75%',
                            rating: 4.8,
                            imageUrl: 'https://images.unsplash.com/photo-1528127269322-539801943592?w=1000&auto=format&fit=crop&q=85',
                            highlight: `Địa danh ${cleanName} tại ${addressCity} được định vị chuẩn xác qua hệ thống bản đồ vệ tinh GPS. Không khí trong lành, rất thích hợp tham quan và trải nghiệm.`,
                            tags: ['Bản đồ GPS', 'Địa danh thực tế', addressCity, 'Du lịch sinh thái'],
                            activities: ['Tham quan ngắm cảnh', 'Check-in tọa độ GPS', 'Trải nghiệm văn hóa địa phương'],
                        };

                        const forecast = generateWeatherForecast(destObj);
                        let distanceStr = '~150 km';
                        let durationStr = 'Xe 2-3h';
                        if (!isNaN(userLat) && !isNaN(userLon)) {
                            const travel = computeTravelDistance(userLat, userLon, pLat, pLon);
                            if (travel) {
                                distanceStr = travel.distance;
                                durationStr = travel.duration;
                            }
                        }

                        mapResults.push({
                            ...destObj,
                            distance: distanceStr,
                            duration: durationStr,
                            temp: `${baseMin} - ${baseMax}°C`,
                            aqi: baseAqi,
                            aqiStatus: 'Rất trong lành',
                            forecast: forecast,
                            is_map_result: true,
                        });
                    }
                }
            } catch (osmErr) {
                console.log('[OSM Search fallback]', osmErr.message);
            }
        }

        const combined = [...formattedLocal, ...mapResults];
        res.json({ destinations: combined });
    } catch (err) {
        console.error('[GET /api/tourism/search]', err);
        res.status(500).json({ error: 'Lỗi tìm kiếm địa điểm du lịch' });
    }
});

// GET /api/tourism/forecast/:id — Chi tiết dự báo thời tiết & nhiệt độ theo ngày / tuần
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
