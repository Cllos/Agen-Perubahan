import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/attendance_model.dart'; // Pastikan path ini benar
import '../widgets/AppDrawer.dart';
import 'dart:async'; // 1. Import paket timer

class HomePages extends StatefulWidget {
  const HomePages({super.key});

  @override
  State<HomePages> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomePages> {
  // ... variable list dan loading tetap sama
  List<AttendanceRecord> attendanceList = [];
  bool isLoading = true;
  
  // Variabel Timer
  Timer? _timer; // 2. Siapkan variabel timer

  // PASTIKAN IP INI SESUAI DENGAN IP LAPTOP ANDA SAAT INI
  final String apiUrl = "http://192.168.12.86:5000/api/dashboard"; 

  @override
  void initState() {
    super.initState();
    fetchDashboardData(); // Fetch pertama kali

    // 3. Pasang Timer: Jalankan fetchDashboardData setiap 5 detik
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      fetchDashboardData();
    });
  }

  @override
  void dispose() {
    // 4. Matikan Timer saat pindah halaman agar memori tidak bocor
    _timer?.cancel(); 
    super.dispose();
  }

  // --- FETCH DATA DARI API ---
  Future<void> fetchDashboardData() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Ambil data 'todayRecords' dari respon JSON backend
        List<dynamic> recordsJson = data['todayRecords'];

        if (mounted) {
          setState(() {
            attendanceList = recordsJson
                .map((json) => AttendanceRecord.fromJson(json))
                .toList();
            isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint("Error fetching data: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
          // Opsional: Kosongkan list jika error
          attendanceList = []; 
        });
      }
    }
  }

  // --- LOGIC TOP 5 ---
  // Getter ini memperbaiki error 'top5CheckIns isn't defined'
  List<AttendanceRecord> get top5CheckIns {
    // Data dari backend biasanya sudah berurut, tapi kita urutkan lagi untuk memastikan
    final sortedList = List<AttendanceRecord>.from(attendanceList);
    sortedList.sort((a, b) => a.checkInTime.compareTo(b.checkInTime));
    return sortedList.take(5).toList();
  }

  // --- HELPER FORMAT JAM ---
  String _formatTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return "$hour:$minute $period"; 
  }

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
              Stack(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 250,
                    child: Image.network(
                      record.employeeAvatar, // Sementara pakai avatar karena belum ada foto bukti
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, _, __) => Container(color: Colors.grey[300], child: const Icon(Icons.broken_image)),
                    ),
                  ),
                  Positioned(
                    bottom: 0, left: 0, right: 0,
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
        SizedBox(width: 100, child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14))),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final int totalPresent = attendanceList.length;

    return Scaffold(
      drawer: const AppDrawer(),
      backgroundColor: Colors.grey[50],
      body: isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 80),
          child: Column(
            children: [
              // --- HEADER SECTION ---
              Container(
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade600, Colors.blue.shade700],
                  ),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
                  boxShadow: [
                    BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5)),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
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
                        const SizedBox(width: 12),
                        // Title
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("AttendEase", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                              const SizedBox(height: 4),
                              Text("Realtime Dashboard", style: TextStyle(fontSize: 14, color: Colors.blue.shade100)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
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
                            child: const Icon(Icons.people, color: Colors.white),
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
                    
                    if (attendanceList.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text("No attendance data available yet."),
                      )
                    else
                      ...top5CheckIns.asMap().entries.map((entry) {
                        final index = entry.key;
                        final record = entry.value;
                        
                        Color badgeColor = Colors.blue;
                        if (index == 0) badgeColor = Colors.amber;
                        else if (index == 1) badgeColor = Colors.grey;
                        else if (index == 2) badgeColor = Colors.deepOrange;

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
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: badgeColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text("#${index + 1}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                              ),
                              const SizedBox(width: 16),
                              CircleAvatar(
                                radius: 28,
                                backgroundImage: NetworkImage(record.employeeAvatar),
                                onBackgroundImageError: (_, __) => const Icon(Icons.person),
                              ),
                              const SizedBox(width: 16),
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