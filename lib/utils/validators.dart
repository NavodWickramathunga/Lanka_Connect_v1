class Validators {
  static String? requiredField(String? value, String message) {
    if (value == null || value.trim().isEmpty) {
      return message;
    }
    return null;
  }

  static String? numberField(String? value, String message) {
    if (value == null || value.trim().isEmpty) {
      return message;
    }
    final parsed = double.tryParse(value.trim());
    if (parsed == null) {
      return 'Enter a valid number';
    }
    return null;
  }

  static String? emailField(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    // More robust email validation per RFC 5322
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$',
    );
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? phoneField(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final phoneRegex = RegExp(r'^\+?[0-9]{10,15}$');
    if (!phoneRegex.hasMatch(value.trim().replaceAll(RegExp(r'[\s\-\(\)]'), ''))) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  static String? priceField(String? value, String message) {
    if (value == null || value.trim().isEmpty) {
      return message;
    }
    final parsed = double.tryParse(value.trim());
    if (parsed == null) {
      return 'Enter a valid price';
    }
    if (parsed <= 0) {
      return 'Price must be greater than 0';
    }
    return null;
  }

  static String? passwordField(String? value, {required bool isLogin}) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (!isLogin && value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  static String? minLengthField(String? value, int min, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required';
    }
    if (value.trim().length < min) {
      return '$label must be at least $min characters';
    }
    return null;
  }

  static String? optionalLatitude(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final parsed = double.tryParse(value.trim());
    if (parsed == null || parsed < -90 || parsed > 90) {
      return 'Latitude must be between -90 and 90';
    }
    return null;
  }

  static String? optionalLongitude(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final parsed = double.tryParse(value.trim());
    if (parsed == null || parsed < -180 || parsed > 180) {
      return 'Longitude must be between -180 and 180';
    }
    return null;
  }
}
