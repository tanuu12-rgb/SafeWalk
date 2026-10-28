class SafeWalkSession {
  final String id;
  final String userId;
  final String destination;
  final int durationMinutes;
  final DateTime startTime;
  final DateTime scheduledEndTime;
  final String status; // 'IN_PROGRESS', 'ARRIVED_SAFELY', 'ESCALATED_ALERT', 'CANCELLED'
  final double? startLat;
  final double? startLng;

  const SafeWalkSession({
    required this.id,
    required this.userId,
    required this.destination,
    required this.durationMinutes,
    required this.startTime,
    required this.scheduledEndTime,
    required this.status,
    this.startLat,
    this.startLng,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'destination': destination,
      'durationMinutes': durationMinutes,
      'startTime': startTime.toIso8601String(),
      'scheduledEndTime': scheduledEndTime.toIso8601String(),
      'status': status,
      'startLat': startLat,
      'startLng': startLng,
    };
  }

  factory SafeWalkSession.fromJson(Map<dynamic, dynamic> json, [String? idKey]) {
    return SafeWalkSession(
      id: idKey ?? (json['id'] as String? ?? ''),
      userId: json['userId'] as String? ?? '',
      destination: json['destination'] as String? ?? 'Home',
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 15,
      startTime: json['startTime'] != null
          ? DateTime.tryParse(json['startTime'] as String) ?? DateTime.now()
          : DateTime.now(),
      scheduledEndTime: json['scheduledEndTime'] != null
          ? DateTime.tryParse(json['scheduledEndTime'] as String) ?? DateTime.now()
          : DateTime.now(),
      status: json['status'] as String? ?? 'ARRIVED_SAFELY',
      startLat: (json['startLat'] as num?)?.toDouble(),
      startLng: (json['startLng'] as num?)?.toDouble(),
    );
  }
}
