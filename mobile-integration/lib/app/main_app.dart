import 'package:flutter/material.dart';

import '../pages/feed/main_feed_page.dart';
import '../pages/landing/landing_page.dart';
import 'constants.dart';

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: watchItAppTitle,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFEF5350),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (_) => const HomePage(logoAssetPath: watchItLogoAssetPath),
        '/feed': (_) => const MainFeedPage(),
      },
    );
  }
}
