import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:organista/models/repositories/repository.dart';
import 'package:organista/models/repositories/repository_key.dart';

void main() {
  group('Repository Model Tests', () {
    final testTimestamp = Timestamp.fromDate(DateTime(2024, 1, 15, 10, 30));

    final sampleRepositoryJson = {
      RepositoryKey.repositoryId: 'repo-123',
      RepositoryKey.userId: 'user-123',
      RepositoryKey.createdAt: testTimestamp,
      RepositoryKey.name: 'My Music Collection',
    };

    test('should create Repository from valid JSON', () {
      final repository = Repository(json: sampleRepositoryJson);

      expect(repository.repositoryId, 'repo-123');
      expect(repository.userId, 'user-123');
      expect(repository.createdAt, DateTime(2024, 1, 15, 10, 30));
      expect(repository.name, 'My Music Collection');
    });

    test('should create Repository with default values for missing fields', () {
      final minimalJson = {
        RepositoryKey.createdAt: testTimestamp,
        RepositoryKey.repositoryId: 'firebase-generated-id',
      };
      final repository = Repository(json: minimalJson);

      expect(repository.repositoryId, isNotEmpty); // Generated UUID
      expect(repository.userId, '');
      expect(repository.name, '');
    });

    test('should determine privacy based on userId', () {
      final privateRepositoryJson = {
        ...sampleRepositoryJson,
        RepositoryKey.userId: 'user-123',
      };

      final publicRepositoryJson = {
        ...sampleRepositoryJson,
        RepositoryKey.userId: '',
      };

      final privateRepo = Repository(json: privateRepositoryJson);
      final publicRepo = Repository(json: publicRepositoryJson);

      expect(privateRepo.isPrivate, true);
      expect(publicRepo.isPrivate, false);
    });

    test('should support equality comparison', () {
      final repository1 = Repository(json: sampleRepositoryJson);
      final repository2 = Repository(json: sampleRepositoryJson);
      final differentRepository = Repository(
        json: {
          ...sampleRepositoryJson,
          RepositoryKey.name: 'Different Name',
        },
      );

      expect(repository1, equals(repository2));
      expect(repository1, isNot(equals(differentRepository)));
    });

    test('should handle empty name', () {
      final jsonWithEmptyName = {
        ...sampleRepositoryJson,
        RepositoryKey.name: '',
      };

      final repository = Repository(json: jsonWithEmptyName);

      expect(repository.name, '');
    });

    test('should handle special characters in name', () {
      final jsonWithSpecialChars = {
        ...sampleRepositoryJson,
        RepositoryKey.name: 'Organová hudba - košická diecéza',
      };

      final repository = Repository(json: jsonWithSpecialChars);

      expect(repository.name, 'Organová hudba - košická diecéza');
    });

    test('should create copyWith correctly', () {
      final repository = Repository(json: sampleRepositoryJson);
      final copiedRepository = repository.copyWith(name: 'New Name');

      expect(copiedRepository.name, 'New Name');
      expect(copiedRepository.repositoryId, repository.repositoryId);
      expect(copiedRepository.userId, repository.userId);
      expect(copiedRepository.createdAt, repository.createdAt);
    });

    test('should convert to JSON correctly', () {
      final repository = Repository(json: sampleRepositoryJson);
      final json = repository.toJson();

      expect(json[RepositoryKey.repositoryId], 'repo-123');
      expect(json[RepositoryKey.userId], 'user-123');
      expect(json[RepositoryKey.name], 'My Music Collection');
      expect(json[RepositoryKey.createdAt], testTimestamp);
    });
  });
}
