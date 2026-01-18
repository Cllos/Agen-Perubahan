import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../helpers/api_helper.dart';
import 'dart:convert';
import 'dart:async';

// MODEL DATA
class HistoryRecord {
  final int id;
  final String employeeName;
  final String employeeAvatar;
  final DateTime checkInTime;
  final String status;      // 'tercepat' atau 'hadir'
  final String? evidenceUrl;
  final String? location;

  HistoryRecord({
    required this.id,
    required this.employeeName,
    required this.employeeAvatar,
    required this.checkInTime,
    required this.status,
    this.evidenceUrl,
    this.location,
  });

  factory HistoryRecord.fromJson(Map<String, dynamic> json) {
    String dateStr = json['date'] ?? DateTime.now().toIso8601String();
    String timeStr = json['check_in_time'] ?? "00:00:00";
    String dateOnly = dateStr.contains('T') ? dateStr.split('T')[0] : dateStr; 
    DateTime fullDateTime = DateTime.parse("$dateOnly $timeStr");

    return HistoryRecord(
      id: json['id'],
      employeeName: json['full_name'] ?? 'Unknown',
      employeeAvatar: json['avatar_url'] ?? 'https://ui-avatars.com/api/?name=${json['full_name']}',
      checkInTime: fullDateTime,
      status: json['status'] ?? 'hadir',
      evidenceUrl: json['photo_url'], 
      location: json['location'],
    );
  }
}

class HistoryPages extends StatefulWidget {
  const HistoryPages({super.key});

  @override
  State<HistoryPages> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryPages> {
  // --- GANTI IP DI SINI SESUAI LAPTOP ---
  final String apiUrl = ApiHelper.getUrl('/api/riwayat');

  List<HistoryRecord> _historyList = [];
  bool _isLoading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchHistoryData();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _fetchHistoryData();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchHistoryData() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _historyList = data.map((json) => HistoryRecord.fromJson(json)).toList();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print("Error history: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Helper Format Waktu
  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return "$hour:$minute";
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return "${date.day} ${months[date.month - 1]} ${date.year}";
  }

  // Popup Foto
  void _showImageDetail(String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(imageUrl, fit: BoxFit.cover),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // HEADER BIRU (Sama seperti Home)
          Container(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 25),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.blue.shade600, Colors.blue.shade800]),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
              boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text("Riwayat Absensi", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                Icon(Icons.history, color: Colors.white),
              ],
            ),
          ),

          // LIST CONTENT
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator()) 
              : _historyList.isEmpty
                ? const Center(child: Text("Belum ada data riwayat.", style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _historyList.length,
                    itemBuilder: (ctx, index) {
                      final record = _historyList[index];
                      final isFastest = record.status == 'tercepat';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              // 1. TANGGAL (Kiri)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  children: [
                                    Text(_formatDate(record.checkInTime).split(' ')[0], 
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                    Text(_formatDate(record.checkInTime).split(' ')[1], 
                                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 15),

                              // 2. INFO USER (Tengah)
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(record.employeeName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.access_time, size: 14, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(_formatTime(record.checkInTime), style: const TextStyle(fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                    if (record.location != null)
                                      Text(record.location!, style: const TextStyle(fontSize: 11, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),

                              // 3. STATUS BADGE & FOTO (Kanan)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  // Badge Status
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isFastest ? Colors.amber.shade100 : Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: isFastest ? Colors.amber : Colors.blue.shade200)
                                    ),
                                    child: Text(
                                      isFastest ? "TERCEPAT" : "HADIR",
                                      style: TextStyle(
                                        color: isFastest ? Colors.amber.shade800 : Colors.blue.shade700,
                                        fontSize: 10, fontWeight: FontWeight.bold
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  
                                  // Tombol Lihat Foto (Jika ada)
                                  if (record.evidenceUrl != null)
                                    GestureDetector(
                                      onTap: () => _showImageDetail(record.evidenceUrl!),
                                      child: const Row(
                                        children: [
                                          Icon(Icons.image, size: 14, color: Colors.blue),
                                          SizedBox(width: 2),
                                          Text("Bukti", style: TextStyle(fontSize: 11, color: Colors.blue)),
                                        ],
                                      ),
                                    )
                                ],
                              )
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