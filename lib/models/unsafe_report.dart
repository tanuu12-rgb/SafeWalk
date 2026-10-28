class UnsafeReport {
  final String id;
  final String userId;
  final String userEmail;
  final String category;
  final String description;
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  const UnsafeReport({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.category,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userEmail': userEmail,
      'category': category,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory UnsafeReport.fromJson(Map<dynamic, dynamic> json, [String? idKey]) {
    return UnsafeReport(
      id: idKey ?? (json['id'] as String? ?? ''),
      userId: json['userId'] as String? ?? '',
      userEmail: json['userEmail'] as String? ?? 'Anonymous',
      category: json['category'] as String? ?? 'Other Hazard',
      description: json['description'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
