// Drives a running Flutter debug app through the Dart VM service by injecting
// pointer events and editing text fields — no flutter_driver extension needed.
// Used for the iOS simulator, where `adb shell input` has no equivalent.
//
//   dart --packages=.dart_tool/package_config.json tools/store-screenshots/vm_driver.dart <ws-url> < commands.txt
//
// Commands (one per line, coordinates in logical pixels):
//   tap X Y              down X Y             up X Y            move X Y
//   longpress X Y [MS]   swipe X1 Y1 X2 Y2 [MS]
//   text N STRING        — set the text of the N-th EditableText on screen (0-based)
//   eval EXPRESSION      — evaluate a Dart expression in lib/main.dart's scope
//   js CODE              — run JavaScript in the first WebViewWidget on screen
//   scroll N PX          — jump the N-th Scrollable on screen (0-based) to offset PX
//   sleep MS
//   shot PATH            — `xcrun simctl io booted screenshot PATH`
//   # comment

// vm_service comes in transitively through flutter_test; the script borrows the
// app's package config (see the usage line above) instead of declaring it.
// ignore_for_file: depend_on_referenced_packages
import 'dart:convert';
import 'dart:io';

import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

late VmService service;
late String isolateId;
late String libraryId;

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('usage: vm_driver.dart ws://127.0.0.1:PORT/TOKEN=/ws < commands');
    exit(2);
  }
  service = await vmServiceConnectUri(args[0]);
  final vm = await service.getVM();
  isolateId = vm.isolates!.first.id!;
  final isolate = await service.getIsolate(isolateId);
  libraryId = isolate.rootLib!.id!;

  await for (final line in stdin.transform(utf8.decoder).transform(const LineSplitter())) {
    final cmd = line.trim();
    if (cmd.isEmpty || cmd.startsWith('#')) continue;
    stderr.writeln('> $cmd');
    final parts = cmd.split(RegExp(r'\s+'));
    switch (parts[0]) {
      case 'tap':
        await pointer('PointerDownEvent', parts[1], parts[2]);
        await Future<void>.delayed(const Duration(milliseconds: 60));
        await pointer('PointerUpEvent', parts[1], parts[2]);
      case 'down':
        await pointer('PointerDownEvent', parts[1], parts[2]);
      case 'up':
        await pointer('PointerUpEvent', parts[1], parts[2]);
      case 'move':
        await pointer('PointerMoveEvent', parts[1], parts[2]);
      case 'longpress':
        final ms = parts.length > 3 ? int.parse(parts[3]) : 900;
        await pointer('PointerDownEvent', parts[1], parts[2]);
        await Future<void>.delayed(Duration(milliseconds: ms));
        await pointer('PointerUpEvent', parts[1], parts[2]);
      case 'swipe':
        final x1 = double.parse(parts[1]), y1 = double.parse(parts[2]);
        final x2 = double.parse(parts[3]), y2 = double.parse(parts[4]);
        final ms = parts.length > 5 ? int.parse(parts[5]) : 300;
        const steps = 12;
        final dx = (x2 - x1) / steps, dy = (y2 - y1) / steps;
        await pointer('PointerDownEvent', '$x1', '$y1');
        for (var i = 1; i <= steps; i++) {
          await Future<void>.delayed(Duration(milliseconds: ms ~/ steps));
          final x = x1 + dx * i, y = y1 + dy * i;
          // Drag recognizers read `delta`, so a move without it never scrolls.
          await eval(
            '(WidgetsBinding.instance..handlePointerEvent('
            'PointerMoveEvent(position: Offset($x, $y), delta: Offset($dx, $dy)))).hashCode',
          );
        }
        await pointer('PointerUpEvent', '$x2', '$y2');
      case 'text':
        final n = int.parse(parts[1]);
        final text = cmd.substring(cmd.indexOf(parts[1]) + parts[1].length).trim();
        await eval('''(() {
          final found = <EditableTextState>[];
          void visit(Element e) {
            if (e is StatefulElement && e.state is EditableTextState) found.add(e.state as EditableTextState);
            e.visitChildren(visit);
          }
          WidgetsBinding.instance.rootElement!.visitChildren(visit);
          found[$n].widget.controller.text = ${jsonEncode(text)};
          return found.length;
        })()''');
      case 'js':
        final code = cmd.substring(2).trim();
        await eval('''(() {
          Element? found;
          void visit(Element e) {
            if (e.widget.runtimeType.toString() == 'WebViewWidget') found ??= e;
            e.visitChildren(visit);
          }
          WidgetsBinding.instance.rootElement!.visitChildren(visit);
          (found!.widget as dynamic).platform.params.controller.runJavaScript(${jsonEncode(code)});
          return found == null ? 0 : 1;
        })()''');
      case 'scroll':
        await eval('''(() {
          final found = <ScrollableState>[];
          void visit(Element e) {
            if (e is StatefulElement && e.state is ScrollableState) found.add(e.state as ScrollableState);
            e.visitChildren(visit);
          }
          WidgetsBinding.instance.rootElement!.visitChildren(visit);
          found[${parts[1]}].position.jumpTo(${parts[2]});
          return found.length;
        })()''');
      case 'eval':
        await eval(cmd.substring(4).trim());
      case 'sleep':
        await Future<void>.delayed(Duration(milliseconds: int.parse(parts[1])));
      case 'shot':
        // simctl may not write into ~/Documents (sandbox), so go through a temp file.
        final tmp = '${Directory.systemTemp.path}/vm_driver_shot.png';
        final r = await Process.run('xcrun', ['simctl', 'io', 'booted', 'screenshot', tmp]);
        if (r.exitCode != 0) stderr.writeln((r.stderr as String).trim());
        await File(tmp).copy(parts[1]);
      default:
        stderr.writeln('unknown command: $cmd');
    }
  }
  await service.dispose();
}

Future<void> pointer(String type, String x, String y) =>
    eval('(WidgetsBinding.instance..handlePointerEvent($type(position: Offset($x, $y)))).hashCode');

Future<void> eval(String expression) async {
  // The expression compiler wants a single line.
  final oneLine = expression.replaceAll(RegExp(r'\s*\n\s*'), ' ');
  try {
    final result = await service.evaluate(isolateId, libraryId, oneLine);
    if (result is ErrorRef) {
      stderr.writeln('eval error: ${result.message}');
    } else if (result is InstanceRef && result.valueAsString != null) {
      stderr.writeln('= ${result.valueAsString}');
    }
  } on RPCError catch (e) {
    stderr.writeln('eval failed: ${e.message} ${e.details}');
  }
}
