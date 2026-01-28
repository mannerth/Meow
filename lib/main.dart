import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meow/ui/page/main_page.dart';
import 'package:meow/util/store.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Store().init();
  runApp(const ProviderScope(child: MyApp()));
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
