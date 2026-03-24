/// Normalizes Sri Lankan phone numbers to +94 format.
/// If the phone number starts with '0' and has 10 digits, it replaces '0' with '+94'.
/// Otherwise, it returns the trimmed original string.
String normalizePhoneNumber(String phone) {
  final trimmed = phone.trim();
  if (trimmed.startsWith('0') && trimmed.length == 10) {
    return '+94${trimmed.substring(1)}';
  }
  return trimmed;
}
