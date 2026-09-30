import 'package:flutter/material.dart';
import 'screens/avatar_gallery_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RPMApp());
}

class RPMApp extends StatelessWidget {
  const RPMApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RPM 3D Avatar Studio',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6366F1),
          secondary: Color(0xFFEC4899),
          surface: Color(0xFF1E293B),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E293B),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF6366F1),
          foregroundColor: Colors.white,
        ),
        useMaterial3: true,
      ),
      home: const AvatarGalleryScreen(),
    );
  }
}
