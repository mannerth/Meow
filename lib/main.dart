import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meow/api/http.dart';
import 'package:meow/api/service/auth_repository.dart';
import 'package:meow/model/user.dart';
import 'package:meow/ui/page/main_page.dart';
import 'package:meow/util/store.dart';
import 'package:meow/provider/auth_provider.dart';
import 'package:meow/ui/page/common/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Store().init();
  try{
    final token = Store().getString('token');
    if(token!=null && token.isNotEmpty){
      Http().setToken(token);
    }
    final user = await AuthRepository.getMe();
    String? roleType = Store().getString('roleType');
    if( roleType!=null && roleType.isNotEmpty ){
      user.roleType = RoleType.values.firstWhere((e) => e.toString() == roleType, orElse: () => user.roleType);
    }
    Store().user = user;
  }catch(e){
    Store().remove('token');
  }finally{
    Http.hasInit = true;
  }
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_){
      if(Store().user != null){
        ref.read(authStateProvider.notifier).update(Store().user!, Store().getString('token')!);
      }else if( Store().getString('roleType')==RoleType.guest.toString() ){
        // 游客模式
        final user = User(
          id: -1,
          roleType: RoleType.guest,
          currency: 0, studentId: '', level: 0, experience: 0, nextLevelExp: 0,
        );
        ref.read(authStateProvider.notifier).update(user, '');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
