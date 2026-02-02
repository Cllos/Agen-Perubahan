// File: lib/widgets/AppDrawer.dart
import 'package:flutter/material.dart';
import '../helpers/api_helper.dart';
import '../pages/Login_pages.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final user = ApiHelper.currentUser;
    final username = (user?['username'] ?? 'Admin').toString();
    final employeeId = (user?['employee_id'] ?? 'EMP000').toString();
    final roleRaw = (user?['role'] ?? 'administrator').toString();
    final roleLabel = _formatRole(roleRaw);

    return Drawer(
      child: Column(
        children: [
          // Header Gradient
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color.fromARGB(255, 227, 230, 47), Color(0xFF1D4ED8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: const Color.fromARGB(255, 0, 0, 0).withValues(alpha: 51),
                    child: const Icon(Icons.person, size: 35, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Text(username, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(employeeId, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: Colors.blue[800], borderRadius: BorderRadius.circular(4)),
                    child: Text(roleLabel, style: const TextStyle(color: Colors.white, fontSize: 10)),
                  )
                ],
              ),
            ),
          ),
          
          // Menu Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildMenuItem(
                  context,
                  Icons.logout,
                  "Logout",
                  "Sign out of your account",
                  Colors.red,
                  onTap: () {
                    ApiHelper.currentUser = null;
                    Navigator.of(context).pop();
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginPages()),
                      (route) => false,
                    );
                  },
                ),
              ],
            ),
          ),
          
          // Footer
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text("AttendEase v1.0.0\n© 2026 All rights reserved", 
              textAlign: TextAlign.center, 
              style: TextStyle(color: Colors.grey[400], fontSize: 12)
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    Color color, {
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withValues(alpha: 26), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: Colors.white),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      onTap: onTap,
    );
  }

  String _formatRole(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return "Role";
    final lower = trimmed.toLowerCase();
    return lower[0].toUpperCase() + lower.substring(1);
  }
}
