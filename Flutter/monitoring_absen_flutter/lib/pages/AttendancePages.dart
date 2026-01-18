import 'dart:io'; // Untuk File
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../helpers/api_helper.dart';
import 'package:image_picker/image_picker.dart'; // Kamera
import 'package:geolocator/geolocator.dart'; // GPS
import 'package:geocoding/geocoding.dart'; // Alamat
import '../widgets/AppDrawer.dart';

// --- MODEL DATA ---
class AttendanceRecord {
  final String id;
  final String employeeName;
  final String avatarUrl; 
  final DateTime checkInTime;
  final String status;
  final String? location; // Tambahan Lokasi
  final String? evidenceUrl; // Tambahan Bukti Foto

  AttendanceRecord(this.id, this.employeeName, this.avatarUrl, this.checkInTime, this.status, {this.location, this.evidenceUrl});
}

// --- MAIN WIDGET ---
class AttendancePages extends StatefulWidget {
  const AttendancePages({super.key});

  @override
  State<AttendancePages> createState() => _AttendancePagesState();
}

class _AttendancePagesState extends State<AttendancePages> {
  List<AttendanceRecord> _todayAttendance = [];
  bool _isLoadingToday = true;

  @override
  void initState() {
    super.initState();
    _fetchTodayAttendance();
  }

  // Format Waktu UI
  String _formatTime(DateTime date) {
    return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }

  String _getInitials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return "?";
    final parts = trimmed.split(RegExp(r"\s+")).where((p) => p.isNotEmpty).toList();
    if (parts.length == 1) {
      final p = parts.first;
      return (p.length >= 2 ? p.substring(0, 2) : p.substring(0, 1)).toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  String _displayStatus(String raw) {
    final normalized = raw.toLowerCase();
    if (normalized == 'tercepat') return "Tercepat";
    if (normalized == 'hadir') return "Hadir";
    if (normalized == 'tepat_waktu') return "Tepat Waktu";
    return raw;
  }

  Future<void> _fetchTodayAttendance() async {
    setState(() => _isLoadingToday = true);
    try {
      final response = await http
          .get(Uri.parse(ApiHelper.getUrl('/api/attendance/today')))
          .timeout(ApiHelper.requestTimeout);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final parsed = data.map<AttendanceRecord>((json) {
          final name = (json['full_name'] ?? '').toString();
          final dateStr = (json['date'] ?? DateTime.now().toIso8601String()).toString();
          final timeStr = (json['check_in_time'] ?? '00:00:00').toString();
          final dateOnly = dateStr.contains('T') ? dateStr.split('T')[0] : dateStr;
          final dt = DateTime.tryParse("$dateOnly $timeStr") ?? DateTime.now();
          final status = _displayStatus((json['status'] ?? '-').toString());

          return AttendanceRecord(
            (json['id'] ?? '').toString(),
            name.isEmpty ? "Unknown" : name,
            _getInitials(name.isEmpty ? "Unknown" : name),
            dt,
            status,
            location: json['location']?.toString(),
            evidenceUrl: json['photo_url']?.toString(),
          );
        }).toList();

        if (!mounted) return;
        setState(() {
          _todayAttendance = parsed;
          _isLoadingToday = false;
        });
        return;
      }
      debugPrint("Gagal memuat absensi hari ini: ${response.statusCode} ${response.body}");
    } on TimeoutException {
      debugPrint("Gagal memuat absensi hari ini: timeout");
    } on SocketException {
      debugPrint("Gagal memuat absensi hari ini: socket");
    } catch (e) {
      debugPrint("Gagal memuat absensi hari ini: $e");
    }

    if (!mounted) return;
    setState(() => _isLoadingToday = false);
  }

  void _showAddAttendanceDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AddAttendanceDialog(
        onSuccess: (newRecord) {
          setState(() {
            // Logic: Tambahkan data baru ke list paling atas (index 0)
            // agar data tidak hilang dan langsung muncul
            _todayAttendance.insert(0, newRecord);
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
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Scaffold.of(context).openDrawer(),
                  child: const Icon(Icons.menu, color: Colors.white),
                ),
                const Column(
                  children: [
                    Text("Attendance", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text("Manage Daily Check-ins", style: TextStyle(fontSize: 12, color: Colors.white70)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                  onPressed: _showAddAttendanceDialog,
                ),
              ],
            ),
          ),

          // --- LIST ATTENDANCE ---
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 13), blurRadius: 12, offset: const Offset(0, -2))],
              ),
              child: _isLoadingToday
                  ? const Center(child: CircularProgressIndicator())
                  : _todayAttendance.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt, size: 60, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              const Text("Belum ada data absensi hari ini", style: TextStyle(color: Colors.grey)),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: _showAddAttendanceDialog,
                                icon: const Icon(Icons.add),
                                label: const Text("Absen Sekarang"),
                              )
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _todayAttendance.length,
                          itemBuilder: (context, index) {
                            final record = _todayAttendance[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor: Colors.blue[100],
                                      child: record.evidenceUrl != null
                                          ? ClipOval(
                                              child: Image.network(
                                                record.evidenceUrl!,
                                                width: 48,
                                                height: 48,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return const SizedBox(
                                                    width: 48,
                                                    height: 48,
                                                    child: Center(
                                                      child: Icon(Icons.broken_image_outlined, color: Colors.white),
                                                    ),
                                                  );
                                                },
                                              ),
                                            )
                                          : Text(record.avatarUrl, style: const TextStyle(fontWeight: FontWeight.bold)),
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
                                              Text(_formatTime(record.checkInTime), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                            ],
                                          ),
                                          if (record.location != null)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 4.0),
                                              child: Row(
                                                children: [
                                                  const Icon(Icons.location_on, size: 14, color: Colors.redAccent),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      record.location!,
                                                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.green[50],
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        record.status,
                                        style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- DIALOG ADD ATTENDANCE (KAMERA & LOKASI) ---
class AddAttendanceDialog extends StatefulWidget {
  final Function(AttendanceRecord) onSuccess;
  const AddAttendanceDialog({super.key, required this.onSuccess});

  @override
  State<AddAttendanceDialog> createState() => _AddAttendanceDialogState();
}

class _AddAttendanceDialogState extends State<AddAttendanceDialog> {
  // State
  File? _imageFile;
  String _currentAddress = "Mencari lokasi...";
  bool _isLoading = false;

  // Data Pegawai
  List<dynamic> _employees = []; 
  String? _selectedEmployeeName; 
  String? _selectedEmployeeId;   

  final ImagePicker _picker = ImagePicker();

  String _getInitials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return "?";
    final parts = trimmed.split(RegExp(r"\s+")).where((p) => p.isNotEmpty).toList();
    if (parts.length == 1) {
      final p = parts.first;
      return (p.length >= 2 ? p.substring(0, 2) : p.substring(0, 1)).toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  String _displayStatus(String raw) {
    final normalized = raw.toLowerCase();
    if (normalized == 'tercepat') return "Tercepat";
    if (normalized == 'hadir') return "Hadir";
    if (normalized == 'tepat_waktu') return "Tepat Waktu";
    return raw;
  }

  @override
  void initState() {
    super.initState();
    _fetchEmployees();
    _getCurrentLocation(); // Otomatis cari lokasi saat dibuka
  }

  // 1. Fetch Pegawai
  Future<void> _fetchEmployees() async {
    try {
      final response = await http
          .get(Uri.parse(ApiHelper.getUrl('/api/pegawai')))
          .timeout(ApiHelper.requestTimeout);
      if (response.statusCode == 200) {
        if (!mounted) return;
        setState(() => _employees = jsonDecode(response.body));
        return;
      }
      debugPrint("Error fetching employees: ${response.statusCode} ${response.body}");
    } on TimeoutException {
      debugPrint("Error fetching employees: timeout");
    } on SocketException {
      debugPrint("Error fetching employees: socket");
    } catch (e) {
      debugPrint("Error fetching employees: $e");
    }
  }

  // 2. Ambil Lokasi (GPS -> Alamat)
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _currentAddress = "GPS dimatikan.");
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _currentAddress = "Izin lokasi ditolak.");
        return;
      }
    }

    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _currentAddress = "${place.street}, ${place.subLocality}, ${place.locality}";
        });
      }
    } catch (e) {
      setState(() => _currentAddress = "Gagal memuat lokasi.");
    }
  }

  // 3. Ambil Foto (Kamera)
  Future<void> _handleCapture() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera, 
      imageQuality: 50 // Kompres biar gak berat
    );
    
    if (photo != null) {
      setState(() {
        _imageFile = File(photo.path);
      });
    }
  }

  // 4. Submit ke Backend
  Future<void> _handleSubmit() async {
    if (_selectedEmployeeId == null || _imageFile == null) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() => _isLoading = true);

    try {
      // Setup Request Multipart
      var request = http.MultipartRequest('POST', Uri.parse(ApiHelper.getUrl('/api/attendance')));
      
      // Fields text
      request.fields['user_id'] = _selectedEmployeeId.toString(); // ID dari user_id tabel users
      request.fields['location'] = _currentAddress;

      // File Image
      request.files.add(await http.MultipartFile.fromPath('photo', _imageFile!.path));

      // Kirim
      var streamedResponse = await request.send().timeout(ApiHelper.requestTimeout);
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var responseData = jsonDecode(response.body);
        var data = responseData['data']; // Data log yang baru masuk
        final assignedStatusRaw = (responseData['assignedStatus'] ?? data['status'] ?? '').toString();

        final dateStr = (data['date'] ?? DateTime.now().toIso8601String()).toString();
        final timeStr = (data['check_in_time'] ?? '00:00:00').toString();
        final dateOnly = dateStr.contains('T') ? dateStr.split('T')[0] : dateStr;
        final dt = DateTime.tryParse("$dateOnly $timeStr") ?? DateTime.now();
        final name = (data['full_name'] ?? _selectedEmployeeName ?? "Unknown").toString();

        final newRecord = AttendanceRecord(
          data['id'].toString(),
          name, 
          _getInitials(name),
          dt,
          _displayStatus(assignedStatusRaw),
          location: _currentAddress,
          evidenceUrl: data['photo_url'] // URL foto dari backend
        );

        widget.onSuccess(newRecord); // Callback ke halaman utama
        if (!mounted) return;
        navigator.pop(); // Tutup dialog
      } else if (response.statusCode == 409) {
        final body = jsonDecode(response.body);
        final message = (body['message'] ?? 'Pegawai sudah absen hari ini').toString();
        if (!mounted) return;
        messenger.showSnackBar(SnackBar(content: Text(message)));
      } else {
        debugPrint("Gagal upload: ${response.statusCode} ${response.body}");
      }
    } on TimeoutException {
      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(content: Text("Request timeout")));
    } on SocketException {
      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(content: Text("Gagal terhubung ke server")));
    } catch (e) {
      debugPrint("Error submitting: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showEmployeeListDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(16),
          constraints: const BoxConstraints(maxHeight: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Pilih Pegawai", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const Divider(),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _employees.length,
                  itemBuilder: (ctx, i) {
                    final emp = _employees[i];
                    return ListTile(
                      title: Text(emp['full_name']),
                      onTap: () {
                        setState(() {
                          _selectedEmployeeName = emp['full_name'];
                          // Jika di DB ID adalah string 'EMP001', pastikan backend handle ini
                          // Jika ID integer, parse dulu. Asumsi di sini ID = id (integer primary key)
                          _selectedEmployeeId = emp['id'].toString(); 
                        });
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Absen Masuk", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              // 1. Pilih Pegawai
              GestureDetector(
                onTap: _showEmployeeListDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_selectedEmployeeName ?? "Pilih Nama Pegawai"),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 2. Area Foto & Lokasi
              GestureDetector(
                onTap: _handleCapture,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    image: _imageFile != null 
                      ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover)
                      : null,
                  ),
                  child: _imageFile == null 
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, color: Colors.blue, size: 40),
                          SizedBox(height: 8),
                          Text("Tap untuk ambil foto"),
                        ],
                      )
                    : null,
                ),
              ),
              const SizedBox(height: 12),

              // 3. Info Lokasi
              Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _currentAddress, 
                      style: const TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 4. Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_imageFile != null && _selectedEmployeeId != null && !_isLoading) 
                    ? _handleSubmit 
                    : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue, 
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                    : const Text("Submit Attendance", style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
