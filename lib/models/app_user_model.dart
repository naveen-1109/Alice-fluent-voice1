class AppUser {
  final String id;
  final String email;
  final String role;
  final String fullName;
  final String? phone;
  final String? profileImage;
  final DateTime? createdAt;

  AppUser({
    required this.id,
    required this.email,
    required this.role,
    required this.fullName,
    this.phone,
    this.profileImage,
    this.createdAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'patient',
      fullName: json['full_name'] ?? '',
      phone: json['phone'],
      profileImage: json['profile_image'],
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': role,
      'full_name': fullName,
      'phone': phone,
      'profile_image': profileImage,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }
}
