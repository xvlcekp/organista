import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:provider/provider.dart';
import 'package:organista/features/music_sheet_repository/view/music_sheet_repository_view.dart';
import 'package:organista/models/repositories/repository.dart';
import 'package:organista/repositories/firebase_firestore_repository.dart';

class RepositoryTile extends HookWidget {
  final Repository repository;

  const RepositoryTile({
    super.key,
    required this.repository,
  });

  @override
  Widget build(BuildContext context) {
    final musicSheetsCount = useState(0);

    useEffect(() {
      _loadMusicSheetsCount(context, musicSheetsCount);
      return null;
    }, []);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MusicSheetRepositoryView.route(
            repository: repository,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: _getRandomColor(),
          borderRadius: BorderRadius.circular(8.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4.0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              bottom: -20,
              child: Icon(
                Icons.folder,
                size: 100,
                color: Colors.white.withOpacity(0.2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    repository.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${musicSheetsCount.value} sheets',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadMusicSheetsCount(BuildContext context, ValueNotifier<int> count) async {
    final result = await context.read<FirebaseFirestoreRepository>().getRepositoryMusicSheetsCount(repository.repositoryId);
    count.value = result;
  }

  Color _getRandomColor() {
    final List<Color> colors = [
      Colors.blue[400]!,
      Colors.red[400]!,
      Colors.green[400]!,
      Colors.orange[400]!,
      Colors.purple[400]!,
      Colors.teal[400]!,
      Colors.pink[400]!,
      Colors.indigo[400]!,
    ];
    return colors[math.Random().nextInt(colors.length)];
  }
}
