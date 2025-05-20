import 'package:organista/services/auth/auth_error.dart';
import 'package:organista/services/auth/auth_provider.dart';
import 'package:organista/services/auth/auth_user.dart';
import 'package:test/test.dart';

void main() {
  group('Mock Authentication', () {
    final provider = MockAuthProvider();
    test('should not be initialized to begin with', () {
      expect(provider.isInitialized, false);
    });

    test('Cannot log out if not initialized', () {
      expect(provider.logOut(), throwsA(const TypeMatcher<NotInitializedException>()));
    });

    test('Should be able to initialize in less than 2 seconds', () async {
      await provider.initialize();
      expect(provider.isInitialized, true);
    }, timeout: const Timeout(Duration(seconds: 2)));

    test('User should be null after initialization', () {
      expect(provider.currentUser, null);
    });

    test('Create user should delegate to logIn function', () async {
      final badEmailUser = provider.createUser(
        email: 'foo@bar.com',
        password: 'anypassword',
      );
      expect(badEmailUser, throwsA(const TypeMatcher<AuthErrorUserNotFound>()));

      final badPasswordUser = provider.createUser(
        email: 'any@email.com',
        password: 'foobar',
      );
      expect(badPasswordUser, throwsA(const TypeMatcher<AuthErrorInvalidCredential>()));

      final user = await provider.createUser(
        email: 'foo',
        password: 'bar',
      );
      expect(provider.currentUser, user);
      expect(user.isEmailVerified, false);
    });

    test('Logged in user should be able to get verified', () async {
      await provider.sendEmailVerification();
      final user = provider.currentUser;
      expect(user, isNotNull);
      expect(user!.isEmailVerified, true);
    });

    test('Should be able to log out and log in again', () async {
      await provider.logOut();
      await provider.logIn(email: 'user', password: 'password');
      final user = provider.currentUser;
      expect(user, isNotNull);
    });

    test('Should be able to send password reset email', () async {
      final resetFail = provider.sendPasswordResetEmail(email: 'invalid@email.com');
      expect(resetFail, throwsA(const TypeMatcher<AuthErrorInvalidEmail>()));

      final resetSuccess = await provider.sendPasswordResetEmail(email: 'foo@bar.com');
      expect(resetSuccess, true);
    });
  });
}

class NotInitializedException implements Exception {}

class MockAuthProvider implements AuthProvider {
  AuthUser? _user;
  var _isInitialized = false;
  bool get isInitialized => _isInitialized;

  @override
  Future<AuthUser> createUser({
    required String email,
    required String password,
  }) async {
    if (!isInitialized) throw NotInitializedException();
    await Future.delayed(const Duration(seconds: 1));
    return logIn(
      email: email,
      password: password,
    );
  }

  @override
  AuthUser? get currentUser => _user;

  @override
  Future<void> deleteUser() async {
    if (!isInitialized) throw NotInitializedException();
    if (_user == null) throw AuthErrorUserNotFound();
    await Future.delayed(const Duration(seconds: 1));
    await deleteUser();
    _user = null;
  }

  @override
  Future<void> initialize() async {
    await Future.delayed(const Duration(seconds: 1));
    _isInitialized = true;
  }

  @override
  Future<AuthUser> logIn({
    required String email,
    required String password,
  }) {
    if (!isInitialized) throw NotInitializedException();
    if (email == 'foo@bar.com') throw AuthErrorUserNotFound();
    if (password == 'foobar') throw AuthErrorInvalidCredential();
    const user = AuthUser(isEmailVerified: false, id: '123', email: 'foo@bar.com');
    _user = user;
    return Future.value(user);
  }

  @override
  Future<void> logOut() async {
    if (!isInitialized) throw NotInitializedException();
    if (_user == null) throw AuthErrorUserNotFound();
    await Future.delayed(const Duration(seconds: 1));
    _user = null;
  }

  @override
  Future<void> sendEmailVerification() async {
    if (!isInitialized) throw NotInitializedException();
    final user = _user;
    if (user == null) throw AuthErrorUserNotFound();
    var newUser = AuthUser(id: user.id, email: user.email, isEmailVerified: true);
    _user = newUser;
  }

  @override
  Future<bool> sendPasswordResetEmail({required String email}) async {
    if (!isInitialized) throw NotInitializedException();
    if (email == 'invalid@email.com') throw AuthErrorInvalidEmail();
    return Future.value(true);
  }
}
