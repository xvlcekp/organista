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
      home: UploadFolderScreen(),
    );
  }
}

class UploadFolderScreen extends StatefulWidget {
  const UploadFolderScreen({super.key});

  @override
  _UploadFolderScreenState createState() => _UploadFolderScreenState();
}

class _UploadFolderScreenState extends State<UploadFolderScreen> {
  final CustomLogger logger = CustomLogger.instance;
  bool isUploading = false;
  List<String> uploadedFiles = [];

  final FirebaseAuthRepository firebaseAuthRepository = FirebaseAuthRepository();
  final FirebaseFirestoreRepository firebaseFirestoreRepositary = FirebaseFirestoreRepository();
  final FirebaseStorageRepository firebaseStorageRepository = FirebaseStorageRepository();

  Future<User?> checkUserAuth() async {
    await Config.load();

    final emailUploaderUser = Config.get('emailUploaderUser') ?? 'defalutValue';
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
          final reference = await firebaseStorageRepository.uploadFile(
            file: file,
            userId: 'JKS',
          );
          if (reference != null) {
            final uploadSucceeded = await firebaseFirestoreRepositary.uploadMusicSheetRecord(
              reference: reference,
              userId: '',
              fileName: file.name,
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
      appBar: AppBar(title: Text("Upload Folder to Firebase")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: isUploading ? null : uploadFolder,
              child: Text(isUploading ? "Uploading..." : "Pick Upload a Folder"),
            ),
            SizedBox(height: 20),
            if (uploadedFiles.isNotEmpty) ...[
              Text("Uploaded Files:", style: TextStyle(fontWeight: FontWeight.bold)),
              ...uploadedFiles.map((url) => SelectableText(url, style: TextStyle(color: Colors.blue))),
            ]
          ],
        ),
      ),
    );
  }
}
