import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:organista/models/internal/music_sheet_file.dart';
import 'package:organista/models/music_sheets/media_type.dart';
import 'package:organista/repositories/firebase_storage_repository.dart';

// Mock classes
class MockFirebaseStorage extends Mock implements FirebaseStorage {}

class MockReference extends Mock implements Reference {}

class MockListResult extends Mock implements ListResult {}

class MockTaskSnapshot extends Mock implements TaskSnapshot {}

class MockSettableMetadata extends Mock implements SettableMetadata {}

// Fake UploadTask that completes immediately
class FakeUploadTask extends Fake implements UploadTask {
  final TaskSnapshot _snapshot;

  FakeUploadTask(this._snapshot);

  @override
  Future<S> then<S>(FutureOr<S> Function(TaskSnapshot) onValue, {Function? onError}) async {
    return onValue(_snapshot) as S;
  }
}

void main() {
  late MockFirebaseStorage mockStorage;
  late FirebaseStorageRepository repository;

  setUp(() {
    mockStorage = MockFirebaseStorage();
    repository = FirebaseStorageRepository(storage: mockStorage);
    registerFallbackValue(SettableMetadata());
    registerFallbackValue(Uint8List(0));
  });

  group('FirebaseStorageRepository', () {
    group('listFolderContents', () {
      test('should call listAll on the correct reference', () async {
        const path = 'folder/path';
        final mockRef = MockReference();
        final mockListResult = MockListResult();

        when(() => mockStorage.ref(path)).thenReturn(mockRef);
        when(() => mockRef.listAll()).thenAnswer((_) async => mockListResult);

        final result = await repository.listFolderContents(path);

        expect(result, mockListResult);
        verify(() => mockStorage.ref(path)).called(1);
        verify(() => mockRef.listAll()).called(1);
      });
    });

    group('deleteFolder', () {
      test('should delete all files and subfolders recursively', () async {
        const path = 'folder/path';
        final mockRootRef = MockReference();
        final mockFileRef1 = MockReference();
        final mockFileRef2 = MockReference();
        final mockSubfolderRef = MockReference();
        final mockSubfolderContentRef = MockReference();

        // Root folder contents
        final mockRootListResult = MockListResult();
        when(() => mockRootListResult.items).thenReturn([mockFileRef1, mockFileRef2]);
        when(() => mockRootListResult.prefixes).thenReturn([mockSubfolderRef]);

        // Subfolder contents
        final mockSubfolderListResult = MockListResult();
        when(() => mockSubfolderListResult.items).thenReturn([mockSubfolderContentRef]);
        when(() => mockSubfolderListResult.prefixes).thenReturn([]);

        // Setup mock calls
        when(() => mockStorage.ref(path)).thenReturn(mockRootRef);
        when(() => mockRootRef.listAll()).thenAnswer((_) async => mockRootListResult);

        when(() => mockSubfolderRef.fullPath).thenReturn('$path/subfolder');
        when(() => mockStorage.ref('$path/subfolder')).thenReturn(mockSubfolderRef);
        when(() => mockSubfolderRef.listAll()).thenAnswer((_) async => mockSubfolderListResult);

        // Deletion mocks
        when(() => mockFileRef1.delete()).thenAnswer((_) async {});
        when(() => mockFileRef2.delete()).thenAnswer((_) async {});
        when(() => mockSubfolderContentRef.delete()).thenAnswer((_) async {});

        // Mock fullPath for error logging
        when(() => mockFileRef1.fullPath).thenReturn('$path/file1');
        when(() => mockFileRef2.fullPath).thenReturn('$path/file2');
        when(() => mockSubfolderContentRef.fullPath).thenReturn('$path/subfolder/file');

        await repository.deleteFolder(path);

        // Verify root files deleted
        verify(() => mockFileRef1.delete()).called(1);
        verify(() => mockFileRef2.delete()).called(1);

        // Verify subfolder content deleted
        verify(() => mockSubfolderContentRef.delete()).called(1);

        // Verify recursive calls (implied by content deletion)
        verify(() => mockStorage.ref('$path/subfolder')).called(1);
        verify(() => mockSubfolderRef.listAll()).called(1);
      });

      test('should handle errors during file deletion gracefully', () async {
        const path = 'folder/path';
        final mockRootRef = MockReference();
        final mockFileRef = MockReference();
        final mockListResult = MockListResult();

        when(() => mockStorage.ref(path)).thenReturn(mockRootRef);
        when(() => mockRootRef.listAll()).thenAnswer((_) async => mockListResult);
        when(() => mockListResult.items).thenReturn([mockFileRef]);
        when(() => mockListResult.prefixes).thenReturn([]);

        when(() => mockFileRef.fullPath).thenReturn('$path/file');
        when(() => mockFileRef.delete()).thenThrow(Exception('Delete failed'));

        // Should not throw
        await repository.deleteFolder(path);

        verify(() => mockFileRef.delete()).called(1);
      });

      test('should handle errors during folder listing gracefully', () async {
        const path = 'folder/path';
        final mockRootRef = MockReference();

        when(() => mockStorage.ref(path)).thenReturn(mockRootRef);
        when(() => mockRootRef.listAll()).thenThrow(Exception('List failed'));

        // Should not throw
        await repository.deleteFolder(path);
      });
    });

    group('uploadFile', () {
      test('should upload file successfully and return reference', () async {
        const bucket = 'test-bucket';
        final bytes = Uint8List.fromList([1, 2, 3]);
        final file = MusicSheetFile(
          file: PlatformFile(
            name: 'test.pdf',
            size: 3,
            bytes: bytes,
          ),
          mediaType: MediaType.pdf,
        );

        final mockBucketRef = MockReference();
        final mockFileRef = MockReference();
        final mockTaskSnapshot = MockTaskSnapshot();
        final fakeUploadTask = FakeUploadTask(mockTaskSnapshot);

        when(() => mockStorage.ref(bucket)).thenReturn(mockBucketRef);
        // Mock child() call to return a reference with any UUID
        when(() => mockBucketRef.child(any())).thenReturn(mockFileRef);
        when(() => mockFileRef.fullPath).thenReturn('test-bucket/uuid');

        // putData returns the fake upload task which completes immediately
        when(() => mockFileRef.putData(any(), any())).thenAnswer((_) => fakeUploadTask);

        final result = await repository.uploadFile(
          file: file,
          bucket: bucket,
        );

        expect(result, mockFileRef);

        verify(
          () => mockFileRef.putData(
            bytes,
            any(that: isA<SettableMetadata>()),
          ),
        ).called(1);
      });

      test('should return null when file bytes are null', () async {
        const bucket = 'test-bucket';
        final file = MusicSheetFile(
          file: PlatformFile(
            name: 'test.pdf',
            size: 0,
            bytes: null,
          ),
          mediaType: MediaType.pdf,
        );

        final mockBucketRef = MockReference();
        final mockFileRef = MockReference();

        when(() => mockStorage.ref(bucket)).thenReturn(mockBucketRef);
        // We need to return a valid reference for child() call as implementation calls it first
        when(() => mockBucketRef.child(any())).thenReturn(mockFileRef);
        when(() => mockFileRef.fullPath).thenReturn('test-bucket/uuid');

        final result = await repository.uploadFile(
          file: file,
          bucket: bucket,
        );

        expect(result, isNull);
        verify(() => mockStorage.ref(bucket)).called(1);
      });

      test('should return null and log error when upload fails', () async {
        const bucket = 'test-bucket';
        final bytes = Uint8List.fromList([1, 2, 3]);
        final file = MusicSheetFile(
          file: PlatformFile(
            name: 'test.pdf',
            size: 3,
            bytes: bytes,
          ),
          mediaType: MediaType.pdf,
        );

        final mockBucketRef = MockReference();
        final mockFileRef = MockReference();

        when(() => mockStorage.ref(bucket)).thenReturn(mockBucketRef);
        when(() => mockBucketRef.child(any())).thenReturn(mockFileRef);

        // Mock putData to throw exception
        when(() => mockFileRef.putData(any(), any())).thenThrow(Exception('Upload failed'));

        final result = await repository.uploadFile(
          file: file,
          bucket: bucket,
        );

        expect(result, isNull);
      });
    });
  });
}
