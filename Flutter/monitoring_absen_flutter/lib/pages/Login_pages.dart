import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'BottomNav.dart'; 

class LoginPages extends StatefulWidget {
  const LoginPages({super.key});

  @override
  State<LoginPages> createState() => _LoginPagesState();
}

class _LoginPagesState extends State<LoginPages> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _rememberMe = false;
  bool _isLoading = false;

  // --- GANTI IP DI SINI SESUAI LAPTOP ANDA ---
  final String apiUrl = "http://10.63.23.253:5000/api/login"; 

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    String username = _usernameController.text.trim();
    String password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showSnackBar("Username dan Password harus diisi", Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": username,
          "password": password,
        }),
      );

      final data = jsonDecode(response.body);

      if (!mounted) return; 

      if (response.statusCode == 200) {
        _showSnackBar("Login Berhasil! Selamat datang ${data['user']['name']}", Colors.green);
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (context) => const BottomNav())
        );

      } else if (response.statusCode == 403) {
        _showSnackBar("Akses Ditolak: Karyawan tidak dapat login di aplikasi ini.", Colors.orange);
      } else {
        _showSnackBar(data['message'] ?? "Login Gagal", Colors.red);
      }
    } catch (e) {
      _showSnackBar("Gagal terhubung ke server. Pastikan IP benar.", Colors.red);
      print("Error Login: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade600,
              Colors.blue.shade900,
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ICON HEADER 
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(Icons.admin_panel_settings, size: 50, color: Colors.blue.shade800),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "AttendEase",
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2),
                ),
                const SizedBox(height: 8),
                Text(
                  "Admin & Security Access",
                  style: TextStyle(color: Colors.blue.shade100, fontSize: 16),
                ),
                const SizedBox(height: 50),

                // CARD LOGIN 
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 400),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 25,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        "Welcome Back",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Username Input
                      _buildInputLabel("Username"),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _usernameController,
                        decoration: _inputDecoration(
                          hint: "Masukkan Username",
                          icon: Icons.person_outline,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Password Input
                      _buildInputLabel("Password"),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: _inputDecoration(
                          hint: "Masukkan Password",
                          icon: Icons.lock_outline,
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Tombol Login
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 5,
                            shadowColor: Colors.blue.withOpacity(0.4),
                          ),
                          child: _isLoading 
                            ? const SizedBox(
                                height: 24, width: 24, 
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
                              )
                            : const Text(
                                "LOGIN",
                                style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1),
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 30),
                Text(
                  "Versi 1.0.0",
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF4B5563)),
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400),
      prefixIcon: Icon(icon, color: Colors.blue.shade300, size: 22),
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
      filled: true,
      fillColor: Colors.grey.shade50,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
      ),
    );
  }
}