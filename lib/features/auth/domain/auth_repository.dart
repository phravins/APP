import '../../../shared/models/models.dart';

abstract interface class AuthRepository {
  Future<User?> restore();
  Future<User> signIn(String email, String password, {bool remember = true});
  Future<User> register({
    required String name,
    required String email,
    required String password,
    required String phone,
  });
  Future<User> enterDemo();
  Future<void> forgotPassword(String email);
  Future<void> signOut();
}

/// Matches the web app's sign-up rule: accepts `98765 43210`, `09876543210`
/// or `+91 98765 43210` and returns `+919876543210`, or null if invalid.
String? normaliseIndianMobile(String raw) {
  var digits = raw.replaceAll(RegExp(r'[\s\-()]'), '');
  if (digits.startsWith('+91')) {
    digits = digits.substring(3);
  } else if (digits.startsWith('91') && digits.length == 12) {
    digits = digits.substring(2);
  } else if (digits.startsWith('0') && digits.length == 11) {
    digits = digits.substring(1);
  }
  return RegExp(r'^[6-9]\d{9}$').hasMatch(digits) ? '+91$digits' : null;
}
