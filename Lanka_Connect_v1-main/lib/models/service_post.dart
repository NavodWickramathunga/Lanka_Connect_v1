class ServicePost {
  ServicePost({
    required this.id,
    required this.providerId,
    required this.title,
    required this.category,
    required this.price,
    required this.location,
    required this.description,
    required this.status,
    this.imageUrls = const [],
    this.rating = 0.0,
    this.reviewCount = 0,
    this.district = '',
    this.city = '',
    this.lat,
    this.lng,
  });

  final String id;
  final String providerId;
  final String title;
  final String category;
  final double price;
  final String location;
  final String description;
  final String status;
  final List<String> imageUrls;
  final double rating;
  final int reviewCount;
  final String district;
  final String city;
  final double? lat;
  final double? lng;

  factory ServicePost.fromMap(String id, Map<String, dynamic> data) {
    final rawImages = data['imageUrls'];
    final images = rawImages is List
        ? rawImages.map((e) => e.toString()).toList()
        : <String>[];

    return ServicePost(
      id: id,
      providerId: (data['providerId'] ?? '').toString(),
      title: (data['title'] ?? '').toString(),
      category: (data['category'] ?? '').toString(),
      price: (data['price'] ?? 0).toDouble(),
      location: (data['location'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      status: (data['status'] ?? 'pending').toString(),
      imageUrls: images,
      rating: (data['rating'] ?? 0).toDouble(),
      reviewCount: (data['reviewCount'] ?? 0).toInt(),
      district: (data['district'] ?? '').toString(),
      city: (data['city'] ?? '').toString(),
      lat: data['lat'] != null ? (data['lat'] as num).toDouble() : null,
      lng: data['lng'] != null ? (data['lng'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'providerId': providerId,
      'title': title,
      'category': category,
      'price': price,
      'location': location,
      'description': description,
      'status': status,
      'imageUrls': imageUrls,
      'rating': rating,
      'reviewCount': reviewCount,
      'district': district,
      'city': city,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
    };
  }
}
