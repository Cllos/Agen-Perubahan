import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../helpers/api_helper.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:io';

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
  DateTime? _selectedDate;
  int? _selectedMonth;
  int? _selectedYear;

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
      final response = await http
          .get(Uri.parse(apiUrl))
          .timeout(ApiHelper.requestTimeout);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _historyList = data.map((json) => HistoryRecord.fromJson(json)).toList();
            _isLoading = false;
          });
        }
        return;
      }
      debugPrint("Error history: ${response.statusCode} ${response.body}");
    } on TimeoutException {
      debugPrint("Error history: timeout");
    } on SocketException {
      debugPrint("Error history: socket");
    } catch (e) {
      debugPrint("Error history: $e");
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
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

  List<HistoryRecord> _applyFilters(List<HistoryRecord> records) {
    return records.where((r) {
      final dt = r.checkInTime;

      if (_selectedDate != null) {
        final selected = _selectedDate!;
        return dt.year == selected.year && dt.month == selected.month && dt.day == selected.day;
      }

      if (_selectedMonth != null && dt.month != _selectedMonth) return false;
      if (_selectedYear != null && dt.year != _selectedYear) return false;
      return true;
    }).toList();
  }

  Future<void> _pickDate(void Function(void Function()) setModalState) async {
    final now = DateTime.now();
    final initialDate = _selectedDate ?? DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
    );
    if (picked == null) return;
    if (!mounted) return;
    setState(() {
      _selectedDate = DateTime(picked.year, picked.month, picked.day);
      _selectedMonth = picked.month;
      _selectedYear = picked.year;
    });
    setModalState(() {});
  }

  void _clearFilters() {
    setState(() {
      _selectedDate = null;
      _selectedMonth = null;
      _selectedYear = null;
    });
  }

  void _openFilterSheet() {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final yearOptions = _historyList.map((r) => r.checkInTime.year).toSet().toList();
    if (yearOptions.isEmpty) yearOptions.add(DateTime.now().year);
    yearOptions.sort();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: StatefulBuilder(
              builder: (context, setModalState) {
                return Padding(
                  padding: EdgeInsets.fromLTRB(16, 10, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 44,
                          height: 5,
                          decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Filter Riwayat", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          TextButton(
                            onPressed: () {
                              _clearFilters();
                              setModalState(() {});
                            },
                            child: const Text("Reset"),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: () => _pickDate(setModalState),
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(_selectedDate == null ? "Tanggal: Semua" : "Tanggal: ${_formatDate(_selectedDate!)}"),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade400),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int?>(
                                  value: _selectedMonth,
                                  isExpanded: true,
                                  hint: const Text("Bulan"),
                                  items: [
                                    const DropdownMenuItem<int?>(value: null, child: Text("Bulan: Semua")),
                                    ...List.generate(12, (i) {
                                      final monthIndex = i + 1;
                                      return DropdownMenuItem<int?>(
                                        value: monthIndex,
                                        child: Text("Bulan: ${months[i]}"),
                                      );
                                    }),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedDate = null;
                                      _selectedMonth = value;
                                    });
                                    setModalState(() {});
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade400),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int?>(
                                  value: _selectedYear,
                                  isExpanded: true,
                                  hint: const Text("Tahun"),
                                  items: [
                                    const DropdownMenuItem<int?>(value: null, child: Text("Tahun: Semua")),
                                    ...yearOptions.map((y) => DropdownMenuItem<int?>(value: y, child: Text("Tahun: $y"))),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedDate = null;
                                      _selectedYear = value;
                                    });
                                    setModalState(() {});
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text("Terapkan", style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
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
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  final expectedTotalBytes = loadingProgress.expectedTotalBytes;
                  final loadedBytes = loadingProgress.cumulativeBytesLoaded;
                  final value = expectedTotalBytes == null ? null : loadedBytes / expectedTotalBytes;
                  return Container(
                    color: Colors.black54,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(16),
                    child: CircularProgressIndicator(value: value, color: Colors.white),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.black54,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.broken_image_outlined, color: Colors.white, size: 48),
                        const SizedBox(height: 10),
                        const Text(
                          "Foto bukti tidak bisa dimuat",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          imageUrl,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  );
                },
              ),
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
    final displayedList = _applyFilters(_historyList);
    final isFilterActive = _selectedDate != null || _selectedMonth != null || _selectedYear != null;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 25),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.blue.shade600, Colors.blue.shade800]),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
                boxShadow: [BoxShadow(color: Colors.blue.withValues(alpha: 77), blurRadius: 10, offset: const Offset(0, 5))],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Riwayat Absensi", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      IconButton(
                        onPressed: _openFilterSheet,
                        icon: const Icon(Icons.filter_list_rounded, color: Colors.white),
                      ),
                      if (isFilterActive)
                        Positioned(
                          right: 10,
                          top: 10,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white, width: 1),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator()) 
                : _historyList.isEmpty
                  ? const Center(child: Text("Belum ada data riwayat.", style: TextStyle(color: Colors.grey)))
                  : displayedList.isEmpty
                    ? const Center(child: Text("Tidak ada data sesuai filter.", style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: displayedList.length,
                      itemBuilder: (ctx, index) {
                        final record = displayedList[index];
                        final isFastest = record.status == 'tercepat';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
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
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
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
      ),
    );
  }
}
