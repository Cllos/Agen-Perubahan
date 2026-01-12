import 'package:flutter/material.dart';
import 'HomePages.dart';
import 'AttendancePages.dart';
import 'HistoryPages.dart';
import '../widgets/AppDrawer.dart';

class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  int _selectedIndex = 0;
  
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const HomePages(),
      const AttendancePages(),
      const HistoryPages(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Drawer agar bisa di-swipe dari kiri di semua halaman
      drawer: const AppDrawer(), 
      body: _pages[_selectedIndex],
      // GANTI BottomNavigationBar bawaan dengan CustomBottomNavigation
      bottomNavigationBar: CustomBottomNavigation(
        selectedIndex: _selectedIndex,
        onItemTapped: (index) {
          setState(() => _selectedIndex = index);
        },
      ),
    );
  }
}

// --- WIDGET CUSTOM BOTTOM NAVIGATION ---
class CustomBottomNavigation extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const CustomBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: Color(0xFFE5E7EB), width: 1), // border-gray-200
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1), // shadow-lg simulation
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 65, // Tinggi navbar
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home, "Home"),
              _buildNavItem(1, Icons.assignment, "Attendance"), // ClipboardList equivalent
              _buildNavItem(2, Icons.history, "History"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final bool isActive = selectedIndex == index;
    final color = isActive ? Colors.blue.shade600 : Colors.grey.shade500;

    return Expanded(
      child: GestureDetector(
        onTap: () => onItemTapped(index),
        behavior: HitTestBehavior.opaque, // Agar seluruh area bisa diklik
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon Container relative for the dot
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Icon dengan animasi scale
                AnimatedScale(
                  scale: isActive ? 1.1 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                
                // Dot Indicator (muncul jika active)
                if (isActive)
                  Positioned(
                    bottom: -8, // -bottom-2 equivalent
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade600,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            // Label Text
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}