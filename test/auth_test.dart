import 'package:organista/services/auth/auth_error.dart';
import 'package:organista/services/auth/auth_provider.dart';
import 'package:organista/services/auth/auth_user.dart';
import 'package:test/test.dart';

void main() {
  group('Mock Authentication', () {
    late MockAuthProvider provider;

    setUp(() {
      provider = MockAuthProvider();
    });

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
      await provider.initialize();
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
      await provider.initialize();
      await provider.createUser(email: 'foo', password: 'bar');
      await provider.sendEmailVerification();
      final user = provider.currentUser;
      expect(user, isNotNull);
      expect(user!.isEmailVerified, true);
    });

    test('Should be able to log in and log out', () async {
      await provider.initialize();

      await provider.logIn(email: 'user', password: 'password');
      final user = provider.currentUser;
      expect(user, isNotNull);
      await provider.logOut();
      expect(provider.currentUser, null);
    });

    test('Should be able to send password reset email', () async {
      await provider.initialize();
      final resetFail = provider.sendPasswordResetEmail(email: 'invalid@email.com');
      expect(resetFail, throwsA(const TypeMatcher<AuthErrorInvalidEmail>()));

      final resetSuccess = await provider.sendPasswordResetEmail(email: 'foo@bar.com');
      expect(resetSuccess, true);
    });

    test('Should be able to sign in with Google', () async {
      await provider.initialize();
      expect(provider.currentUser, null);

      final user = await provider.signInWithGoogle();
      expect(provider.currentUser, user);
      expect(user.isEmailVerified, true); // Google users are verified by default
      expect(user.email, 'google@example.com');
    });

    test('Should handle Google Sign-In when not initialized', () async {
      final uninitializedProvider = MockAuthProvider();
      expect(uninitializedProvider.signInWithGoogle(), throwsA(const TypeMatcher<NotInitializedException>()));
    });

    test('Should force account picker on repeated Google Sign-In', () async {
      await provider.initialize();

      // First Google Sign-In
      await provider.signInWithGoogle();
      expect(provider.currentUser, isNotNull);
      expect(provider.currentUser!.email, 'google@example.com');
      expect(provider.googleSignOutCallCount, 1); // Called once during sign-in

      // Second Google Sign-In should force account picker by calling signOut first
      await provider.signInWithGoogle();
      expect(provider.currentUser, isNotNull);
      expect(provider.currentUser!.email, 'google@example.com');
      expect(provider.googleSignOutCallCount, 2); // Called again during second sign-in
    });

    test('Should sign out from both Firebase and Google on logout', () async {
      await provider.initialize();

      // Sign in with Google first
      await provider.signInWithGoogle();
      expect(provider.currentUser, isNotNull);
      expect(provider.googleSignOutCallCount, 1);

      // Logout should sign out from both services
      await provider.logOut();
      expect(provider.currentUser, null);
      expect(provider.googleSignOutCallCount, 2); // Called during logout as well
    });

    test('Should allow switching between regular login and Google Sign-In', () async {
      await provider.initialize();

      // Start with regular login
      await provider.logIn(email: 'user', password: 'password');
      expect(provider.currentUser!.email, 'foo@bar.com');
      expect(provider.currentUser!.isEmailVerified, false);

      // Logout completely
      await provider.logOut();
      expect(provider.currentUser, null);

      // Sign in with Google
      await provider.signInWithGoogle();
      expect(provider.currentUser!.email, 'google@example.com');
      expect(provider.currentUser!.isEmailVerified, true);

      // Logout and back to regular login
      await provider.logOut();
      await provider.logIn(email: 'user', password: 'password');
      expect(provider.currentUser!.email, 'foo@bar.com');
    });

    test('Should handle multiple Google accounts simulation', () async {
      await provider.initialize();

      // Simulate signing in with first Google account
      await provider.signInWithGoogle();
      final firstUser = provider.currentUser;
      expect(firstUser!.email, 'google@example.com');

      // Simulate signing out and choosing different account
      await provider.logOut();
      await provider.signInWithGoogleDifferentAccount();
      final secondUser = provider.currentUser;
      expect(secondUser!.email, 'google2@example.com');
      expect(secondUser.id, 'google456');
    });

    test('Should handle account deletion for Google Sign-In users', () async {
      await provider.initialize();

      // Sign in with Google
      await provider.signInWithGoogle();
      expect(provider.currentUser, isNotNull);
      expect(provider.currentUser!.email, 'google@example.com');

      // Delete the account
      await provider.deleteUser();

      // User should be null after deletion
      expect(provider.currentUser, null);

      // Should be able to sign in again with different account
      await provider.signInWithGoogleDifferentAccount();
      expect(provider.currentUser, isNotNull);
      expect(provider.currentUser!.email, 'google2@example.com');
    });
  });
}

class NotInitializedException implements Exception {}

class MockAuthProvider implements AuthProvider {
  AuthUser? _user;
  var _isInitialized = false;
  int _googleSignOutCallCount = 0;

  bool get isInitialized => _isInitialized;
  int get googleSignOutCallCount => _googleSignOutCallCount;

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
    // Simulate user deletion by setting user to null
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
  Future<AuthUser> signInWithGoogle() async {
    if (!isInitialized) throw NotInitializedException();

    // Simulate clearing previous account selection (like googleSignIn.signOut())
    _googleSignOutCallCount++;

    await Future.delayed(const Duration(milliseconds: 500));
    const user = AuthUser(isEmailVerified: true, id: 'google123', email: 'google@example.com');
    _user = user;
    return Future.value(user);
  }

  // Additional method to simulate signing in with different Google account
  Future<AuthUser> signInWithGoogleDifferentAccount() async {
    if (!isInitialized) throw NotInitializedException();

    // Simulate clearing previous account selection
    _googleSignOutCallCount++;

    await Future.delayed(const Duration(milliseconds: 500));
    const user = AuthUser(isEmailVerified: true, id: 'google456', email: 'google2@example.com');
    _user = user;
    return Future.value(user);
  }

  @override
  Future<void> logOut() async {
    if (!isInitialized) throw NotInitializedException();
    if (_user == null) throw AuthErrorUserNotFound();

    // Simulate signing out from both Firebase and Google
    _googleSignOutCallCount++;

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
