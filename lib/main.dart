import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meow/ui/page/main_page.dart';
import 'package:meow/util/store.dart';
import 'package:meow/provider/auth_provider.dart';
import 'package:meow/ui/page/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Store().init();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '猫猫图鉴',
      navigatorKey: navigatorKey,

      home: auth.loggedIn ? const MainPage() : const LoginPage(),
    );
  }
}

GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();