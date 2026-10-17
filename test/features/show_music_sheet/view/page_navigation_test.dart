import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:organista/features/settings/cubit/settings_cubit.dart';
import 'package:organista/features/settings/cubit/settings_state.dart';
import 'package:organista/features/show_music_sheet/view/page_navigation.dart';
import 'package:organista/features/show_music_sheet/view/pdf_navigation_touch_area.dart';

class MockSettingsCubit extends MockCubit<SettingsState> implements SettingsCubit {}

void main() {
  group('PageNavigation', () {
    late MockSettingsCubit settingsCubit;
    late int previousCalls;
    late int nextCalls;

    const settingsWithArrows = SettingsState(
      themeModeIndex: 0,
      localeString: 'en',
      showNavigationArrows: true,
      keepScreenOn: false,
    );

    setUp(() {
      settingsCubit = MockSettingsCubit();
      when(() => settingsCubit.state).thenReturn(settingsWithArrows);
      previousCalls = 0;
      nextCalls = 0;
    });

    Future<void> pump(WidgetTester tester, {required int currentPage, required int pageCount}) {
      return tester.pumpWidget(
        BlocProvider<SettingsCubit>.value(
          value: settingsCubit,
          child: MaterialApp(
            home: Stack(
              children: [
                PageNavigation(
                  currentPage: currentPage,
                  pageCount: pageCount,
                  onPrevious: () => previousCalls++,
                  onNext: () => nextCalls++,
                ),
              ],
            ),
          ),
        ),
      );
    }

    testWidgets('shows both tap areas on a middle page', (tester) async {
      await pump(tester, currentPage: 2, pageCount: 3);

      expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
      expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
    });

    testWidgets('shows only the forward tap area on the first page', (tester) async {
      await pump(tester, currentPage: 1, pageCount: 3);

      expect(find.byIcon(Icons.arrow_upward), findsNothing);
      expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
    });

    testWidgets('shows only the backward tap area on the last page', (tester) async {
      await pump(tester, currentPage: 3, pageCount: 3);

      expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
      expect(find.byIcon(Icons.arrow_downward), findsNothing);
    });

    testWidgets('shows nothing for a single page', (tester) async {
      await pump(tester, currentPage: 1, pageCount: 1);

      expect(find.byType(PdfNavigationTouchArea), findsNothing);
    });

    testWidgets('shows nothing when the navigation arrows are disabled', (tester) async {
      when(() => settingsCubit.state).thenReturn(settingsWithArrows.copyWith(showNavigationArrows: false));
      await pump(tester, currentPage: 2, pageCount: 3);

      expect(find.byType(PdfNavigationTouchArea), findsNothing);
    });

    testWidgets('tap areas call onPrevious and onNext', (tester) async {
      await pump(tester, currentPage: 2, pageCount: 3);

      await tester.tap(find.byIcon(Icons.arrow_upward));
      expect(previousCalls, 1);
      expect(nextCalls, 0);

      await tester.tap(find.byIcon(Icons.arrow_downward));
      expect(previousCalls, 1);
      expect(nextCalls, 1);
    });
  });
}
