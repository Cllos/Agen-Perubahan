import 'package:flutter/material.dart';

// --- MOCK DATA & MODEL (Sementara) ---
class HistoryRecord {
  final String id;
  final String employeeName;
  final String employeeAvatar;
  final DateTime checkInTime;
  final String status; // 'Present' or 'Late'

  HistoryRecord({
    required this.id,
    required this.employeeName,
    required this.employeeAvatar,
    required this.checkInTime,
    required this.status,
  });
}

// Data dummy yang diperluas untuk keperluan testing filter
final List<HistoryRecord> attendanceHistory = [
  HistoryRecord(id: '1', employeeName: 'Sarah Smith', employeeAvatar: 'https://i.pravatar.cc/150?u=1', checkInTime: DateTime.now(), status: 'Present'),
  HistoryRecord(id: '2', employeeName: 'John Doe', employeeAvatar: 'https://i.pravatar.cc/150?u=2', checkInTime: DateTime.now().subtract(const Duration(minutes: 15)), status: 'Late'),
  HistoryRecord(id: '3', employeeName: 'Jane Wilson', employeeAvatar: 'https://i.pravatar.cc/150?u=3', checkInTime: DateTime.now().subtract(const Duration(days: 1)), status: 'Present'),
  HistoryRecord(id: '4', employeeName: 'Mike Brown', employeeAvatar: 'https://i.pravatar.cc/150?u=4', checkInTime: DateTime.now().subtract(const Duration(days: 1, minutes: 20)), status: 'Present'),
  HistoryRecord(id: '5', employeeName: 'Emily Davis', employeeAvatar: 'https://i.pravatar.cc/150?u=5', checkInTime: DateTime.now().subtract(const Duration(days: 35)), status: 'Present'), // Bulan lalu
];

// -------------------------------------

class HistoryPages extends StatefulWidget {
  const HistoryPages({super.key});

  @override
  State<HistoryPages> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryPages> {
  // State variables
  String _filterType = 'day'; // 'day', 'month', 'year'
  DateTime _selectedDate = DateTime.now();

  // --- LOGIC HELPERS ---

  // Helper format jam (HH:mm AM/PM)
  String _formatTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return "$hour:$minute $period";
  }

  // Helper format tanggal (Mon, Jan 10, 2026)
  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return "${days[date.weekday % 7]}, ${months[date.month - 1]} ${date.day}, ${date.year}";
  }

  // Helper untuk mendapatkan nama bulan (untuk filter dropdown)
  String _getMonthName(int monthIndex) {
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return months[monthIndex - 1];
  }

  // Logic Filtering & Grouping
  Map<String, List<HistoryRecord>> _getFilteredAndGroupedData() {
    // 1. Filter
    final filtered = attendanceHistory.filter((record) {
      final rDate = record.checkInTime;
      final sDate = _selectedDate;

      if (_filterType == 'day') {
        return rDate.year == sDate.year && rDate.month == sDate.month && rDate.day == sDate.day;
      } else if (_filterType == 'month') {
        return rDate.year == sDate.year && rDate.month == sDate.month;
      } else {
        // year
        return rDate.year == sDate.year;
      }
    }).toList();

    // 2. Group by Date String
    final Map<String, List<HistoryRecord>> grouped = {};
    for (var record in filtered) {
      // Kita group berdasarkan tanggal saja (tanpa jam)
      final dateKey = DateTime(record.checkInTime.year, record.checkInTime.month, record.checkInTime.day).toString();
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(record);
    }

    return grouped;
  }

  // Fungsi untuk membuka Bottom Sheet Filter
  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Agar bisa menyesuaikan tinggi
      backgroundColor: Colors.transparent,
      builder: (context) {
        // Menggunakan StatefulBuilder agar bottom sheet bisa update state-nya sendiri (misal ganti tombol filter)
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
                  // Header Modal
                  const Text("Filter Attendance", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text("Select the filter type and date range to view attendance records.", style: TextStyle(color: Colors.grey, fontSize: 14)),
                  
                  const SizedBox(height: 24),

                  // Filter Type Selection
                  const Text("Filter By", style: TextStyle(fontSize: 14, color: Colors.grey)),
                  const SizedBox(height: 12),
                  Row(
                    children: ['day', 'month', 'year'].map((type) {
                      final isSelected = _filterType == type;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: GestureDetector(
                            onTap: () {
                              setModalState(() {
                                // Update state di dalam modal
                                setState(() => _filterType = type);
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.blue.shade600 : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: isSelected ? [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
                              ),
                              child: Text(
                                type[0].toUpperCase() + type.substring(1),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // Date Selection Input based on Filter Type
                  Text(
                    _filterType == 'day' ? "Select Date" : _filterType == 'month' ? "Select Month" : "Select Year",
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),

                  _buildDateInput(context, setModalState),

                  const SizedBox(height: 24),

                  // Apply Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        // Karena state utama (_filterType & _selectedDate) sudah diupdate lewat setState parent,
                        // kita tinggal tutup modal.
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Apply Filter", style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          }
        );
      },
    );
  }

  // Widget Input Tanggal dinamis sesuai Filter Type
  Widget _buildDateInput(BuildContext context, StateSetter setModalState) {
    if (_filterType == 'day') {
      return GestureDetector(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: _selectedDate,
            firstDate: DateTime(2020),
            lastDate: DateTime(2030),
          );
          if (picked != null) {
            setModalState(() => setState(() => _selectedDate = picked));
          }
        },
        child: _inputContainer(Text(_formatDate(_selectedDate), style: const TextStyle(fontSize: 16))),
      );
    } else if (_filterType == 'month') {
       // Simulasi input bulan sederhana menggunakan Dropdown atau DatePicker
       // Untuk kemudahan tanpa library tambahan, kita pakai Dropdown sederhana
       return Row(
         children: [
           Expanded(
             child: Container(
               padding: const EdgeInsets.symmetric(horizontal: 12),
               decoration: BoxDecoration(
                 border: Border.all(color: Colors.grey.shade300),
                 borderRadius: BorderRadius.circular(12),
               ),
               child: DropdownButtonHideUnderline(
                 child: DropdownButton<int>(
                   value: _selectedDate.month,
                   items: List.generate(12, (index) => index + 1).map((m) {
                     return DropdownMenuItem(value: m, child: Text(_getMonthName(m)));
                   }).toList(),
                   onChanged: (val) {
                     if (val != null) {
                        setModalState(() => setState(() => _selectedDate = DateTime(_selectedDate.year, val, 1)));
                     }
                   },
                 ),
               ),
             ),
           ),
           const SizedBox(width: 8),
           Expanded(
             child: Container(
               padding: const EdgeInsets.symmetric(horizontal: 12),
               decoration: BoxDecoration(
                 border: Border.all(color: Colors.grey.shade300),
                 borderRadius: BorderRadius.circular(12),
               ),
               child: DropdownButtonHideUnderline(
                 child: DropdownButton<int>(
                   value: _selectedDate.year,
                   items: [2024, 2025, 2026].map((y) {
                     return DropdownMenuItem(value: y, child: Text(y.toString()));
                   }).toList(),
                   onChanged: (val) {
                     if (val != null) {
                        setModalState(() => setState(() => _selectedDate = DateTime(val, _selectedDate.month, 1)));
                     }
                   },
                 ),
               ),
             ),
           ),
         ],
       );
    } else {
      // Year Select
      return Container(
         padding: const EdgeInsets.symmetric(horizontal: 12),
         decoration: BoxDecoration(
           border: Border.all(color: Colors.grey.shade300),
           borderRadius: BorderRadius.circular(12),
         ),
         child: DropdownButtonHideUnderline(
           child: DropdownButton<int>(
             isExpanded: true,
             value: _selectedDate.year,
             items: [2024, 2025, 2026].map((y) {
               return DropdownMenuItem(value: y, child: Text(y.toString()));
             }).toList(),
             onChanged: (val) {
               if (val != null) {
                  setModalState(() => setState(() => _selectedDate = DateTime(val, 1, 1)));
               }
             },
           ),
         ),
       );
    }
  }

  Widget _inputContainer(Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupedData = _getFilteredAndGroupedData();
    // Sort keys (dates) descending
    final sortedKeys = groupedData.keys.toList()
      ..sort((a, b) => DateTime.parse(b).compareTo(DateTime.parse(a)));

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 80),
        child: Column(
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
                      
                      // Filter Button Trigger
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
                    "Viewing ${_filterType == 'day' ? 'daily' : _filterType == 'month' ? 'monthly' : 'yearly'} records",
                    style: TextStyle(color: Colors.blue.shade100, fontSize: 14),
                  ),
                ],
              ),
            ),

            // --- LIST CONTENT ---
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: sortedKeys.isEmpty 
              ? SizedBox(
                height: 300,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_today, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      const Text("No attendance records found", style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              )
              : Column(
                children: sortedKeys.map((dateString) {
                  final records = groupedData[dateString]!;
                  final dateObj = DateTime.parse(dateString);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date Group Header
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12, top: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_month, size: 16, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(
                              _formatDate(dateObj),
                              style: const TextStyle(color: Color(0xFF4B5563), fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "(${records.length} ${records.length == 1 ? 'record' : 'records'})",
                              style: TextStyle(color: Colors.grey[400], fontSize: 14),
                            ),
                          ],
                        ),
                      ),

                      // Records List for this date
                      ...records.map((record) {
                        final isPresent = record.status == 'Present';
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
                              CircleAvatar(
                                radius: 24,
                                backgroundImage: NetworkImage(record.employeeAvatar),
                                onBackgroundImageError: (_,__) => const Icon(Icons.person),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(record.employeeName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.access_time, size: 14, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(_formatTime(record.checkInTime), style: const TextStyle(fontSize: 14, color: Colors.grey)),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isPresent ? Colors.green.shade100 : Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  record.status,
                                  style: TextStyle(
                                    color: isPresent ? Colors.green.shade700 : Colors.orange.shade700,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 12),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Extension sederhana untuk filter (mirip JS filter)
extension FilterList<E> on List<E> {
  List<E> filter(bool Function(E) test) {
    return where(test).toList();
  }
}