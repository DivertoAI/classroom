import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'config/app_theme.dart';
import 'screens/classroom_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  runApp(const ClassroomApp());
}

class ClassroomApp extends StatelessWidget {
  const ClassroomApp({super.key, this.enableRtc = true});

  final bool enableRtc;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Classroom Studio',
      theme: buildAppTheme(),
      debugShowCheckedModeBanner: false,
      home: ClassroomScreen(enableRtc: enableRtc),
    );
  }
}
