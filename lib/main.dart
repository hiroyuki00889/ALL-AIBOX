import 'package:flutter/material.dart';
import 'package:test_flutter4/presentation/screens/auth/splash_screen.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/router.dart';
import 'data/services/claude_api_service.dart';
import 'logic/providers/auth_provider.dart';
import 'logic/providers/claude_chat_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Hiveを使うなら必要、フレームワークとFlutterエンジン機能を結びつける
  //Flutter Engineの機能とは、プラットフォーム (Android, iOSなど) の画面の向きの設定やロケールなどです
  await Hive.initFlutter();               // Hiveローカルストレージを初期化
  await Firebase.initializeApp();         // Firebase初期化
  await dotenv.load(fileName:".env");     // dotenvを初期化
  // HiveBoxを開く
  await Hive.openBox('authBox');
  await Hive.openBox('chatBox');

  runApp(
    MultiProvider(
        providers: [
          // 先に依存関係となるサービスを提供
          Provider<ClaudeApiService>(
            create: (_) => ClaudeApiService(),
          ),
          // ClaudeChatProviderの作成（ClaudeApiServiceに依存）
          ChangeNotifierProvider(
              create: (context) => ClaudeChatProvider(
                context.read<ClaudeApiService>(),
              ),
          ),
        ],
    child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),

      ],
      child: MaterialApp.router(
        title: 'YOURBUDDY',
        theme: ThemeData(
          primaryColor: Colors.green,
          colorScheme: ColorScheme.fromSwatch().copyWith(
            secondary: Colors.yellowAccent[100],
          ),
          scaffoldBackgroundColor: Colors.white,
        ),
        debugShowCheckedModeBanner: false,
        routerConfig: appRouter,
      ),
    );
  }
}



