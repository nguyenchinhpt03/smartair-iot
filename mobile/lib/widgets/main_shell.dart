import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../screens/dashboard_screen.dart';
import '../screens/chat_screen.dart';
import '../screens/eco_tourism_screen.dart';
import '../screens/history_screen.dart';
import '../screens/notifications_screen.dart';

/// Main navigation shell with floating bottom nav bar.
/// Home (index 2) is the center prominent button.
class MainShell extends StatefulWidget {
  final String deviceId;
  final int userId;
  final int initialIndex;

  const MainShell({
    super.key,
    required this.deviceId,
    required this.userId,
    this.initialIndex = 2,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _currentIndex;
  int _unreadCount = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pages = [
      HistoryScreen(deviceId: widget.deviceId),
      ChatScreen(deviceId: widget.deviceId),
      DashboardScreen(deviceId: widget.deviceId, userId: widget.userId),
      const EcoTourismScreen(),
      NotificationsScreen(userId: widget.userId),
    ];
  }

  void _onTap(int index) {
    if (index == 4) setState(() => _unreadCount = 0);
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.white,
      ),
      child: Scaffold(
        body: IndexedStack(index: _currentIndex, children: _pages),
        extendBody: false,
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  Widget _buildBottomNav() {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        height: 72,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.97),
          borderRadius: BorderRadius.circular(36),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF004D40).withValues(alpha: 0.14),
              blurRadius: 28,
              offset: const Offset(0, 8),
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.9),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _navItem(0, Icons.show_chart_outlined, Icons.show_chart_rounded,
                'Lịch sử'),
            _navItem(1, Icons.auto_awesome_outlined, Icons.auto_awesome,
                'Trợ lý AI'),
            _homeBtn(),
            _navItem(3, Icons.landscape_outlined, Icons.landscape_rounded,
                'Du lịch'),
            _navBadge(4, Icons.notifications_none_rounded,
                Icons.notifications_rounded, 'Thông báo'),
          ],
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, IconData activeIcon, String label) {
    final isActive = _currentIndex == index;
    const activeColor = Color(0xFF00796B);
    final inactiveColor = Colors.grey.shade400;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: isActive
                    ? activeColor.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                isActive ? activeIcon : icon,
                size: 24,
                color: isActive ? activeColor : inactiveColor,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                color: isActive ? activeColor : inactiveColor,
                letterSpacing: 0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _navBadge(
      int index, IconData icon, IconData activeIcon, String label) {
    final isActive = _currentIndex == index;
    const activeColor = Color(0xFF00796B);
    final inactiveColor = Colors.grey.shade400;
    Widget iconW = Icon(
      isActive ? activeIcon : icon,
      size: 24,
      color: isActive ? activeColor : inactiveColor,
    );
    if (_unreadCount > 0) {
      iconW = Badge(
        label: Text(
          _unreadCount > 99 ? '99+' : '$_unreadCount',
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.redAccent,
        child: iconW,
      );
    }
    return Expanded(
      child: GestureDetector(
        onTap: () => _onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: isActive
                    ? activeColor.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: iconW,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                color: isActive ? activeColor : inactiveColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _homeBtn() {
    final isActive = _currentIndex == 2;
    return GestureDetector(
      onTap: () => _onTap(2),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutBack,
              width: isActive ? 56 : 50,
              height: isActive ? 56 : 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00897B), Color(0xFF004D40)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00796B).withValues(
                      alpha: isActive ? 0.5 : 0.25,
                    ),
                    blurRadius: isActive ? 18 : 10,
                    offset: const Offset(0, 4),
                    spreadRadius: isActive ? 2 : 0,
                  ),
                ],
                border: Border.all(color: Colors.white, width: 2.5),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.home_rounded,
                      color: Colors.white, size: isActive ? 28 : 24),
                  if (isActive)
                    Positioned(
                      bottom: 5,
                      child: Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: Color(0xFF64FFDA),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Home',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isActive ? FontWeight.w900 : FontWeight.w600,
                color:
                    isActive ? const Color(0xFF004D40) : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
