import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:organista/dialogs/error_dialog.dart';
import 'package:organista/logger/custom_logger.dart';
import 'package:organista/main.dart';
import 'package:organista/models/internal/music_sheet_file.dart';
import 'package:organista/repositories/firebase_firestore_repository.dart';
import 'package:organista/repositories/firebase_storage_repository.dart';
import 'package:organista/models/repositories/repository.dart';
import 'package:organista/services/auth/auth_user.dart';

import 'auth_utils.dart';

final firebaseFirestoreRepository = FirebaseFirestoreRepository();
final firebaseStorageRepository = FirebaseStorageRepository();

void main() async {
  await mainInitialize();
  runApp(const PublicMusicSheetsUploader());
}

class PublicMusicSheetsUploader extends StatelessWidget {
  const PublicMusicSheetsUploader({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: UploadFolderScreen(),
    );
  }
}

class UploadFolderScreen extends HookWidget {
  const UploadFolderScreen({super.key});

  String _mapFileName(String originalFileName, Map<String, String> mapping) {
    String fileNameWithoutExt = originalFileName.trim().replaceAll(RegExp(r'\.(pdf|jpg|png)$'), '');
    String fileNameToUse = fileNameWithoutExt;

    // Case 1: Exact match - file name equals a key in the mapping
    if (mapping.containsKey(fileNameWithoutExt)) {
      fileNameToUse = mapping[fileNameWithoutExt]!;
    }
    // Case 2: Partial match - file name starts with a key in the mapping
    else {
      List<String> matchingKeys = mapping.keys.where((key) => fileNameWithoutExt.startsWith(key)).toList();

      if (matchingKeys.isNotEmpty) {
        // Sort by length to get the longest matching key
        matchingKeys.sort((a, b) => b.length.compareTo(a.length));
        String baseName = mapping[matchingKeys.first]!;
        // It makes sense to ignore it here, because it is straightforward and not a security issue.
        // ignore: avoid-substring
        String remainingName = fileNameWithoutExt.substring(matchingKeys.first.length).trim();
        remainingName = remainingName.replaceAll('__', '');

        fileNameToUse = remainingName.isEmpty ? baseName : "$baseName $remainingName";
      }
      // Case 3: No match - use original filename without extension
      else {
        fileNameToUse = fileNameWithoutExt;
      }
    }

    return fileNameToUse;
  }

  @override
  Widget build(BuildContext context) {
    final isUploading = useState(false);
    final uploadedFiles = useState<List<String>>([]);
    final repositories = useState<List<Repository>>([]);
    final selectedRepository = useState<Repository?>(null);
    final authenticatedUser = useState<AuthUser?>(null);
    final filenameMapping = useState<Map<String, String>>({});
    final newRepositoryNameController = useTextEditingController();

    // Initialize repositories
    useEffect(() {
      loadRepositories(
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
        if (context.mounted) {
          showErrorDialog(context: context, text: "Repository name cannot be empty");
        }
        return;
      }

      if (authenticatedUser.value == null) {
        authenticatedUser.value = await authUtils.checkUserAuth();
        if (authenticatedUser.value == null) {
          if (context.mounted) {
            showErrorDialog(context: context, text: "Authentication failed. Please restart the app.");
          }
          return;
        }
      }

      try {
        await firebaseFirestoreRepository.createGlobalRepository(
          name: newRepositoryNameController.text.trim(),
        );

        if (context.mounted) {
          showErrorDialog(context: context, text: "Repository created successfully");
        }

        newRepositoryNameController.clear();
      } catch (e) {
        logger.e("Error creating repository", error: e);
        if (context.mounted) {
          showErrorDialog(context: context, text: "Failed to create repository: ${e.toString()}");
        }
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
        if (context.mounted) {
          showErrorDialog(context: context, text: "Please select a repository first");
        }
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
        authenticatedUser.value = await authUtils.checkUserAuth();
        if (authenticatedUser.value == null) {
          isUploading.value = false;
          if (context.mounted) {
            showErrorDialog(context: context, text: "Authentication failed. Please restart the app.");
          }
          return;
        }
      }

      for (var file in result.files) {
        try {
          if (file.bytes == null) continue;

          MusicSheetFile musicSheetFile = MusicSheetFile.fromPlatformFile(file);
          String fileNameToUse = _mapFileName(file.name, filenameMapping.value);

          logger.i(
            filenameMapping.value.isEmpty
                ? "Using original filename: $fileNameToUse"
                : "Using mapped filename: $fileNameToUse, original file name was ${file.name}",
          );

          final reference = await firebaseStorageRepository.uploadFile(
            file: musicSheetFile,
            bucket: 'public/${selectedRepository.value!.name}',
          );

          if (reference != null) {
            final uploadSucceeded = await firebaseFirestoreRepository.uploadMusicSheetRecord(
              reference: reference,
              userId: '',
              fileName: fileNameToUse,
              mediaType: musicSheetFile.mediaType,
              repositoryId: selectedRepository.value!.repositoryId,
            );
            logger.i('Manual upload of recording succeeded? - $uploadSucceeded');
          } else {
            throw Exception('Failed to upload image, not uploading MusicSheet record to Firestore');
          }

          uploadedFiles.value = [...uploadedFiles.value, fileNameToUse];
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
          Text(
            filenameMapping.value.isNotEmpty
                ? "JSON Loaded: ${filenameMapping.value.length} mappings - Only mapped files will be uploaded"
                : "No JSON file selected - all files will be uploaded with original filenames",
          ),
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

Future<void> loadRepositories(
  ValueNotifier<AuthUser?> authenticatedUser,
  ValueNotifier<List<Repository>> repositories,
  ValueNotifier<Repository?> selectedRepository,
) async {
  try {
    authenticatedUser.value = await authUtils.checkUserAuth();
    if (authenticatedUser.value != null) {
      final repoStream = firebaseFirestoreRepository.getRepositoriesStream(userId: authenticatedUser.value!.id);
      repoStream.listen((repos) {
        final publicRepos = repos.where((repo) => repo.userId.isEmpty).toList();
        repositories.value = publicRepos;
        if (publicRepos.isNotEmpty && selectedRepository.value == null) {
          selectedRepository.value = publicRepos.first;
        }
      });
    }
  } catch (e) {
    logger.e("Error loading repositories", error: e);
  }
}
