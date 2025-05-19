import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'dart:math' as math;
import '../models/chat_message.dart';

class ClaudeApiService {
  // APIのエンドポイントとキー
  final apiUrl = Uri.parse('https://api.anthropic.com/v1/messages');
  final String apiKey;

  final String model = 'claude-3-7-sonnet-20250219';

  // コンストラクタでAPIキーを初期化
  ClaudeApiService() : apiKey = dotenv.env['API_KEY'] ?? ''{
    // デバッグ用（本番環境では削除すること）
    print("APIKEY:"+apiKey);
    print('API Key: ${apiKey.isNotEmpty ? "設定されています" : "空です"}');
    if (apiKey.isEmpty) {
      print('警告: API キーが設定されていません。.env ファイルを確認してください。');
    }
  }

  Future<bool> checkInternetConnection() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    return connectivityResult != ConnectivityResult.none;
  }

  // 会話の状況に応じて適切なプロンプトを選択する関数
  String selectAppropriatePrompt(String latestMessage, List<Map<String, dynamic>> history) {
    // 会話の分析ロジック
    bool isSerious = analyzeIfSerious(latestMessage, history);
    bool isSeekingAdvice = analyzeIfSeekingAdvice(latestMessage, history);
    bool isCasualConversation = analyzeIfCasualConversation(latestMessage, history);

    // 条件に基づいてプロンプトを選択
    if (isSerious) {
      return "あなたは共感的なカウンセラーです。深刻な悩みを抱えるユーザーに対して、まず話をよく聞き、急かさず、否定せず、安全な空間を提供してください。具体的なアドバイスよりも傾聴を優先してください。";
    } else if (isSeekingAdvice) {
      return "あなたは問題解決を手伝うアドバイザーです。ユーザーの悩みに対して、具体的で実行可能な提案を提供してください。可能な選択肢とそれぞれのメリット・デメリットを示し、ユーザー自身が意思決定できるよう支援してください。";
    } else if (isCasualConversation) {
      return "あなたは友好的な会話パートナーです。自然な対話の流れを維持し、ユーザーの話題に興味を示してください。会話を広げる質問をし、適切な場所で自分の見解も共有してください。";
    } else {
      // デフォルトのプロンプト
      return "あなたは親切なアシスタントです。ユーザーの状況に合わせて適切なサポートを提供してください。";
    }
  }

  // メッセージが深刻な内容かを分析
  bool analyzeIfSerious(String message, List<Map<String, dynamic>> history) {
    // 深刻な内容を示すキーワードや表現のリスト
    List<String> seriousKeywords = ['苦しい', '辛い', '死にたい', '絶望', '助けて', '悲しい', '不安'];

    // メッセージ内にキーワードが含まれているか確認
    for (var keyword in seriousKeywords) {
      if (message.toLowerCase().contains(keyword)) {
        return true;
      }
    }

    // 必要に応じて会話の文脈も分析（例：短い返答が続く、否定的な表現が多いなど）
    // ...

    return false;
  }

  // アドバイスを求めているかを分析
  bool analyzeIfSeekingAdvice(String message, List<Map<String, dynamic>> history) {
    // アドバイスを求める表現のリスト
    List<String> adviceKeywords = ['どうすれば', 'アドバイス', '助言', '教えて', '解決策', 'どうしたら'];

    for (var keyword in adviceKeywords) {
      if (message.toLowerCase().contains(keyword)) {
        return true;
      }
    }

    // 質問形式かどうかも確認
    if (message.endsWith('?') || message.endsWith('？')) {
      return true;
    }

    return false;
  }

  // カジュアルな会話かを分析
  bool analyzeIfCasualConversation(String message, List<Map<String, dynamic>> history) {
    // 会話を続けようとする表現
    List<String> conversationalKeywords = ['そうなんだ', 'へー', 'なるほど', 'どう思う', '話そう'];

    for (var keyword in conversationalKeywords) {
      if (message.toLowerCase().contains(keyword)) {
        return true;
      }
    }

    // 短いメッセージが続いている場合も会話モードと判断
    if (message.split(' ').length < 5 && history.isNotEmpty) {
      int shortMessageCount = 0;
      for (int i = history.length - 1; i >= math.max(0, history.length - 3); i--) {
        if (history[i]['role'] == 'user' &&
            history[i]['content'].toString().split(' ').length < 5) {
          shortMessageCount++;
        }
      }
      if (shortMessageCount >= 2) return true;
    }

    return false;
  }

  // claude_chat_providerのsendMessage()の途中から
  Future<String> sendMessage(String message, List<Map<String, dynamic>> history) async {
    try {
      // 状況に応じたプロンプトを選択
      String appropriatePrompt = selectAppropriatePrompt(message, history);

      //　リクエストのヘッダー設定
      final Map<String, String> headers = {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
      };

      // リクエストボディの構築
      final body = jsonEncode({
        'model' : model,
        'system' : appropriatePrompt,
        'messages' : [
          ...history, // 過去のメッセージ履歴
          {'role' : 'user', 'content' : message}, // 新しいユーザーメッセージ
        ],
        'max_tokens' : 8000,
      });

      // HTTP POSTリクエストの送信
      final response = await http.post(
        apiUrl,
        headers: headers,
        body: body,
      );
      // デバック用
      print('レスポンスコード: ${response.statusCode}');
      print('レスポンスボディ: ${response.body}');  // センシティブ情報に注意

      // レスポンスの処理
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['content'][0]['text'];
      } else {
        // エラーハンドリング
        throw Exception('APIリクエスト失敗: ${response.statusCode} ${response.body}');
      }
    } catch (e, stackTrace) {
      print('エラーの詳細: $e');
      print('スタックトレース: $stackTrace');
      // 例外処理
      throw Exception('メッセージ送信中にエラー発生： $e');
    }
  }
}