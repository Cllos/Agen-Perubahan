class AttendanceRecord {
  final String id;
  final String employeeName;
  final String employeeAvatar;
  final DateTime checkInTime;
  final String status;
  final String photoUrl;
  final String location;

  AttendanceRecord({
    required this.id,
    required this.employeeName,
    required this.employeeAvatar,
    required this.checkInTime,
    required this.status,
    this.location = "Office", // Default location jika tidak ada di DB
    this.photoUrl = "https://via.placeholder.com/200",
  });

  // Factory untuk convert JSON dari Backend ke Object Dart
  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    // parse check_in_time which may be ISO or just HH:mm:ss
    DateTime parsed;
    final raw = json['check_in_time']?.toString() ?? '';
    parsed = DateTime.tryParse(raw) ??
        (() {
          try {
            final parts = raw.split(':').map((s) => int.parse(s)).toList();
            final now = DateTime.now();
            return DateTime(now.year, now.month, now.day, parts[0], parts.length > 1 ? parts[1] : 0, parts.length > 2 ? parts[2] : 0);
          } catch (_) {
            return DateTime.now();
          }
        })();

    return AttendanceRecord(
      id: json['id'].toString(),
      employeeName: json['full_name'] ?? json['employeeName'] ?? 'Unknown',
      employeeAvatar: json['avatar_url'] ?? json['employeeAvatar'] ?? 'https://via.placeholder.com/150',
      checkInTime: parsed,
      status: json['status'] ?? '-',
      location: json['location'] ?? 'Office',
      photoUrl: json['photo_url'] ?? json['photoUrl'] ?? 'https://via.placeholder.com/200',
    );
  }
}