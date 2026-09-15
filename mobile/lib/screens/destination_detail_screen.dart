import 'package:flutter/material.dart';

// Extended details for destinations
final Map<String, Map<String, dynamic>> _destinationExtras = {
  'Thị Trấn Trong Sương Sapa': {
    'heroDesc':
        'Sapa – "Nóc nhà Đông Dương" giữa dãy Hoàng Liên Sơn hùng vĩ, nơi hội tụ những thửa ruộng bậc thang kỳ vĩ nhất thế giới, biển mây bồng bềnh và không khí trong lành mát lạnh quanh năm.',
    'gallery': [
      'https://images.unsplash.com/photo-1528127269322-539801943592?w=800&auto=format&fit=crop&q=80',
      'https://images.unsplash.com/photo-1509099836639-18ba1795216d?w=800&auto=format&fit=crop&q=80',
      'https://images.unsplash.com/photo-1570789210967-2cac24afeb00?w=800&auto=format&fit=crop&q=80',
      'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=800&auto=format&fit=crop&q=80',
    ],
    'galleryCaptions': [
      'Thung lũng Mường Hoa ruộng bậc thang thơ mộng',
      'Đỉnh Fansipan 3.143m ngập tràn biển mây',
      'Bản Cát Cát cổ kính bên dòng suối Tiên Sa',
      'Hoàng hôn rực rỡ trên đèo Ô Quy Hồ',
    ],
    'distanceKm': '315 km',
    'durationHours': '4.5 - 5 giờ',
    'departure': 'Hà Nội',
    'highlights': [
      {
        'emoji': '🏔️',
        'title': 'Đỉnh Fansipan (3.143m)',
        'desc':
            'Chinh phục "Nóc nhà Đông Dương" bằng cáp treo 3 dây đạt kỷ lục thế giới, săn biển mây cuồn cuộn.',
      },
      {
        'emoji': '🌾',
        'title': 'Thung Lũng Mường Hoa',
        'desc':
            'Ruộng bậc thang kỳ vĩ uốn lượn bên dòng suối Hoa thơ mộng, đẹp nao lòng bốn mùa.',
      },
      {
        'emoji': '🌅',
        'title': 'Đèo Ô Quy Hồ (Cổng Trời)',
        'desc':
            'Một trong "Tứ đại đỉnh đèo" Việt Nam, địa điểm săn hoàng hôn và biển mây đẹp nhất Tây Bắc.',
      },
      {
        'emoji': '🏞️',
        'title': 'Bản Cát Cát Người H\'Mông',
        'desc':
            'Bản làng cổ kính với guồng nước gỗ khổng lồ, cầu treo và thác nước Tiên Sa tuyệt đẹp.',
      },
      {
        'emoji': '🍲',
        'title': 'Ẩm Thực Vùng Cao Tây Bắc',
        'desc':
            'Lẩu cá hồi Sapa tươi sống, thịt lợn cắp nách nướng than hoa, rau mầm đá và cơm lam.',
      },
    ],
    'routeSteps': [
      {
        'icon': '🚗',
        'step': 'Chặng 1: Hà Nội → Nút giao CT05 (Nội Bài)',
        'detail':
            'Từ nội thành theo cầu Nhật Tân ra cao tốc Hà Nội - Lào Cai (~30km, 40 phút).',
      },
      {
        'icon': '🛣️',
        'step': 'Chặng 2: Cao tốc CT05 → TP. Lào Cai',
        'detail':
            'Chạy thẳng trên cao tốc 4 làn (~245km, 3h15). Có trạm dừng chân Km117 & Km171 rất tiện lợi.',
      },
      {
        'icon': '⛰️',
        'step': 'Chặng 3: TP. Lào Cai → Thị trấn Sapa',
        'detail':
            'Theo QL4D leo đèo lên Sapa (~35km, 50 phút). Đường nhựa êm ái, ngắm trọn núi non hùng vĩ.',
      },
    ],
    'transports': [
      {
        'type': 'Ô tô riêng / Tự lái',
        'cost': 'Phí cao tốc ETC ~300.000đ',
        'tip':
            'Lái xe êm ái, chủ động thời gian dừng chân chụp ảnh tại các cung đèo hùng vĩ.',
      },
      {
        'type': 'Xe Limousine VIP Giường Nằm',
        'cost': '250.000đ - 380.000đ / vé',
        'tip':
            'Đón tại nội thành Hà Nội, trả tận khách sạn Sapa. Đi đêm ngủ một giấc sáng tới nơi.',
      },
      {
        'type': 'Tàu hỏa du lịch',
        'cost': '350.000đ - 650.000đ / giường',
        'tip':
            'Khoang giường nằm êm ái đến ga Lào Cai, sau đó trung chuyển 45 phút xe bus lên Sapa.',
      },
    ],
    'itinerary': [
      {
        'time': 'Thứ Bảy – 05:30',
        'activity':
            'Khởi hành từ Hà Nội theo cao tốc Nội Bài - Lào Cai. Đến Sapa ~10:30, check-in khách sạn view núi.',
      },
      {
        'time': 'Thứ Bảy – 11:30',
        'activity':
            'Thưởng thức lẩu cá hồi, gà nướng tiêu rừng tại trung tâm thị trấn.',
      },
      {
        'time': 'Thứ Bảy – 13:30',
        'activity':
            'Đi cáp treo lên đỉnh Fansipan 3.143m, dạo bước qua quần thể tâm linh và săn mây.',
      },
      {
        'time': 'Thứ Bảy – 16:30',
        'activity': 'Chạy xe lên Cổng trời đèo Ô Quy Hồ ngắm hoàng hôn rực rỡ.',
      },
      {
        'time': 'Thứ Bảy – 19:30',
        'activity':
            'Dạo chợ đêm Sapa, thưởng thức xiên que nướng hạt dổi và tắm lá thuốc người Dao đỏ.',
      },
      {
        'time': 'Chủ Nhật – 07:30',
        'activity':
            'Thức dậy đón bình minh trong sương sớm, ăn sáng phở cốn sủi hoặc bánh cuốn nóng.',
      },
      {
        'time': 'Chủ Nhật – 08:30',
        'activity':
            'Khám phá Bản Cát Cát hoặc thung lũng Mường Hoa, chụp ảnh ruộng bậc thang.',
      },
      {
        'time': 'Chủ Nhật – 14:00',
        'activity':
            'Mua quà đặc sản (nấm hương rừng, thịt trâu gác bếp, hạt dẻ) và lên xe về Hà Nội.',
      },
    ],
    'packingList': [
      'Áo ấm giữ nhiệt dày / áo khoác gió (đêm nhiệt độ xuống 10-14°C)',
      'Giày trekking hoặc giày thể thao êm chân, chống trơn trượt',
      'Thuốc chống say xe đèo dốc và kem chống muỗi, xịt côn trùng',
      'Sạc dự phòng dung lượng lớn & gậy selfie/máy ảnh',
      'Giấy tờ tùy thân (CCCD/Hộ chiếu) để check-in khách sạn và đi cáp treo',
      'Khăn choàng ấm, mũ len, kính râm chống chói nắng đèo',
    ],
  },
  'Vườn Quốc Gia Ba Vì': {
    'heroDesc':
        'Lá phổi xanh khổng lồ phía Tây Hà Nội với bạt ngàn rừng thông cổ thụ, không khí trong lành thanh lọc phổi tự nhiên, là điểm dã ngoại picnic cuối tuần lý tưởng nhất cho gia đình.',
    'gallery': [
      'https://images.unsplash.com/photo-1511497584788-87676104235f?w=800&auto=format&fit=crop&q=80',
      'https://images.unsplash.com/photo-1448375240586-882707db888b?w=800&auto=format&fit=crop&q=80',
    ],
    'galleryCaptions': [
      'Đồi thông Ba Vì xanh mướt ngập tràn oxy',
      'Đường lên đỉnh núi uốn lượn mờ sương',
    ],
    'distanceKm': '55 km',
    'durationHours': '1.5 giờ',
    'departure': 'Hà Nội',
    'highlights': [
      {
        'emoji': '🌲',
        'title': 'Rừng Thông Cốt 400',
        'desc':
            'Địa điểm lý tưởng dựng lều cắm trại, nướng BBQ và thư giãn giữa tiếng thông reo rì rào.',
      },
      {
        'emoji': '👑',
        'title': 'Đỉnh Vua (1.296m)',
        'desc':
            'Nơi tọa lạc Đền thờ Bác Hồ trên đỉnh cao nhất dãy Ba Vì, tầm nhìn bao trọn đồng bằng Bắc Bộ.',
      },
      {
        'emoji': '🌵',
        'title': 'Nhà Kính Xương Rồng',
        'desc':
            'Bộ sưu tập hơn 1.200 giống xương rồng kỳ lạ bên trong kiến trúc nhà kính vòm kính độc đáo.',
      },
    ],
    'routeSteps': [
      {
        'icon': '🚗',
        'step': 'Chặng 1: Đại lộ Thăng Long → Cầu Yên Bài',
        'detail':
            'Từ Trung tâm Hội nghị Quốc Gia chạy hết Đại lộ Thăng Long (~30km, 30 phút).',
      },
      {
        'icon': '🌲',
        'step': 'Chặng 2: Đường 87 → Cổng Vườn Quốc Gia',
        'detail':
            'Rẽ vào đường TL87 theo biển chỉ dẫn đến cổng Vườn Quốc Gia Ba Vì (~25km, 35 phút).',
      },
    ],
    'transports': [
      {
        'type': 'Ô tô gia đình / Tự lái',
        'cost': 'Vé vào cổng 60.000đ / người lớn',
        'tip':
            'Đường dốc quanh co cốt 400-1100, nên đi số thấp và giữ khoảng cách an toàn.',
      },
      {
        'type': 'Xe máy dã ngoại',
        'cost': 'Xăng xe ~100.000đ',
        'tip':
            'Thích hợp cho các bạn trẻ thích phượt ngắm cảnh rừng thông mát lạnh.',
      },
    ],
    'itinerary': [
      {
        'time': 'Thứ Bảy – 07:00',
        'activity': 'Khởi hành từ Hà Nội, ăn sáng phở trên đường đi.',
      },
      {
        'time': 'Thứ Bảy – 08:45',
        'activity':
            'Tới cổng vườn, mua vé và lái xe lên đồi thông Cốt 400 dựng lều picnic.',
      },
      {
        'time': 'Thứ Bảy – 11:30',
        'activity':
            'Tiệc BBQ ngoài trời giữa rừng thông, thưởng thức gà đồi nướng và sữa chua Ba Vì.',
      },
      {
        'time': 'Thứ Bảy – 14:00',
        'activity':
            'Tham quan Nhà thờ Đổ cổ kính và check-in Vườn Xương Rồng huyền bí.',
      },
      {
        'time': 'Thứ Bảy – 16:30',
        'activity':
            'Thu dọn hành lý, mua sữa chua và sữa tươi Ba Vì mang về làm quà.',
      },
    ],
    'packingList': [
      'Lều trại dã ngoại, thảm trải picnic, bạt chống nước',
      'Đồ ăn nhẹ BBQ chuẩn bị sẵn, than củi nướng không khói',
      'Bình xịt chống côn trùng, thuốc bôi muỗi đốt cho trẻ em',
      'Áo khoác nhẹ (nhiệt độ trên đỉnh thường thấp hơn 4-6°C)',
      'Túi đựng rác để giữ gìn vệ sinh môi trường rừng',
    ],
  },
  'Thị Trấn Trong Mây Tam Đảo': {
    'heroDesc':
        'Nằm trên độ cao 900m, Tam Đảo như một Đà Lạt thu nhỏ phía Bắc với khí hậu 4 mùa trong 1 ngày, nồng độ oxy cao giúp giải tỏa mọi âu lo căng thẳng.',
    'gallery': [
      'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=800&auto=format&fit=crop&q=80',
      'https://images.unsplash.com/photo-1544644181-1484b3fdfc62?w=800&auto=format&fit=crop&q=80',
    ],
    'galleryCaptions': [
      'Lâu đài Tam Đảo cổ kính trong sương mù',
      'Cổng trời ngắm mây vờn đỉnh núi',
    ],
    'distanceKm': '75 km',
    'durationHours': '1.5 - 2 giờ',
    'departure': 'Hà Nội',
    'highlights': [
      {
        'emoji': '🏰',
        'title': 'Lâu Đài Tam Đảo & Quảng Trường',
        'desc':
            'Kiến trúc Gothic châu Âu huyền ảo giữa biển mây, biểu tượng của thị trấn sương mù.',
      },
      {
        'emoji': '☁️',
        'title': 'Cổng Trời & Thác Bạc',
        'desc':
            'Điểm săn mây đỉnh cao và ngắm nhìn toàn cảnh thị trấn từ trên cao.',
      },
      {
        'emoji': '🥬',
        'title': 'Ẩm Thực Đọt Su Su',
        'desc':
            'Rau su su xào tỏi giòn ngọt đặc sản, thịt lợn bản nướng xiên lá móc mật thơm lừng.',
      },
    ],
    'routeSteps': [
      {
        'icon': '🚗',
        'step': 'Chặng 1: Hà Nội → Cao tốc Nội Bài - Lào Cai',
        'detail': 'Rẽ ra nút giao IC4 Tam Dương (Vĩnh Phúc) (~50km, 45 phút).',
      },
      {
        'icon': '⛰️',
        'step': 'Chặng 2: Dốc Đèo Tam Đảo',
        'detail':
            'Chinh phục cung đèo 13km dốc quanh co lên thị trấn Tam Đảo (~25km, 45 phút).',
      },
    ],
    'transports': [
      {
        'type': 'Ô tô riêng',
        'cost': 'Phí cao tốc ~50.000đ',
        'tip':
            'Đoạn đèo 13km khá dốc, kiểm tra phanh và đi số thấp (D1/D2 hoặc S).',
      },
      {
        'type': 'Xe Limousine đưa đón',
        'cost': '130.000đ - 160.000đ / vé',
        'tip':
            'Đón tận nhà tại Hà Nội, đưa đến khách sạn tại Tam Đảo, không lo say xe.',
      },
    ],
    'itinerary': [
      {
        'time': 'Thứ Bảy – 07:30',
        'activity':
            'Khởi hành từ Hà Nội, đến Tam Đảo lúc 09:30, check-in quán cafe săn mây.',
      },
      {
        'time': 'Thứ Bảy – 12:00',
        'activity':
            'Ăn trưa đặc sản đọt su su xào tỏi, gà đồi bọc đất nướng than hoa.',
      },
      {
        'time': 'Thứ Bảy – 14:30',
        'activity': 'Check-in Nhà thờ đá cổ kính và Quảng trường trung tâm.',
      },
      {
        'time': 'Thứ Bảy – 18:30',
        'activity': 'Thưởng thức đồ nướng bên đường phố mù sương se lạnh.',
      },
      {
        'time': 'Chủ Nhật – 08:00',
        'activity':
            'Leo tháp truyền hình hoặc ghé Thác Bạc tận hưởng không khí tinh khiết.',
      },
      {
        'time': 'Chủ Nhật – 14:00',
        'activity':
            'Mua ngọn su su tươi ngon tại chợ Tam Đảo rồi trở về Hà Nội.',
      },
    ],
    'packingList': [
      'Áo khoác gió hoặc áo cardigan mỏng (nhiệt độ về đêm hạ sâu 15-18°C)',
      'Giày đi bộ đế bám tốt để dạo bộ bậc thang nhà thờ đá',
      'Kem chống nắng và thuốc nhỏ mắt (độ ẩm cao tạo sương mù)',
      'Pin sạc dự phòng cho điện thoại chụp ảnh mây bay',
    ],
  },
};

class DestinationDetailScreen extends StatefulWidget {
  final Map<String, dynamic> destination;

  const DestinationDetailScreen({super.key, required this.destination});

  @override
  State<DestinationDetailScreen> createState() =>
      _DestinationDetailScreenState();
}

class _DestinationDetailScreenState extends State<DestinationDetailScreen> {
  int _currentPhotoIndex = 0;
  final PageController _pageController = PageController();

  Map<String, dynamic> _getExtendedData() {
    final name = widget.destination['name'] as String? ?? '';
    for (final entry in _destinationExtras.entries) {
      if (name.contains(entry.key) || entry.key.contains(name)) {
        return entry.value;
      }
    }
    // Fallback data
    return {
      'heroDesc': widget.destination['highlight'] ??
          'Điểm du lịch sinh thái tuyệt đẹp với không khí trong lành.',
      'gallery': [
        widget.destination['imageUrl'] ??
            'https://images.unsplash.com/photo-1528127269322-539801943592?w=800&auto=format&fit=crop&q=80',
      ],
      'galleryCaptions': ['Cảnh quan thiên nhiên thơ mộng'],
      'distanceKm': widget.destination['distance'] ?? '~100 km',
      'durationHours': widget.destination['duration'] ?? '2 giờ',
      'departure': 'Trung tâm',
      'highlights': [
        {
          'emoji': '🌿',
          'title': 'Không khí trong lành',
          'desc': 'Chỉ số AQI xuất sắc giúp hồi phục thể trạng và hô hấp.',
        },
        {
          'emoji': '📸',
          'title': 'Check-in tuyệt đẹp',
          'desc': 'Nhiều góc ảnh thiên nhiên xanh mướt hút mắt.',
        },
      ],
      'routeSteps': [
        {
          'icon': '🚗',
          'step': 'Xuất phát theo tuyến đường chính',
          'detail':
              'Đi theo chỉ dẫn cao tốc hoặc quốc lộ hướng dẫn bởi bản đồ.',
        },
      ],
      'transports': [
        {
          'type': 'Ô tô riêng / Taxi dịch vụ',
          'cost': 'Theo cước đường bộ',
          'tip': 'Chủ động thời gian và lịch trình cùng gia đình.',
        },
      ],
      'itinerary': [
        {
          'time': 'Thứ Bảy – 07:30',
          'activity': 'Khởi hành chuyến đi, ăn sáng trên đường.',
        },
        {
          'time': 'Thứ Bảy – 11:30',
          'activity': 'Đến nơi, thưởng thức ẩm thực địa phương và nghỉ ngơi.',
        },
      ],
      'packingList': [
        'Trang phục thoáng mát kèm áo khoác nhẹ',
        'Giày thể thao êm chân',
        'Thuốc men y tế cơ bản và sạc dự phòng',
      ],
    };
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dest = widget.destination;
    final extra = _getExtendedData();
    final gallery = (extra['gallery'] as List<dynamic>?)?.cast<String>() ??
        [dest['imageUrl'] as String];
    final captions =
        (extra['galleryCaptions'] as List<dynamic>?)?.cast<String>() ?? [];
    final highlights =
        (extra['highlights'] as List<dynamic>?)?.cast<Map<String, String>>() ??
            [];
    final routeSteps =
        (extra['routeSteps'] as List<dynamic>?)?.cast<Map<String, String>>() ??
            [];
    final transports =
        (extra['transports'] as List<dynamic>?)?.cast<Map<String, String>>() ??
            [];
    final itinerary =
        (extra['itinerary'] as List<dynamic>?)?.cast<Map<String, String>>() ??
            [];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      body: CustomScrollView(
        slivers: [
          // ── Sliver App Bar with Image Carousel ──
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: const Color(0xFF004D40),
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  shape: BoxShape.circle,
                ),
                child:
                    const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.share_outlined,
                      color: Colors.white, size: 20),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Đã chia sẻ chuyến đi ${dest['name']}!')),
                  );
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  PageView.builder(
                    controller: _pageController,
                    itemCount: gallery.length,
                    onPageChanged: (i) =>
                        setState(() => _currentPhotoIndex = i),
                    itemBuilder: (_, index) {
                      return Image.network(
                        gallery[index],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFF004D40),
                          child: const Icon(Icons.landscape,
                              size: 80, color: Colors.white54),
                        ),
                      );
                    },
                  ),
                  // Gradient shadow
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.35),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.8),
                          ],
                          stops: const [0.0, 0.4, 1.0],
                        ),
                      ),
                    ),
                  ),
                  // Caption & Dots
                  Positioned(
                    bottom: 16,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (captions.isNotEmpty &&
                            _currentPhotoIndex < captions.length)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              captions[_currentPhotoIndex],
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12),
                            ),
                          ),
                        const SizedBox(height: 8),
                        Row(
                          children: List.generate(
                            gallery.length,
                            (idx) => AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              margin: const EdgeInsets.only(right: 6),
                              width: idx == _currentPhotoIndex ? 22 : 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: idx == _currentPhotoIndex
                                    ? const Color(0xFF00BFA5)
                                    : Colors.white54,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Body content ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Location
                  Text(
                    dest['name'] ?? '',
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF00382E)),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 16, color: Color(0xFF00796B)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          dest['location'] ?? '',
                          style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Metrics Row (AQI, Temp, Humidity, Distance, Duration)
                  _buildMetricsRow(dest, extra),
                  const SizedBox(height: 20),

                  // Hero Description
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 3)),
                      ],
                    ),
                    child: Text(
                      extra['heroDesc'] ?? '',
                      style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade800,
                          height: 1.55),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Section AI: Dự báo vi khí hậu & Nhiệt độ do AI cập nhật
                  _buildAIWeatherForecastCard(dest),
                  const SizedBox(height: 24),

                  // Section 1: Highlights
                  _sectionHeader(
                      'Cảnh quan & Trải nghiệm nổi bật', Icons.star_rounded),
                  const SizedBox(height: 12),
                  ...highlights.map((h) => _buildHighlightCard(h)),
                  const SizedBox(height: 24),

                  // Section 2: Route & Directions
                  _sectionHeader(
                      'Chỉ dẫn lộ trình di chuyển', Icons.route_rounded),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 3)),
                      ],
                    ),
                    child: Column(
                      children: routeSteps
                          .map((s) => _buildRouteStepItem(s))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Section 3: Transport options
                  _sectionHeader('Phương tiện di chuyển gợi ý',
                      Icons.directions_car_rounded),
                  const SizedBox(height: 12),
                  ...transports.map((t) => _buildTransportCard(t)),
                  const SizedBox(height: 24),

                  // Section 4: 2D1N Itinerary
                  _sectionHeader('Gợi ý lịch trình 2 Ngày 1 Đêm',
                      Icons.calendar_month_rounded),
                  const SizedBox(height: 12),
                  ...itinerary.map((it) => _buildItineraryCard(it)),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomCTA(context, dest),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF00796B), size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF004D40)),
        ),
      ],
    );
  }

  Widget _buildAIWeatherForecastCard(Map<String, dynamic> dest) {
    final weeklyForecast = dest['weekly_forecast'] as List<dynamic>? ??
        (dest['forecast'] != null && dest['forecast']['weekly'] != null
            ? dest['forecast']['weekly'] as List<dynamic>
            : [
                {
                  'day': 'Thứ 2',
                  'temp': '16 - 21°C',
                  'icon': '🌤️',
                  'cond': 'Nắng nhẹ'
                },
                {
                  'day': 'Thứ 3',
                  'temp': '15 - 20°C',
                  'icon': '⛅',
                  'cond': 'Mây mỏng'
                },
                {
                  'day': 'Thứ 4',
                  'temp': '16 - 22°C',
                  'icon': '☀️',
                  'cond': 'Hửng nắng'
                },
                {
                  'day': 'Thứ 5',
                  'temp': '15 - 21°C',
                  'icon': '🍃',
                  'cond': 'Gió mát'
                },
                {
                  'day': 'Thứ 6',
                  'temp': '14 - 20°C',
                  'icon': '🌿',
                  'cond': 'Khí hậu dịu'
                },
                {
                  'day': 'Thứ 7',
                  'temp': '13 - 19°C',
                  'icon': '🏔️',
                  'cond': 'Săn mây đẹp'
                },
                {
                  'day': 'Chủ Nhật',
                  'temp': '14 - 20°C',
                  'icon': '🌅',
                  'cond': 'Hoàng hôn'
                },
              ]);

    final dailyForecast = dest['daily_forecast'] as List<dynamic>? ??
        (dest['forecast'] != null && dest['forecast']['daily'] != null
            ? dest['forecast']['daily'] as List<dynamic>
            : [
                {
                  'period': 'Hôm nay',
                  'temp': '16 - 21°C',
                  'icon': '🌤️',
                  'advice': 'Khí hậu mát mẻ, cần áo ấm nhẹ vào buổi tối.'
                },
                {
                  'period': 'Ngày mai',
                  'temp': '15 - 20°C',
                  'icon': '⛅',
                  'advice': 'Độ ẩm 75%, sáng sớm có sương mù đẹp mắt.'
                },
                {
                  'period': 'Cuối tuần (T7-CN)',
                  'temp': '13 - 19°C',
                  'icon': '🏔️',
                  'advice': 'Thời điểm vàng săn mây và nghỉ dưỡng!'
                },
              ]);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF80CBC4), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF004D40).withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.auto_awesome, color: Color(0xFF00796B), size: 18),
                  SizedBox(width: 6),
                  Text(
                    'Dự báo vi khí hậu & Nhiệt độ (AI)',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF004D40),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2F1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Cập nhật tự động',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00796B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Lời khuyên của AI
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('💡', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'AI SmartAir nhận định: Điểm đến có khí hậu ôn hòa quanh năm. Cuối tuần nhiệt độ có xu hướng giảm 2°C, độ ẩm lý tưởng 70-80%, hoàn hảo cho các hoạt động săn mây, dã ngoại và cắm trại ngoài trời.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade900,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Dự báo theo tuần 7 ngày
          const Text(
            'Dự báo nhiệt độ 7 ngày trong tuần:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF004D40),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 82,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: weeklyForecast.length,
              itemBuilder: (context, idx) {
                final day = weeklyForecast[idx] as Map<String, dynamic>;
                final isWeekend = (day['day'] == 'Thứ 7' ||
                    day['day'] == 'Chủ Nhật' ||
                    day['isWeekend'] == true);
                return Container(
                  width: 74,
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  decoration: BoxDecoration(
                    color: isWeekend
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFF5F9F6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isWeekend
                          ? const Color(0xFF66BB6A)
                          : Colors.grey.shade200,
                      width: isWeekend ? 1.2 : 1.0,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text(
                        day['day']?.toString() ?? '',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight:
                              isWeekend ? FontWeight.bold : FontWeight.w600,
                          color: isWeekend
                              ? const Color(0xFF2E7D32)
                              : Colors.grey.shade700,
                        ),
                      ),
                      Text(
                        day['icon']?.toString() ?? '🌤️',
                        style: const TextStyle(fontSize: 16),
                      ),
                      Text(
                        day['temp_display']?.toString() ??
                            day['temp']?.toString() ??
                            '16-20°C',
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF004D40),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),

          // Dự báo theo ngày
          const Text(
            'Lộ trình thời tiết theo mốc thời gian:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF004D40),
            ),
          ),
          const SizedBox(height: 8),
          ...dailyForecast.map((d) {
            final m = d as Map<String, dynamic>;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Text(m['icon']?.toString() ?? '🌤️',
                      style: const TextStyle(fontSize: 15)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade800),
                        children: [
                          TextSpan(
                            text: '${m['period']}: ',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF004D40)),
                          ),
                          TextSpan(
                            text: '(${m['temp_range'] ?? m['temp']}) ',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF00796B)),
                          ),
                          TextSpan(text: m['advice']?.toString() ?? ''),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMetricsRow(
      Map<String, dynamic> dest, Map<String, dynamic> extra) {
    return Row(
      children: [
        _metricBox('AQI', '${dest['aqi'] ?? 15}', 'Trong lành',
            const Color(0xFF00C853)),
        const SizedBox(width: 8),
        _metricBox('Nhiệt độ', '${dest['temp'] ?? '18°C'}', 'Mát lạnh',
            const Color(0xFF00897B)),
        const SizedBox(width: 8),
        _metricBox(
            'Quãng đường',
            '${extra['distanceKm'] ?? dest['distance'] ?? '100km'}',
            '${extra['durationHours'] ?? '2h'}',
            const Color(0xFF00695C)),
      ],
    );
  }

  Widget _metricBox(String label, String value, String sub, Color col) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: col.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
                color: col.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w900, color: col),
                maxLines: 1),
            const SizedBox(height: 2),
            Text(sub,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                maxLines: 1),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightCard(Map<String, String> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item['emoji'] ?? '🌿', style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['title'] ?? '',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF004D40))),
                const SizedBox(height: 4),
                Text(item['desc'] ?? '',
                    style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.grey.shade700,
                        height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteStepItem(Map<String, String> step) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(step['icon'] ?? '🚗', style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(step['step'] ?? '',
                    style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00382E))),
                const SizedBox(height: 3),
                Text(step['detail'] ?? '',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransportCard(Map<String, String> t) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: const Color(0xFF00796B).withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(t['type'] ?? '',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF004D40))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF00796B).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(t['cost'] ?? '',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00796B))),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(t['tip'] ?? '',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildItineraryCard(Map<String, String> it) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF004D40),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              it['time'] ?? '',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              it['activity'] ?? '',
              style: TextStyle(
                  fontSize: 12.5, color: Colors.grey.shade800, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomCTA(BuildContext context, Map<String, dynamic> dest) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () => showWeekendTripDialog(context, dest),
            icon: const Icon(Icons.hiking_rounded, color: Colors.white),
            label: const FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'Thêm Vào Chuyến Đi Cuối Tuần',
                maxLines: 1,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00796B),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 4,
            ),
          ),
        ),
      ),
    );
  }
}

/// Global dialog for Weekend Trip Planning
void showWeekendTripDialog(
    BuildContext context, Map<String, dynamic> destination) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _WeekendTripModal(destination: destination),
  );
}

class _WeekendTripModal extends StatefulWidget {
  final Map<String, dynamic> destination;
  const _WeekendTripModal({required this.destination});

  @override
  State<_WeekendTripModal> createState() => _WeekendTripModalState();
}

class _WeekendTripModalState extends State<_WeekendTripModal> {
  late final List<String> _items;
  final Set<int> _checkedIndices = {};

  @override
  void initState() {
    super.initState();
    final name = widget.destination['name'] as String? ?? '';
    List<String>? list;
    for (final entry in _destinationExtras.entries) {
      if (name.contains(entry.key) || entry.key.contains(name)) {
        list = (entry.value['packingList'] as List<dynamic>?)?.cast<String>();
        break;
      }
    }
    _items = list ??
        [
          'Áo khoác giữ nhiệt / áo chống gió',
          'Giày thể thao êm chân hoặc giày leo núi',
          'Bình nước cá nhân & thuốc y tế cơ bản',
          'Sạc dự phòng cho điện thoại',
          'Giấy tờ tùy thân (CCCD)',
        ];
  }

  @override
  Widget build(BuildContext context) {
    final dest = widget.destination;
    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Header Bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Kế Hoạch Chuyến Đi Cuối Tuần',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF004D40)),
                      ),
                      Text(
                        'Điểm đến: ${dest['name']}',
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Quick info box
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2F1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _quickInfoCol('Quãng đường',
                          dest['distance'] ?? '~315 km', Icons.route),
                      _quickInfoCol('Thời gian', dest['duration'] ?? '4.5 giờ',
                          Icons.timer),
                      _quickInfoCol('AQI', '${dest['aqi'] ?? 15}', Icons.air),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                const Text(
                  'Hành Trang Cần Chuẩn Bị (Checklist):',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00382E)),
                ),
                const SizedBox(height: 10),
                ...List.generate(_items.length, (idx) {
                  final isChecked = _checkedIndices.contains(idx);
                  return CheckboxListTile(
                    value: isChecked,
                    activeColor: const Color(0xFF00796B),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      _items[idx],
                      style: TextStyle(
                        fontSize: 13.5,
                        decoration:
                            isChecked ? TextDecoration.lineThrough : null,
                        color: isChecked ? Colors.grey : Colors.grey.shade800,
                      ),
                    ),
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _checkedIndices.add(idx);
                        } else {
                          _checkedIndices.remove(idx);
                        }
                      });
                    },
                  );
                }),
              ],
            ),
          ),

          // Confirm Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Đã lưu kế hoạch đi ${dest['name']} vào cuối tuần! 🎒'),
                      backgroundColor: const Color(0xFF00796B),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00796B),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'LƯU KẾ HOẠCH CHUYẾN ĐI',
                    maxLines: 1,
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickInfoCol(String label, String val, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF00796B)),
        const SizedBox(height: 4),
        Text(val,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Color(0xFF004D40))),
        Text(label,
            style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600)),
      ],
    );
  }
}
