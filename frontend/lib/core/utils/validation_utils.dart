class ValidationUtils {
  /// Validates email based on user rules:
  /// - Optional (returns null if empty or null)
  /// - If provided, must end with '@gmail.com'
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional
    }
    final trimmed = value.trim();
    if (!trimmed.toLowerCase().endsWith('@gmail.com')) {
      return 'Email must end with @gmail.com';
    }
    return null;
  }

  /// Validates either email or phone for login
  static String? validateIdentifier(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email or Phone is required';
    }
    final trimmed = value.trim();
    if (trimmed.contains('@')) {
      return validateEmail(trimmed);
    } else {
      return validatePhone(trimmed);
    }
  }

  /// Validates phone number based on user rules:
  /// - Required
  /// - Must have exactly 9 digits after '0' or '+94'
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final trimmed = value.trim();
    
    // Check if it starts with '0' and followed by 9 digits
    final zeroPattern = RegExp(r'^0[0-9]{9}$');
    // Check if it starts with '+94' and followed by 9 digits
    final intlPattern = RegExp(r'^\+94[0-9]{9}$');

    if (trimmed.startsWith('0')) {
      if (!zeroPattern.hasMatch(trimmed)) {
        return 'Phone number must have 9 digits after 0 (e.g. 0771234567)';
      }
    } else if (trimmed.startsWith('+94')) {
      if (!intlPattern.hasMatch(trimmed)) {
        return 'Phone number must have 9 digits after +94 (e.g. +94771234567)';
      }
    } else {
      return 'Phone number must start with 0 or +94';
    }
    
    return null;
  }

  /// Validates password based on user rules:
  /// - Required
  /// - At least 8 characters
  static String? validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Password is required';
    }
    if (value.trim().length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  /// Validates required fields with a custom field name
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? validatePrice(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Price is required';
    }
    final price = double.tryParse(value);
    if (price == null || price <= 0) {
      return 'Enter a valid price greater than 0';
    }
    return null;
  }

  static String? validateStock(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Stock level is required';
    }
    final stock = int.tryParse(value);
    if (stock == null || stock < 0) {
      return 'Enter a valid non-negative number';
    }
    return null;
  }
}
