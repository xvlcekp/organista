import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:organista/features/add_edit_music_sheet/cubit/add_edit_music_sheet_cubit.dart';
import 'package:pdfx/pdfx.dart';

class UploadedMusicSheetImageView extends StatelessWidget {
  const UploadedMusicSheetImageView({
    super.key,
    required this.image,
  });

  final Uint8List image;

  @override
  Widget build(BuildContext context) {
    final pdfController = PdfController(
      document: PdfDocument.openData(image),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // GestureDetector(
        // child:
        Expanded(
          child: PdfView(
            controller: pdfController,
          ),
        ),
        // Image.memory(
        //   image,
        //   fit: BoxFit.fitHeight,
        // ),

        // onTap: () {
        //   CustomLogger.instance.i("Tapped");
        //   Navigator.of(context).push(
        //     MaterialPageRoute(
        //       builder: (_) => Scaffold(
        //         body: InteractiveViewer(
        //           child: Image.memory(
        //             image,
        //             fit: BoxFit.fitHeight,
        //             alignment: Alignment.center,
        //           ),
        //         ),
        //       ),
        //     ),
        //   );
        // }),
        IconButton(
          onPressed: () => context.read<AddEditMusicSheetCubit>().resetState(),
          icon: Icon(Icons.change_circle),
        ),
      ],
    );
  }
}
