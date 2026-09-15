import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'destination_detail_screen.dart';
import 'chat_screen.dart';

class EcoTourismScreen extends StatefulWidget {
  final String? activeDeviceId;
  const EcoTourismScreen({super.key, this.activeDeviceId});

  @override
  State<EcoTourismScreen> createState() => _EcoTourismScreenState();
}

class _EcoTourismScreenState extends State<EcoTourismScreen> {
  String _selectedRegion = 'Tất cả';
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _forecastMode = 'weekly'; // 'daily' hoặc 'weekly'
  bool _loading = false;
  List<Map<String, dynamic>> _destinationsData = [];

  // Dữ liệu mặc định ban đầu phong phú
  static const List<Map<String, dynamic>> _fallbackDestinations = [
    {
      'id': 'sapa',
      'name': 'Thị Trấn Trong Sương Sapa',
      'sub': 'Nóc Nhà Đông Dương & Xứ Sở Mây Ngàn',
      'location': 'Lào Cai (Cách Hà Nội ~315km)',
      'region': 'Miền Bắc',
      'distance': '~315 km',
      'duration': '4.5 - 5 giờ',
      'aqi': 12,
      'aqiStatus': 'Hoàn hảo',
      'temp': '13 - 19°C',
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
      'weekly_forecast': [
        {'day': 'Thứ 2', 'temp': '13 - 18°C', 'icon': '🌤️', 'cond': 'Nắng nhẹ, se lạnh'},
        {'day': 'Thứ 3', 'temp': '14 - 19°C', 'icon': '⛅', 'cond': 'Nhiều mây, thoáng'},
        {'day': 'Thứ 4', 'temp': '12 - 17°C', 'icon': '🌫️', 'cond': 'Sương mù dày'},
        {'day': 'Thứ 5', 'temp': '13 - 18°C', 'icon': '☀️', 'cond': 'Hửng nắng trưa'},
        {'day': 'Thứ 6', 'temp': '14 - 20°C', 'icon': '🍃', 'cond': 'Gió mát dịu'},
        {'day': 'Thứ 7', 'temp': '12 - 19°C', 'icon': '🏔️', 'cond': 'Biển mây Fansipan'},
        {'day': 'Chủ Nhật', 'temp': '13 - 18°C', 'icon': '🌅', 'cond': 'Hoàng hôn Ô Quy Hồ'},
      ],
      'daily_forecast': [
        {'period': 'Hôm nay', 'temp': '14 - 19°C', 'icon': '🌤️', 'advice': 'Khí hậu mát mẻ, cần áo ấm mỏng vào chiều tối.'},
        {'period': 'Ngày mai', 'temp': '13 - 18°C', 'icon': '⛅', 'advice': 'Độ ẩm 80%, sáng sớm có sương mù nhẹ lãng mạn.'},
        {'period': 'Cuối tuần', 'temp': '12 - 19°C', 'icon': '🏔️', 'advice': 'Thời điểm vàng để leo đỉnh Fansipan săn mây!'},
      ]
    },
    {
      'id': 'bavi',
      'name': 'Vườn Quốc Gia Ba Vì',
      'sub': 'Lá Phổi Xanh Thủ Đô',
      'location': 'Hà Nội (Cách trung tâm 55km)',
      'region': 'Miền Bắc',
      'distance': '~55 km',
      'duration': '1.5 giờ',
      'aqi': 18,
      'aqiStatus': 'Rất trong lành',
      'temp': '19 - 25°C',
      'humidity': '72%',
      'rating': 4.9,
      'imageUrl':
          'https://images.unsplash.com/photo-1511497584788-87676104235f?w=800&auto=format&fit=crop&q=80',
      'highlight':
          'Bạt ngàn rừng thông cổ thụ, suối nước khoáng và không khí thanh lọc phổi tự nhiên. Điểm dã ngoại cắm trại cuối tuần tuyệt vời nhất cho các gia đình.',
      'tags': ['Cắm trại', 'Đồi thông', 'Khí hậu mát lành', 'Picnic gia đình'],
      'activities': ['Leo đỉnh Vua', 'Vườn xương rồng', 'Thưởng thức gà đồi'],
      'weekly_forecast': [
        {'day': 'Thứ 2', 'temp': '20 - 25°C', 'icon': '☀️', 'cond': 'Nắng ấm trong lành'},
        {'day': 'Thứ 3', 'temp': '19 - 24°C', 'icon': '🍃', 'cond': 'Gió rừng thông'},
        {'day': 'Thứ 4', 'temp': '21 - 26°C', 'icon': '🌤️', 'cond': 'Trời trong xanh'},
        {'day': 'Thứ 5', 'temp': '20 - 25°C', 'icon': '⛅', 'cond': 'Mây mỏng che mát'},
        {'day': 'Thứ 6', 'temp': '19 - 24°C', 'icon': '🌿', 'cond': 'Khí hậu dịu mát'},
        {'day': 'Thứ 7', 'temp': '18 - 23°C', 'icon': '🏕️', 'cond': 'Lý tưởng cắm trại'},
        {'day': 'Chủ Nhật', 'temp': '19 - 24°C', 'icon': '🌲', 'cond': 'Dã ngoại gia đình'},
      ],
      'daily_forecast': [
        {'period': 'Hôm nay', 'temp': '20 - 25°C', 'icon': '☀️', 'advice': 'Trời nắng dịu, đường khô ráo rất đẹp.'},
        {'period': 'Ngày mai', 'temp': '19 - 24°C', 'icon': '🍃', 'advice': 'Gió rừng thông mát mẻ, nồng độ oxy cao.'},
        {'period': 'Cuối tuần', 'temp': '18 - 23°C', 'icon': '🏕️', 'advice': 'Nhiệt độ đồi thông giảm 3°C, tuyệt hảo để cắm trại.'},
      ]
    },
    {
      'id': 'tamdao',
      'name': 'Thị Trấn Trong Mây Tam Đảo',
      'sub': 'Đà Lạt Thu Nhỏ Phía Bắc',
      'location': 'Vĩnh Phúc (Cách Hà Nội 75km)',
      'region': 'Miền Bắc',
      'distance': '~75 km',
      'duration': '1.5 - 2 giờ',
      'aqi': 20,
      'aqiStatus': 'Tuyệt vời',
      'temp': '16 - 22°C',
      'humidity': '78%',
      'rating': 4.8,
      'imageUrl':
          'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=800&auto=format&fit=crop&q=80',
      'highlight':
          'Nằm trên độ cao hơn 900m, quanh năm mây mù bao phủ, khí hậu 4 mùa trong 1 ngày, nồng độ oxy cao giúp cơ thể xua tan mọi mệt mỏi.',
      'tags': ['Nghỉ dưỡng', 'Săn mây', 'Khách sạn view núi', 'Ẩm thực su su'],
      'activities': ['Tháp truyền hình', 'Cổng Trời', 'Nhà thờ đá cổ'],
      'weekly_forecast': [
        {'day': 'Thứ 2', 'temp': '17 - 22°C', 'icon': '⛅', 'cond': 'Mây vờn sườn núi'},
        {'day': 'Thứ 3', 'temp': '16 - 21°C', 'icon': '🌫️', 'cond': 'Sương phủ lãng mạn'},
        {'day': 'Thứ 4', 'temp': '17 - 23°C', 'icon': '🌤️', 'cond': 'Nắng nhẹ ban trưa'},
        {'day': 'Thứ 5', 'temp': '16 - 22°C', 'icon': '🍃', 'cond': 'Khí hậu dịu mát'},
        {'day': 'Thứ 6', 'temp': '15 - 21°C', 'icon': '☁️', 'cond': 'Biển mây bềnh bồng'},
        {'day': 'Thứ 7', 'temp': '15 - 20°C', 'icon': '🏰', 'cond': 'Đẹp như châu Âu'},
        {'day': 'Chủ Nhật', 'temp': '16 - 21°C', 'icon': '☕', 'cond': 'Cafe ngắm hoàng hôn'},
      ],
      'daily_forecast': [
        {'period': 'Hôm nay', 'temp': '17 - 22°C', 'icon': '⛅', 'advice': 'Buổi chiều mát lạnh, thích hợp dạo chợ đêm.'},
        {'period': 'Ngày mai', 'temp': '16 - 21°C', 'icon': '🌫️', 'advice': 'Độ ẩm 78%, sương mù sáng sớm ôm trọn quảng trường.'},
        {'period': 'Cuối tuần', 'temp': '15 - 20°C', 'icon': '🏰', 'advice': 'Thời tiết 4 mùa trong ngày, mang áo ấm đi dạo phố.'},
      ]
    },
    {
      'id': 'mocchau',
      'name': 'Thiên Đường Xanh Mộc Châu',
      'sub': 'Xứ Sở Chè & Thảo Nguyên',
      'location': 'Sơn La (Cách Hà Nội ~190km)',
      'region': 'Miền Bắc',
      'distance': '~190 km',
      'duration': '4 giờ',
      'aqi': 15,
      'aqiStatus': 'Hoàn hảo',
      'temp': '17 - 24°C',
      'humidity': '65%',
      'rating': 4.9,
      'imageUrl':
          'https://images.unsplash.com/photo-1544644181-1484b3fdfc62?w=800&auto=format&fit=crop&q=80',
      'highlight':
          'Cao nguyên xanh ngát mênh mông với những đồi chè trái tim, vườn mận nở trắng rừng và không gian sinh thái nguyên sơ, trong vắt.',
      'tags': ['Đồi chè', 'Rừng thông Bản Áng', 'Thác Dải Yếm', 'Sữa chua nếp cẩm'],
      'activities': ['Chụp ảnh đồi chè', 'Hái dâu tây', 'Khám phá thác nước'],
      'weekly_forecast': [
        {'day': 'Thứ 2', 'temp': '17 - 23°C', 'icon': '☀️', 'cond': 'Nắng ráo thảo nguyên'},
        {'day': 'Thứ 3', 'temp': '18 - 24°C', 'icon': '🍃', 'cond': 'Gió cao nguyên'},
        {'day': 'Thứ 4', 'temp': '17 - 23°C', 'icon': '🌤️', 'cond': 'Trời xanh trong'},
        {'day': 'Thứ 5', 'temp': '18 - 24°C', 'icon': '🌾', 'cond': 'Đồi chè xanh mướt'},
        {'day': 'Thứ 6', 'temp': '16 - 22°C', 'icon': '⛅', 'cond': 'Mát dịu dễ chịu'},
        {'day': 'Thứ 7', 'temp': '16 - 23°C', 'icon': '🍓', 'cond': 'Hái dâu cắm trại'},
        {'day': 'Chủ Nhật', 'temp': '17 - 23°C', 'icon': '🌲', 'cond': 'Rừng thông trong lành'},
      ],
      'daily_forecast': [
        {'period': 'Hôm nay', 'temp': '18 - 24°C', 'icon': '☀️', 'advice': 'Độ ẩm 65%, rất khô ráo dễ chịu để chụp ảnh đồi chè.'},
        {'period': 'Ngày mai', 'temp': '17 - 23°C', 'icon': '🍃', 'advice': 'Nắng nhẹ ấm áp, thích hợp tham quan vườn dâu.'},
        {'period': 'Cuối tuần', 'temp': '16 - 23°C', 'icon': '🏕️', 'advice': 'Ban đêm se lạnh 16°C, cắm trại rừng thông nhớ chăn ấm.'},
      ]
    },
    {
      'id': 'puluong',
      'name': 'Khu Bảo Tồn Pù Luông',
      'sub': 'Thung Lũng Đại Ngàn Thanh Bình',
      'location': 'Thanh Hóa (Cách Hà Nội 175km)',
      'region': 'Miền Trung',
      'distance': '~175 km',
      'duration': '3.5 - 4 giờ',
      'aqi': 14,
      'aqiStatus': 'Hoàn hảo',
      'temp': '19 - 26°C',
      'humidity': '76%',
      'rating': 4.9,
      'imageUrl':
          'https://images.unsplash.com/photo-1509099836639-18ba1795216d?w=800&auto=format&fit=crop&q=80',
      'highlight':
          'Rừng nguyên sinh ngút ngàn, thung lũng lúa xanh mướt và những guồng nước mộc mạc mang lại sự tĩnh lặng tuyệt đối cho tâm hồn.',
      'tags': ['Ruộng bậc thang', 'Resort vô cực', 'Guồng nước', 'Trekking bản làng'],
      'activities': ['Tắm suối Hiêu', 'Bơi hồ vô cực ngắm thung lũng', 'Check-in bản Đôn'],
      'weekly_forecast': [
        {'day': 'Thứ 2', 'temp': '20 - 26°C', 'icon': '☀️', 'cond': 'Nắng vàng thung lũng'},
        {'day': 'Thứ 3', 'temp': '21 - 27°C', 'icon': '🍃', 'cond': 'Gió suối mát'},
        {'day': 'Thứ 4', 'temp': '20 - 26°C', 'icon': '🌤️', 'cond': 'Trời trong xanh'},
        {'day': 'Thứ 5', 'temp': '19 - 25°C', 'icon': '⛅', 'cond': 'Mây nhẹ ôm bản'},
        {'day': 'Thứ 6', 'temp': '20 - 26°C', 'icon': '🌾', 'cond': 'Lúa xanh mơn mởn'},
        {'day': 'Thứ 7', 'temp': '19 - 25°C', 'icon': '🏊', 'cond': 'Bơi hồ vô cực'},
        {'day': 'Chủ Nhật', 'temp': '20 - 26°C', 'icon': '🌄', 'cond': 'Hoàng hôn đại ngàn'},
      ],
      'daily_forecast': [
        {'period': 'Hôm nay', 'temp': '20 - 26°C', 'icon': '☀️', 'advice': 'Không khí cực sạch AQI 14, rất tốt cho hệ hô hấp.'},
        {'period': 'Ngày mai', 'temp': '19 - 25°C', 'icon': '🍃', 'advice': 'Khí hậu thung lũng trong lành, thư thái nghỉ dưỡng.'},
        {'period': 'Cuối tuần', 'temp': '19 - 25°C', 'icon': '🏊', 'advice': 'Bơi hồ bơi vô cực ngắm ruộng bậc thang tuyệt đỉnh!'},
      ]
    },
    {
      'id': 'dalat',
      'name': 'Thành Phố Ngàn Hoa Đà Lạt',
      'sub': 'Xứ Sở Rừng Thông & Khí Hậu Ôn Đới',
      'location': 'Lâm Đồng (Tây Nguyên)',
      'region': 'Miền Trung',
      'distance': '~300 km từ TP.HCM',
      'duration': '5 - 6 giờ xe / Bay 45p',
      'aqi': 14,
      'aqiStatus': 'Hoàn hảo',
      'temp': '14 - 22°C',
      'humidity': '80%',
      'rating': 5.0,
      'imageUrl':
          'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=800&auto=format&fit=crop&q=80',
      'highlight':
          'Thủ phủ nghỉ dưỡng vi khí hậu mát lạnh hàng đầu cả nước với bạt ngàn rừng thông ba lá tạo nồng độ oxy và ion âm cực lớn.',
      'tags': ['Rừng thông', 'Hồ Tuyền Lâm', 'Đồi hoa cẩm tú cầu', 'Cafe ngắm mây'],
      'activities': ['Chèo SUP hồ Tuyền Lâm', 'Săn mây Cầu Đất', 'Hái dâu tây'],
      'weekly_forecast': [
        {'day': 'Thứ 2', 'temp': '15 - 22°C', 'icon': '⛅', 'cond': 'Mát dịu se lạnh'},
        {'day': 'Thứ 3', 'temp': '14 - 21°C', 'icon': '🌫️', 'cond': 'Sương sớm hồ Tuyền Lâm'},
        {'day': 'Thứ 4', 'temp': '15 - 22°C', 'icon': '☀️', 'cond': 'Nắng vàng đồi chè'},
        {'day': 'Thứ 5', 'temp': '14 - 22°C', 'icon': '🍃', 'cond': 'Gió rừng thông vi vu'},
        {'day': 'Thứ 6', 'temp': '13 - 21°C', 'icon': '☕', 'cond': 'Cực hợp uống cafe ấm'},
        {'day': 'Thứ 7', 'temp': '13 - 20°C', 'icon': '☁️', 'cond': 'Săn mây Cầu Đất'},
        {'day': 'Chủ Nhật', 'temp': '14 - 21°C', 'icon': '🍓', 'cond': 'Vườn dâu thơm mát'},
      ],
      'daily_forecast': [
        {'period': 'Hôm nay', 'temp': '15 - 22°C', 'icon': '⛅', 'advice': 'Thời tiết se lạnh êm đềm, cần áo len nhẹ vào ban đêm.'},
        {'period': 'Ngày mai', 'temp': '14 - 21°C', 'icon': '🌫️', 'advice': 'Sáng sớm 14°C sương mù dày, 8h hửng nắng vàng.'},
        {'period': 'Cuối tuần', 'temp': '13 - 20°C', 'icon': '☁️', 'advice': 'Săn mây Cầu Đất vào 5h30 sáng cực kỳ ngoạn mục!'},
      ]
    },
  ];

  @override
  void initState() {
    super.initState();
    _destinationsData = List.from(_fallbackDestinations);
    _loadOnlineDestinations();
  }

  Future<void> _loadOnlineDestinations() async {
    try {
      final online = await ApiService().getTourismDestinations();
      if (online.isNotEmpty && mounted) {
        setState(() {
          // Merge hoặc cập nhật dữ liệu online
          _destinationsData = online.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        });
      }
    } catch (_) {}
  }

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
    final filtered = _destinationsData.where((d) {
      final matchesRegion =
          _selectedRegion == 'Tất cả' || d['region'] == _selectedRegion;
      final query = _searchQuery.toLowerCase().trim();
      final name = (d['name'] ?? '').toString().toLowerCase();
      final loc = (d['location'] ?? '').toString().toLowerCase();
      final sub = (d['sub'] ?? '').toString().toLowerCase();
      final matchesSearch =
          query.isEmpty || name.contains(query) || loc.contains(query) || sub.contains(query);
      return matchesRegion && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF1F6F3),
      body: CustomScrollView(
        slivers: [
          // ── SliverAppBar với ảnh nền Parallax & Gradient Xanh Sinh Thái ──
          SliverAppBar(
            expandedHeight: 260,
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
                          Colors.black.withValues(alpha: 0.35),
                          const Color(0xFF004D40).withValues(alpha: 0.90),
                        ],
                        stops: const [0.0, 0.9],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 60,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00E676),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00E676).withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.auto_awesome, size: 13, color: Color(0xFF00382E)),
                              SizedBox(width: 4),
                              Text(
                                'AI DỰ BÁO KHÍ HẬU & NHIỆT ĐỘ',
                                style: TextStyle(
                                  color: Color(0xFF00382E),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Trốn Khói Bụi, Hít Thở Khí Lành',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 21,
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
                          'Cập nhật thời tiết theo ngày & tuần từ AI SmartAir cho các tọa độ xanh.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.92),
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

          // ── AI Climate Advisory Banner ──
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF004D40), Color(0xFF00796B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF004D40).withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.wb_sunny_outlined, color: Color(0xFFFFD600), size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Nhận định tuần từ AI SmartAir',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            SizedBox(width: 6),
                            Icon(Icons.verified, size: 14, color: Color(0xFF64FFDA)),
                          ],
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Tuần này các điểm Ba Vì, Tam Đảo & Mộc Châu có nhiệt độ se mát 16-24°C, AQI cực sạch (<20). Cuối tuần nắng đẹp, không mưa, rất thuận lợi để dã ngoại!',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11.5,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Search Bar, Mode Switch & Region Filter ──
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Column(
                children: [
                  // Search Bar
                  TextField(
                    controller: _searchCtrl,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Tìm Sapa, Tam Đảo, Ba Vì, Mộc Châu, Đà Lạt...',
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
                  const SizedBox(height: 12),

                  // Thanh chuyển đổi Chế độ Xem: Theo Tuần vs Theo Ngày
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2F1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _forecastMode = 'weekly'),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _forecastMode == 'weekly'
                                    ? const Color(0xFF00796B)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: _forecastMode == 'weekly'
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFF00796B).withValues(alpha: 0.3),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        )
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.calendar_view_week_rounded,
                                    size: 16,
                                    color: _forecastMode == 'weekly' ? Colors.white : const Color(0xFF004D40),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Dự Báo 7 Ngày Trong Tuần',
                                    style: TextStyle(
                                      color: _forecastMode == 'weekly' ? Colors.white : const Color(0xFF004D40),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _forecastMode = 'daily'),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _forecastMode == 'daily'
                                    ? const Color(0xFF00796B)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: _forecastMode == 'daily'
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFF00796B).withValues(alpha: 0.3),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        )
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.today_rounded,
                                    size: 16,
                                    color: _forecastMode == 'daily' ? Colors.white : const Color(0xFF004D40),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Dự Báo Hôm Nay & Cuối Tuần',
                                    style: TextStyle(
                                      color: _forecastMode == 'daily' ? Colors.white : const Color(0xFF004D40),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Region Filter Chips
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
                              fontSize: 12,
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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
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
    final aqi = (dest['aqi'] as num?)?.toInt() ?? 15;
    final aqiCol = _aqiColor(aqi);

    final weeklyForecast = dest['weekly_forecast'] as List<dynamic>? ??
        (dest['forecast'] != null && dest['forecast']['weekly'] != null
            ? dest['forecast']['weekly'] as List<dynamic>
            : []);

    final dailyForecast = dest['daily_forecast'] as List<dynamic>? ??
        (dest['forecast'] != null && dest['forecast']['daily'] != null
            ? dest['forecast']['daily'] as List<dynamic>
            : []);

    return Container(
      margin: const EdgeInsets.only(bottom: 22),
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
                  dest['imageUrl'] as String? ??
                      'https://images.unsplash.com/photo-1528127269322-539801943592?w=800&auto=format&fit=crop&q=80',
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
                        Colors.black.withValues(alpha: 0.65),
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
                        'AQI $aqi • ${dest['aqiStatus'] ?? "Trong lành"}',
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
                    color: Colors.black.withValues(alpha: 0.65),
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
                        '${dest['rating'] ?? "5.0"}',
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

          // ── Nội dung thông tin & Dự báo thời tiết AI ──
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
                            dest['name'] as String? ?? '',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF00382E),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            dest['sub'] as String? ?? '',
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2F1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.thermostat, size: 14, color: Color(0xFF00796B)),
                              Text(
                                dest['temp'] as String? ?? '18 - 24°C',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF004D40),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'Ẩm ${dest['humidity'] ?? "75%"}',
                            style: const TextStyle(
                                fontSize: 10.5, color: Color(0xFF00796B), fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Đoạn tóm tắt highlight
                Text(
                  dest['highlight'] as String? ?? '',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.grey.shade700,
                    height: 1.45,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),

                // ── Phần dự báo thời tiết AI Động (Theo Tuần / Theo Ngày) ──
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7FAF8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFB2DFDB).withValues(alpha: 0.6)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.auto_awesome, size: 14, color: Color(0xFF00897B)),
                              const SizedBox(width: 5),
                              Text(
                                _forecastMode == 'weekly'
                                    ? 'Dự báo nhiệt độ 7 ngày (AI cập nhật)'
                                    : 'Dự báo vi khí hậu hôm nay & cuối tuần',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF004D40),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00E676).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Đồng bộ AI',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF00796B),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Hiển thị theo tuần (7 ngày cuộn ngang)
                      if (_forecastMode == 'weekly' && weeklyForecast.isNotEmpty)
                        SizedBox(
                          height: 78,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: weeklyForecast.length,
                            itemBuilder: (context, idx) {
                              final day = weeklyForecast[idx] as Map<String, dynamic>;
                              final isWeekend = (day['day'] == 'Thứ 7' ||
                                  day['day'] == 'Chủ Nhật' ||
                                  day['isWeekend'] == true);
                              return Container(
                                width: 70,
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                                decoration: BoxDecoration(
                                  color: isWeekend ? const Color(0xFFE8F5E9) : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isWeekend
                                        ? const Color(0xFF81C784)
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
                                      day['icon']?.toString() ?? '⛅',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    Text(
                                      day['temp_display']?.toString() ??
                                          day['temp']?.toString() ??
                                          '18-22°C',
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

                      // Hiển thị theo ngày (3 mốc: Hôm nay, Ngày mai, Cuối tuần)
                      if (_forecastMode == 'daily' && dailyForecast.isNotEmpty)
                        Column(
                          children: dailyForecast.map((d) {
                            final map = d as Map<String, dynamic>;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(map['icon']?.toString() ?? '🌤️', style: const TextStyle(fontSize: 15)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              map['period']?.toString() ?? '',
                                              style: const TextStyle(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF004D40),
                                              ),
                                            ),
                                            Text(
                                              map['temp_range']?.toString() ?? map['temp']?.toString() ?? '',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF00796B),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          map['advice']?.toString() ?? '',
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            color: Colors.grey.shade600,
                                            height: 1.25,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Tags
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: ((dest['tags'] as List<dynamic>?) ?? []).map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2F1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '#$tag',
                        style: const TextStyle(
                          color: Color(0xFF00796B),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                // ── 3 Nút Hành Động ──
                Row(
                  children: [
                    // Nút Hỏi AI
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              deviceId: widget.activeDeviceId ?? 'SA-001',
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDE7F6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.smart_toy_outlined, size: 16, color: Colors.deepPurple),
                            SizedBox(width: 4),
                            Text(
                              'Hỏi AI',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Nút Xem chi tiết & Lộ trình
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
                        icon: const Icon(Icons.explore_outlined, size: 15),
                        label: const Text(
                          'Chi Tiết & Lộ Trình',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF00796B),
                          side: const BorderSide(
                              color: Color(0xFF00796B), width: 1.2),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Nút Thêm Chuyến Đi Cuối Tuần
                    ElevatedButton(
                      onPressed: () => showWeekendTripDialog(context, dest),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00796B),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_task_rounded,
                              size: 15, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            '+ Cuối Tuần',
                            style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ],
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
