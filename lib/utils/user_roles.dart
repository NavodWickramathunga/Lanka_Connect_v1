class UserRoles {
  static const String seeker = 'seeker';
  static const String provider = 'provider';
  static const String admin = 'admin';

  static String normalize(dynamic rawRole) {
    final role = (rawRole ?? '').toString().trim().toLowerCase();
    if (role == 'provider' || role == 'service provider') return provider;
    if (role == 'admin') return admin;
    return seeker;
  }
}
