import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:organista/config/app_theme.dart';
import 'package:organista/widgets/scroll_aware_fab.dart';

void main() {
  group('ScrollAwareFab', () {
    const testLabel = 'New playlist';
    const scrolledPastThreshold = AppTheme.fabCollapseThreshold + 1;

    Widget buildFab({
      required ScrollController scrollController,
      VoidCallback? onPressed,
      String label = testLabel,
      IconData icon = Icons.add,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              ListView.builder(
                controller: scrollController,
                itemCount: 100,
                itemBuilder: (context, i) => const SizedBox(height: 50),
              ),
              ScrollAwareFab(
                scrollController: scrollController,
                onPressed: onPressed ?? () {},
                label: label,
                icon: icon,
              ),
            ],
          ),
        ),
      );
    }

    group('Extended state (not scrolled)', () {
      testWidgets('shows add icon', (tester) async {
        final controller = ScrollController();
        addTearDown(controller.dispose);
        await tester.pumpWidget(buildFab(scrollController: controller));
        await tester.pump();
        expect(find.byIcon(Icons.add), findsOneWidget);
      });

      testWidgets('label width factor is 1.0', (tester) async {
        final controller = ScrollController();
        addTearDown(controller.dispose);
        await tester.pumpWidget(buildFab(scrollController: controller));
        await tester.pump();
        final align = tester.widget<AnimatedAlign>(find.byType(AnimatedAlign));
        expect(align.widthFactor, 1.0);
      });

      testWidgets('label opacity is 1.0', (tester) async {
        final controller = ScrollController();
        addTearDown(controller.dispose);
        await tester.pumpWidget(buildFab(scrollController: controller));
        await tester.pump();
        final opacity = tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity));
        expect(opacity.opacity, 1.0);
      });

      testWidgets('label text is in the widget tree', (tester) async {
        final controller = ScrollController();
        addTearDown(controller.dispose);
        await tester.pumpWidget(buildFab(scrollController: controller));
        await tester.pump();
        expect(find.text(testLabel), findsOneWidget);
      });
    });

    group('Collapsed state (scrolled past threshold)', () {
      testWidgets('shows add icon', (tester) async {
        final controller = ScrollController();
        addTearDown(controller.dispose);
        await tester.pumpWidget(buildFab(scrollController: controller));
        await tester.pump();
        controller.jumpTo(scrolledPastThreshold);
        await tester.pump();
        expect(find.byIcon(Icons.add), findsOneWidget);
      });

      testWidgets('label width factor is 0.0', (tester) async {
        final controller = ScrollController();
        addTearDown(controller.dispose);
        await tester.pumpWidget(buildFab(scrollController: controller));
        await tester.pump();
        controller.jumpTo(scrolledPastThreshold);
        await tester.pump();
        final align = tester.widget<AnimatedAlign>(find.byType(AnimatedAlign));
        expect(align.widthFactor, 0.0);
      });

      testWidgets('label opacity is 0.0', (tester) async {
        final controller = ScrollController();
        addTearDown(controller.dispose);
        await tester.pumpWidget(buildFab(scrollController: controller));
        await tester.pump();
        controller.jumpTo(scrolledPastThreshold);
        await tester.pump();
        final opacity = tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity));
        expect(opacity.opacity, 0.0);
      });

      testWidgets('label text remains in widget tree for accessibility', (tester) async {
        final controller = ScrollController();
        addTearDown(controller.dispose);
        await tester.pumpWidget(buildFab(scrollController: controller));
        await tester.pump();
        controller.jumpTo(scrolledPastThreshold);
        await tester.pump();
        expect(find.text(testLabel), findsOneWidget);
      });
    });

    group('Scroll threshold', () {
      testWidgets('collapses when scrolled past threshold', (tester) async {
        final controller = ScrollController();
        addTearDown(controller.dispose);
        await tester.pumpWidget(buildFab(scrollController: controller));
        await tester.pump();

        controller.jumpTo(scrolledPastThreshold);
        await tester.pump();

        final align = tester.widget<AnimatedAlign>(find.byType(AnimatedAlign));
        expect(align.widthFactor, 0.0);
      });

      testWidgets('re-extends when scrolled back to top', (tester) async {
        final controller = ScrollController();
        addTearDown(controller.dispose);
        await tester.pumpWidget(buildFab(scrollController: controller));
        await tester.pump();

        controller.jumpTo(scrolledPastThreshold);
        await tester.pump();
        controller.jumpTo(0);
        await tester.pump();

        final align = tester.widget<AnimatedAlign>(find.byType(AnimatedAlign));
        expect(align.widthFactor, 1.0);
      });
    });

    group('Dimensions', () {
      testWidgets('has fixed height of 56', (tester) async {
        final controller = ScrollController();
        addTearDown(controller.dispose);
        await tester.pumpWidget(buildFab(scrollController: controller));
        await tester.pump();
        final size = tester.getSize(find.byType(ScrollAwareFab));
        expect(size.height, 56.0);
      });

      testWidgets('is wider when extended than collapsed after animation settles', (tester) async {
        final controller = ScrollController();
        addTearDown(controller.dispose);
        await tester.pumpWidget(buildFab(scrollController: controller));
        await tester.pumpAndSettle();
        final extendedWidth = tester.getSize(find.byType(ScrollAwareFab)).width;

        controller.jumpTo(scrolledPastThreshold);
        await tester.pumpAndSettle();
        final collapsedWidth = tester.getSize(find.byType(ScrollAwareFab)).width;

        expect(extendedWidth, greaterThan(collapsedWidth));
      });

      testWidgets('is square when collapsed', (tester) async {
        final controller = ScrollController();
        addTearDown(controller.dispose);
        await tester.pumpWidget(buildFab(scrollController: controller));
        await tester.pump();
        controller.jumpTo(scrolledPastThreshold);
        await tester.pumpAndSettle();
        final size = tester.getSize(find.byType(ScrollAwareFab));
        expect(size.width, size.height);
      });
    });

    group('Interaction', () {
      testWidgets('calls onPressed when tapped in extended state', (tester) async {
        final controller = ScrollController();
        addTearDown(controller.dispose);
        var pressed = false;
        await tester.pumpWidget(buildFab(scrollController: controller, onPressed: () => pressed = true));
        await tester.pump();
        await tester.tap(find.byType(ScrollAwareFab));
        expect(pressed, isTrue);
      });

      testWidgets('calls onPressed when tapped in collapsed state', (tester) async {
        final controller = ScrollController();
        addTearDown(controller.dispose);
        var pressed = false;
        await tester.pumpWidget(buildFab(scrollController: controller, onPressed: () => pressed = true));
        await tester.pump();
        controller.jumpTo(scrolledPastThreshold);
        await tester.pump();
        await tester.tap(find.byType(ScrollAwareFab));
        expect(pressed, isTrue);
      });
    });

    group('Label', () {
      testWidgets('renders the provided label text', (tester) async {
        final controller = ScrollController();
        addTearDown(controller.dispose);
        const customLabel = 'New repository';
        await tester.pumpWidget(buildFab(scrollController: controller, label: customLabel));
        await tester.pump();
        expect(find.text(customLabel), findsOneWidget);
      });
    });

    group('Custom icon', () {
      testWidgets('renders provided icon instead of default add icon', (tester) async {
        final controller = ScrollController();
        addTearDown(controller.dispose);
        await tester.pumpWidget(buildFab(scrollController: controller, icon: Icons.upload));
        await tester.pump();
        expect(find.byIcon(Icons.upload), findsOneWidget);
        expect(find.byIcon(Icons.add), findsNothing);
      });
    });
  });
}
