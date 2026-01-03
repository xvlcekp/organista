import 'package:bloc_test/bloc_test.dart';
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

  setUp(() {
    authProvider = MockAuthProvider();
    firebaseFirestoreRepository = MockFirebaseFirestoreRepository();
    firebaseStorageRepository = MockFirebaseStorageRepository();

    // Default stubs
    registerFallbackValue(const AuthUser(id: 'id', email: 'email', isEmailVerified: true));
    when(() => firebaseFirestoreRepository.deleteUser(userId: any(named: 'userId'))).thenAnswer((_) async => true);
    when(() => firebaseStorageRepository.deleteFolder(any())).thenAnswer((_) async {});
    when(() => authProvider.deleteUser()).thenAnswer((_) async {});
  });

  group('AuthBloc Delete Account', () {
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
      'proceeds with deletion if lastSignInTime is null',
      build: () => AuthBloc(
        authProvider: authProvider,
        firebaseFirestoreRepository: firebaseFirestoreRepository,
        firebaseStorageRepository: firebaseStorageRepository,
      ),
      seed: () => const AuthStateLoggedIn(user: nullTimeUser, isLoading: false),
      act: (bloc) => bloc.add(const AuthEventDeleteAccount()),
      expect: () => [
        const AuthStateLoggedIn(user: nullTimeUser, isLoading: true),
        const AuthStateLoggedOut(isLoading: false),
      ],
      verify: (_) {
        verify(() => firebaseFirestoreRepository.deleteUser(userId: nullTimeUser.id)).called(1);
      },
    );
  });
}
