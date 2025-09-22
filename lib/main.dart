import 'package:briqwear/src/feature/auth/presentation/view/auth_screen.dart';
import 'package:briqwear/src/feature/auth/presentation/view/splash_screen.dart';
import 'package:flutter/material.dart';

void main(List<String> args) {
  runApp(const Myapp());
}

class Myapp extends StatelessWidget {
  const Myapp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}
