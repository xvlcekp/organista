import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:organista/firebase_options.dart';
import 'package:organista/logger/custom_logger.dart';
import 'package:organista/models/music_sheets/media_type.dart';
import 'package:organista/repositories/firebase_auth_repository.dart';
import 'package:organista/repositories/firebase_firestore_repository.dart';
import 'package:organista/repositories/firebase_storage_repository.dart';
import 'package:organista/config/config_controller.dart';
import 'package:organista/models/repositories/repository.dart';

final firebaseAuthRepository = FirebaseAuthRepository();
final firebaseFirestoreRepository = FirebaseFirestoreRepository();
final firebaseStorageRepository = FirebaseStorageRepository();

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
      home: const UploadFolderScreen(),
    );
  }
}

class UploadFolderScreen extends HookWidget {
  const UploadFolderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isUploading = useState(false);
    final uploadedFiles = useState<List<String>>([]);
    final repositories = useState<List<Repository>>([]);
    final selectedRepository = useState<Repository?>(null);
    final authenticatedUser = useState<User?>(null);
    final filenameMapping = useState<Map<String, String>>({});
    final newRepositoryNameController = useTextEditingController();

    // Initialize repositories
    useEffect(() {
      loadRepositories(
        context,
        authenticatedUser,
        repositories,
        selectedRepository,
      );
      return null;
    }, []);

    // Cleanup controller
    useEffect(() {
      return () => newRepositoryNameController.dispose();
    }, []);

    Future<void> createNewRepository() async {
      if (newRepositoryNameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Repository name cannot be empty")),
        );
        return;
      }

      if (authenticatedUser.value == null) {
        authenticatedUser.value = await checkUserAuth();
        if (authenticatedUser.value == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Authentication failed. Please restart the app.")),
          );
          return;
        }
      }

      try {
        await firebaseFirestoreRepository.createGlobalRepository(
          name: newRepositoryNameController.text.trim(),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Repository created successfully")),
        );

        newRepositoryNameController.clear();
      } catch (e) {
        logger.e("Error creating repository", error: e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to create repository: ${e.toString()}")),
        );
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

          filenameMapping.value = jsonData.map((key, value) => MapEntry(key, value.toString()));
          logger.i("JSON Mapping Loaded: ${filenameMapping.value}");
        } catch (e) {
          logger.e("Error reading JSON file", error: e);
        }
      } else {
        logger.i("No JSON file selected.");
      }
    }

    Future<void> uploadFolder() async {
      if (selectedRepository.value == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select a repository first")),
        );
        return;
      }

      isUploading.value = true;
      uploadedFiles.value = [];

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
        withData: true,
      );

      if (result == null) {
        logger.i("No files selected.");
        isUploading.value = false;
        return;
      }

      if (authenticatedUser.value == null) {
        logger.i("User authentication expired, attempting to re-authenticate");
        authenticatedUser.value = await checkUserAuth();
        if (authenticatedUser.value == null) {
          isUploading.value = false;
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Authentication failed. Please restart the app.")),
            );
          }
          return;
        }
      }

      for (var file in result.files) {
        try {
          if (file.bytes == null) continue;

          if (filenameMapping.value.isNotEmpty && !filenameMapping.value.containsKey(file.name)) {
            logger.i("filenameMapping is not empty, these files are in the mapping: ${filenameMapping.value.keys}");
            logger.i("${file.name} not found in the files mapping, skipping this file!");
            continue;
          }

          String fileNameToUse = filenameMapping.value.isEmpty ? file.name : filenameMapping.value[file.name]!;

          logger.i(filenameMapping.value.isEmpty ? "Using original filename: $fileNameToUse" : "Using mapped filename: $fileNameToUse, original file name was ${file.name}");

          final reference = await firebaseStorageRepository.uploadFile(
            file: file,
            bucket: 'public/${selectedRepository.value!.name}',
          );

          if (reference != null) {
            final uploadSucceeded = await firebaseFirestoreRepository.uploadMusicSheetRecord(
              reference: reference,
              userId: '',
              fileName: fileNameToUse,
              mediaType: MediaType.fromPath(file.name),
              repositoryId: selectedRepository.value!.repositoryId,
            );
            logger.i('Manual upload of recording succeeded? - $uploadSucceeded');
          } else {
            throw Exception('Failed to upload image, not uploading MusicSheet record to Firestore');
          }

          uploadedFiles.value = [...uploadedFiles.value, file.name];
        } catch (e) {
          logger.e("Error uploading ${file.name}", error: e);
        }
      }

      isUploading.value = false;

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Upload completed!")),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Upload Folder with JSON Mapping")),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: DropdownButtonFormField<Repository>(
              decoration: const InputDecoration(
                labelText: 'Select Repository',
                border: OutlineInputBorder(),
              ),
              value: selectedRepository.value,
              items: repositories.value.map((Repository repository) {
                return DropdownMenuItem<Repository>(
                  value: repository,
                  child: Text(repository.name),
                );
              }).toList(),
              onChanged: (Repository? newValue) {
                selectedRepository.value = newValue;
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: newRepositoryNameController,
                    decoration: const InputDecoration(
                      labelText: 'New Repository Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: createNewRepository,
                  child: const Text("Create Repository"),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: pickJsonFile,
            child: const Text("Pick JSON Mapping File (Optional)"),
          ),
          const SizedBox(height: 10),
          Text(filenameMapping.value.isNotEmpty
              ? "JSON Loaded: ${filenameMapping.value.length} mappings - Only mapped files will be uploaded"
              : "No JSON file selected - all files will be uploaded with original filenames"),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: isUploading.value || selectedRepository.value == null ? null : uploadFolder,
            child: Text(isUploading.value ? "Uploading..." : "Pick & Upload Files"),
          ),
          const SizedBox(height: 20),
          if (uploadedFiles.value.isNotEmpty) ...[
            const Text("Uploaded Files:", style: TextStyle(fontWeight: FontWeight.bold)),
            Expanded(
              child: SizedBox(
                height: 300,
                child: Scrollbar(
                  thumbVisibility: true,
                  child: ListView.builder(
                    itemCount: uploadedFiles.value.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 8.0),
                        child: SelectableText(
                          uploadedFiles.value[index],
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

Future<void> loadRepositories(
  BuildContext context,
  ValueNotifier<User?> authenticatedUser,
  ValueNotifier<List<Repository>> repositories,
  ValueNotifier<Repository?> selectedRepository,
) async {
  try {
    authenticatedUser.value = await checkUserAuth();
    if (authenticatedUser.value != null) {
      final repoStream = firebaseFirestoreRepository.getRepositoriesStream();
      repoStream.listen((repos) {
        repositories.value = repos.toList();
        if (repos.isNotEmpty && selectedRepository.value == null) {
          selectedRepository.value = repos.first;
        }
      });
    }
  } catch (e) {
    logger.e("Error loading repositories", error: e);
  }
}
