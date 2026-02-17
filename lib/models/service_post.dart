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
  });

  final String id;
  final String providerId;
  final String title;
  final String category;
  final double price;
  final String location;
  final String description;
  final String status;

  factory ServicePost.fromMap(String id, Map<String, dynamic> data) {
    return ServicePost(
      id: id,
      providerId: (data['providerId'] ?? '').toString(),
      title: (data['title'] ?? '').toString(),
      category: (data['category'] ?? '').toString(),
      price: (data['price'] ?? 0).toDouble(),
      location: (data['location'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      status: (data['status'] ?? 'pending').toString(),
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
    };
  }
}
