import 'package:collection/collection.dart' show compareNatural;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:organista/blocs/app_bloc/app_bloc.dart';
import 'package:organista/features/add_edit_music_sheet/cubit/add_edit_music_sheet_cubit.dart';
import 'package:organista/features/add_edit_music_sheet/view/add_music_sheet_view.dart';
import 'package:organista/features/show_music_sheet/music_sheet_view.dart';
import 'package:organista/models/music_sheets/music_sheet.dart';
import 'package:organista/repositories/firebase_firestore_repository.dart';

class DownloadMusicSheetView extends HookWidget {
  const DownloadMusicSheetView({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const DownloadMusicSheetView());
  }

  @override
  Widget build(BuildContext context) {
    final FirebaseFirestoreRepository firebaseFirestoreRepository = context.read<FirebaseFirestoreRepository>();
    final String userId = context.read<AppBloc>().state.user!.uid;

    // State hooks
    final isLoading = useState(true);
    final filteredImageRefs = useState<List<MusicSheet>>([]); // References displayed after filtering
    final searchController = useTextEditingController();

    // Fetch images dynamically based on the search query
    Future<void> fetchImages(String query) async {
      isLoading.value = true;
      final List<MusicSheet> result = (await firebaseFirestoreRepository.getMusicSheetsFromRepository(userId)).toList();
      // Filter images based on the search query and sort them numerically
      final List<MusicSheet> filtered = result
          .where((musicSheet) => musicSheet.fileName.contains(query)) // Filter by query
          .toList()
        ..sort((a, b) => compareNatural(a.fileName, b.fileName));

      filteredImageRefs.value = filtered;
      isLoading.value = false;
    }

    // Fetch all images when the widget is initialized
    useEffect(() {
      fetchImages(''); // Fetch without query initially
      return null; // No cleanup needed
    }, []);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Repository ♬♬♬'),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20.0, right: 8.0), // Adjust padding as needed
        child: const UploadFileFragment(),
      ),
      body: Column(
        children: [
          // Search Bar at the top
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
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

          // List of Images Below
          Expanded(
            child: isLoading.value
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: filteredImageRefs.value.length,
                    itemBuilder: (context, index) {
                      final musicSheet = filteredImageRefs.value[index];
                      return ListTile(
                        title: Text(musicSheet.fileName),
                        trailing: IconButton(
                          icon: const Icon(Icons.download),
                          onPressed: () {
                            context.read<AddEditMusicSheetCubit>().addMusicSheetToPlaylist(
                                  musicSheet: musicSheet,
                                );
                            Navigator.of(context).push<void>(AddMusicSheetView.route());
                          },
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => MusicSheetView(musicSheet: musicSheet, mode: MusicSheetViewMode.full),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class UploadFileFragment extends StatelessWidget {
  const UploadFileFragment({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min, // Ensures it doesn't take extra space
          children: [
            const SizedBox(height: 16), // Space between buttons
            FloatingActionButton(
              heroTag: 'uploadPdfButton',
              onPressed: () async {
                FilePickerResult? result = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['jpg', 'pdf', 'png'],
                  withData: true,
                );
                if (result != null) {
                  if (context.mounted) {
                    final PlatformFile file = result.files.first;
                    context.read<AddEditMusicSheetCubit>().uploadMusicSheet(
                          file: file,
                        );
                    Navigator.of(context).push<void>(AddMusicSheetView.route());
                  }
                }
              },
              child: const Icon(Icons.upload),
            ),
          ],
        ),
      ],
    );
  }
}


// TODO: refactor code
// TODO: handle errors