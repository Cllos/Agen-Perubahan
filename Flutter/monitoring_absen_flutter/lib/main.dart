import 'package:flutter/material.dart';
import 'pages/Login_pages.dart'; // Pastikan path import benar

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
      theme: ThemeData(
        primarySwatch: Colors.blue,
        // Opsional: Setting font default atau warna global
        scaffoldBackgroundColor: Colors.grey[50],
      ),
      // Langsung panggil LoginPages()
      // Navigasi ke Home sudah diatur di dalam _handleLogin pada Login_pages.dart
      home: const LoginPages(), 
    );
  }
}