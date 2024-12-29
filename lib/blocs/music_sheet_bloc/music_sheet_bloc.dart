import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:organista/models/music_sheets/music_sheet.dart';
import 'package:organista/models/music_sheets/music_sheet_key.dart';

class MusicSheetCubit extends Cubit<Iterable<MusicSheet>> {
  final String userId;
  late final StreamSubscription _subscription;

  MusicSheetCubit({required this.userId}) : super([]) {
    _subscription = FirebaseFirestore.instance
        .collection(userId)
        .orderBy(MusicSheetKey.sequenceId, descending: false)
        // .where(
        //   MusicSheetKey.userId,
        //   isEqualTo: userId,
        // )
        .snapshots()
        .listen(
      (snapshot) {
        final documents = snapshot.docs;
        final musicSheets = documents.where((doc) => !doc.metadata.hasPendingWrites).map((doc) => MusicSheet(
              musicSheetId: doc.id,
              json: doc.data(),
            ));
        emit(musicSheets); // Emit the posts to update the UI
      },
    );
  }

  @override
  Future<void> close() {
    _subscription.cancel(); // Cancel the subscription when BLoC is closed
    return super.close();
  }
}
