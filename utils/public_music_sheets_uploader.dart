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
import 'package:organista/models/repositories/repository.dart';

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
  List<Repository> repositories = [];
  Repository? selectedRepository;
  User? authenticatedUser;

  final FirebaseAuthRepository firebaseAuthRepository = FirebaseAuthRepository();
  final FirebaseFirestoreRepository firebaseFirestoreRepository = FirebaseFirestoreRepository();
  final FirebaseStorageRepository firebaseStorageRepository = FirebaseStorageRepository();

  Map<String, String> filenameMapping = {}; // Stores JSON filename mappings

  @override
  void initState() {
    super.initState();
    loadRepositories();
  }

  Future<void> loadRepositories() async {
    try {
      authenticatedUser = await checkUserAuth();
      if (authenticatedUser != null) {
        final repoStream = firebaseFirestoreRepository.getRepositoriesStream();
        repoStream.listen((repos) {
          setState(() {
            repositories = repos.toList();
            if (repos.isNotEmpty && selectedRepository == null) {
              selectedRepository = repos.first;
            }
          });
        });
      }
    } catch (e) {
      logger.e("Error loading repositories", error: e);
    }
  }

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

  Future<void> uploadFolder(BuildContext context) async {
    if (selectedRepository == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select a repository first")),
      );
      return;
    }

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

    // Check if user is still authenticated
    if (authenticatedUser == null) {
      logger.i("User authentication expired, attempting to re-authenticate");
      authenticatedUser = await checkUserAuth();
      if (authenticatedUser == null) {
        setState(() {
          isUploading = false;
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Authentication failed. Please restart the app.")),
          );
        }
        return;
      }
    }

    for (var file in result.files) {
      try {
        if (file.bytes == null) continue; // Skip if file is empty

        // If JSON mapping is selected, only upload files included in the mapping
        if (filenameMapping.isNotEmpty && !filenameMapping.containsKey(file.name)) {
          logger.i("filenameMapping is not empty, these files are in the mapping: ${filenameMapping.keys}");
          logger.i("${file.name} not found in the files mapping, skipping this file!");
          continue; // Skip if mapping exists but file not found in mapping
        }

        // Determine the filename to use
        String fileNameToUse;

        if (filenameMapping.isEmpty) {
          // If no JSON mapping file is selected, use the original filename
          fileNameToUse = file.name;
          logger.i("Using original filename: $fileNameToUse");
        } else {
          // Use the mapped filename from the JSON
          fileNameToUse = filenameMapping[file.name]!;
          logger.i("Using mapped filename: $fileNameToUse, original file name was ${file.name}");
        }

        final reference = await firebaseStorageRepository.uploadFile(
          file: file,
          bucket: 'public/${selectedRepository!.name}',
        );
        if (reference != null) {
          final uploadSucceeded = await firebaseFirestoreRepository.uploadMusicSheetRecord(
            reference: reference,
            userId: '',
            fileName: fileNameToUse,
            mediaType: MediaType.fromPath(file.name),
            repositoryId: selectedRepository!.repositoryId,
          );
          logger.i('Manual upload of recording succeeded? - $uploadSucceeded');
        } else {
          throw Exception('Failed to upload image, not uploading MusicSheet record to Firestore');
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
          // Repository dropdown
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: DropdownButtonFormField<Repository>(
              decoration: InputDecoration(
                labelText: 'Select Repository',
                border: OutlineInputBorder(),
              ),
              value: selectedRepository,
              items: repositories.map((Repository repository) {
                return DropdownMenuItem<Repository>(
                  value: repository,
                  child: Text(repository.name),
                );
              }).toList(),
              onChanged: (Repository? newValue) {
                setState(() {
                  selectedRepository = newValue;
                });
              },
            ),
          ),
          ElevatedButton(
            onPressed: pickJsonFile,
            child: Text("Pick JSON Mapping File (Optional)"),
          ),
          SizedBox(height: 10),
          Text(filenameMapping.isNotEmpty
              ? "JSON Loaded: ${filenameMapping.length} mappings - Only mapped files will be uploaded"
              : "No JSON file selected - all files will be uploaded with original filenames"),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: isUploading || selectedRepository == null ? null : () => uploadFolder(context),
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
