import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:organista/models/firebase_collection_name.dart';
import 'package:organista/models/music_sheets/music_sheet_key.dart';
import 'package:organista/services/auth/auth_user.dart';

import '../../utils/auth_utils.dart';
import '../../utils/update_sequence_ids.dart';

// Tested how to do testing with mockito

@GenerateMocks([AuthUser])
import 'update_sequence_ids_test.mocks.dart';

// Create a mock for AuthUtils manually since it's our own class
class MockAuthUtils extends Mock implements AuthUtils {
  @override
  Future<AuthUser?> checkUserAuth() async {
    return super.noSuchMethod(
      Invocation.method(#checkUserAuth, []),
      returnValue: Future<AuthUser?>.value(null),
    ) as Future<AuthUser?>;
  }
}

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late MockAuthUser mockUser;
  late MockAuthUtils mockAuthUtils;
  late String repositoryId;
  late CollectionReference musicSheetsCollection;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockUser = MockAuthUser();
    mockAuthUtils = MockAuthUtils();

    // Setup repository and collection references
    repositoryId = 'c36X6vfMxHypT3CQUT9N';
    final repositoriesCollection = fakeFirestore.collection(FirebaseCollectionName.repositories);

    // Create repository document
    repositoriesCollection.doc(repositoryId).set({
      'name': 'Test Repository',
      'userId': 'test_user_id',
    });

    musicSheetsCollection = repositoriesCollection.doc(repositoryId).collection(FirebaseCollectionName.musicSheets);
  });

  group('updateSequenceIds', () {
    test('should update sequence IDs for documents without sequence_id', () async {
      WidgetsFlutterBinding.ensureInitialized();
      // Arrange
      // Add test documents
      await musicSheetsCollection.add({
        MusicSheetKey.fileName: '1_Test_Sheet.pdf',
      });
      await musicSheetsCollection.add({
        MusicSheetKey.fileName: '2_Another_Sheet.pdf',
      });
      await musicSheetsCollection.add({
        MusicSheetKey.fileName: 'No_Number_Sheet.pdf',
      });

      // Mock auth check
      when(mockAuthUtils.checkUserAuth()).thenAnswer((_) => Future.value(mockUser));

      // Act
      await updateSequenceIds(
        authUtilsInstance: mockAuthUtils,
        firestoreInstance: fakeFirestore,
      );

      // Assert
      final docs = await musicSheetsCollection.get();
      expect(docs.docs.length, 3);

      expect((docs.docs[0].data() as Map<String, dynamic>)[MusicSheetKey.sequenceId], 1);
      expect((docs.docs[0].data() as Map<String, dynamic>)[MusicSheetKey.fileName], '1_Test_Sheet.pdf');

      expect((docs.docs[1].data() as Map<String, dynamic>)[MusicSheetKey.sequenceId], 2);
      expect((docs.docs[1].data() as Map<String, dynamic>)[MusicSheetKey.fileName], '2_Another_Sheet.pdf');

      expect((docs.docs[2].data() as Map<String, dynamic>)[MusicSheetKey.sequenceId], 0);
      expect((docs.docs[2].data() as Map<String, dynamic>)[MusicSheetKey.fileName], 'No_Number_Sheet.pdf');
    });

    test('should skip documents that already have sequence_id', () async {
      // Arrange
      // Add test documents
      await musicSheetsCollection.add({
        MusicSheetKey.fileName: '1_Test_Sheet.pdf',
        MusicSheetKey.sequenceId: 999, // Existing sequence_id
      });
      await musicSheetsCollection.add({
        MusicSheetKey.fileName: '2_Another_Sheet.pdf',
      });

      // Mock auth check
      when(mockAuthUtils.checkUserAuth()).thenAnswer((_) => Future.value(mockUser));

      // Act
      await updateSequenceIds(
        authUtilsInstance: mockAuthUtils,
        firestoreInstance: fakeFirestore,
      );

      // Assert
      final docs = await musicSheetsCollection.get();
      expect(docs.docs.length, 2);

      expect((docs.docs[0].data() as Map<String, dynamic>)[MusicSheetKey.sequenceId], 999);
      expect((docs.docs[0].data() as Map<String, dynamic>)[MusicSheetKey.fileName], '1_Test_Sheet.pdf');

      expect((docs.docs[1].data() as Map<String, dynamic>)[MusicSheetKey.sequenceId], 2);
      expect((docs.docs[1].data() as Map<String, dynamic>)[MusicSheetKey.fileName], '2_Another_Sheet.pdf');
    });

    test('should throw exception when user is not authenticated', () async {
      // Arrange
      when(mockAuthUtils.checkUserAuth()).thenAnswer((_) => Future.value(null));

      // Act & Assert
      expect(
        () => updateSequenceIds(
          authUtilsInstance: mockAuthUtils,
          firestoreInstance: fakeFirestore,
        ),
        throwsException,
      );
    });

    test('should handle empty collection', () async {
      // Arrange
      // Mock auth check
      when(mockAuthUtils.checkUserAuth()).thenAnswer((_) => Future.value(mockUser));

      // Act
      await updateSequenceIds(
        authUtilsInstance: mockAuthUtils,
        firestoreInstance: fakeFirestore,
      );

      // Assert
      final docs = await musicSheetsCollection.get();
      expect(docs.docs.length, 0);
    });

    test('should handle invalid file names gracefully', () async {
      // Arrange
      // Add test documents with invalid file names
      await musicSheetsCollection.add({
        MusicSheetKey.fileName: 'Invalid_Sheet.pdf',
      });
      await musicSheetsCollection.add({
        MusicSheetKey.fileName: '123_Valid_Sheet.pdf',
      });

      // Mock auth check
      when(mockAuthUtils.checkUserAuth()).thenAnswer((_) => Future.value(mockUser));

      // Act
      await updateSequenceIds(
        authUtilsInstance: mockAuthUtils,
        firestoreInstance: fakeFirestore,
      );

      // Assert
      final docs = await musicSheetsCollection.get();
      expect(docs.docs.length, 2);

      expect((docs.docs[0].data() as Map<String, dynamic>)[MusicSheetKey.sequenceId], 0);
      expect((docs.docs[0].data() as Map<String, dynamic>)[MusicSheetKey.fileName], 'Invalid_Sheet.pdf');

      expect((docs.docs[1].data() as Map<String, dynamic>)[MusicSheetKey.sequenceId], 123);
      expect((docs.docs[1].data() as Map<String, dynamic>)[MusicSheetKey.fileName], '123_Valid_Sheet.pdf');
    });
  });
}
