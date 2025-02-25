import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:test_flutter4/Hive.dart';
import 'Result.dart';
import 'package:mermaid/mermaid.dart'as mermaid;
import 'package:flutter_svg/flutter_svg.dart';

/**　
 *
 */
class ProcessDiagramScreen extends StatefulWidget {
  final String advice;
  const ProcessDiagramScreen({super.key, required this.advice});
  @override
  _ProcessDiagramScreen createState() => _ProcessDiagramScreen();
}

/**　
 *
 */
class _ProcessDiagramScreen extends State<ProcessDiagramScreen> {
  // Hiveデータベースサービスのインスタンス
  final hiveService = HiveService();
  // ユーザー入力と質問関連の状態変数
  String firstWorry = '';              // 最初に入力された悩み
  Map<String, String> questionsAndChoices = {};    //質問と選択肢リストから選んだ文章のセットの変数

  // UI状態管理用の変数
  bool isLoading = false;              // ローディング状態
  String errorMessage = '';            // エラーメッセージ
  String adviceText = '';             // Claudeからのアドバイステキスト
  String? mermaidDiagram;             // Mermaidダイアグラムのコードを保存
  bool isDiagramReady = false;        // ダイアグラムの準備状態

  /**
   * ウィジェットの初期化時に実行される処理
   * データの読み込みとClaude APIの呼び出しを行う
   */
  @override
  void initState() {
    super.initState();
    _loadData();
    Future.microtask(() => callClaude());
  }

  /**
   * Hiveデータベースから保存されているデータを読み込む
   * 質問、悩み、要約などの情報を取得してステート変数を更新する
   */
  void _loadData() {
    setState(() {
      questionsAndChoices = hiveService.getQuestionsAndChoices();
      firstWorry = hiveService.getFirstWorry();
    });
  }

  /** インターネット接続を確認する
   * @return インターネットに接続されているかどうか
   */
  Future<bool> checkInternetConnection() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    return connectivityResult != ConnectivityResult.none;
  }

  /**
   * Claude APIを呼び出してアドバイスを生成する非同期関数
   * APIキーの検証、リクエストの作成、レスポンスの処理を行う
   * エラーハンドリングとローディング状態の管理も実装
   */
  Future<void> callClaude() async {
    // 既に処理中の場合は早期リターン
    if (isLoading) return;

    //　インターネット接続確認
    if (!await checkInternetConnection()) {
      setState(() {
        errorMessage = 'インターネット接続がありません。接続を確認してください。';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      print('Calling Claude API...'); // デバッグログ

      // 環境変数からAPIキーを取得
      final apikey = dotenv.env['API_KEY'];
      if (apikey == null) {
        throw Exception('API_KEY not found in .env file');
      }

      // APIエンドポイントの設定
      final url = Uri.parse('https://api.anthropic.com/v1/messages');
      print('API Key loaded successfully'); // デバッグログ

      // プロンプトの構築
      final prompt = '''
#前提条件:
- タイトル: 悩み・問題解決のタイムフロー図作成プロンプト
- 依頼者条件: 自分の悩みや問題を明確にし、解決策を見つけたい人。
- 制作者条件: 問題解決のプロセスを視覚的に表現するスキルを持つ人
- 目的と目標: 悩みや問題を段階的に整理し、解決策を明確にするためのタイムフロー図を作成すること。

#変数設定
最初の悩みポスト="$firstWorry"
今までの質問と答え="$questionsAndChoices"

#この内容を実行してください
{最初の悩みポスト}と{今までの質問と答え}から悩み・問題解決のタイムフロー図をMermaid形式で生成してください。
生成する文章に変数名を出さないでください。

''';

      // リクエストボディの準備
      print('Preparing request body...'); // デバッグログ
      final body = jsonEncode({
        "model": "claude-3-5-sonnet-20240620",
        "max_tokens": 8096,
        "messages": [
          {"role": "user", "content": prompt}
        ],
      });

      // APIリクエストの送信
      print('Sending request to Claude API...'); // デバッグログ
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apikey,
          'anthropic-version': '2023-06-01'
        },
        body: body,
      );

      // レスポンスの処理
      print('Response received. Status code: ${response.statusCode}'); // デバッグログ
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data['content'] != null && data['content'].isNotEmpty) {
          String responseText = data['content'][0]['text'] ?? '';

          // Mermaidダイアグラムのコードを抽出
          final RegExp mermaidRegex = RegExp(
            r'```mermaid\n([\s\S]*?)\n```',
            multiLine: true,
          );

          final match = mermaidRegex.firstMatch(responseText);
          if (match != null) {
            setState(() {
              mermaidDiagram = match.group(1)?.trim();
              isDiagramReady = true;
              adviceText = responseText.replaceAll(match.group(0) ?? '', '').trim();
            });
          } else {
            setState(() {
              adviceText = responseText;
              errorMessage = 'ダイアグラムの生成に失敗しました。';
            });
          }
        }
      }
    } catch (e, stackTrace) {
      // エラーハンドリング
      print('Error in callClaude: $e'); // デバッグログ
      print('Stack trace: $stackTrace');
    } finally {
      // 処理完了後のクリーンアップ
      setState(() {
        isLoading = false;
      });
      print('API call completed'); // デバッグログ
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '悩み・相談解決くん：タイムフロー図',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isLoading)
              Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('タイムフロー図を生成中...'),
                  ],
                ),
              ),

            if (errorMessage.isNotEmpty)
              Container(
                padding: EdgeInsets.all(16),
                color: Colors.red.shade100,
                child: Text(
                  errorMessage,
                  style: TextStyle(color: Colors.red),
                ),
              ),

            if (isDiagramReady && mermaidDiagram != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'タイムフロー図',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    // Mermaidダイアグラムを表示
                    child: mermaid.Mermaid(
                      code: mermaidDiagram!,
                    ),
                  ),
                ],
              ),

            if (adviceText.isNotEmpty) ...[
              SizedBox(height: 24),
              Text(
                '解説',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              SizedBox(height: 16),
              Text(adviceText),
            ],
          ],
        ),
      ),
    );
  }
}