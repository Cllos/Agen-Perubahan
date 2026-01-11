import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

// --- MOCK DATA (Data Dummy) ---
class AttendanceRecord {
  final String id;
  final String employeeName;
  final String avatarUrl; // Kita pakai inisial/icon sebagai ganti URL gambar nyata
  final DateTime checkInTime;
  final String status;

  AttendanceRecord(this.id, this.employeeName, this.avatarUrl, this.checkInTime, this.status);
}

// Data awal
List<AttendanceRecord> todayAttendance = [
  AttendanceRecord('1', 'Budi Santoso', 'BS', DateTime.now().subtract(Duration(minutes: 30)), 'Present'),
  AttendanceRecord('2', 'Siti Aminah', 'SA', DateTime.now().subtract(Duration(hours: 1)), 'Late'),
];

// --- MAIN WIDGET ---
class AttendancePages extends StatefulWidget {
  const AttendancePages({super.key});

  @override
  State<AttendancePages> createState() => _AttendancePagesState();
}

class _AttendancePagesState extends State<AttendancePages> {
  // State pengganti useState
  bool isLoading = false;
  
  // Format Waktu
  String _formatTime(DateTime date) {
    return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }

  // Format Tanggal
  String _getDateNow() {
    // Sederhana saja tanpa package intl untuk mempermudah
    final now = DateTime.now();
    return "${now.day}/${now.month}/${now.year}";
  }

  // Fungsi sort data (Terbaru di atas)
  List<AttendanceRecord> get sortedList {
    List<AttendanceRecord> list = List.from(todayAttendance);
    list.sort((a, b) => b.checkInTime.compareTo(a.checkInTime));
    return list;
  }

  // Handle Buka Dialog Absen
  void _showAddAttendanceDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AddAttendanceDialog(
        onSuccess: (newRecord) {
          setState(() {
            todayAttendance.add(newRecord);
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      drawer: const AppDrawer(), // ← Pindahkan di sini

      body: Column(
        children: [
          // --- HEADER ---
          Container(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade600, Colors.blue.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Scaffold.of(context).openDrawer(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.menu, color: Colors.white),
                  ),
                ),
                Column(
                  children: const [
                    Text("Attendance", 
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text("Manage Daily Check-ins", 
                      style: TextStyle(fontSize: 12, color: Colors.white70)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                  onPressed: _showAddAttendanceDialog,
                ),
              ],
            ),
          ),

          // --- BODY LIST ---
          Expanded(
            child: sortedList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt, size: 60, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        const Text("No Attendance Record", style: TextStyle(fontSize: 18, color: Colors.grey)),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: _showAddAttendanceDialog,
                          icon: const Icon(Icons.add),
                          label: const Text("Add Attendance"),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[600]),
                        )
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: sortedList.length,
                    itemBuilder: (context, index) {
                      final record = sortedList[index];
                      final isPresent = record.status == 'Present';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.blue[100],
                                child: Text(record.avatarUrl, style: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(record.employeeName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.access_time, size: 14, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(_formatTime(record.checkInTime), style: const TextStyle(color: Colors.grey)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isPresent ? Colors.green[50] : Colors.orange[50],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  record.status,
                                  style: TextStyle(
                                    color: isPresent ? Colors.green[700] : Colors.orange[700],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// --- WIDGET DIALOG ADD ATTENDANCE ---
class AddAttendanceDialog extends StatefulWidget {
  final Function(AttendanceRecord) onSuccess;
  const AddAttendanceDialog({super.key, required this.onSuccess});

  @override
  State<AddAttendanceDialog> createState() => _AddAttendanceDialogState();
}

class _AddAttendanceDialogState extends State<AddAttendanceDialog> {
  bool isCapturing = false;
  bool isSuccess = false;
  bool hasPhoto = false;

  void _handleCapture() {
    setState(() => isCapturing = true);
    // Simulasi delay kamera
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          isCapturing = false;
          hasPhoto = true;
        });
      }
    });
  }

  void _handleSubmit() {
    setState(() => isCapturing = true);
    // Simulasi submit ke backend
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          isCapturing = false;
          isSuccess = true;
        });
        
        // Buat record baru dummy
        final newRecord = AttendanceRecord(
          Random().nextInt(1000).toString(), 
          "New Employee", 
          "NE", 
          DateTime.now(), 
          "Present"
        );
        
        // Tutup dialog setelah delay sukses
        Future.delayed(const Duration(seconds: 1), () {
          widget.onSuccess(newRecord);
          Navigator.of(context).pop();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: SizedBox(
        width: 300,
        child: isSuccess
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Colors.green[600], size: 60),
                  const SizedBox(height: 16),
                  const Text("Success!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const Text("Attendance recorded"),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Add Attendance", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text("Capture photo to check in", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 20),
                  
                  // Area Foto
                  GestureDetector(
                    onTap: hasPhoto ? null : _handleCapture,
                    child: Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
                      ),
                      child: isCapturing
                          ? const Center(child: CircularProgressIndicator())
                          : hasPhoto
                              ? Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(color: Colors.blue[50], child: const Center(child: Icon(Icons.person, size: 80, color: Colors.blue))),
                                    ),
                                    Positioned(
                                      right: 8, top: 8,
                                      child: CircleAvatar(
                                        backgroundColor: Colors.white,
                                        radius: 16,
                                        child: IconButton(
                                          icon: const Icon(Icons.refresh, size: 16, color: Colors.black),
                                          onPressed: () => setState(() => hasPhoto = false),
                                        ),
                                      ),
                                    )
                                  ],
                                )
                              : const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.camera_alt, size: 40, color: Colors.grey),
                                    SizedBox(height: 8),
                                    Text("Tap to capture", style: TextStyle(color: Colors.grey)),
                                  ],
                                ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: hasPhoto && !isCapturing ? _handleSubmit : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text("Submit Attendance"),
                    ),
                  )
                ],
              ),
      ),
    );
  }
}

// --- APP DRAWER WIDGET (Sidebar) ---
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // Header Gradient
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
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
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: const Icon(Icons.person, size: 35, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  const Text("John Admin", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const Text("admin@company.com", style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: Colors.blue[800], borderRadius: BorderRadius.circular(4)),
                    child: const Text("Administrator", style: TextStyle(color: Colors.white, fontSize: 10)),
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
                _buildMenuItem(Icons.person_outline, "Profile", "View and edit profile", Colors.blue),
                _buildMenuItem(Icons.settings_outlined, "Settings", "App preferences", Colors.purple),
                const Divider(),
                _buildMenuItem(Icons.logout, "Logout", "Sign out of your account", Colors.red),
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

  Widget _buildMenuItem(IconData icon, String title, String subtitle, Color color) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      onTap: () {
        // Handle navigation
      },
    );
  }
}