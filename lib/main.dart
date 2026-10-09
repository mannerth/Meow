import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meow/api/http.dart';
import 'package:meow/api/service/auth_repository.dart';
import 'package:meow/provider/auth_provider.dart';
import 'package:meow/router/route.dart';
import 'package:meow/util/store.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Store().init();
  try {
    final token = Store().accessToken;
    if (token != null && token.isNotEmpty) {
      Http().setToken(token);
    }
    final refreshToken = Store().refreshToken;
    if (refreshToken != null && refreshToken.isNotEmpty) {
      Http().setRefreshToken(refreshToken);
    }
    if (token != null && token.isNotEmpty) {
      Store().user = await AuthRepository.getMe();
    }
  } catch (e) {
    Http().clearToken();
    Store().user = null;
    await Store().remove('roleType');
  } finally {
    Http.hasInit = true;
  }
  runApp(
    ProviderScope(
      overrides: [initialAuthProvider.overrideWithValue(Auth.fromStore())],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
    debugShowCheckedModeBanner: false,
    title: '猫猫图鉴',
    routerConfig: ref.watch(appRouterProvider),
  );
}
