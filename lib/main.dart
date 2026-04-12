import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/theme.dart';
import 'presentation/screens/home_shell.dart';
import 'presentation/screens/profile/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp]);

  runApp(const ProviderScope(child: FinanceFlowApp()));
}

class FinanceFlowApp extends StatelessWidget {
  const FinanceFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FinanceFlow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      // AppLock দিয়ে wrap করা — PIN চালু থাকলে lock screen দেখাবে
      home: const AppLockScreen(child: HomeShell()),
    );
  }
}
