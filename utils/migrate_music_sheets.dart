import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:organista/dialogs/error_dialog.dart';
import 'package:organista/logger/custom_logger.dart';
import 'package:organista/main.dart';
import 'package:organista/models/firebase_collection_name.dart';
import 'package:organista/models/repositories/repository_payload.dart';
import 'package:organista/models/repositories/repository_key.dart';

import 'auth_utils.dart';

void main() async {
  await mainInitialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const _MigrationScreen(),
    );
  }
}

class _MigrationScreen extends StatefulWidget {
  const _MigrationScreen();

  @override
  _MigrationScreenState createState() => _MigrationScreenState();
}

class _MigrationScreenState extends State<_MigrationScreen> {
  bool isMigrating = false;
  List<String> migratedDocs = [];
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<void> migrateMusicSheets() async {
    setState(() {
      isMigrating = true;
      migratedDocs.clear();
    });

    try {
      final user = await authUtils.checkUserAuth();
      if (user == null) {
        throw Exception('Authentication failed');
      }

      // Create a new repository document with auto-generated ID using the Repository model
      final repoDocRef = firestore.collection(FirebaseCollectionName.repositories).doc();
      final repositoryPayload = RepositoryPayload(
        name: 'Main Repository',
        userId: user.id,
      );
      await repoDocRef.set(repositoryPayload);

      // Get all documents from musicSheets collection
      final QuerySnapshot musicSheetsSnapshot = await firestore.collection(FirebaseCollectionName.musicSheets).get();

      // Copy each document to the new structure
      for (var doc in musicSheetsSnapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;

          // Create a new document in the subcollection with the same ID
          await repoDocRef.collection(RepositoryKey.musicSheets).doc(doc.id).set(data);

          setState(() {
            migratedDocs.add(doc.id);
          });
          logger.i('Migrated document: ${doc.id}');
        } catch (e) {
          logger.e('Error migrating document ${doc.id}', error: e);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Migration completed! ${migratedDocs.length} documents migrated')),
        );
      }
    } catch (e) {
      logger.e('Migration failed', error: e);
      if (mounted) {
        showErrorDialog(context, 'Migration failed: ${e.toString()}');
      }
    } finally {
      setState(() {
        isMigrating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text("Music Sheets Migration Tool")),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            style: theme.elevatedButtonTheme.style,
            onPressed: isMigrating ? null : migrateMusicSheets,
            child: Text(isMigrating ? "Migration in progress..." : "Start Migration"),
          ),
          const SizedBox(height: 20),
          if (migratedDocs.isNotEmpty) ...[
            Text("Migrated Documents:", style: const TextStyle(fontWeight: FontWeight.bold)),
            Expanded(
              child: SizedBox(
                height: 300,
                child: Scrollbar(
                  thumbVisibility: true,
                  child: ListView.builder(
                    itemCount: migratedDocs.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 8.0),
                        child: SelectableText(
                          migratedDocs[index],
                          style: const TextStyle(color: Colors.blue),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
