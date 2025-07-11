import 'package:logger/logger.dart';

class CustomPrettyPrinter extends PrettyPrinter {
  CustomPrettyPrinter()
    : super(
        methodCount: 0,
        errorMethodCount: 5,
        lineLength: 100,
        colors: true,
        printEmojis: true,
      );
}
