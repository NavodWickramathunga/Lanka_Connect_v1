class UserProfile {
  UserProfile({
    required this.uid,
    required this.role,
    required this.name,
    required this.contact,
    required this.district,
    required this.city,
    required this.skills,
    required this.bio,
    required this.imageUrl,
  });

  final String uid;
  final String role;
  final String name;
  final String contact;
  final String district;
  final String city;
  final List<String> skills;
  final String bio;
  final String imageUrl;

  factory UserProfile.fromMap(String uid, Map<String, dynamic> data) {
    return UserProfile(
      uid: uid,
      role: (data['role'] ?? '').toString(),
      name: (data['name'] ?? '').toString(),
      contact: (data['contact'] ?? '').toString(),
      district: (data['district'] ?? '').toString(),
      city: (data['city'] ?? '').toString(),
      skills: List<String>.from(data['skills'] ?? const []),
      bio: (data['bio'] ?? '').toString(),
      imageUrl: (data['imageUrl'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'role': role,
      'name': name,
      'contact': contact,
      'district': district,
      'city': city,
      'skills': skills,
      'bio': bio,
      'imageUrl': imageUrl,
    };
  }
}
