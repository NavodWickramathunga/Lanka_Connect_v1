class Review {
  Review({
    required this.id,
    required this.serviceId,
    required this.providerId,
    required this.reviewerId,
    required this.rating,
    required this.comment,
  });

  final String id;
  final String serviceId;
  final String providerId;
  final String reviewerId;
  final int rating;
  final String comment;

  factory Review.fromMap(String id, Map<String, dynamic> data) {
    return Review(
      id: id,
      serviceId: (data['serviceId'] ?? '').toString(),
      providerId: (data['providerId'] ?? '').toString(),
      reviewerId: (data['reviewerId'] ?? '').toString(),
      rating: (data['rating'] ?? 0).toInt(),
      comment: (data['comment'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'serviceId': serviceId,
      'providerId': providerId,
      'reviewerId': reviewerId,
      'rating': rating,
      'comment': comment,
    };
  }
}
