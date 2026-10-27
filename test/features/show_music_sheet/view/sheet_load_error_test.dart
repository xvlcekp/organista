import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:organista/features/connectivity/cubit/connectivity_cubit.dart';
import 'package:organista/features/show_music_sheet/view/music_sheet_view.dart';
import 'package:organista/features/show_music_sheet/view/sheet_load_error.dart';
import 'package:organista/l10n/app_localizations.dart';

class MockConnectivityCubit extends MockCubit<ConnectivityState> implements ConnectivityCubit {}

void main() {
  const offlineMessage = 'No internet connection. This music sheet has not been downloaded to this device yet.';

  Widget app({required Widget child, ConnectivityCubit? cubit}) {
    final page = MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );
    return cubit == null ? page : BlocProvider<ConnectivityCubit>.value(value: cubit, child: page);
  }

  MockConnectivityCubit cubit({required bool isOnline}) {
    final cubit = MockConnectivityCubit();
    when(() => cubit.state).thenReturn(ConnectivityState(isOnline: isOnline));
    return cubit;
  }

  testWidgets('shows a plain error icon while online', (tester) async {
    await tester.pumpWidget(
      app(
        child: const SheetLoadError(mode: MusicSheetViewMode.full),
        cubit: cubit(isOnline: true),
      ),
    );

    expect(find.byIcon(Icons.error), findsOneWidget);
    expect(find.text(offlineMessage), findsNothing);
  });

  testWidgets('names the missing download while offline', (tester) async {
    await tester.pumpWidget(
      app(
        child: const SheetLoadError(mode: MusicSheetViewMode.preview),
        cubit: cubit(isOnline: false),
      ),
    );

    expect(find.byIcon(Icons.cloud_off), findsOneWidget);
    expect(find.text(offlineMessage), findsOneWidget);
  });

  testWidgets('keeps only the icon in a thumbnail while offline', (tester) async {
    await tester.pumpWidget(
      app(
        child: const SheetLoadError(mode: MusicSheetViewMode.thumbnail),
        cubit: cubit(isOnline: false),
      ),
    );

    expect(find.byIcon(Icons.cloud_off), findsOneWidget);
    expect(find.text(offlineMessage), findsNothing);
  });

  testWidgets('works without a ConnectivityCubit in the tree', (tester) async {
    await tester.pumpWidget(app(child: const SheetLoadError(mode: MusicSheetViewMode.full)));

    expect(find.byIcon(Icons.error), findsOneWidget);
  });
}
