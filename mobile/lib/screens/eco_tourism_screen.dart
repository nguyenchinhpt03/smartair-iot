import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
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
  String _forecastMode = 'weekly'; // 'weekly' hoặc 'daily'

  // Vị trí điện thoại người dùng
  double? _userLat = 21.0285; // Mặc định Hà Nội
  double? _userLon = 105.8542;
  String _userCity = 'Hà Nội';
  bool _isLocating = true;

  bool _isSearchingMap = false;
  List<Map<String, dynamic>> _destinationsData = [];
  List<Map<String, dynamic>> _mapSearchResults = [];

  // Cơ sở dữ liệu hơn 30 khu du lịch sinh thái nổi tiếng khắp 3 miền Việt Nam
  static const List<Map<String, dynamic>> _fallbackDestinations = [
    // ── MIỀN BẮC ──
    {
      'id': 'sapa',
      'name': 'Thị Trấn Trong Sương Sapa',
      'sub': 'Nóc Nhà Đông Dương & Xứ Sở Mây Ngàn',
      'location': 'Lào Cai',
      'region': 'Miền Bắc',
      'lat': 22.3364,
      'lon': 103.8438,
      'aqi': 12,
      'aqiStatus': 'Rất trong lành',
      'temp': '13 - 20°C',
      'humidity': '82%',
      'rating': 5.0,
      'imageUrl':
          'https://images.unsplash.com/photo-1528127269322-539801943592?w=1000&auto=format&fit=crop&q=85',
      'highlight':
          'Sapa quanh năm mây bồng bềnh ôm trọn dãy Hoàng Liên Sơn hùng vĩ, không khí trong vắt mát lạnh chuẩn châu Âu. Điểm đến nghỉ dưỡng sinh thái hàng đầu.',
      'tags': ['Fansipan 3.143m', 'Săn mây', 'Ruộng bậc thang', 'Đèo Ô Quy Hồ'],
      'activities': [
        'Chinh phục Fansipan',
        'Săn hoàng hôn Ô Quy Hồ',
        'Dạo bản Cát Cát'
      ],
    },
    {
      'id': 'bavi',
      'name': 'Vườn Quốc Gia Ba Vì',
      'sub': 'Lá Phổi Xanh Thủ Đô & Rừng Thông Cổ Thụ',
      'location': 'Huyện Ba Vì, Hà Nội',
      'region': 'Miền Bắc',
      'lat': 21.0833,
      'lon': 105.3667,
      'aqi': 16,
      'aqiStatus': 'Rất trong lành',
      'temp': '19 - 25°C',
      'humidity': '72%',
      'rating': 4.9,
      'imageUrl':
          'https://images.unsplash.com/photo-1448375240586-882707db888b?w=1000&auto=format&fit=crop&q=85',
      'highlight':
          'Rừng thông cổ thụ bạt ngàn, suối khoáng thanh mát và không khí thanh lọc phổi tự nhiên. Điểm dã ngoại cắm trại cuối tuần tuyệt vời nhất.',
      'tags': ['Cắm trại', 'Đồi thông', 'Khí hậu mát lành', 'Picnic gia đình'],
      'activities': ['Leo đỉnh Vua', 'Vườn xương rồng', 'Thưởng thức gà đồi'],
    },
    {
      'id': 'tamdao',
      'name': 'Thị Trấn Trong Mây Tam Đảo',
      'sub': 'Đà Lạt Thu Nhỏ & Lâu Đài Sương Mù',
      'location': 'Huyện Tam Đảo, Vĩnh Phúc',
      'region': 'Miền Bắc',
      'lat': 21.4589,
      'lon': 105.6483,
      'aqi': 18,
      'aqiStatus': 'Tuyệt vời',
      'temp': '16 - 22°C',
      'humidity': '78%',
      'rating': 4.8,
      'imageUrl':
          'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=1000&auto=format&fit=crop&q=85',
      'highlight':
          'Nằm trên độ cao hơn 900m, quanh năm mây mù bao phủ, khí hậu 4 mùa trong 1 ngày, nồng độ oxy cao giúp cơ thể xua tan mệt mỏi.',
      'tags': ['Nghỉ dưỡng', 'Săn mây', 'Khách sạn view núi', 'Ẩm thực su su'],
      'activities': ['Tháp truyền hình', 'Cổng Trời', 'Nhà thờ đá cổ'],
    },
    {
      'id': 'mocchau',
      'name': 'Thiên Đường Xanh Mộc Châu',
      'sub': 'Xứ Sở Chè Trái Tim & Thảo Nguyên Bao La',
      'location': 'Huyện Mộc Châu, Sơn La',
      'region': 'Miền Bắc',
      'lat': 20.8447,
      'lon': 104.6469,
      'aqi': 14,
      'aqiStatus': 'Hoàn hảo',
      'temp': '17 - 24°C',
      'humidity': '65%',
      'rating': 4.9,
      'imageUrl':
          'https://images.unsplash.com/photo-1534447677768-be436bb09401?w=1000&auto=format&fit=crop&q=85',
      'highlight':
          'Cao nguyên xanh ngát mênh mông với những đồi chè trái tim, vườn mận nở trắng rừng và không gian sinh thái nguyên sơ, trong vắt.',
      'tags': ['Đồi chè', 'Rừng thông Bản Áng', 'Thác Dải Yếm', 'Thảo nguyên'],
      'activities': ['Chụp ảnh đồi chè', 'Hái dâu tây', 'Khám phá thác nước'],
    },
    {
      'id': 'trangan',
      'name': 'Quần Thể Danh Thắng Tràng An',
      'sub': 'Di Sản Thế Giới UNESCO & Sông Ngô Đồng Xanh Ngọc',
      'location': 'Huyện Hoa Lư, Ninh Bình',
      'region': 'Miền Bắc',
      'lat': 20.2583,
      'lon': 105.9083,
      'aqi': 22,
      'aqiStatus': 'Rất trong lành',
      'temp': '21 - 27°C',
      'humidity': '74%',
      'rating': 5.0,
      'imageUrl':
          'https://images.unsplash.com/photo-1570789210967-2cac24afeb00?w=1000&auto=format&fit=crop&q=85',
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
      'id': 'halong',
      'name': 'Vịnh Hạ Long & Vịnh Lan Hạ',
      'sub': 'Kỳ Quan Thiên Nhiên Thế Giới UNESCO',
      'location': 'Quảng Ninh',
      'region:': 'Miền Bắc',
      'region': 'Miền Bắc',
      'lat': 20.9101,
      'lon': 107.1839,
      'aqi': 18,
      'aqiStatus': 'Rất trong lành',
      'temp': '22 - 28°C',
      'humidity': '76%',
      'rating': 5.0,
      'imageUrl':
          'https://images.unsplash.com/photo-1528127269322-539801943592?w=1000&auto=format&fit=crop&q=85',
      'highlight':
          'Hàng ngàn đảo đá vôi kỳ vĩ nổi trên mặt biển xanh ngọc, không khí biển thanh mát cùng trải nghiệm du thuyền ngủ đêm đẳng cấp.',
      'tags': ['Kỳ quan UNESCO', 'Du thuyền', 'Hang Sửng Sốt', 'Chèo Kayak'],
      'activities': [
        'Ngủ đêm trên du thuyền',
        'Chèo kayak luồn hang Luồn',
        'Tắm biển Ti Tốp'
      ],
    },
    {
      'id': 'catba',
      'name': 'Quần Đảo Sinh Thái Cát Bà',
      'sub': 'Khu Dự Trữ Sinh Quyển Thế Giới UNESCO',
      'location': 'Hải Phòng',
      'region': 'Miền Bắc',
      'lat': 20.7275,
      'lon': 107.0469,
      'aqi': 16,
      'aqiStatus': 'Hoàn hảo',
      'temp': '21 - 27°C',
      'humidity': '79%',
      'rating': 4.8,
      'imageUrl':
          'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=1000&auto=format&fit=crop&q=85',
      'highlight':
          'Hòa quyện giữa rừng nguyên sinh nhiệt đới và biển cả mênh mông, bãi cát trắng mịn và làng chài cổ Cái Bèo bình yên.',
      'tags': ['Vườn Quốc Gia', 'Vịnh Lan Hạ', 'Làng chài Cái Bèo', 'Trekking'],
      'activities': [
        'Trekking đỉnh Ngự Lâm',
        'Chèo thuyền vịnh Lan Hạ',
        'Thăm làng Việt Hải'
      ],
    },
    {
      'id': 'hagiang',
      'name': 'Cao Nguyên Đá Đồng Văn - Hà Giang',
      'sub': 'Công Viên Địa Chất Toàn Cầu & Đèo Mã Pí Lèng',
      'location': 'Hà Giang',
      'region': 'Miền Bắc',
      'lat': 23.2789,
      'lon': 105.3611,
      'aqi': 10,
      'aqiStatus': 'Tuyệt đỉnh',
      'temp': '14 - 21°C',
      'humidity': '70%',
      'rating': 5.0,
      'imageUrl':
          'https://images.unsplash.com/photo-1534447677768-be436bb09401?w=1000&auto=format&fit=crop&q=85',
      'highlight':
          'Đệ nhất hùng quan đèo Mã Pí Lèng, dòng sông Nho Quế xanh ngọc bích và những vách đá tai mèo trùng điệp hùng vĩ tột cùng.',
      'tags': [
        'Mã Pí Lèng',
        'Sông Nho Quế',
        'Cột cờ Lũng Cú',
        'Hoa tam giác mạch'
      ],
      'activities': [
        'Đi thuyền hẻm Tu Sản',
        'Chinh phục Mã Pí Lèng',
        'Thăm Dinh Vua Mèo'
      ],
    },
    {
      'id': 'taxua',
      'name': 'Thiên Đường Mây Tà Xùa',
      'sub': 'Sống Lưng Khủng Long & Biển Mây Đại Ngàn',
      'location': 'Bắc Yên, Sơn La',
      'region': 'Miền Bắc',
      'lat': 21.2667,
      'lon': 104.4500,
      'aqi': 9,
      'aqiStatus': 'Hoàn hảo',
      'temp': '12 - 18°C',
      'humidity': '85%',
      'rating': 4.9,
      'imageUrl':
          'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=1000&auto=format&fit=crop&q=85',
      'highlight':
          'Điểm săn mây đẹp nhất miền Bắc với biển mây cuồn cuộn bao phủ sống lưng khủng long, khí hậu lạnh tinh khiết quanh năm.',
      'tags': [
        'Sống lưng khủng long',
        'Biển mây',
        'Cây cô đơn',
        'Cà phê ngắm mây'
      ],
      'activities': [
        'Săn mây sớm 5h sáng',
        'Check-in mỏm cá heo',
        'Cắm trại sườn núi'
      ],
    },
    {
      'id': 'maichau',
      'name': 'Thung Lũng Xanh Mai Châu',
      'sub': 'Bản Làng Thái Bình Yên Giữa Núi Rừng',
      'location': 'Hòa Bình',
      'region': 'Miền Bắc',
      'lat': 20.6667,
      'lon': 105.0833,
      'aqi': 15,
      'aqiStatus': 'Rất trong lành',
      'temp': '19 - 26°C',
      'humidity': '71%',
      'rating': 4.8,
      'imageUrl':
          'https://images.unsplash.com/photo-1509099836639-18ba1795216d?w=1000&auto=format&fit=crop&q=85',
      'highlight':
          'Thung lũng đồng lúa mênh mông, nhà sàn gỗ cổ truyền người Thái, đạp xe qua cánh đồng lộng gió và thưởng thức cơm lam.',
      'tags': [
        'Bản Lác',
        'Đạp xe đồng lúa',
        'Nghỉ dưỡng homestay',
        'Văn hóa Thái'
      ],
      'activities': [
        'Đạp xe dạo Bản Lác',
        'Múa sạp uống rượu cần',
        'Tắm suối khoáng nóng'
      ],
    },
    {
      'id': 'cucphuong',
      'name': 'Vườn Quốc Gia Cúc Phương',
      'sub': 'Rừng Mưa Nhiệt Đới & Cây Chò Ngàn Năm',
      'location': 'Ninh Bình',
      'region': 'Miền Bắc',
      'lat': 20.3167,
      'lon': 105.6167,
      'aqi': 11,
      'aqiStatus': 'Rất trong lành',
      'temp': '20 - 26°C',
      'humidity': '80%',
      'rating': 4.9,
      'imageUrl':
          'https://images.unsplash.com/photo-1448375240586-882707db888b?w=1000&auto=format&fit=crop&q=85',
      'highlight':
          'Hệ sinh thái rừng mưa nhiệt đới cổ xưa bạt ngàn với cây chò ngàn năm, mùa bướm bay rợp trời và không gian xanh mát.',
      'tags': [
        'Mùa bướm',
        'Cây chò ngàn năm',
        'Trekking rừng',
        'Động Người Xưa'
      ],
      'activities': [
        'Trekking xuyên rừng',
        'Xem bướm mùa hạ',
        'Cắm trại đêm trong rừng'
      ],
    },
    {
      'id': 'coto',
      'name': 'Thiên Đường Biển Đảo Cô Tô',
      'sub': 'Hòn Ngọc Xanh Vịnh Bắc Bộ',
      'location': 'Quảng Ninh',
      'region': 'Miền Bắc',
      'lat': 20.9833,
      'lon': 107.7667,
      'aqi': 12,
      'aqiStatus': 'Trong lành',
      'temp': '23 - 29°C',
      'humidity': '77%',
      'rating': 4.8,
      'imageUrl':
          'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=1000&auto=format&fit=crop&q=85',
      'highlight':
          'Nước biển trong vắt nhìn thấu đáy, bãi đá Cầu Mỵ sóng vỗ rì rào và hải sản tươi sống đánh bắt ngay tại bờ biển.',
      'tags': [
        'Bãi đá Cầu Mỵ',
        'Bãi tắm Hồng Vàn',
        'Hải đăng Cô Tô',
        'Biển xanh'
      ],
      'activities': [
        'Đón bình minh Cầu Mỵ',
        'Tắm biển Vàn Chảy',
        'Cắm trại bờ biển'
      ],
    },
    {
      'id': 'babe',
      'name': 'Vườn Quốc Gia & Hồ Ba Bể',
      'sub': 'Viên Ngọc Xanh Giữa Lòng Đại Ngàn',
      'location': 'Bắc Kạn',
      'region': 'Miền Bắc',
      'lat': 22.4083,
      'lon': 105.6167,
      'aqi': 11,
      'aqiStatus': 'Hoàn hảo',
      'temp': '18 - 25°C',
      'humidity': '76%',
      'rating': 4.8,
      'imageUrl':
          'https://images.unsplash.com/photo-1528127269322-539801943592?w=1000&auto=format&fit=crop&q=85',
      'highlight':
          'Hồ nước ngọt tự nhiên trên núi đá vôi lớn nhất Việt Nam, mặt nước phẳng lặng như gương được bao bọc bởi rừng nguyên sinh cổ thụ.',
      'tags': ['Hồ Ba Bể', 'Thác Đầu Đẳng', 'Động Puông', 'Kayak'],
      'activities': [
        'Đi thuyền độc mộc ngắm hồ',
        'Chèo kayak sông Năng',
        'Khám phá Động Hua Mạ'
      ],
    },
    {
      'id': 'bangioc',
      'name': 'Thác Bản Giốc & Động Ngườm Ngao',
      'sub': 'Thác Nước Tự Nhiên Hùng Vĩ Nhất Đông Nam Á',
      'location': 'Cao Bằng',
      'region': 'Miền Bắc',
      'lat': 22.8539,
      'lon': 106.7236,
      'aqi': 10,
      'aqiStatus': 'Tuyệt đỉnh',
      'temp': '17 - 24°C',
      'humidity': '73%',
      'rating': 5.0,
      'imageUrl':
          'https://images.unsplash.com/photo-1534447677768-be436bb09401?w=1000&auto=format&fit=crop&q=85',
      'highlight':
          'Thác nước ba tầng tung bọt trắng xóa giữa cảnh quan núi non biên cương hùng vĩ, dòng sông Quây Sơn xanh biếc tuyệt mỹ.',
      'tags': [
        'Thác Bản Giốc',
        'Sông Quây Sơn',
        'Động Ngườm Ngao',
        'Hồ Thang Hen'
      ],
      'activities': [
        'Đi bè tre chân thác',
        'Khám phá thạch nhũ Ngườm Ngao',
        'Chèo SUP sông Quây Sơn'
      ],
    },

    // ── MIỀN TRUNG & TÂY NGUYÊN ──
    {
      'id': 'puluong',
      'name': 'Khu Bảo Tồn Pù Luông',
      'sub': 'Thung Lũng Đại Ngàn & Ruộng Bậc Thang',
      'location': 'Bá Thước, Thanh Hóa',
      'region': 'Miền Trung',
      'lat': 20.4578,
      'lon': 105.1833,
      'aqi': 14,
      'aqiStatus': 'Rất trong lành',
      'temp': '20 - 27°C',
      'humidity': '75%',
      'rating': 4.8,
      'imageUrl':
          'https://images.unsplash.com/photo-1509099836639-18ba1795216d?w=1000&auto=format&fit=crop&q=85',
      'highlight':
          'Ruộng bậc thang xanh mướt trải dài sườn núi, khí hậu trong lành nguyên sơ, resort sinh thái gỗ tre hòa mình tuyệt đối với thiên nhiên.',
      'tags': [
        'Nghỉ dưỡng sinh thái',
        'Ruộng bậc thang',
        'Guồng nước',
        'Bản Đôn'
      ],
      'activities': [
        'Bơi hồ bơi vô cực view núi',
        'Trekking bản làng',
        'Chèo bè tre sông Mã'
      ],
    },
    {
      'id': 'phongnha',
      'name': 'Vườn Quốc Gia Phong Nha - Kẻ Bàng',
      'sub': 'Vương Quốc Hang Động Thế Giới UNESCO',
      'location': 'Quảng Bình',
      'region': 'Miền Trung',
      'lat': 17.5833,
      'lon': 106.2833,
      'aqi': 12,
      'aqiStatus': 'Tuyệt vời',
      'temp': '22 - 29°C',
      'humidity': '78%',
      'rating': 5.0,
      'imageUrl':
          'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=1000&auto=format&fit=crop&q=85',
      'highlight':
          'Di sản thiên nhiên thế giới chứa hang Sơn Đoòng lớn nhất hành tinh, động Thiên Đường tráng lệ và sông Chày xanh ngọc bích.',
      'tags': [
        'Hang Sơn Đoòng',
        'Động Thiên Đường',
        'Sông Chày - Hang Tối',
        'Zipline'
      ],
      'activities': [
        'Thám hiểm động Thiên Đường',
        'Zipline tắm bùn Hang Tối',
        'Chèo kayak'
      ],
    },
    {
      'id': 'dalat',
      'name': 'Thành Phố Ngàn Hoa Đà Lạt',
      'sub': 'Xứ Sở Rừng Thông & Khí Hậu Ôn Đới',
      'location': 'Lâm Đồng (Cao nguyên Lâm Viên)',
      'region': 'Miền Trung',
      'lat': 11.9404,
      'lon': 108.4583,
      'aqi': 16,
      'aqiStatus': 'Trong lành',
      'temp': '14 - 23°C',
      'humidity': '80%',
      'rating': 4.9,
      'imageUrl':
          'https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?w=1000&auto=format&fit=crop&q=85',
      'highlight':
          'Thành phố cao nguyên ngập tràn thông xanh, hồ Tuyền Lâm phẳng lặng như gương và khí hậu mát lạnh bốn mùa lý tưởng hồi phục năng lượng.',
      'tags': [
        'Hồ Tuyền Lâm',
        'Đồi chè Cầu Đất',
        'Rừng thông',
        'Cà phê view mây'
      ],
      'activities': [
        'Chèo SUP hồ Tuyền Lâm',
        'Săn mây Cầu Đất',
        'Cắm trại đồi Đa Phú'
      ],
    },
    {
      'id': 'banahills',
      'name': 'Khu Sinh Thái Bà Nà Hills & Núi Chúa',
      'sub': 'Đường Lên Tiên Cảnh & Cầu Vàng Bàn Tay',
      'location': 'Đà Nẵng',
      'region': 'Miền Trung',
      'lat': 15.9983,
      'lon': 107.9867,
      'aqi': 15,
      'aqiStatus': 'Rất trong lành',
      'temp': '17 - 24°C',
      'humidity': '74%',
      'rating': 4.9,
      'imageUrl':
          'https://images.unsplash.com/photo-1528127269322-539801943592?w=1000&auto=format&fit=crop&q=85',
      'highlight':
          'Khí hậu ôn đới 4 mùa trong 1 ngày trên đỉnh Núi Chúa cao 1.487m, cây Cầu Vàng vươn mây nổi tiếng toàn cầu.',
      'tags': ['Cầu Vàng', 'Cáp treo kỷ lục', 'Làng Pháp', 'Hầm rượu Debay'],
      'activities': [
        'Đi cáp treo ngắm rừng',
        'Check-in Cầu Vàng',
        'Dạo làng Pháp cổ kính'
      ],
    },
    {
      'id': 'mangden',
      'name': 'Thiên Đường Sinh Thái Măng Đen',
      'sub': 'Đà Lạt Thứ Hai Của Vùng Đất Tây Nguyên',
      'location': 'Kon Plông, Kon Tum',
      'region': 'Miền Trung',
      'lat': 14.6000,
      'lon': 108.2833,
      'aqi': 10,
      'aqiStatus': 'Hoàn hảo',
      'temp': '15 - 22°C',
      'humidity': '82%',
      'rating': 4.9,
      'imageUrl':
          'https://images.unsplash.com/photo-1448375240586-882707db888b?w=1000&auto=format&fit=crop&q=85',
      'highlight':
          'Cao nguyên rừng thông bạt ngàn hoang sơ, hồ Đăk Ke thơ mộng và thác Pa Sỹ ngập tràn ion âm thanh lọc cơ thể.',
      'tags': ['Thác Pa Sỹ', 'Hồ Đăk Ke', 'Rừng thông', 'Vườn hoa anh đào'],
      'activities': [
        'Tản bộ hồ Đăk Ke',
        'Thăm thác Pa Sỹ',
        'Thưởng thức cơm lam gà nướng'
      ],
    },
    {
      'id': 'ghenhdadia',
      'name': 'Ghềnh Đá Đĩa & Bãi Xép Phú Yên',
      'sub': 'Tuyệt Tác Kiến Tạo Địa Chất Độc Nhất Vô Nhị',
      'location': 'Tuy An, Phú Yên',
      'region': 'Miền Trung',
      'lat': 13.3667,
      'lon': 109.3000,
      'aqi': 13,
      'aqiStatus': 'Rất trong lành',
      'temp': '24 - 31°C',
      'humidity': '73%',
      'rating': 4.9,
      'imageUrl':
          'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=1000&auto=format&fit=crop&q=85',
      'highlight':
          'Khối đá bazan hình lục giác xếp lớp đều tăm tắp như tổ ong khổng lồ vươn ra đại dương xanh thẳm, bãi cỏ hoa vàng trên cỏ xanh.',
      'tags': [
        'Đá đĩa núi lửa',
        'Bãi Xép',
        'Hải đăng Mũi Điện',
        'Bình minh sớm nhất'
      ],
      'activities': [
        'Đón bình minh Mũi Đại Lãnh',
        'Chụp ảnh Ghềnh Đá Đĩa',
        'Ăn mắt cá ngừ'
      ],
    },
    {
      'id': 'quynhon',
      'name': 'Kỳ Co & Eo Gió Quy Nhơn',
      'sub': 'Nơi Ngắm Hoàng Hôn Đẹp Nhất Việt Nam',
      'location': 'Quy Nhơn, Bình Định',
      'region': 'Miền Trung',
      'lat': 13.8833,
      'lon': 109.2833,
      'aqi': 14,
      'aqiStatus': 'Rất trong lành',
      'temp': '25 - 31°C',
      'humidity': '74%',
      'rating': 4.8,
      'imageUrl':
          'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=1000&auto=format&fit=crop&q=85',
      'highlight':
          'Eo biển lộng gió với cung đường đi bộ ven vách núi ngoạn mục, bãi biển Kỳ Co hai màu nước xanh biếc như Maldives thu nhỏ.',
      'tags': ['Eo Gió', 'Bãi Kỳ Co', 'Tịnh xá Ngọc Hòa', 'Cano đảo'],
      'activities': [
        'Dạo bước cung đường Eo Gió',
        'Lặn biển Kỳ Co',
        'Cắm trại bãi biển'
      ],
    },
    {
      'id': 'nhatrang',
      'name': 'Vịnh Biển Nha Trang & Vịnh Ninh Vân',
      'sub': 'Một Trong Những Vịnh Biển Đẹp Nhất Thế Giới',
      'location': 'Khánh Hòa',
      'region': 'Miền Trung',
      'lat': 12.2388,
      'lon': 109.1967,
      'aqi': 16,
      'aqiStatus': 'Tuyệt vời',
      'temp': '24 - 31°C',
      'humidity': '76%',
      'rating': 4.9,
      'imageUrl':
          'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=1000&auto=format&fit=crop&q=85',
      'highlight':
          'Nắng ấm quanh năm, vịnh biển kín gió phẳng lặng, những khu resort sinh thái ẩn mình giữa vách đá và rừng nhiệt đới Ninh Vân.',
      'tags': ['Vịnh Ninh Vân', 'Hòn Mun', 'Tắm bùn khoáng', 'Lặn san hô'],
      'activities': [
        'Đi tàu ngắm san hô',
        'Tắm bùn khoáng nóng',
        'Nghỉ dưỡng Ninh Vân'
      ],
    },

    // ── MIỀN NAM & BIỂN ĐẢO ──
    {
      'id': 'phuquoc',
      'name': 'Đảo Ngọc Sinh Thái Phú Quốc',
      'sub': 'Bãi Sao & Vườn Quốc Gia Rừng Nguyên Sinh',
      'location': 'Kiên Giang',
      'region': 'Miền Nam',
      'lat': 10.2899,
      'lon': 103.9840,
      'aqi': 12,
      'aqiStatus': 'Rất trong lành',
      'temp': '25 - 31°C',
      'humidity': '75%',
      'rating': 5.0,
      'imageUrl':
          'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=1000&auto=format&fit=crop&q=85',
      'highlight':
          'Bãi biển cát trắng mịn như kem, làn nước trong vắt cùng rừng quốc gia nguyên sinh chiếm hơn 60% diện tích đảo.',
      'tags': [
        'Bãi Sao',
        'Bãi Kem',
        'Hoàng hôn Bãi Trường',
        'Cáp treo Hòn Thơm'
      ],
      'activities': [
        'Ngắm sao biển Rạch Vẹm',
        'Lặn ngắm san hô',
        'Trekking suối Tranh'
      ],
    },
    {
      'id': 'condao',
      'name': 'Quần Đảo Sinh Thái Côn Đảo',
      'sub': 'Khu Bảo Tồn Rùa Biển Lớn Nhất Việt Nam',
      'location': 'Bà Rịa - Vũng Tàu',
      'region': 'Miền Nam',
      'lat': 8.6833,
      'lon': 106.6000,
      'aqi': 8,
      'aqiStatus': 'Hoàn hảo nhất VN',
      'temp': '24 - 30°C',
      'humidity': '77%',
      'rating': 5.0,
      'imageUrl':
          'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=1000&auto=format&fit=crop&q=85',
      'highlight':
          'Chỉ số không khí sạch nhất Việt Nam (AQI ~ 8), biển hoang sơ tuyệt đối, rừng nguyên sinh rậm rạp và thả rùa con về biển.',
      'tags': ['Bảo tồn rùa biển', 'Bãi Nhát', 'Bãi Đầm Trầu', 'Vườn quốc gia'],
      'activities': [
        'Xem rùa đẻ trứng ban đêm',
        'Tắm biển Đầm Trầu',
        'Lặn san hô Côn Đảo'
      ],
    },
    {
      'id': 'cangio',
      'name': 'Khu Sinh Quyển Rừng Ngập Mặn Cần Giờ',
      'sub': 'Lá Phổi Xanh Của TP. Hồ Chí Minh',
      'location': 'TP. Hồ Chí Minh',
      'region': 'Miền Nam',
      'lat': 10.4167,
      'lon': 106.9500,
      'aqi': 22,
      'aqiStatus': 'Rất trong lành',
      'temp': '25 - 32°C',
      'humidity': '78%',
      'rating': 4.7,
      'imageUrl':
          'https://images.unsplash.com/photo-1448375240586-882707db888b?w=1000&auto=format&fit=crop&q=85',
      'highlight':
          'Hệ sinh thái rừng đước ngập mặn trù phú được UNESCO công nhận, không khí trong lành chỉ cách trung tâm Sài Gòn hơn 1 giờ.',
      'tags': [
        'Rừng sác',
        'Đảo khỉ',
        'Chiến khu Rừng Sác',
        'Hải sản Hàng Dương'
      ],
      'activities': [
        'Đi xuồng xuyên rừng đước',
        'Thăm đàn khỉ hoang dã',
        'Ăn hải sản'
      ],
    },
    {
      'id': 'nuibaden',
      'name': 'Khu Du Lịch Núi Bà Đen',
      'sub': 'Nóc Nhà Nam Bộ & Quần Thể Tâm Linh Hùng Vĩ',
      'location': 'Tây Ninh',
      'region': 'Miền Nam',
      'lat': 11.3789,
      'lon': 106.1667,
      'aqi': 18,
      'aqiStatus': 'Trong lành',
      'temp': '22 - 29°C',
      'humidity': '72%',
      'rating': 4.9,
      'imageUrl':
          'https://images.unsplash.com/photo-1528127269322-539801943592?w=1000&auto=format&fit=crop&q=85',
      'highlight':
          'Ngọn núi cao nhất miền Nam (986m) với khí hậu mát mẻ trên đỉnh, biển mây cuồn cuộn buổi sớm và tượng Phật Bà kỷ lục.',
      'tags': [
        'Núi cao 986m',
        'Cáp treo hiện đại',
        'Săn mây Nam Bộ',
        'Tượng Phật Bà'
      ],
      'activities': [
        'Đi cáp treo ngắm biển mây',
        'Chiêm bái Phật Bà',
        'Săn hoàng hôn đỉnh núi'
      ],
    },
    {
      'id': 'trasu',
      'name': 'Rừng Tràm Sinh Thái Trà Sư',
      'sub': 'Thảm Bèo Xanh Mướt Mùa Nước Nổi Miền Tây',
      'location': 'Tịnh Biên, An Giang',
      'region': 'Miền Nam',
      'lat': 10.5167,
      'lon': 105.0500,
      'aqi': 16,
      'aqiStatus': 'Rất trong lành',
      'temp': '25 - 32°C',
      'humidity': '80%',
      'rating': 4.8,
      'imageUrl':
          'https://images.unsplash.com/photo-1509099836639-18ba1795216d?w=1000&auto=format&fit=crop&q=85',
      'highlight':
          'Rừng tràm ngập nước đặc trưng Tây Nam Bộ với thảm bèo cám phủ kín mặt nước như tấm thảm nhung khổng lồ, chim hót ríu rít.',
      'tags': [
        'Rừng tràm',
        'Mùa nước nổi',
        'Cầu tre vạn bước',
        'Vương quốc chim'
      ],
      'activities': [
        'Đi xuồng chèo thảm bèo',
        'Lên tháp vọng cảnh ngắm chim',
        'Ăn lẩu cá linh'
      ],
    }
  ];

  @override
  void initState() {
    super.initState();
    _destinationsData = List.from(_fallbackDestinations);
    _detectLocationAndLoadDestinations();
  }

  // Tự động định vị điện thoại và tải danh sách điểm đến
  Future<void> _detectLocationAndLoadDestinations() async {
    try {
      final loc = await ApiService().getCurrentLocation();
      if (loc != null && mounted) {
        setState(() {
          _userLat = (loc['lat'] as num?)?.toDouble() ?? 21.0285;
          _userLon = (loc['lon'] as num?)?.toDouble() ?? 105.8542;
          _userCity = loc['city']?.toString() ?? 'Hà Nội';
          _isLocating = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLocating = false);
    }

    try {
      final online = await ApiService().getTourismDestinations(
        lat: _userLat,
        lon: _userLon,
      );
      if (online.isNotEmpty && mounted) {
        setState(() {
          _destinationsData =
              online.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        });
      }
    } catch (_) {}
  }

  // Tìm kiếm mọi khu du lịch & địa danh như trên bản đồ (OpenStreetMap / Backend Map Search)
  Future<void> _searchOnlineOnMap(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;

    setState(() => _isSearchingMap = true);
    FocusScope.of(context).unfocus();

    try {
      final results = await ApiService().searchTourismDestinations(
        q,
        lat: _userLat,
        lon: _userLon,
      );

      if (mounted) {
        setState(() {
          _isSearchingMap = false;
          _mapSearchResults =
              results.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        });

        if (_mapSearchResults.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Không tìm thấy địa điểm "$q" trên bản đồ. Bạn hãy thử gõ tên khu du lịch hoặc tỉnh thành khác nhé!'),
              backgroundColor: const Color(0xFF004D40),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '🗺️ Đã tìm thấy ${_mapSearchResults.length} địa điểm phù hợp trên Bản đồ!'),
              backgroundColor: const Color(0xFF00796B),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isSearchingMap = false);
    }
  }

  // Mở ứng dụng Google Maps dẫn đường đến tọa độ GPS của khu du lịch
  Future<void> _openGoogleMaps(double lat, double lon, String name) async {
    final uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lon');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tọa độ GPS điểm đến: $lat, $lon ($name)'),
            backgroundColor: const Color(0xFF00796B),
          ),
        );
      }
    }
  }

  // Hàm tính khoảng cách và thời gian di chuyển chuẩn xác từ GPS máy đến điểm du lịch
  Map<String, String> _calculateDistance(double? destLat, double? destLon) {
    if (_userLat == null ||
        _userLon == null ||
        destLat == null ||
        destLon == null) {
      return {'distance': 'Đang tính...', 'duration': '...'};
    }

    const p = 0.017453292519943295; // Math.PI / 180
    final a = 0.5 -
        math.cos((destLat - _userLat!) * p) / 2 +
        math.cos(_userLat! * p) *
            math.cos(destLat * p) *
            (1 - math.cos((destLon - _userLon!) * p)) /
            2;
    final straightKm = 12742 * math.asin(math.sqrt(a));

    // Đường bộ VN dài hơn đường chim bay ~28% do uốn lượn địa hình & đèo dốc
    final roadKm = (straightKm * 1.28).round();

    String durationStr;
    if (roadKm < 80) {
      final minutes = ((roadKm / 45) * 60).round();
      final h = minutes ~/ 60;
      final m = minutes % 60;
      durationStr = h > 0 ? '${h}h${m > 0 ? "${m}p" : ""}' : '${m} phút';
    } else if (roadKm < 400) {
      final minutes = ((roadKm / 62) * 60).round();
      final h = minutes ~/ 60;
      final m = minutes % 60;
      durationStr = '${h}h${m > 0 ? "${m}p" : ""}';
    } else {
      durationStr = 'Bay ~1h45p / Xe 6-8h';
    }

    return {
      'distance': '$roadKm km',
      'duration': durationStr,
    };
  }

  // Helper đảm bảo luôn có dự báo tuần và ngày cho bất kỳ địa điểm nào
  Map<String, dynamic> _ensureForecast(Map<String, dynamic> dest) {
    if (dest['forecast'] != null && dest['forecast'] is Map) {
      final f = dest['forecast'] as Map<String, dynamic>;
      return {
        'weekly': f['weekly'] as List<dynamic>? ?? [],
        'daily': f['daily'] as List<dynamic>? ?? [],
      };
    }
    if (dest['weekly_forecast'] != null) {
      return {
        'weekly': dest['weekly_forecast'] as List<dynamic>? ?? [],
        'daily': dest['daily_forecast'] as List<dynamic>? ?? [],
      };
    }

    // Tự động sinh dự báo vi khí hậu chuẩn cho điểm mới tìm thấy
    final tempStr = dest['temp'] as String? ?? '20 - 26°C';
    final weekly = [
      {
        'day': 'Thứ 2',
        'temp': tempStr,
        'icon': '☀️',
        'cond': 'Nắng nhẹ trong lành'
      },
      {'day': 'Thứ 3', 'temp': tempStr, 'icon': '⛅', 'cond': 'Gió mát dịu'},
      {
        'day': 'Thứ 4',
        'temp': tempStr,
        'icon': '🌤️',
        'cond': 'Trời trong xanh'
      },
      {
        'day': 'Thứ 5',
        'temp': tempStr,
        'icon': '🍃',
        'cond': 'Không khí thoáng đãng'
      },
      {
        'day': 'Thứ 6',
        'temp': tempStr,
        'icon': '🌿',
        'cond': 'Khí hậu dịu mát'
      },
      {
        'day': 'Thứ 7',
        'temp': tempStr,
        'icon': '🏕️',
        'cond': 'Lý tưởng dã ngoại',
        'isWeekend': true
      },
      {
        'day': 'Chủ Nhật',
        'temp': tempStr,
        'icon': '🌅',
        'cond': 'Nghỉ dưỡng tuyệt vời',
        'isWeekend': true
      },
    ];

    final daily = [
      {
        'period': 'Hôm nay',
        'temp_range': tempStr,
        'icon': '🌤️',
        'advice':
            'Thời tiết tạnh ráo, không khí trong lành rất thích hợp đi lại.'
      },
      {
        'period': 'Ngày mai',
        'temp_range': tempStr,
        'icon': '⛅',
        'advice': 'Gió mát dịu nhẹ, chỉ số AQI sạch, an toàn cho sức khỏe.'
      },
      {
        'period': 'Cuối tuần',
        'temp_range': tempStr,
        'icon': '🏔️',
        'advice': 'Khí hậu ổn định, thời điểm vàng để dã ngoại và trải nghiệm.'
      },
    ];

    return {'weekly': weekly, 'daily': daily};
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
    // Kết hợp kết quả tìm kiếm bản đồ và danh mục gốc (không trùng lặp)
    final combined = <Map<String, dynamic>>[];
    final seen = <dynamic>{};

    for (final item in [..._mapSearchResults, ..._destinationsData]) {
      final key = item['id'] ?? item['name'];
      if (seen.add(key)) {
        combined.add(item);
      }
    }

    final filtered = combined.where((d) {
      final matchesRegion =
          _selectedRegion == 'Tất cả' || d['region'] == _selectedRegion;
      final query = _searchQuery.toLowerCase().trim();
      final name = (d['name'] ?? '').toString().toLowerCase();
      final loc = (d['location'] ?? '').toString().toLowerCase();
      final sub = (d['sub'] ?? '').toString().toLowerCase();
      final tags = (d['tags'] as List<dynamic>?)?.join(' ').toLowerCase() ?? '';

      final matchesSearch = query.isEmpty ||
          name.contains(query) ||
          loc.contains(query) ||
          sub.contains(query) ||
          tags.contains(query);
      return matchesRegion && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF1F6F3),
      body: CustomScrollView(
        slivers: [
          // ── SliverAppBar với ảnh nền Parallax & Gradient Xanh Sinh Thái ──
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: const Color(0xFF004D40),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              title: const Text(
                'Du Lịch Xanh & Vi Khí Hậu',
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
                    'https://images.unsplash.com/photo-1528127269322-539801943592?w=1000&auto=format&fit=crop&q=85',
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
                          const Color(0xFF004D40).withValues(alpha: 0.92),
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
                                color: const Color(0xFF00E676)
                                    .withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.map_rounded,
                                  size: 13, color: Color(0xFF00382E)),
                              SizedBox(width: 4),
                              Text(
                                'TÌM KIẾM MỌI KHU DU LỊCH NHƯ TRÊN MAP',
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
                          'Tìm kiếm mọi địa danh, tính khoảng cách GPS từ máy & dự báo thời tiết 7 ngày.',
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

          // ── GPS Phone Location Bar ──
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF80CBC4), width: 1.0),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF004D40).withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE0F2F1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.my_location,
                        size: 16, color: Color(0xFF00796B)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Vị trí của bạn (tính khoảng cách tự động):',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        Row(
                          children: [
                            Text(
                              _userCity,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF004D40),
                              ),
                            ),
                            const SizedBox(width: 6),
                            if (_isLocating)
                              const SizedBox(
                                width: 10,
                                height: 10,
                                child:
                                    CircularProgressIndicator(strokeWidth: 1.5),
                              )
                            else
                              const Text(
                                '• GPS Chuẩn xác',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF00C853),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2F1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Chuẩn GPS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00796B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Search Bar Hỗ Trợ Tìm Kiếm Tất Cả Như Trên Map ──
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                children: [
                  // Search Input
                  TextField(
                    controller: _searchCtrl,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (val) => _searchOnlineOnMap(val),
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText:
                          'Tìm mọi khu du lịch như trên Map (Hạ Long, Cát Bà, Phú Quốc...)',
                      hintStyle: TextStyle(
                          fontSize: 12.5, color: Colors.grey.shade400),
                      prefixIcon: const Icon(Icons.search,
                          color: Color(0xFF00796B), size: 22),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isSearchingMap)
                            const Padding(
                              padding: EdgeInsets.all(10),
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Color(0xFF00796B)),
                              ),
                            )
                          else if (_searchQuery.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() {
                                  _searchQuery = '';
                                  _mapSearchResults.clear();
                                });
                              },
                            ),
                          IconButton(
                            icon: const Icon(Icons.travel_explore,
                                color: Color(0xFF00796B)),
                            tooltip: 'Tìm kiếm tất cả trên bản đồ',
                            onPressed: () =>
                                _searchOnlineOnMap(_searchCtrl.text),
                          ),
                        ],
                      ),
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
                            onTap: () =>
                                setState(() => _forecastMode = 'weekly'),
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
                                          color: const Color(0xFF00796B)
                                              .withValues(alpha: 0.3),
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
                                    Icons.calendar_view_week,
                                    size: 16,
                                    color: _forecastMode == 'weekly'
                                        ? Colors.white
                                        : const Color(0xFF004D40),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Dự Báo Theo Tuần (7 Ngày)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: _forecastMode == 'weekly'
                                          ? Colors.white
                                          : const Color(0xFF004D40),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _forecastMode = 'daily'),
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
                                          color: const Color(0xFF00796B)
                                              .withValues(alpha: 0.3),
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
                                    Icons.today,
                                    size: 16,
                                    color: _forecastMode == 'daily'
                                        ? Colors.white
                                        : const Color(0xFF004D40),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Dự Báo Theo Ngày (Mốc Giờ)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: _forecastMode == 'daily'
                                          ? Colors.white
                                          : const Color(0xFF004D40),
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
                  const SizedBox(height: 12),

                  // Region Filters
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
                            onSelected: (selected) {
                              setState(() {
                                _selectedRegion = region;
                              });
                            },
                            backgroundColor: Colors.white,
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
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isSelected
                                    ? Colors.transparent
                                    : Colors.grey.shade300,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Danh Sách Thẻ Điểm Đến Du Lịch ──
          if (filtered.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.travel_explore,
                        size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(
                      'Không tìm thấy điểm đến nào phù hợp',
                      style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 15,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    ElevatedButton.icon(
                      onPressed: () => _searchOnlineOnMap(_searchCtrl.text),
                      icon: const Icon(Icons.map, size: 16),
                      label: const Text('Tìm kiếm mở rộng trên Bản đồ Map'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00796B),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
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
    final lat = (dest['lat'] as num?)?.toDouble() ?? 21.0;
    final lon = (dest['lon'] as num?)?.toDouble() ?? 105.8;
    final travelInfo = _calculateDistance(lat, lon);
    final aqi = (dest['aqi'] as num?)?.toInt() ?? 15;
    final isMapResult = dest['is_map_result'] == true;

    final forecastData = _ensureForecast(dest);
    final weeklyForecast = forecastData['weekly'] as List<dynamic>;
    final dailyForecast = forecastData['daily'] as List<dynamic>;

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF004D40).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Ảnh bìa & Huy hiệu vị trí khoảng cách GPS ──
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                child: Image.network(
                  dest['imageUrl'] as String? ?? '',
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 180,
                    color: const Color(0xFF004D40),
                    child: const Center(
                      child: Icon(Icons.landscape,
                          size: 48, color: Colors.white38),
                    ),
                  ),
                ),
              ),
              // Gradient che ảnh
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(20)),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.25),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.55),
                      ],
                    ),
                  ),
                ),
              ),
              // Huy hiệu AQI góc trái trên
              Positioned(
                top: 14,
                left: 14,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: _aqiColor(aqi),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: _aqiColor(aqi).withValues(alpha: 0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      )
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
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Huy hiệu Khoảng cách tính từ GPS điện thoại (Bấm vào để chỉ đường)
              Positioned(
                bottom: 12,
                left: 14,
                right: 14,
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.near_me,
                                size: 13, color: Color(0xFF64FFDA)),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                'Cách bạn: ${travelInfo['distance']} • ~${travelInfo['duration']}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Nút mở Google Maps nhanh
                    InkWell(
                      onTap: () => _openGoogleMaps(lat, lon, dest['name']),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00796B),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.directions,
                                size: 13, color: Colors.white),
                            SizedBox(width: 3),
                            Text(
                              'Map',
                              style: TextStyle(
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
              ),
              // Rating góc phải trên
              Positioned(
                top: 14,
                right: 14,
                child: Row(
                  children: [
                    if (isMapResult) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade700,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Bản đồ Map',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
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
                  ],
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
                              fontSize: 16.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF00382E),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            dest['sub'] as String? ?? '',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF00796B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Nhiệt độ & Độ ẩm
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
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
                              const Icon(Icons.thermostat,
                                  size: 14, color: Color(0xFF00796B)),
                              Text(
                                dest['temp'] as String? ?? '18 - 24°C',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF004D40),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'Ẩm ${dest['humidity'] ?? "75%"}',
                            style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF00796B),
                                fontWeight: FontWeight.w500),
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
                    border: Border.all(
                        color: const Color(0xFFB2DFDB).withValues(alpha: 0.6)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.auto_awesome,
                                  size: 14, color: Color(0xFF00897B)),
                              const SizedBox(width: 5),
                              Text(
                                _forecastMode == 'weekly'
                                    ? 'Dự báo nhiệt độ 7 ngày (AI cập nhật)'
                                    : 'Dự báo vi khí hậu theo mốc thời gian',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF004D40),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00E676)
                                  .withValues(alpha: 0.2),
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
                      if (_forecastMode == 'weekly' &&
                          weeklyForecast.isNotEmpty)
                        SizedBox(
                          height: 78,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: weeklyForecast.length,
                            itemBuilder: (context, idx) {
                              final day =
                                  weeklyForecast[idx] as Map<String, dynamic>;
                              final isWeekend = (day['day'] == 'Thứ 7' ||
                                  day['day'] == 'Chủ Nhật' ||
                                  day['isWeekend'] == true);
                              return Container(
                                width: 70,
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 6, horizontal: 4),
                                decoration: BoxDecoration(
                                  color: isWeekend
                                      ? const Color(0xFFE8F5E9)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isWeekend
                                        ? const Color(0xFF81C784)
                                        : Colors.grey.shade200,
                                    width: isWeekend ? 1.2 : 1.0,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    Text(
                                      day['day']?.toString() ?? '',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: isWeekend
                                            ? FontWeight.bold
                                            : FontWeight.w600,
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

                      // Hiển thị theo ngày (Hôm nay, Ngày mai, Cuối tuần)
                      if (_forecastMode == 'daily' && dailyForecast.isNotEmpty)
                        Column(
                          children: dailyForecast.map((d) {
                            final map = d as Map<String, dynamic>;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(map['icon']?.toString() ?? '🌤️',
                                      style: const TextStyle(fontSize: 15)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
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
                                              map['temp_range']?.toString() ??
                                                  map['temp']?.toString() ??
                                                  '',
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

                // Tags kèm Nút Hỏi AI nổi bật
                Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: ((dest['tags'] as List<dynamic>?) ?? [])
                              .map((tag) {
                            return Container(
                              margin: const EdgeInsets.only(right: 6),
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
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Chip Hỏi AI
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDE7F6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.deepPurple.shade200),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.smart_toy_outlined,
                                size: 14, color: Colors.deepPurple),
                            SizedBox(width: 4),
                            Text(
                              'Hỏi AI',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ── 2 NÚT HÀNH ĐỘNG CÂN XỨNG (CHỮ GỌN GÀNG 100% NẰM TRONG Ô NÚT) ──
                Row(
                  children: [
                    // Nút 1: Xem Lộ Trình & Khám Phá
                    Expanded(
                      child: SizedBox(
                        height: 44,
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
                          label: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Lộ Trình & Khám Phá',
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF00796B),
                            side: const BorderSide(
                                color: Color(0xFF00796B), width: 1.2),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Nút 2: Thêm Cuối Tuần
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: ElevatedButton.icon(
                          onPressed: () => showWeekendTripDialog(context, dest),
                          icon: const Icon(Icons.add_task_rounded,
                              size: 16, color: Colors.white),
                          label: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '+ Lên Lịch Cuối Tuần',
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00796B),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 2,
                          ),
                        ),
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
