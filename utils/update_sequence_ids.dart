import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:organista/logger/custom_logger.dart';
import 'package:organista/models/firebase_collection_name.dart';
import 'package:organista/models/music_sheets/music_sheet_key.dart';
import 'package:organista/repositories/firebase_firestore_repository.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:organista/firebase_options.dart';
import 'package:organista/dialogs/error_dialog.dart';

import 'auth_utils.dart';

// Used only once on 6.5.2025 to add sequence_id for all music sheets

final firebaseFirestoreRepository = FirebaseFirestoreRepository();
final firestore = FirebaseFirestore.instance;

Future<void> updateSequenceIds({
  AuthUtils? authUtilsInstance,
  FirebaseFirestore? firestoreInstance,
}) async {
  try {
    final auth = authUtilsInstance ?? authUtils;
    final user = await auth.checkUserAuth();
    if (user == null) {
      throw Exception('Authentication failed');
    }

    final fs = firestoreInstance ?? firestore;

    // Get all repositories
    final repositoriesSnapshot = await fs.collection(FirebaseCollectionName.repositories).get();
    logger.i('Found ${repositoriesSnapshot.docs.length} repositories to process');

    for (var repoDoc in repositoriesSnapshot.docs) {
      final repositoryId = repoDoc.id;
      logger.i('Processing repository: $repositoryId');

      // Get all music sheets in this repository
      final musicSheetsSnapshot = await fs.collection(FirebaseCollectionName.repositories).doc(repositoryId).collection(FirebaseCollectionName.musicSheets).get();

      logger.i('Found ${musicSheetsSnapshot.docs.length} music sheets in repository $repositoryId');

      for (var doc in musicSheetsSnapshot.docs) {
        try {
          final data = doc.data();

          // Skip if sequence_id already exists
          if (data.containsKey(MusicSheetKey.sequenceId)) {
            logger.i('Skipping document ${doc.id} as it already has a sequence_id');
            continue;
          }

          final fileName = data[MusicSheetKey.fileName] as String;

          // Extract sequence ID from file name
          int sequenceId = 0;
          final match = RegExp(r'^(\d+)').firstMatch(fileName);
          if (match != null) {
            sequenceId = int.parse(match.group(1)!);
          }

          // Update the document with sequence_id
          await doc.reference.update({
            MusicSheetKey.sequenceId: sequenceId,
          });

          logger.i('Updated document ${doc.id} with sequence_id: $sequenceId');
        } catch (e) {
          logger.e('Error updating document ${doc.id}', error: e);
        }
      }

      logger.i('Completed processing repository: $repositoryId');
    }

    logger.i('Sequence ID update completed successfully for all repositories');
  } catch (e) {
    logger.e('Error updating sequence IDs', error: e);
    rethrow;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const _SequenceUpdaterScreen(),
    );
  }
}

class _SequenceUpdaterScreen extends StatefulWidget {
  const _SequenceUpdaterScreen();

  @override
  State<_SequenceUpdaterScreen> createState() => _SequenceUpdaterScreenState();
}

class _SequenceUpdaterScreenState extends State<_SequenceUpdaterScreen> {
  bool isUpdating = false;
  String status = '';

  Future<void> _startUpdate() async {
    setState(() {
      isUpdating = true;
      status = 'Starting sequence update...';
    });

    try {
      await updateSequenceIds();
      if (mounted) {
        setState(() {
          status = 'Sequence update completed successfully!';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sequence update completed successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          status = 'Sequence update failed: ${e.toString()}';
        });
        showErrorDialog(
          context,
          'Sequence update failed: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isUpdating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sequence Updater'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              status,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isUpdating ? null : _startUpdate,
              child: Text(isUpdating ? 'Updating...' : 'Start Update'),
            ),
          ],
        ),
      ),
    );
  }
}
