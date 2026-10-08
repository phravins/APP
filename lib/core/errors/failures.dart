sealed class AppFailure implements Exception {
  final String message;
  const AppFailure(this.message);
  @override
  String toString() => message;
}

class NetworkFailure extends AppFailure {
  const NetworkFailure([
    super.message =
        'You appear to be offline. Please try again when connected.',
  ]);
}

class AuthenticationFailure extends AppFailure {
  const AuthenticationFailure([
    super.message = 'Please sign in again to continue.',
  ]);
}

class ValidationFailure extends AppFailure {
  const ValidationFailure(super.message);
}

class PermissionFailure extends AppFailure {
  const PermissionFailure([
    super.message = 'Your role does not allow this action.',
  ]);
}

class ServerFailure extends AppFailure {
  const ServerFailure([
    super.message = 'The service is temporarily unavailable. Please try again.',
  ]);
}

class UnknownFailure extends AppFailure {
  const UnknownFailure([
    super.message = 'Something went wrong. Please try again.',
  ]);
}

String friendlyError(Object error) => error is AppFailure
    ? error.message
    : 'Something went wrong. Please try again.';
