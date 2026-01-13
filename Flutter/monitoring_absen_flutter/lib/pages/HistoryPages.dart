import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

// --- MODEL DATA ---
class HistoryRecord {
  final int id;
  final String employeeName;
  final String employeeAvatar;
  final DateTime checkInTime;
  final String status;
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
    try {
      String dateStr = json['date'] ?? DateTime.now().toIso8601String();
      String timeStr = json['check_in_time'] ?? "00:00:00";
      
      String dateOnly = dateStr.contains('T') ? dateStr.split('T')[0] : dateStr; 
      DateTime fullDateTime = DateTime.parse("$dateOnly $timeStr");

      return HistoryRecord(
        id: json['id'],
        employeeName: json['full_name'] ?? 'Unknown',
        employeeAvatar: 'https://ui-avatars.com/api/?name=${json['full_name']}&background=random',
        checkInTime: fullDateTime,
        status: json['status'] == 'tepat_waktu' ? 'Present' : 'Late',
        evidenceUrl: json['photo_url'], 
        location: json['location'],
      );
    } catch (e) {
      print("Error parsing record ID ${json['id']}: $e");
      return HistoryRecord(
        id: json['id'] ?? 0,
        employeeName: "Data Error",
        employeeAvatar: "",
        checkInTime: DateTime.now(),
        status: "Error",
      );
    }
  }
}

class HistoryPages extends StatefulWidget {
  const HistoryPages({super.key});

  @override
  State<HistoryPages> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryPages> {
  // State variables
  String _filterType = 'day'; 
  DateTime _selectedDate = DateTime.now();
  
  List<HistoryRecord> _historyList = [];
  bool _isLoading = true;
  Timer? _timer;

  // GANTI IP DI SINI SESUAI LAPTOP ANDA
  final String apiUrl = "http://10.29.71.1:5000/api/riwayat"; 

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
      print("Error fetching history: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Helpers
  String _formatTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return "$hour:$minute $period";
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return "${days[date.weekday % 7]}, ${months[date.month - 1]} ${date.day}, ${date.year}";
  }

  // Grouping Data
  Map<String, List<HistoryRecord>> _getFilteredAndGroupedData() {
    final filtered = _historyList.where((record) {
      final rDate = record.checkInTime;
      final sDate = _selectedDate;

      if (_filterType == 'day') {
        return rDate.year == sDate.year && rDate.month == sDate.month && rDate.day == sDate.day;
      } else if (_filterType == 'month') {
        return rDate.year == sDate.year && rDate.month == sDate.month;
      } else {
        return rDate.year == sDate.year;
      }
    }).toList();

    final Map<String, List<HistoryRecord>> grouped = {};
    for (var record in filtered) {
      final dateKey = DateTime(record.checkInTime.year, record.checkInTime.month, record.checkInTime.day).toString();
      if (!grouped.containsKey(dateKey)) grouped[dateKey] = [];
      grouped[dateKey]!.add(record);
    }
    return grouped;
  }

  // Modal Filter
  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Filter Attendance", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  Row(
                    children: ['day', 'month', 'year'].map((type) {
                      final isSelected = _filterType == type;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: GestureDetector(
                            onTap: () {
                              setModalState(() => _filterType = type);
                              setState(() => _filterType = type); 
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.blue.shade600 : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                type.toUpperCase(),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.grey.shade700,
                                  fontWeight: FontWeight.bold
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  const Text("Select Date", style: TextStyle(fontSize: 14, color: Colors.grey)),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setModalState(() => _selectedDate = picked);
                        setState(() => _selectedDate = picked);
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatDate(_selectedDate), style: const TextStyle(fontSize: 16)),
                          const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Apply Filter", style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Fungsi popup detail foto
  void _showImageDetail(String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10), // Memberi sedikit jarak dari tepi layar
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            // Kontainer Gambar
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain, // Agar gambar tidak terpotong
                      errorBuilder: (ctx, _, __) => Container(
                        height: 200,
                        width: double.infinity,
                        color: Colors.grey[200],
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image, size: 50, color: Colors.grey),
                            SizedBox(height: 8),
                            Text("Gagal memuat gambar", style: TextStyle(color: Colors.grey))
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Tombol Tutup di bawah gambar (opsional, untuk kemudahan)
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("Tutup", style: TextStyle(fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupedData = _getFilteredAndGroupedData();
    final sortedKeys = groupedData.keys.toList()
      ..sort((a, b) => DateTime.parse(b).compareTo(DateTime.parse(a)));

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // --- HEADER ---
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("History", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                    
                    // Tombol Filter
                    GestureDetector(
                      onTap: _showFilterModal,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.filter_list, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "Viewing ${_filterType}ly records",
                  style: TextStyle(color: Colors.blue.shade100, fontSize: 14),
                ),
              ],
            ),
          ),

          // --- LIST CONTENT ---
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator()) 
              : sortedKeys.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_today, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        const Text("No attendance records found", style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _fetchHistoryData, 
                          child: const Text("Refresh Data")
                        )
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: sortedKeys.length,
                    itemBuilder: (ctx, index) {
                      final dateKey = sortedKeys[index];
                      final records = groupedData[dateKey]!;
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_month, size: 16, color: Colors.grey),
                                const SizedBox(width: 8),
                                Text(
                                  _formatDate(DateTime.parse(dateKey)),
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          
                          ...records.map((record) => Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: CircleAvatar(
                                radius: 25,
                                backgroundColor: Colors.blue.shade100,
                                backgroundImage: NetworkImage(record.employeeAvatar),
                                onBackgroundImageError: (_, __) => const Icon(Icons.person),
                              ),
                              title: Text(record.employeeName, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time, size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(_formatTime(record.checkInTime)),
                                    ],
                                  ),
                                  if (record.location != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        "📍 ${record.location}",
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                ],
                              ),
                              // --- BAGIAN INI YANG DIUBAH ---
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min, // Agar muat di ujung kanan
                                children: [
                                  // 1. Status Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: record.status == 'Present' ? Colors.green[50] : Colors.orange[50],
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: record.status == 'Present' ? Colors.green.shade200 : Colors.orange.shade200
                                      )
                                    ),
                                    child: Text(
                                      record.status,
                                      style: TextStyle(
                                        color: record.status == 'Present' ? Colors.green[700] : Colors.orange[700],
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  
                                  const SizedBox(width: 8), // Jarak antar status dan tombol

                                  // 2. Tombol Evidence (Hanya muncul jika ada URL foto)
                                  if (record.evidenceUrl != null)
                                    IconButton(
                                      icon: const Icon(Icons.image_outlined, color: Colors.blue),
                                      tooltip: "Lihat Bukti Foto",
                                      onPressed: () => _showImageDetail(record.evidenceUrl!),
                                    )
                                  else
                                    // Placeholder disabled jika tidak ada foto
                                    const IconButton(
                                      icon: Icon(Icons.image_not_supported_outlined, color: Colors.grey),
                                      onPressed: null, 
                                    )
                                ],
                              ),
                            ),
                          )),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}