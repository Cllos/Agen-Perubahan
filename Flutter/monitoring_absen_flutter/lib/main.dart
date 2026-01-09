import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Tambahkan package intl di pubspec.yaml jika ingin format tanggal advanced
import 'package:device_preview/device_preview.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (context) => const InputRankingPage(),
    ),
  );
}

class InputRankingPage extends StatefulWidget {
  const InputRankingPage({super.key});

  @override
  State<InputRankingPage> createState() => _InputRankingPageState();
}

class _InputRankingPageState extends State<InputRankingPage> {
  // Data Dummy Pegawai
  final List<String> employees = [
    'Ahmad Santoso',
    'Budi Pratama',
    'Citra Lestari',
    'Dewi Anggraeni',
    'Eko Kurniawan',
    'Fajar Sidiq',
    'Gita Gutawa',
    'Heri Purnomo',
  ];

  // State untuk menyimpan pilihan (index 0 = Rank 1, dst)
  final List<String?> _selectedRanks =List.filled(5, null);

  // Fungsi untuk mendapatkan warna berdasarkan Ranking
  Color _getRankColor(int index) {
    switch (index) {
      case 0: return const Color(0xFFFFD700); // Gold
      case 1: return const Color(0xFFC0C0C0); // Silver
      case 2: return const Color(0xFFCD7F32); // Bronze
      default: return const Color(0xFFE0F7FA); // Light Blue for others
    }
  }

  // Fungsi Submit
  void _submitData() {
    // 1. Validasi: Apakah semua slot terisi?
    if (_selectedRanks.contains(null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap isi semua 5 posisi pegawai!'), backgroundColor: Colors.red),
      );
      return;
    }

    // 2. Validasi: Apakah ada nama ganda?
    if (_selectedRanks.toSet().length != _selectedRanks.length) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Satu pegawai tidak boleh menempati 2 posisi!'), backgroundColor: Colors.orange),
      );
      return;
    }

    // 3. Jika valid, proses kirim data (Nanti disambungkan ke API)
    // Simulasi sukses:
    print("Data Terkirim: $_selectedRanks");
    showDialog(
      context: context, 
      builder: (_) => AlertDialog(
        title: const Text("Berhasil!"),
        content: const Text("Data kedatangan tercepat hari ini telah disimpan."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    // Format Tanggal Hari Ini
    String todayDate = DateFormat('EEEE, d MMMM yyyy').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text("Input Absensi Tercepat"),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // HEADER TANGGAL
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.blueAccent,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Halo, Petugas!",
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  todayDate,
                  style: const TextStyle(
                    color: Colors.white, 
                    fontSize: 22, 
                    fontWeight: FontWeight.bold
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Silakan input 5 pegawai yang datang paling awal hari ini.",
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),

          // LIST INPUT (RANK 1 - 5)
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 5,
              itemBuilder: (context, index) {
                int rankNumber = index + 1;
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(color: _getRankColor(index), width: 6)
                      )
                    ),
                    child: Row(
                      children: [
                        // Circle Rank Number
                        CircleAvatar(
                          backgroundColor: _getRankColor(index).withOpacity(0.2),
                          foregroundColor: Colors.black87,
                          child: Text(
                            "#$rankNumber",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 16),
                        
                        // Dropdown
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: "Pemenang Posisi #$rankNumber",
                              border: InputBorder.none,
                            ),
                            initialValue: _selectedRanks[index],
                            items: employees.map((name) {
                              return DropdownMenuItem(
                                value: name,
                                child: Text(name),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedRanks[index] = value;
                              });
                            },
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
      
      // TOMBOL SIMPAN
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5))
          ]
        ),
        child: ElevatedButton(
          onPressed: _submitData,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text(
            "SIMPAN DATA",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ),
    );
  }
}