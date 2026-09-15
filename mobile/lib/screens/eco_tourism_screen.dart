import 'package:flutter/material.dart';
import 'destination_detail_screen.dart';

class EcoTourismScreen extends StatefulWidget {
  const EcoTourismScreen({super.key});

  @override
  State<EcoTourismScreen> createState() => _EcoTourismScreenState();
}

class _EcoTourismScreenState extends State<EcoTourismScreen> {
  String _selectedRegion = 'Tất cả';
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  static const List<Map<String, dynamic>> _destinations = [
    {
      'name': 'Thị Trấn Trong Sương Sapa',
      'sub': 'Nóc Nhà Đông Dương & Xứ Sở Mây Ngàn',
      'location': 'Lào Cai (Cách Hà Nội ~315km)',
      'region': 'Miền Bắc',
      'distance': '~315 km',
      'duration': '4.5 - 5 giờ',
      'aqi': 12,
      'aqiStatus': 'Hoàn hảo',
      'temp': '14 - 19°C',
      'humidity': '82%',
      'rating': 5.0,
      'imageUrl':
          'https://images.unsplash.com/photo-1528127269322-539801943592?w=800&auto=format&fit=crop&q=80',
      'highlight':
          'Sapa quanh năm mây bồng bềnh ôm trọn dãy Hoàng Liên Sơn hùng vĩ, không khí trong vắt mát lạnh chuẩn châu Âu. Điểm đến nghỉ dưỡng sinh thái hàng đầu tránh xa khói bụi đô thị.',
      'tags': [
        'Fansipan 3.143m',
        'Săn mây',
        'Ruộng bậc thang',
        'Đèo Ô Quy Hồ',
        'Bản Cát Cát'
      ],
      'activities': [
        'Chinh phục đỉnh Fansipan',
        'Săn hoàng hôn Ô Quy Hồ',
        'Dạo bản Cát Cát',
        'Tắm lá thuốc người Dao đỏ'
      ],
    },
    {
      'name': 'Vườn Quốc Gia Ba Vì',
      'sub': 'Lá Phổi Xanh Thủ Đô',
      'location': 'Hà Nội (Cách trung tâm 55km)',
      'region': 'Miền Bắc',
      'distance': '~55 km',
      'duration': '1.5 giờ',
      'aqi': 18,
      'aqiStatus': 'Rất trong lành',
      'temp': '20 - 24°C',
      'humidity': '72%',
      'rating': 4.9,
      'imageUrl':
          'https://images.unsplash.com/photo-1511497584788-87676104235f?w=800&auto=format&fit=crop&q=80',
      'highlight':
          'Bạt ngàn rừng thông cổ thụ, suối nước khoáng và không khí thanh lọc phổi tự nhiên. Điểm dã ngoại cắm trại cuối tuần tuyệt vời nhất cho các gia đình.',
      'tags': ['Cắm trại', 'Đồi thông', 'Khí hậu mát lành', 'Picnic gia đình'],
      'activities': ['Leo đỉnh Vua', 'Vườn xương rồng', 'Thưởng thức gà đồi'],
    },
    {
      'name': 'Thị Trấn Trong Mây Tam Đảo',
      'sub': 'Đà Lạt Thu Nhỏ Phía Bắc',
      'location': 'Vĩnh Phúc (Cách Hà Nội 75km)',
      'region': 'Miền Bắc',
      'distance': '~75 km',
      'duration': '1.5 - 2 giờ',
      'aqi': 22,
      'aqiStatus': 'Tuyệt vời',
      'temp': '17 - 21°C',
      'humidity': '78%',
      'rating': 4.8,
      'imageUrl':
          'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=800&auto=format&fit=crop&q=80',
      'highlight':
          'Nằm trên độ cao hơn 900m, quanh năm mây mù bao phủ, khí hậu 4 mùa trong 1 ngày, nồng độ oxy cao giúp cơ thể xua tan mọi mệt mỏi.',
      'tags': ['Nghỉ dưỡng', 'Săn mây', 'Khách sạn view núi', 'Ẩm thực su su'],
      'activities': ['Tháp truyền hình', 'Cổng Trời', 'Nhà thờ đá cổ'],
    },
    {
      'name': 'Thiên Đường Xanh Mộc Châu',
      'sub': 'Xứ Sở Chè & Thảo Nguyên',
      'location': 'Sơn La (Cách Hà Nội ~190km)',
      'region': 'Miền Bắc',
      'distance': '~190 km',
      'duration': '4 giờ',
      'aqi': 15,
      'aqiStatus': 'Hoàn hảo',
      'temp': '18 - 23°C',
      'humidity': '65%',
      'rating': 4.9,
      'imageUrl':
          'https://images.unsplash.com/photo-1544644181-1484b3fdfc62?w=800&auto=format&fit=crop&q=80',
      'highlight':
          'Cao nguyên xanh ngát mênh mông với những đồi chè trái tim, vườn mận nở trắng rừng và không gian sinh thái nguyên sơ, trong vắt.',
      'tags': [
        'Đồi chè',
        'Rừng thông Bản Áng',
        'Thác Dải Yếm',
        'Sữa chua nếp cẩm'
      ],
      'activities': ['Chụp ảnh đồi chè', 'Hái dâu tây', 'Khám phá thác nước'],
    },
    {
      'name': 'Quần Thể Danh Thắng Tràng An',
      'sub': 'Di Sản Văn Hóa & Thiên Nhiên Thế Giới',
      'location': 'Ninh Bình (Cách Hà Nội 95km)',
      'region': 'Miền Bắc',
      'distance': '~95 km',
      'duration': '1.5 - 2 giờ',
      'aqi': 24,
      'aqiStatus': 'Rất trong lành',
      'temp': '22 - 26°C',
      'humidity': '75%',
      'rating': 5.0,
      'imageUrl':
          'https://images.unsplash.com/photo-1570789210967-2cac24afeb00?w=800&auto=format&fit=crop&q=80',
      'highlight':
          'Hệ sinh thái núi đá vôi ngập nước ngoạn mục, chèo thuyền nan len lỏi qua các hang động kỳ bí trên làn nước xanh ngọc bích.',
      'tags': [
        'Di sản UNESCO',
        'Đi thuyền nan',
        'Non nước hữu tình',
        'Hang động'
      ],
      'activities': [
        'Chèo thuyền Tràng An',
        'Thăm chùa Bái Đính',
        'Thưởng thức dê núi'
      ],
    },
    {
      'name': 'Khu Bảo Tồn Pù Luông',
      'sub': 'Thiên Nhiên Nguyên Sơ Tây Bắc Thu Nhỏ',
      'location': 'Thanh Hóa (Cách Hà Nội 175km)',
      'region': 'Miền Trung',
      'distance': '~175 km',
      'duration': '4 giờ',
      'aqi': 16,
      'aqiStatus': 'Hoàn hảo',
      'temp': '19 - 24°C',
      'humidity': '79%',
      'rating': 4.9,
      'imageUrl':
          'https://images.unsplash.com/photo-1509099836639-18ba1795216d?w=800&auto=format&fit=crop&q=80',
      'highlight':
          'Rừng nguyên sinh ngút ngàn, thung lũng lúa xanh mướt và những guồng nước mộc mạc mang lại sự tĩnh lặng tuyệt đối cho tâm hồn.',
      'tags': [
        'Ruộng bậc thang',
        'Resort vô cực',
        'Guồng nước',
        'Trekking bản làng'
      ],
      'activities': [
        'Tắm suối Hiêu',
        'Bơi hồ vô cực ngắm thung lũng',
        'Check-in bản Đôn'
      ],
    },
    {
      'name': 'Thành Phố Ngàn Hoa Đà Lạt',
      'sub': 'Xứ Sở Rừng Thông & Khí Hậu Ôn Đới',
      'location': 'Lâm Đồng (Tây Nguyên)',
      'region': 'Miền Trung',
      'distance': '~300 km từ TP.HCM',
      'duration': '5 - 6 giờ xe / Bay 45p',
      'aqi': 14,
      'aqiStatus': 'Hoàn hảo',
      'temp': '15 - 22°C',
      'humidity': '80%',
      'rating': 5.0,
      'imageUrl':
          'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=800&auto=format&fit=crop&q=80',
      'highlight':
          'Thủ phủ nghỉ dưỡng vi khí hậu mát lạnh hàng đầu cả nước với bạt ngàn rừng thông ba lá tạo nồng độ oxy và ion âm cực lớn.',
      'tags': [
        'Rừng thông',
        'Hồ Tuyền Lâm',
        'Đồi hoa cẩm tú cầu',
        'Cafe ngắm mây'
      ],
      'activities': ['Chèo SUP hồ Tuyền Lâm', 'Săn mây Cầu Đất', 'Hái dâu tây'],
    },
    {
      'name': 'Khu Nghỉ Dưỡng Bà Nà Hills',
      'sub': 'Đường Lên Tiên Cảnh',
      'location': 'Đà Nẵng (Độ cao 1.487m)',
      'region': 'Miền Trung',
      'distance': '~35 km từ Đà Nẵng',
      'duration': '45 phút',
      'aqi': 15,
      'aqiStatus': 'Hoàn hảo',
      'temp': '17 - 20°C',
      'humidity': '75%',
      'rating': 4.9,
      'imageUrl':
          'https://images.unsplash.com/photo-1544644181-1484b3fdfc62?w=800&auto=format&fit=crop&q=80',
      'highlight':
          'Nằm trên đỉnh núi Chúa hùng vĩ với khí hậu 4 mùa trong 1 ngày, Cầu Vàng nổi tiếng thế giới và làng Pháp lãng mạn giữa mây ngàn.',
      'tags': ['Cầu Vàng', 'Cáp treo kỷ lục', 'Làng Pháp', 'Khí hậu mát mẻ'],
      'activities': [
        'Đi bộ trên Cầu Vàng',
        'Đi cáp treo ngắm thác',
        'Lễ hội hoa'
      ],
    },
  ];

  Color _aqiColor(int aqi) {
    if (aqi <= 20) return const Color(0xFF00C853);
    if (aqi <= 30) return const Color(0xFF64DD17);
    return const Color(0xFFFFD600);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _destinations.where((d) {
      final matchesRegion =
          _selectedRegion == 'Tất cả' || d['region'] == _selectedRegion;
      final query = _searchQuery.toLowerCase().trim();
      final matchesSearch = query.isEmpty ||
          (d['name'] as String).toLowerCase().contains(query) ||
          (d['location'] as String).toLowerCase().contains(query) ||
          (d['sub'] as String).toLowerCase().contains(query);
      return matchesRegion && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF2F7F4),
      body: CustomScrollView(
        slivers: [
          // ── SliverAppBar với ảnh nền Parallax & Gradient ──
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: const Color(0xFF004D40),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              title: const Text(
                'Du Lịch Xanh & Nghỉ Dưỡng',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  letterSpacing: 0.3,
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    'https://images.unsplash.com/photo-1528127269322-539801943592?w=800&auto=format&fit=crop&q=80',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: const Color(0xFF004D40)),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.25),
                          const Color(0xFF004D40).withValues(alpha: 0.85),
                        ],
                        stops: const [0.0, 0.9],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 65,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00E676),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'GỢI Ý CUỐI TUẦN CHO GIA ĐÌNH',
                            style: TextStyle(
                              color: Color(0xFF00382E),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Trốn Khói Bụi, Hít Thở Khí Lành',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            shadows: [
                              Shadow(
                                  color: Colors.black45,
                                  blurRadius: 8,
                                  offset: Offset(0, 2)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Khám phá các điểm đến có chỉ số AQI tuyệt hảo và cảnh quan thiên nhiên kỳ vĩ.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Search Bar & Filter Chips ──
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                children: [
                  // Ô Tìm kiếm
                  TextField(
                    controller: _searchCtrl,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Tìm Sapa, Tam Đảo, Ba Vì, Mộc Châu...',
                      hintStyle:
                          TextStyle(fontSize: 13, color: Colors.grey.shade400),
                      prefixIcon: const Icon(Icons.search,
                          color: Color(0xFF00796B), size: 22),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: const Color(0xFFF2F7F4),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['Tất cả', 'Miền Bắc', 'Miền Trung', 'Miền Nam']
                          .map((region) {
                        final isSelected = _selectedRegion == region;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(region),
                            selected: isSelected,
                            onSelected: (_) =>
                                setState(() => _selectedRegion = region),
                            selectedColor: const Color(0xFF00796B),
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey.shade700,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 12.5,
                            ),
                            backgroundColor: const Color(0xFFF0F4F2),
                            checkmarkColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                            side: BorderSide.none,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Danh sách điểm đến ──
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final dest = filtered[index];
                  return _buildDestinationCard(context, dest);
                },
                childCount: filtered.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDestinationCard(
      BuildContext context, Map<String, dynamic> dest) {
    final aqi = dest['aqi'] as int;
    final aqiCol = _aqiColor(aqi);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF004D40).withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Ảnh bìa + Badges ──
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  dest['imageUrl'] as String,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFF004D40),
                    child: const Icon(Icons.landscape,
                        size: 60, color: Colors.white54),
                  ),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.3),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.6),
                      ],
                      stops: const [0.0, 0.4, 1.0],
                    ),
                  ),
                ),
              ),
              // Badge AQI góc trái trên
              Positioned(
                top: 14,
                left: 14,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: aqiCol,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: aqiCol.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.eco, size: 14, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        'AQI $aqi • ${dest['aqiStatus']}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Badge Quãng đường & Thời gian
              Positioned(
                bottom: 12,
                left: 14,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.route,
                          size: 13, color: Color(0xFF64FFDA)),
                      const SizedBox(width: 4),
                      Text(
                        '${dest['distance']}  •  ${dest['duration']}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Rating góc phải trên
              Positioned(
                top: 14,
                right: 14,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star,
                          size: 13, color: Color(0xFFFFD600)),
                      const SizedBox(width: 3),
                      Text(
                        '${dest['rating']}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ── Nội dung thông tin ──
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dest['name'] as String,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF00382E),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            dest['sub'] as String,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF00796B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Nhiệt độ & Độ ẩm
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          dest['temp'] as String,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF004D40),
                          ),
                        ),
                        Text(
                          'Ẩm ${dest['humidity']}',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Đoạn tóm tắt highlight
                Text(
                  dest['highlight'] as String,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    height: 1.45,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),

                // Tags
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: (dest['tags'] as List<String>).map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2F1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '#$tag',
                        style: const TextStyle(
                          color: Color(0xFF00796B),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // ── 2 Nút Hành Động ──
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  DestinationDetailScreen(destination: dest),
                            ),
                          );
                        },
                        icon: const Icon(Icons.explore_outlined, size: 16),
                        label: const Text(
                          'Xem Chi Tiết & Lộ Trình',
                          style: TextStyle(
                              fontSize: 12.5, fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF00796B),
                          side: const BorderSide(
                              color: Color(0xFF00796B), width: 1.2),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: () => showWeekendTripDialog(context, dest),
                      icon: const Icon(Icons.add_task_rounded,
                          size: 16, color: Colors.white),
                      label: const Text(
                        'Thêm Cuối Tuần',
                        style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00796B),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 11),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
