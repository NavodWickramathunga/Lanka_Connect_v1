class Booking {
  Booking({
    required this.id,
    required this.serviceId,
    required this.providerId,
    required this.seekerId,
    required this.status,
    this.date,
    this.price,
    this.serviceTitle = '',
  });

  final String id;
  final String serviceId;
  final String providerId;
  final String seekerId;
  final String status;
  final DateTime? date;
  final double? price;
  final String serviceTitle;

  factory Booking.fromMap(String id, Map<String, dynamic> data) {
    DateTime? parsedDate;
    final rawDate = data['date'];
    if (rawDate is String && rawDate.isNotEmpty) {
      parsedDate = DateTime.tryParse(rawDate);
    }

    return Booking(
      id: id,
      serviceId: (data['serviceId'] ?? '').toString(),
      providerId: (data['providerId'] ?? '').toString(),
      seekerId: (data['seekerId'] ?? '').toString(),
      status: (data['status'] ?? 'pending').toString(),
      date: parsedDate,
      price: data['amount'] != null ? (data['amount'] as num).toDouble() : null,
      serviceTitle: (data['serviceTitle'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'serviceId': serviceId,
      'providerId': providerId,
      'seekerId': seekerId,
      'status': status,
      if (date != null) 'date': date!.toIso8601String(),
      if (price != null) 'amount': price,
      if (serviceTitle.isNotEmpty) 'serviceTitle': serviceTitle,
    };
  }
}
