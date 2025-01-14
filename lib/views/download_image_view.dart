import 'package:collection/collection.dart' show compareNatural;
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:organista/features/add_music_sheet/cubit/add_music_sheet_cubit.dart';
import 'package:organista/repositories/firebase_storage_repository.dart';

class DownloadImageView extends HookWidget {
  const DownloadImageView({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const DownloadImageView());
  }

  @override
  Widget build(BuildContext context) {
    final FirebaseStorageRepository firebaseStorageRepository = context.read<FirebaseStorageRepository>();

    // State hooks
    final isLoading = useState(true);
    final allImageRefs = useState<List<Reference>>([]); // All references fetched from Firebase
    final filteredImageRefs = useState<List<Reference>>([]); // References displayed after filtering
    final searchController = useTextEditingController(); // Controller for search input

    // Fetch images dynamically based on the search query
    Future<void> fetchImages(String query) async {
      isLoading.value = true;
      final ListResult result = await firebaseStorageRepository.getReference('JKS').listAll();
      // Filter images based on the search query and sort them numerically
      final List<Reference> filtered = result.items
          .where((ref) => ref.name.contains(query)) // Filter by query
          .toList()
        ..sort((a, b) => compareNatural(a.name, b.name));

      allImageRefs.value = result.items;
      filteredImageRefs.value = filtered;
      isLoading.value = false;
    }

    // Fetch all images when the widget is initialized
    useEffect(() {
      fetchImages(''); // Fetch without query initially
      return null; // No cleanup needed
    }, []);

    // Function to handle image downloads and uploads
    Future<void> downloadAndMoveImage(Reference ref) async {
      try {
        final Uint8List? imageData = await ref.getData();
        if (imageData == null) {
          throw Exception("Failed to download image data.");
        }

        if (context.mounted) {
          context.read<AddMusicSheetCubit>().newMusicSheet(
                file: imageData,
                fileName: ref.name,
              );
          Navigator.of(context).pop();
        }
      } catch (e, stacktrace) {
        FirebaseCrashlytics.instance.recordError(e, stacktrace);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          decoration: BoxDecoration(
            color: Colors.grey[800], // Background color for the search box
            borderRadius: BorderRadius.circular(8), // Rounded corners
          ),
          child: TextField(
            controller: searchController,
            decoration: const InputDecoration(
              hintText: 'Search images...',
              border: InputBorder.none,
              hintStyle: TextStyle(color: Colors.white60),
              icon: Icon(Icons.search, color: Colors.white), // Add a search icon
            ),
            style: const TextStyle(color: Colors.white), // Text color
            onChanged: (query) {
              fetchImages(query);
            },
          ),
        ),
      ),
      body: isLoading.value
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: filteredImageRefs.value.length,
              itemBuilder: (context, index) {
                final ref = filteredImageRefs.value[index];
                return ListTile(
                  title: Text(ref.name),
                  trailing: IconButton(
                    icon: const Icon(Icons.download),
                    onPressed: () => downloadAndMoveImage(ref),
                  ),
                  onTap: () => {},
                );
              },
            ),
    );
  }
}


// TODO: refactor code
// TODO: handle errors