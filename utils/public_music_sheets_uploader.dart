import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:organista/firebase_options.dart';
import 'package:organista/logger/custom_logger.dart';
import 'package:organista/models/music_sheets/media_type.dart';
import 'package:organista/repositories/firebase_auth_repository.dart';
import 'package:organista/repositories/firebase_firestore_repository.dart';
import 'package:organista/repositories/firebase_storage_repository.dart';
import 'package:organista/config/config_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: _UploadFolderScreen(),
    );
  }
}

class _UploadFolderScreen extends StatefulWidget {
  const _UploadFolderScreen();

  @override
  _UploadFolderScreenState createState() => _UploadFolderScreenState();
}

class _UploadFolderScreenState extends State<_UploadFolderScreen> {
  bool isUploading = false;
  List<String> uploadedFiles = [];

  final FirebaseAuthRepository firebaseAuthRepository = FirebaseAuthRepository();
  final FirebaseFirestoreRepository firebaseFirestoreRepository = FirebaseFirestoreRepository();
  final FirebaseStorageRepository firebaseStorageRepository = FirebaseStorageRepository();

  Map<String, String> filenameMapping = {}; // Stores JSON filename mappings

  Future<void> pickJsonFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null && result.files.isNotEmpty) {
      try {
        String jsonString = utf8.decode(result.files.single.bytes!);
        Map<String, dynamic> jsonData = jsonDecode(jsonString);

        // Convert JSON data to Map<String, String>
        setState(() {
          filenameMapping = jsonData.map((key, value) => MapEntry(key, value.toString()));
        });

        logger.i("JSON Mapping Loaded: $filenameMapping");
      } catch (e) {
        logger.e("Error reading JSON file", error: e);
      }
    } else {
      logger.i("No JSON file selected.");
    }
  }

  Future<User?> checkUserAuth() async {
    await Config.load();

    final emailUploaderUser = Config.get('emailUploaderUser') ?? '';
    final passwordUploaderUser = Config.get('passwordUploaderUser') ?? '';
    logger.i(emailUploaderUser);

    await firebaseAuthRepository.signInWithEmailAndPassword(
      email: emailUploaderUser,
      password: passwordUploaderUser,
    );
    final User? user = firebaseAuthRepository.getCurrentUser();

    if (user == null) {
      logger.e("User is NOT authenticated.");
      return null;
    }
    logger.i("User is authenticated: ${user.uid}");
    return user;
  }

  Future<void> uploadFolder() async {
    setState(() {
      isUploading = true;
      uploadedFiles.clear();
    });

    // Pick multiple files from folder
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.any, // Accept all file types
      withData: true, // Loads file as Uint8List for Web
    );

    if (result == null) {
      logger.i("No files selected.");
      setState(() {
        isUploading = false;
      });
      return;
    }

    for (var file in result.files) {
      try {
        if (file.bytes == null) continue; // Skip if file is empty

        final user = await checkUserAuth();

        if (user != null) {
          // Get the new filename from the mapping, if it exists
          if (!filenameMapping.containsKey(file.name)) {
            logger.i("${file.name} not found in the files mapping, skipping this file!");
            continue; // Skip if no mapping found
          }
          String fileNameFromConfig = filenameMapping[file.name]!;
          logger.i("New filename is $fileNameFromConfig, original file name was ${file.name}");

          final reference = await firebaseStorageRepository.uploadFile(
            file: file,
            bucket: 'public/JKS',
          );
          if (reference != null) {
            final uploadSucceeded = await firebaseFirestoreRepository.uploadMusicSheetRecord(
              reference: reference,
              userId: '',
              fileName: fileNameFromConfig,
              mediaType: MediaType.fromPath(file.name),
            );
            logger.i('Manual upload of recording succeeded? - $uploadSucceeded');
          } else {
            throw Exception('Failed to upload image, not uploading MusicSheet record to Firestore');
          }
        }

        setState(() {
          uploadedFiles.add(file.name);
        });
      } catch (e) {
        logger.e("Error uploading ${file.name}", error: e);
      }
    }

    setState(() {
      isUploading = false;
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload completed!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Upload Folder with JSON Mapping")),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: pickJsonFile,
            child: Text("Pick JSON Mapping File"),
          ),
          SizedBox(height: 10),
          Text(filenameMapping.isNotEmpty ? "JSON Loaded: ${filenameMapping.length} mappings" : "No JSON file selected"),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: isUploading ? null : uploadFolder,
            child: Text(isUploading ? "Uploading..." : "Pick & Upload Files"),
          ),
          SizedBox(height: 20),
          if (uploadedFiles.isNotEmpty) ...[
            Text("Uploaded Files:", style: TextStyle(fontWeight: FontWeight.bold)),
            Expanded(
              child: SizedBox(
                height: 300, // Set a fixed height to prevent overflow
                child: Scrollbar(
                  thumbVisibility: true, // Ensures the scrollbar is always visible
                  child: ListView.builder(
                    itemCount: uploadedFiles.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 8.0),
                        child: SelectableText(
                          uploadedFiles[index],
                          style: TextStyle(color: Colors.blue),
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
