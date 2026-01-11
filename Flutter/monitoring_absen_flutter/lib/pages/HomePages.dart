import 'package:flutter/material.dart';

// --- MOCK DATA SEMENTARA (Agar kode bisa langsung jalan) ---
// Nanti pindahkan ini ke folder lib/models/attendance_model.dart
class AttendanceRecord {
  final String id;
  final String employeeName;
  final String employeeAvatar;
  final DateTime checkInTime;
  final String photoUrl;
  final String location;

  AttendanceRecord({
    required this.id,
    required this.employeeName,
    required this.employeeAvatar,
    required this.checkInTime,
    required this.photoUrl,
    required this.location,
  });
}

final List<AttendanceRecord> todayAttendance = [
  AttendanceRecord(id: '1', employeeName: 'Sarah Smith', employeeAvatar: 'https://i.pravatar.cc/150?u=1', checkInTime: DateTime.now().subtract(const Duration(hours: 4)), photoUrl: 'https://picsum.photos/200/300', location: 'Office Lobby'),
  AttendanceRecord(id: '2', employeeName: 'John Doe', employeeAvatar: 'https://i.pravatar.cc/150?u=2', checkInTime: DateTime.now().subtract(const Duration(hours: 3, minutes: 50)), photoUrl: 'https://picsum.photos/200/301', location: 'Main Entrance'),
  AttendanceRecord(id: '3', employeeName: 'Jane Wilson', employeeAvatar: 'https://i.pravatar.cc/150?u=3', checkInTime: DateTime.now().subtract(const Duration(hours: 3, minutes: 45)), photoUrl: 'https://picsum.photos/200/302', location: 'Parking Lot'),
  AttendanceRecord(id: '4', employeeName: 'Mike Brown', employeeAvatar: 'https://i.pravatar.cc/150?u=4', checkInTime: DateTime.now().subtract(const Duration(hours: 3, minutes: 30)), photoUrl: 'https://picsum.photos/200/303', location: 'Office Lobby'),
  AttendanceRecord(id: '5', employeeName: 'Emily Davis', employeeAvatar: 'https://i.pravatar.cc/150?u=5', checkInTime: DateTime.now().subtract(const Duration(hours: 3, minutes: 15)), photoUrl: 'https://picsum.photos/200/304', location: 'Meeting Room A'),
];
// -----------------------------------------------------------

class HomePages extends StatefulWidget {

  const HomePages({super.key});

  @override
  State<HomePages> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomePages> {
  // Logic untuk mengambil Top 5 (Sama seperti React)
  List<AttendanceRecord> get top5CheckIns {
    final sortedList = List<AttendanceRecord>.from(todayAttendance);
    sortedList.sort((a, b) => a.checkInTime.compareTo(b.checkInTime));
    return sortedList.take(5).toList();
  }

  // Helper untuk format jam (pengganti toLocaleTimeString)
  String _formatTime(DateTime date) {
    // Cara manual tanpa library intl agar simple
    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return "$hour:$minute $period"; // e.g., 08:30 AM
  }

  // Fungsi untuk menampilkan Dialog Evidence
  void _showEvidenceDialog(AttendanceRecord record) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Dialog
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text("Attendance Evidence", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text("View the evidence for the check-in.", style: TextStyle(fontSize: 14, color: Colors.grey)),
                  ],
                ),
              ),
              
              // Image Section
              Stack(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 250,
                    child: Image.network(
                      record.photoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, _, __) => Container(color: Colors.grey[300], child: const Icon(Icons.broken_image)),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_formatTime(record.checkInTime), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          Text(record.location, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Details Section
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildDetailRow("Employee", record.employeeName),
                    const SizedBox(height: 12),
                    _buildDetailRow("Check-in Time", _formatTime(record.checkInTime)),
                    const SizedBox(height: 12),
                    _buildDetailRow("Location", record.location),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final int totalPresent = todayAttendance.length;

    return Scaffold(
      backgroundColor: Colors.grey[50], // Background body
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 80), // Padding bawah agar tidak tertutup nav bar
        child: Column(
          children: [
            // --- HEADER SECTION ---
            Container(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 32), // Padding custom (pt-6 pb-8 + status bar)
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade600, Colors.blue.shade700],
                ),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)), // rounded-b-3xl
                boxShadow: [
                  BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5)),
                ],
              ),
              child: Column(
                children: [
                  // Top Bar
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("AttendEase", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                            const SizedBox(height: 4),
                            Text("Saturday, January 10, 2026", style: TextStyle(fontSize: 14, color: Colors.blue.shade100)),
                          ],
                        ),
                        // Kosongkan bagian kanan agar tidak ada tombol
                      ],
                    ),
                  
                  const SizedBox(height: 24),

                  // Today's Statistics Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2), // bg-white/20
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.people, color: Colors.white), // Users Icon
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Total Present Today", style: TextStyle(color: Colors.blue.shade100, fontSize: 14)),
                            Text("$totalPresent", style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // --- LIST SECTION ---
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Top 5 Fastest Check-ins Today", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF1F2937))),
                  const SizedBox(height: 16),
                  
                  // Mapping Data
                  ...top5CheckIns.asMap().entries.map((entry) {
                    final index = entry.key;
                    final record = entry.value;
                    
                    // Logic warna badge ranking
                    Color badgeColor = Colors.blue;
                    if (index == 0) {
                      badgeColor = Colors.amber; // Gold
                    } else if (index == 1) badgeColor = Colors.grey; // Silver
                    else if (index == 2) badgeColor = Colors.deepOrange; // Bronze

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Rank Badge
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: badgeColor,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                "#${index + 1}",
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Avatar
                          CircleAvatar(
                            radius: 28,
                            backgroundImage: NetworkImage(record.employeeAvatar),
                            onBackgroundImageError: (_, __) => const Icon(Icons.person),
                          ),
                          const SizedBox(width: 16),

                          // Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(record.employeeName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16), overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 2),
                                Text(_formatTime(record.checkInTime), style: const TextStyle(color: Colors.grey, fontSize: 14)),
                              ],
                            ),
                          ),

                          // Evidence Button
                          TextButton.icon(
                            onPressed: () => _showEvidenceDialog(record),
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.blue.shade50,
                              foregroundColor: Colors.blue.shade600,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            icon: const Icon(Icons.camera_alt, size: 16),
                            label: const Text("Evidence"),
                          )
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}