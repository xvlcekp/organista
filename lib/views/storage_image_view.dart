import 'dart:developer';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:organista/bloc/app_bloc.dart';
import 'package:organista/bloc/app_state.dart';
import 'package:organista/views/app.dart';
import 'package:provider/provider.dart';

class StorageImageView extends StatelessWidget {
  final Reference image;
  const StorageImageView({
    super.key,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: image.getData(),
      builder: (context, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.none:
          case ConnectionState.waiting:
          case ConnectionState.active:
            return const Center(
              child: CircularProgressIndicator(),
            );
          case ConnectionState.done:
            if (snapshot.hasData) {
              final data = snapshot.data!;
              return GestureDetector(
                child: Image.memory(
                  data,
                  fit: BoxFit.cover,
                  height: double.infinity,
                  width: double.infinity,
                  alignment: Alignment.center,
                ),
                onTap: () {
                  AppBloc bloc = context.read<AppBloc>();
                  log("User email is ${bloc.state.user!.email}");
                  log('Tapped image ${image.fullPath} and logged in user is ');
                  Scaffold(
                    body: Image.memory(
                      data,
                      fit: BoxFit.cover,
                      height: double.infinity,
                      width: double.infinity,
                      alignment: Alignment.center,
                    ),
                  );
                },
              );
            } else {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
        }
      },
    );
  }
}
