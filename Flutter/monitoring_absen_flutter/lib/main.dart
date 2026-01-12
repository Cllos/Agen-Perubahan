import 'package:flutter/material.dart';
import 'pages/Login_pages.dart'; // Import halaman Login
import 'pages/BottomNav.dart';   // Import halaman Utama (BottomNav)

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Monitoring Absen',
      // Home diganti menjadi Wrapper untuk Login
      home: const LoginWrapper(), 
    );
  }
}

// Widget Wrapper untuk menangani Navigasi dari Login ke Home
class LoginWrapper extends StatelessWidget {
  const LoginWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return LoginScreen(
      onLogin: () {
        // Logika Pindah Halaman:
        // pushReplacement digunakan agar user tidak bisa kembali ke halaman login 
        // dengan tombol Back setelah berhasil login.
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const BottomNav()),
        );
      },
    );
  }
}