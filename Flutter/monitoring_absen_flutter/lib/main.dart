import 'package:flutter/material.dart';
import 'pages/AttendancePages.dart';
import 'pages/HistoryPages.dart';
import 'pages/HomePages.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const BottomNav(),
    );
  }
}

class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  int _selectedIndex = 0;

  // Hapus GlobalKey karena kita akan menggunakan gesture swipe alami Scaffold
  
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
      // Drawer diletakkan di sini agar bisa di-swipe dari kiri di semua halaman
      drawer: const AppDrawer(), 
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.check_circle), label: 'Attendance'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
        ],
      ),
    );
  }
}
