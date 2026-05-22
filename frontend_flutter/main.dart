import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/theme_provider.dart';
import 'features/splash/splash_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MindTraceApp(),
    ),
  );
}

class MindTraceApp extends StatelessWidget {
  const MindTraceApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MindTrace',

      /// 🌞 LIGHT THEME (Lavender Soft)
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFFB39DDB),
        scaffoldBackgroundColor: const Color(0xFFF5F3FF),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFB39DDB),
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Color(0xFF6A1B9A),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Color(0xFF4A148C)),
        ),
      ),

      /// 🌙 DARK THEME (Purple Night)
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF9575CD),
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white70),
        ),
      ),

      /// 🌓 CONTROLLED BY PROVIDER (SAVED MODE)
      themeMode: themeProvider.themeMode,

      home: ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          return const SplashScreen();
        },
      ),
    );
  }
}