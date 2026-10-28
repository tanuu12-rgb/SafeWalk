class EmergencyContact {
  final String id;
  final String name;
  final String phoneNumber;
  final String relationship;
  final bool isPrimary;
  final DateTime createdAt;

  const EmergencyContact({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.relationship,
    this.isPrimary = false,
    required this.createdAt,
  });

  EmergencyContact copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    String? relationship,
    bool? isPrimary,
    DateTime? createdAt,
  }) {
    return EmergencyContact(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      relationship: relationship ?? this.relationship,
      isPrimary: isPrimary ?? this.isPrimary,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'relationship': relationship,
      'isPrimary': isPrimary,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: json['name'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      relationship: json['relationship'] as String? ?? 'Friend',
      isPrimary: json['isPrimary'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  static const List<String> relationshipOptions = [
    'Parent',
    'Sibling',
    'Spouse / Partner',
    'Friend',
    'Guardian',
    'Colleague',
    'Other',
  ];
}
