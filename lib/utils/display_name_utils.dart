class DisplayNameUtils {
  static String userDisplayName({
    required String uid,
    dynamic name,
    dynamic email,
  }) {
    final normalizedName = (name ?? '').toString().trim();
    if (normalizedName.isNotEmpty) return normalizedName;

    final emailLocal = _emailLocalPart(email);
    if (emailLocal.isNotEmpty) return _titleize(emailLocal);

    final shortId = uid.trim();
    if (shortId.isNotEmpty) {
      final take = shortId.length < 8 ? shortId.length : 8;
      return 'User ${shortId.substring(0, take)}';
    }
    return 'User';
  }

  static bool isProfileIncomplete(Map<String, dynamic> data) {
    final name = (data['name'] ?? '').toString().trim();
    final city = (data['city'] ?? '').toString().trim();
    final district = (data['district'] ?? '').toString().trim();
    return name.isEmpty || city.isEmpty || district.isEmpty;
  }

  static String locationLabel({
    required dynamic city,
    required dynamic district,
    String fallback = 'Location not set',
  }) {
    final c = (city ?? '').toString().trim();
    final d = (district ?? '').toString().trim();
    if (c.isNotEmpty && d.isNotEmpty) return '$c, $d';
    if (c.isNotEmpty) return c;
    if (d.isNotEmpty) return d;
    return fallback;
  }

  static String _emailLocalPart(dynamic email) {
    final value = (email ?? '').toString().trim();
    final at = value.indexOf('@');
    if (at <= 0) return '';
    return value.substring(0, at).trim();
  }

  static String _titleize(String input) {
    final cleaned = input.replaceAll(RegExp(r'[._-]+'), ' ').trim();
    if (cleaned.isEmpty) return '';
    return cleaned
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .map((part) {
          final first = part.substring(0, 1).toUpperCase();
          final rest = part.length > 1 ? part.substring(1).toLowerCase() : '';
          return '$first$rest';
        })
        .join(' ');
  }
}
