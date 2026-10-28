class OfflineAlert {
  final String id;
  final String userId;
  final String userName;
  final String alertType; // 'SAFE_WALK_TIMEOUT', 'MANUAL_SOS', 'SHAKE_SOS'
  final String destination;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final bool isSynced;
  final String? syncError;

  const OfflineAlert({
    required this.id,
    required this.userId,
    required this.userName,
    required this.alertType,
    required this.destination,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.isSynced = false,
    this.syncError,
  });

  OfflineAlert copyWith({
    String? id,
    String? userId,
    String? userName,
    String? alertType,
    String? destination,
    double? latitude,
    double? longitude,
    DateTime? timestamp,
    bool? isSynced,
    String? syncError,
  }) {
    return OfflineAlert(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      alertType: alertType ?? this.alertType,
      destination: destination ?? this.destination,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      timestamp: timestamp ?? this.timestamp,
      isSynced: isSynced ?? this.isSynced,
      syncError: syncError ?? this.syncError,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'alertType': alertType,
      'destination': destination,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'isSynced': isSynced,
      'syncError': syncError,
    };
  }

  factory OfflineAlert.fromJson(Map<String, dynamic> json) {
    return OfflineAlert(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      userId: json['userId'] as String? ?? 'anonymous',
      userName: json['userName'] as String? ?? 'User',
      alertType: json['alertType'] as String? ?? 'MANUAL_SOS',
      destination: json['destination'] as String? ?? 'General Area',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      isSynced: json['isSynced'] as bool? ?? false,
      syncError: json['syncError'] as String?,
    );
  }
}
