import 'package:bloc_test/bloc_test.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:organista/features/authentication/auth_bloc/auth_bloc.dart';
import 'package:organista/repositories/firebase_firestore_repository.dart';
import 'package:organista/repositories/firebase_storage_repository.dart';
import 'package:organista/services/auth/auth_error.dart';
import 'package:organista/services/auth/auth_provider.dart';
import 'package:organista/services/auth/auth_user.dart';

class MockAuthProvider extends Mock implements AuthProvider {}

class MockFirebaseFirestoreRepository extends Mock implements FirebaseFirestoreRepository {}

class MockFirebaseStorageRepository extends Mock implements FirebaseStorageRepository {}

void main() {
  late AuthProvider authProvider;
  late FirebaseFirestoreRepository firebaseFirestoreRepository;
  late FirebaseStorageRepository firebaseStorageRepository;

  const validUser = AuthUser(
    id: 'uid',
    email: 'test@test.com',
    isEmailVerified: true,
  );

  setUp(() {
    authProvider = MockAuthProvider();
    firebaseFirestoreRepository = MockFirebaseFirestoreRepository();
    firebaseStorageRepository = MockFirebaseStorageRepository();

    // Default stubs
    registerFallbackValue(const AuthUser(id: 'id', email: 'email', isEmailVerified: true));
    when(() => firebaseFirestoreRepository.createUserDocument(user: any(named: 'user'))).thenAnswer((_) async {});
    when(() => firebaseFirestoreRepository.deleteUser(userId: any(named: 'userId'))).thenAnswer((_) async => true);
    when(() => firebaseStorageRepository.deleteFolder(any())).thenAnswer((_) async {});
    when(() => authProvider.deleteUser()).thenAnswer((_) async {});
  });

  group('AuthBloc', () {
    test('initial state is AuthStateLoggedOut with isLoading: false', () {
      expect(
        AuthBloc(
          authProvider: authProvider,
          firebaseFirestoreRepository: firebaseFirestoreRepository,
          firebaseStorageRepository: firebaseStorageRepository,
        ).state,
        const AuthStateLoggedOut(isLoading: false),
      );
    });

    group('AuthEventInitialize', () {
      blocTest<AuthBloc, AuthState>(
        'emits AuthStateLoggedOut when user is null',
        build: () => AuthBloc(
          authProvider: authProvider,
          firebaseFirestoreRepository: firebaseFirestoreRepository,
          firebaseStorageRepository: firebaseStorageRepository,
        ),
        act: (bloc) => bloc.add(const AuthEventInitialize()),
        setUp: () {
          when(() => authProvider.initialize()).thenAnswer((_) async {});
          when(() => authProvider.currentUser).thenReturn(null);
        },
        expect: () => [const AuthStateLoggedOut(isLoading: false)],
        verify: (_) {
          verify(() => authProvider.initialize()).called(1);
          verify(() => authProvider.currentUser).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits AuthStateLoggedIn when user is not null',
        build: () => AuthBloc(
          authProvider: authProvider,
          firebaseFirestoreRepository: firebaseFirestoreRepository,
          firebaseStorageRepository: firebaseStorageRepository,
        ),
        act: (bloc) => bloc.add(const AuthEventInitialize()),
        setUp: () {
          when(() => authProvider.initialize()).thenAnswer((_) async {});
          when(() => authProvider.currentUser).thenReturn(validUser);
        },
        wait: const Duration(milliseconds: 200),
        expect: () => [const AuthStateLoggedIn(isLoading: false, user: validUser)],
        verify: (_) {
          verify(() => authProvider.initialize()).called(1);
          verify(() => authProvider.currentUser).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits AuthStateLoggedOut on exception',
        build: () => AuthBloc(
          authProvider: authProvider,
          firebaseFirestoreRepository: firebaseFirestoreRepository,
          firebaseStorageRepository: firebaseStorageRepository,
        ),
        act: (bloc) => bloc.add(const AuthEventInitialize()),
        setUp: () {
          when(() => authProvider.initialize()).thenThrow(Exception());
        },
        expect: () => [const AuthStateLoggedOut(isLoading: false)],
      );
    });

    group('AuthEventLogIn', () {
      const email = 'test@test.com';
      const password = 'password';

      blocTest<AuthBloc, AuthState>(
        'emits [LoggedOut(loading), LoggedIn(user)] on success',
        build: () => AuthBloc(
          authProvider: authProvider,
          firebaseFirestoreRepository: firebaseFirestoreRepository,
          firebaseStorageRepository: firebaseStorageRepository,
        ),
        act: (bloc) => bloc.add(const AuthEventLogIn(email: email, password: password)),
        setUp: () {
          when(() => authProvider.logIn(email: email, password: password)).thenAnswer((_) async => validUser);
        },
        expect: () => [
          const AuthStateLoggedOut(isLoading: true),
          const AuthStateLoggedIn(isLoading: false, user: validUser),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [LoggedOut(loading), LoggedOut(error)] on FirebaseAuthException',
        build: () => AuthBloc(
          authProvider: authProvider,
          firebaseFirestoreRepository: firebaseFirestoreRepository,
          firebaseStorageRepository: firebaseStorageRepository,
        ),
        act: (bloc) => bloc.add(const AuthEventLogIn(email: email, password: password)),
        setUp: () {
          when(
            () => authProvider.logIn(email: email, password: password),
          ).thenThrow(FirebaseAuthException(code: 'user-not-found'));
        },
        expect: () => [
          const AuthStateLoggedOut(isLoading: true),
          const AuthStateLoggedOut(isLoading: false, authError: AuthErrorUserNotFound()),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [LoggedOut(loading), LoggedOut(genericError)] on Exception',
        build: () => AuthBloc(
          authProvider: authProvider,
          firebaseFirestoreRepository: firebaseFirestoreRepository,
          firebaseStorageRepository: firebaseStorageRepository,
        ),
        act: (bloc) => bloc.add(const AuthEventLogIn(email: email, password: password)),
        setUp: () {
          when(() => authProvider.logIn(email: email, password: password)).thenThrow(Exception());
        },
        expect: () => [
          const AuthStateLoggedOut(isLoading: true),
          const AuthStateLoggedOut(isLoading: false, authError: AuthGenericException()),
        ],
      );
    });

    group('AuthEventRegister', () {
      const email = 'test@test.com';
      const password = 'password';

      blocTest<AuthBloc, AuthState>(
        'emits [LoggedOut(loading), LoggedIn(user)] on success and creates Firestore doc',
        build: () => AuthBloc(
          authProvider: authProvider,
          firebaseFirestoreRepository: firebaseFirestoreRepository,
          firebaseStorageRepository: firebaseStorageRepository,
        ),
        act: (bloc) => bloc.add(const AuthEventRegister(email: email, password: password)),
        setUp: () {
          when(() => authProvider.createUser(email: email, password: password)).thenAnswer((_) async => validUser);
        },
        expect: () => [
          const AuthStateLoggedOut(isLoading: true),
          const AuthStateLoggedIn(isLoading: false, user: validUser),
        ],
        verify: (_) {
          verify(() => firebaseFirestoreRepository.createUserDocument(user: validUser)).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [LoggedOut(loading), LoggedOut(error)] on FirebaseAuthException',
        build: () => AuthBloc(
          authProvider: authProvider,
          firebaseFirestoreRepository: firebaseFirestoreRepository,
          firebaseStorageRepository: firebaseStorageRepository,
        ),
        act: (bloc) => bloc.add(const AuthEventRegister(email: email, password: password)),
        setUp: () {
          when(
            () => authProvider.createUser(email: email, password: password),
          ).thenThrow(FirebaseAuthException(code: 'email-already-in-use'));
        },
        expect: () => [
          const AuthStateLoggedOut(isLoading: true),
          const AuthStateLoggedOut(isLoading: false, authError: AuthErrorEmailAlreadyInUse()),
        ],
      );
    });

    group('Social Sign In', () {
      blocTest<AuthBloc, AuthState>(
        'Google: emits [LoggedOut(loading), LoggedIn(user)] on success',
        build: () => AuthBloc(
          authProvider: authProvider,
          firebaseFirestoreRepository: firebaseFirestoreRepository,
          firebaseStorageRepository: firebaseStorageRepository,
        ),
        act: (bloc) => bloc.add(const AuthEventSignInWithGoogle()),
        setUp: () {
          when(() => authProvider.signInWithGoogle()).thenAnswer((_) async => validUser);
        },
        expect: () => [
          const AuthStateLoggedOut(isLoading: true),
          const AuthStateLoggedIn(isLoading: false, user: validUser),
        ],
        verify: (_) {
          verify(() => firebaseFirestoreRepository.createUserDocument(user: validUser)).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'Apple: emits [LoggedOut(loading), LoggedIn(user)] on success',
        build: () => AuthBloc(
          authProvider: authProvider,
          firebaseFirestoreRepository: firebaseFirestoreRepository,
          firebaseStorageRepository: firebaseStorageRepository,
        ),
        act: (bloc) => bloc.add(const AuthEventSignInWithApple()),
        setUp: () {
          when(() => authProvider.signInWithApple()).thenAnswer((_) async => validUser);
        },
        expect: () => [
          const AuthStateLoggedOut(isLoading: true),
          const AuthStateLoggedIn(isLoading: false, user: validUser),
        ],
        verify: (_) {
          verify(() => firebaseFirestoreRepository.createUserDocument(user: validUser)).called(1);
        },
      );
    });

    group('AuthEventLogOut', () {
      blocTest<AuthBloc, AuthState>(
        'emits [LoggedOut(loading), LoggedOut(false)] on success',
        build: () => AuthBloc(
          authProvider: authProvider,
          firebaseFirestoreRepository: firebaseFirestoreRepository,
          firebaseStorageRepository: firebaseStorageRepository,
        ),
        act: (bloc) => bloc.add(const AuthEventLogOut()),
        setUp: () {
          when(() => authProvider.logOut()).thenAnswer((_) async {});
        },
        expect: () => [
          const AuthStateLoggedOut(isLoading: true),
          const AuthStateLoggedOut(isLoading: false),
        ],
      );
    });

    group('AuthEventForgotPassword', () {
      const email = 'test@test.com';

      blocTest<AuthBloc, AuthState>(
        'emits [LoggedOut(loading), LoggedOut(resetSent: true)] on success',
        build: () => AuthBloc(
          authProvider: authProvider,
          firebaseFirestoreRepository: firebaseFirestoreRepository,
          firebaseStorageRepository: firebaseStorageRepository,
        ),
        act: (bloc) => bloc.add(const AuthEventForgotPassword(email: email)),
        setUp: () {
          when(() => authProvider.sendPasswordResetEmail(email: email)).thenAnswer((_) async => true);
        },
        expect: () => [
          const AuthStateLoggedOut(isLoading: true),
          const AuthStateLoggedOut(isLoading: false, passwordResetSent: true),
        ],
      );
    });

    group('Navigation Events', () {
      blocTest<AuthBloc, AuthState>(
        'GoToLogin emits AuthStateLoggedOut',
        build: () => AuthBloc(
          authProvider: authProvider,
          firebaseFirestoreRepository: firebaseFirestoreRepository,
          firebaseStorageRepository: firebaseStorageRepository,
        ),
        act: (bloc) => bloc.add(const AuthEventGoToLogin()),
        expect: () => [const AuthStateLoggedOut(isLoading: false)],
      );

      blocTest<AuthBloc, AuthState>(
        'GoToRegistration emits AuthStateIsInRegistrationView',
        build: () => AuthBloc(
          authProvider: authProvider,
          firebaseFirestoreRepository: firebaseFirestoreRepository,
          firebaseStorageRepository: firebaseStorageRepository,
        ),
        act: (bloc) => bloc.add(const AuthEventGoToRegistration()),
        expect: () => [const AuthStateIsInRegistrationView(isLoading: false)],
      );
    });

    group('AuthEventDeleteAccount', () {
      final recentUser = AuthUser(
        id: '123',
        email: 'test@test.com',
        isEmailVerified: true,
        lastSignInTime: DateTime.now().subtract(const Duration(minutes: 1)),
      );

      final oldUser = AuthUser(
        id: '123',
        email: 'test@test.com',
        isEmailVerified: true,
        lastSignInTime: DateTime.now().subtract(const Duration(minutes: 10)),
      );

      const nullTimeUser = AuthUser(
        id: '123',
        email: 'test@test.com',
        isEmailVerified: true,
        lastSignInTime: null,
      );

      blocTest<AuthBloc, AuthState>(
        'emits logged out when deletion is successful (recent login)',
        build: () => AuthBloc(
          authProvider: authProvider,
          firebaseFirestoreRepository: firebaseFirestoreRepository,
          firebaseStorageRepository: firebaseStorageRepository,
        ),
        seed: () => AuthStateLoggedIn(user: recentUser, isLoading: false),
        act: (bloc) => bloc.add(const AuthEventDeleteAccount()),
        expect: () => [
          AuthStateLoggedIn(user: recentUser, isLoading: true),
          const AuthStateLoggedOut(isLoading: false),
        ],
        verify: (_) {
          verify(() => firebaseFirestoreRepository.deleteUser(userId: recentUser.id)).called(1);
          verify(() => firebaseStorageRepository.deleteFolder(recentUser.id)).called(1);
          verify(() => authProvider.deleteUser()).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits error when login is too old',
        build: () => AuthBloc(
          authProvider: authProvider,
          firebaseFirestoreRepository: firebaseFirestoreRepository,
          firebaseStorageRepository: firebaseStorageRepository,
        ),
        seed: () => AuthStateLoggedIn(user: oldUser, isLoading: false),
        act: (bloc) => bloc.add(const AuthEventDeleteAccount()),
        expect: () => [
          AuthStateLoggedIn(user: oldUser, isLoading: true),
          AuthStateLoggedIn(
            user: oldUser,
            isLoading: false,
            authError: const AuthErrorRequiresRecentLogin(),
          ),
        ],
        verify: (_) {
          verifyNever(() => firebaseFirestoreRepository.deleteUser(userId: any(named: 'userId')));
          verifyNever(() => authProvider.deleteUser());
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits error if lastSignInTime is null',
        build: () => AuthBloc(
          authProvider: authProvider,
          firebaseFirestoreRepository: firebaseFirestoreRepository,
          firebaseStorageRepository: firebaseStorageRepository,
        ),
        seed: () => const AuthStateLoggedIn(user: nullTimeUser, isLoading: false),
        act: (bloc) => bloc.add(const AuthEventDeleteAccount()),
        expect: () => [
          const AuthStateLoggedIn(user: nullTimeUser, isLoading: true),
          const AuthStateLoggedIn(
            user: nullTimeUser,
            isLoading: false,
            authError: AuthErrorRequiresRecentLogin(),
          ),
        ],
        verify: (_) {
          verifyNever(() => firebaseFirestoreRepository.deleteUser(userId: any(named: 'userId')));
          verifyNever(() => authProvider.deleteUser());
        },
      );
    });
  });
}
