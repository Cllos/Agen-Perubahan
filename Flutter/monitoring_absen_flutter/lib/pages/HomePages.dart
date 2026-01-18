import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../helpers/api_helper.dart';
import '../widgets/AppDrawer.dart'; // Pastikan import Drawer ada

class HomePages extends StatefulWidget {
  const HomePages({super.key});

  @override
  State<HomePages> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomePages> {
  // --- PENTING: GANTI IP INI SESUAI WIFI LAPTOP ---
  final String apiUrl = ApiHelper.getUrl('/api/dashboard');

  Map<String, dynamic>? dashboardData;
  bool isLoading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    fetchDashboardData();
    // Auto-refresh data setiap 5 detik
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      fetchDashboardData();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> fetchDashboardData() async {
    try {
      final response = await http
          .get(Uri.parse(apiUrl))
          .timeout(ApiHelper.requestTimeout);
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            dashboardData = json.decode(response.body);
            isLoading = false;
          });
        }
      }
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        dashboardData = null;
        isLoading = false;
      });
    } on SocketException {
      if (!mounted) return;
      setState(() {
        dashboardData = null;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching dashboard: $e");
      if (!mounted) return;
      setState(() {
        dashboardData = null;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      // 1. MENU DRAWER (Agar sama seperti halaman lain)
      drawer: const AppDrawer(), 
      appBar: AppBar(
        title: const Text("Dashboard", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.blue.shade700, // Warna dasar (fallback)
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white), // Warna icon menu putih
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blue.shade600, Colors.blue.shade800],
            ),
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : dashboardData == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 10),
                      const Text("Gagal terhubung ke server"),
                      Text("Cek IP: $apiUrl", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: fetchDashboardData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        // 2. HEADER BIRU MELENGKUNG (Identitas Visual)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.only(bottom: 30, left: 20, right: 20, top: 20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.blue.shade800, Colors.blue.shade600],
                            ),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(30),
                              bottomRight: Radius.circular(30),
                            ),
                            boxShadow: [
                              BoxShadow(color: Colors.blue.withValues(alpha: 77), blurRadius: 10, offset: const Offset(0, 5))
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Ringkasan Hari Ini",
                                style: TextStyle(color: Colors.white70, fontSize: 14),
                              ),
                              const SizedBox(height: 15),
                              // KARTU STATISTIK DALAM HEADER
                              Row(
                                children: [
                                  _buildHeaderStatCard("Total Pegawai", "${dashboardData!['totalEmployees']}", Icons.people_alt),
                                  const SizedBox(width: 15),
                                  _buildHeaderStatCard("Hadir", "${dashboardData!['presentToday']}", Icons.how_to_reg),
                                ],
                              ),
                            ],
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // --- SECTION 1: KEHADIRAN HARI INI ---
                              const Row(
                                children: [
                                  Icon(Icons.access_time_filled, color: Colors.blue),
                                  SizedBox(width: 8),
                                  Text("Kehadiran Realtime", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 10),
                              _buildAttendanceList(dashboardData!['todayRecords']),

                              const SizedBox(height: 25),

                              // --- SECTION 2: LEADERBOARD BULANAN ---
                              const Row(
                                children: [
                                  Icon(Icons.emoji_events, color: Colors.orange),
                                  SizedBox(width: 8),
                                  Text("Top 5 Tercepat (Bulan Ini)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 10),
                              _buildLeaderboardList(dashboardData!['monthlyLeaderboard']),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  // Widget Kartu Statistik di Header
  Widget _buildHeaderStatCard(String title, String count, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 38),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withValues(alpha: 51)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: Icon(icon, color: Colors.blue.shade700, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(count, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                Text(title, style: const TextStyle(fontSize: 12, color: Colors.white70)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Widget List Kehadiran Hari Ini
  Widget _buildAttendanceList(List<dynamic> records) {
    if (records.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade200)),
        child: const Center(child: Text("Belum ada yang absen hari ini", style: TextStyle(color: Colors.grey))),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 13), blurRadius: 10)],
      ),
      child: ListView.separated(
        shrinkWrap: true, // Agar bisa di dalam SingleChildScrollView
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 10),
        itemCount: records.length,
        separatorBuilder: (ctx, i) => Divider(height: 1, color: Colors.grey.shade100),
        itemBuilder: (context, index) {
          final record = records[index];
          final isFastest = record['status'] == 'tercepat';

          return ListTile(
            leading: Stack(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.grey.shade100,
                  backgroundImage: NetworkImage(record['avatar_url'] ?? "https://ui-avatars.com/api/?name=${record['full_name']}"),
                ),
                if (isFastest)
                  Positioned(
                    right: 0, bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: const Icon(Icons.bolt, color: Colors.amber, size: 14),
                    ),
                  )
              ],
            ),
            title: Text(record['full_name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text(record['employee_id'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(record['check_in_time'].toString().substring(0, 5), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isFastest ? Colors.amber[50] : Colors.blue[50],
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: isFastest ? Colors.amber.shade200 : Colors.blue.shade200, width: 0.5)
                  ),
                  child: Text(
                    isFastest ? "TERCEPAT" : "HADIR",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isFastest ? Colors.amber[800] : Colors.blue[700],
                    ),
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  // Widget List Leaderboard
  Widget _buildLeaderboardList(List<dynamic> records) {
    if (records.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
        child: const Center(child: Text("Belum ada data bulan ini", style: TextStyle(color: Colors.grey))),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 13), blurRadius: 10)],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 10),
        itemCount: records.length,
        separatorBuilder: (ctx, i) => Divider(height: 1, color: Colors.grey.shade100),
        itemBuilder: (context, index) {
          final record = records[index];
          
          // Warna Badge Ranking
          Color rankBg = Colors.grey.shade100;
          Color rankText = Colors.grey.shade600;
          if(index == 0) { rankBg = Colors.amber; rankText = Colors.white; }
          else if(index == 1) { rankBg = Colors.grey.shade400; rankText = Colors.white; }
          else if(index == 2) { rankBg = Colors.orange.shade300; rankText = Colors.white; }

          return ListTile(
            leading: Container(
              width: 35, height: 35,
              decoration: BoxDecoration(color: rankBg, shape: BoxShape.circle),
              child: Center(child: Text("${index + 1}", style: TextStyle(fontWeight: FontWeight.bold, color: rankText))),
            ),
            title: Text(record['full_name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(20)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded, size: 16, color: Colors.orange),
                  const SizedBox(width: 4),
                  Text("${record['score']}x", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
