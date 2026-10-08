import '../../../shared/models/models.dart';

abstract interface class AuthRepository {
  Future<User?> restore();
  Future<User> signIn(String email, String password, {bool remember = true});
  Future<User> register({
    required String name,
    required String email,
    required String password,
    required String company,
  });
  Future<User> enterDemo();
  Future<void> forgotPassword(String email);
  Future<void> signOut();
}
