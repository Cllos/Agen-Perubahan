import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'dart:convert'; // Untuk jsonDecode
import 'package:http/http.dart' as http; // Untuk request API
import '../widgets/AppDrawer.dart'; 

// --- MODEL DATA ---
class AttendanceRecord {
  final String id;
  final String employeeName;
  final String avatarUrl; 
  final DateTime checkInTime;
  final String status;

  AttendanceRecord(this.id, this.employeeName, this.avatarUrl, this.checkInTime, this.status);
}

// Data awal (Dummy untuk tampilan list absen hari ini)
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
  // Format Waktu
  String _formatTime(DateTime date) {
    return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
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
      drawer: const AppDrawer(), 

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

// --- WIDGET DIALOG ADD ATTENDANCE (FULL UPDATE) ---
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
  
  // --- VARIABEL UNTUK DATA PEGAWAI DARI DB ---
  bool isLoadingList = true;
  List<dynamic> _employees = []; // Menyimpan list dari API
  String? _selectedEmployeeName; // Nama untuk ditampilkan
  String? _selectedEmployeeId;   // ID untuk logika (disimpan tapi belum dipakai kirim)

  @override
  void initState() {
    super.initState();
    _fetchEmployees(); // Panggil API saat dialog dibuka
  }

  // --- FUNGSI AMBIL DATA DARI DATABASE ---
  Future<void> _fetchEmployees() async {
    try {
      // GANTI IP INI SESUAI LAPTOP ANDA
      final response = await http.get(Uri.parse('http://10.29.71.1:5000/api/pegawai')); 
      
      if (response.statusCode == 200) {
        setState(() {
          _employees = jsonDecode(response.body);
          isLoadingList = false;
        });
      } else {
        throw Exception('Failed to load employees');
      }
    } catch (e) {
      print("Error fetching employees: $e");
      setState(() {
        isLoadingList = false;
        // Opsional: Tampilkan pesan error atau biarkan list kosong
      });
    }
  }

  void _handleCapture() {
    setState(() => isCapturing = true);
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
    if (_selectedEmployeeName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Harap pilih nama pegawai!")),
      );
      return;
    }

    setState(() => isCapturing = true);
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          isCapturing = false;
          isSuccess = true;
        });

        // Membuat record baru untuk ditampilkan di list sementara
        final newRecord = AttendanceRecord(
          _selectedEmployeeId ?? Random().nextInt(1000).toString(),
          _selectedEmployeeName!, 
          _selectedEmployeeName!.substring(0, 2).toUpperCase(), // Inisial
          DateTime.now(),
          "Present",
        );

        Future.delayed(const Duration(seconds: 1), () {
          widget.onSuccess(newRecord);
          Navigator.of(context).pop();
        });
      }
    });
  }

  // --- FUNGSI MENAMPILKAN LIST PEGAWAI (POPUP) ---
  void _showEmployeeListDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.only(top: 50, left: 16, right: 16, bottom: 16),
                constraints: const BoxConstraints(maxHeight: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Pilih Pegawai",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    
                    // Logic Tampilan List
                    Flexible(
                      child: isLoadingList
                          ? const Center(child: CircularProgressIndicator())
                          : _employees.isEmpty
                              ? const Center(child: Text("Tidak ada data pegawai"))
                              : ListView.separated(
                                  shrinkWrap: true,
                                  itemCount: _employees.length,
                                  separatorBuilder: (ctx, i) => const Divider(),
                                  itemBuilder: (context, index) {
                                    final emp = _employees[index];
                                    return ListTile(
                                      // Sesuaikan key dengan response JSON backend ('full_name')
                                      title: Text(emp['full_name'] ?? 'Nama Tidak Ada', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      subtitle: Text(emp['department'] ?? '-'),
                                      onTap: () {
                                        setState(() {
                                          _selectedEmployeeName = emp['full_name'];
                                          _selectedEmployeeId = emp['employee_id'];
                                        });
                                        Navigator.pop(context); // Tutup list
                                      },
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
              ),
              // Tombol Close (Silang)
              Positioned(
                right: 8,
                top: 8,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
            child: SizedBox(
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
                        const Text("Select name & capture photo", style: TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 20),

                        // --- KOTAK PILIH PEGAWAI ---
                        GestureDetector(
                          onTap: _showEmployeeListDialog,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.white,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _selectedEmployeeName ?? "Pilih Nama Pegawai",
                                  style: TextStyle(
                                    color: _selectedEmployeeName == null ? Colors.grey[600] : Colors.black,
                                    fontSize: 14,
                                  ),
                                ),
                                const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),

                        // --- AREA FOTO ---
                        GestureDetector(
                          onTap: hasPhoto ? null : _handleCapture,
                          child: Container(
                            height: 180,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
                            ),
                            child: isCapturing
                                ? const Center(child: CircularProgressIndicator())
                                : hasPhoto
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: Stack(
                                          children: [
                                            Container(
                                              color: Colors.blue[50],
                                              child: const Center(child: Icon(Icons.person, size: 80, color: Colors.blue)),
                                            ),
                                            Positioned(
                                              right: 8,
                                              top: 8,
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
                                        ),
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
                        
                        // --- TOMBOL SUBMIT ---
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: hasPhoto && !isCapturing ? _handleSubmit : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(255, 27, 127, 215),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text("Submit Attendance", style: TextStyle(color: Colors.white)),
                          ),
                        )
                      ],
                    ),
            ),
          ),

          // --- TOMBOL CLOSE UTAMA ---
          Positioned(
            right: 8,
            top: 8,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.grey),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}