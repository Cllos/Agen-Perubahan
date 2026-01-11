import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: LoginScreen(onLogin: () {
      print("Login clicked!");
    }),
  ));
}

class LoginScreen extends StatefulWidget {
  final VoidCallback onLogin;

  const LoginScreen({super.key, required this.onLogin});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controller untuk menangani input text
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    // Di sini Anda bisa mengambil value dari controller
    // print("Email: ${_emailController.text}");
    // print("Password: ${_passwordController.text}");
    widget.onLogin();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Background Gradient (from-blue-500 to-blue-700)
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade500,
              Colors.blue.shade700,
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Header Section
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      "👤",
                      style: TextStyle(fontSize: 36),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "AttendEase",
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Smart Attendance Management",
                  style: TextStyle(
                    color: Colors.lightBlueAccent, // matches text-blue-100 roughly
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 48),

                // Card Section
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 450),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24), // rounded-3xl
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2), // shadow-2xl equivalent
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
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937), // text-gray-800
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Email Input
                      _buildInputLabel("Email / Employee ID"),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _emailController,
                        decoration: _inputDecoration(
                          hint: "Enter your email or ID",
                          icon: Icons.mail_outline,
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
                          hint: "Enter your password",
                          icon: Icons.lock_outline,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Remember Me Toggle
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _rememberMe = !_rememberMe;
                          });
                        },
                        child: Row(
                          children: [
                            Icon(
                              _rememberMe
                                  ? Icons.check_box
                                  : Icons.check_box_outline_blank,
                              color: _rememberMe ? Colors.blue.shade600 : Colors.grey,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              "Remember me",
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF374151), // text-gray-700
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Login Button
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _handleSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade600,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12), // rounded-xl
                            ),
                            elevation: 4,
                          ),
                          child: const Text(
                            "Login",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Forgot Password Link
                      Center(
                        child: TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            "Forgot Password?",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blue.shade600,
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
      ),
    );
  }

  // Helper widget untuk label
  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF4B5563), // text-gray-600
        ),
      ),
    );
  }

  // Helper untuk style input field agar konsisten
  InputDecoration _inputDecoration({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400),
      prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.blue, width: 2),
      ),
    );
  }
}