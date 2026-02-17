class Booking {
  Booking({
    required this.id,
    required this.serviceId,
    required this.providerId,
    required this.seekerId,
    required this.status,
  });

  final String id;
  final String serviceId;
  final String providerId;
  final String seekerId;
  final String status;

  factory Booking.fromMap(String id, Map<String, dynamic> data) {
    return Booking(
      id: id,
      serviceId: (data['serviceId'] ?? '').toString(),
      providerId: (data['providerId'] ?? '').toString(),
      seekerId: (data['seekerId'] ?? '').toString(),
      status: (data['status'] ?? 'pending').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'serviceId': serviceId,
      'providerId': providerId,
      'seekerId': seekerId,
      'status': status,
    };
  }
}
