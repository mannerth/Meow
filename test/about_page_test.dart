import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meow/api/http.dart';
import 'package:meow/ui/page/common/about_page.dart';
import 'package:meow/ui/page/common/user_page.dart';
import 'package:meow/ui/widget/community_qrcode_dialog.dart';
import 'package:meow/util/store.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fake_http_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final backend = FakeHttpOverrides();
  final originalOverrides = HttpOverrides.current;
  const saveChannel = MethodChannel('meow/image_saver');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late Uint8List png;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await Store().init();
    HttpOverrides.global = backend;
    final recorder = ui.PictureRecorder();
    Canvas(recorder).drawColor(Colors.black, BlendMode.src);
    final picture = recorder.endRecording();
    final image = await picture.toImage(16, 16);
    png = (await image.toByteData(
      format: ui.ImageByteFormat.png,
    ))!.buffer.asUint8List();
    image.dispose();
    picture.dispose();
  });

  setUp(() {
    backend.requests.clear();
    backend.respond = (request) {
      expect(request.authorization, isNull);
      if (request.uri.path == '/api/community/group-qrcode') {
        expect(request.method, 'GET');
        return FakeHttpResponse(200, {
          'code': 200,
          'data': {'qrcodeUrl': 'https://images.example.invalid/group.png'},
        });
      }
      expect(request.uri.host, 'images.example.invalid');
      return FakeHttpResponse.bytes(200, png);
    };
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(saveChannel, null);
    Http().clearToken();
  });

  tearDownAll(() => HttpOverrides.global = originalOverrides);

  Future<void> finishLoadingImage(WidgetTester tester) async {
    for (var i = 0; i < 50; i++) {
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      });
      await tester.pump(const Duration(milliseconds: 20));
      if (find.byType(CircularProgressIndicator).evaluate().isEmpty) return;
    }
    fail('二维码加载未完成');
  }

  testWidgets('游客个人页可从更多进入关于我们，手机和平板均可阅读', (tester) async {
    addTearDown(tester.view.reset);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: UserPage())),
    );
    expect(find.text('更多'), findsOneWidget);
    await tester.tap(find.text('关于我们'));
    await tester.pumpAndSettle();
    expect(find.byType(AboutPage), findsOneWidget);
    expect(find.text('联系我们'), findsOneWidget);
    for (final size in [
      const Size(320, 640),
      const Size(844, 390),
      const Size(1280, 800),
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('特别感谢'),
        150,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      expect(find.text('特别感谢').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    expect(backend.requests, isEmpty);
  });

  testWidgets('联系我们公开加载二维码，保存的是预览中的同一份 PNG', (tester) async {
    Http().setTokens('test-access', 'test-refresh');
    Uint8List? saved;
    messenger.setMockMethodCallHandler(saveChannel, (call) async {
      expect(call.method, 'savePng');
      saved = call.arguments as Uint8List;
      return 'gallery';
    });
    await tester.pumpWidget(const MaterialApp(home: AboutPage()));
    await tester.tap(find.text('联系我们'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(CommunityQrCodeDialog), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.byWidgetPredicate((widget) => widget is FilledButton),
          )
          .onPressed,
      isNull,
    );
    await finishLoadingImage(tester);
    final preview = tester.widget<Image>(
      find.byWidgetPredicate(
        (widget) => widget is Image && widget.semanticLabel == '猫猫图鉴交流群二维码',
      ),
    );
    await tester.tap(find.text('保存图片'));
    await tester.pumpAndSettle();
    expect(saved, (preview.image as MemoryImage).bytes);
    expect(find.text('已保存到相册'), findsOneWidget);
    expect(backend.requests, hasLength(2));
    await tester.tap(find.text('关闭'));
    await tester.pumpAndSettle();
    expect(find.byType(CommunityQrCodeDialog), findsNothing);
  });

  testWidgets('二维码加载失败可重试，保存失败不会关闭预览', (tester) async {
    var metadataRequests = 0;
    backend.respond = (request) {
      if (request.uri.path == '/api/community/group-qrcode') {
        metadataRequests++;
        return FakeHttpResponse(200, {
          'code': 200,
          'data': {
            'qrcodeUrl': metadataRequests == 1
                ? ''
                : 'https://images.example.invalid/group.png',
          },
        });
      }
      return FakeHttpResponse.bytes(200, png);
    };
    messenger.setMockMethodCallHandler(saveChannel, (_) async {
      throw PlatformException(code: 'SAVE_FAILED');
    });
    await tester.pumpWidget(const MaterialApp(home: AboutPage()));
    await tester.tap(find.text('联系我们'));
    await tester.pump(const Duration(milliseconds: 300));
    await finishLoadingImage(tester);
    expect(find.text('二维码加载失败，请重试'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.byWidgetPredicate((widget) => widget is FilledButton),
          )
          .onPressed,
      isNull,
    );
    await tester.tap(find.text('重试'));
    await tester.pump(const Duration(milliseconds: 300));
    await finishLoadingImage(tester);
    await tester.tap(find.text('保存图片'));
    await tester.pumpAndSettle();
    expect(find.text('图片保存失败，请重试'), findsOneWidget);
    expect(find.byType(CommunityQrCodeDialog), findsOneWidget);
    expect(metadataRequests, 2);
    expect(
      tester
          .widget<FilledButton>(
            find.byWidgetPredicate((widget) => widget is FilledButton),
          )
          .onPressed,
      isNotNull,
    );
  });
}
