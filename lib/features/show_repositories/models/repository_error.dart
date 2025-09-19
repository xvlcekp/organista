import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException;
import 'package:flutter/foundation.dart' show immutable;
import 'package:organista/logger/custom_logger.dart';

@immutable
abstract class RepositoryError {
  const RepositoryError();
}

@immutable
class RepositoriesErrorUnknown extends RepositoryError {
  final FirebaseAuthException exception;
  RepositoriesErrorUnknown({required this.exception}) : super() {
    logger.e(exception);
  }
}

@immutable
class RepositoryGenericException extends RepositoryError {
  const RepositoryGenericException() : super();
}

@immutable
class RepositoryNotFound extends RepositoryError {
  const RepositoryNotFound() : super();
}

@immutable
class RepositoryCannotModifyPublic extends RepositoryError {
  const RepositoryCannotModifyPublic() : super();
}

@immutable
class RepositoryCannotModifyOtherUsers extends RepositoryError {
  const RepositoryCannotModifyOtherUsers() : super();
}

@immutable
class MaximumRepositoriesCounExceeded extends RepositoryError {
  final int maximumRepositoriesCount;
  const MaximumRepositoriesCounExceeded({required this.maximumRepositoriesCount}) : super();
}
