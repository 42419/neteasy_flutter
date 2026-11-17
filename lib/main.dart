import 'package:material_ui/material_ui.dart';

import 'features/home/home_page.dart';
import 'theme/tokens.dart';

void main() {
  runApp(const NeteasyApp());
}

class NeteasyApp extends StatelessWidget {
  const NeteasyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'neteasy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Tokens.brand),
        scaffoldBackgroundColor: Tokens.background,
        splashFactory: InkSparkle.splashFactory,
      ),
      home: const HomePage(),
    );
  }
}
