import 'package:flutter/material.dart';
import 'package:meow/ui/page/main_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '猫猫图鉴',
      home: MainPage(),
    );
  }
}
