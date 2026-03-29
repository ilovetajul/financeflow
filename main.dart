cat > lib/main.dart << 'EOF'
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FinanceFlow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF4C55A),
          brightness: Brightness.dark,
        ),
      ),
      home: const Scaffold(
        backgroundColor: Color(0xFF0A0E1A),
        body: Center(
          child: Text(
            '💰 FinanceFlow',
            style: TextStyle(
              color: Color(0xFFF4C55A),
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
EOF
