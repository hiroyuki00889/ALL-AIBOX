/** Hiveを使用するためのパッケージをインポート */
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';



/** Hiveのボックス名を定義する定数クラス */
class HiveBoxNames {
  static const String authBox = 'authBox';
  static const String chatBox = 'chatBox';
  static const String settingsBox = 'settingsBox';
}

/** Hiveを使用したストレージサービスの実装クラス */
class HiveService {
  static final HiveService _instance = HiveService._internal();   //シングルトンインスタンス
  List<String> currentQuestions = [];                             //現在の質問リストを保持するフィールド

  /** ファクトリーコンストラクタ - シングルトンインスタンスを返す */
  factory HiveService() {
    return _instance;
  }

  /** プライベートコンストラクタ */
  HiveService._internal();

  /** Hiveの初期化を行う
   * FlutterのHiveを初期化し、一時保存用のボックスを開く
   */
  Future<void> initHive() async {
    await Hive.initFlutter();
    // Open boxes
    await Hive.openBox(HiveBoxNames.authBox);
    await Hive.openBox(HiveBoxNames.chatBox);
    await Hive.openBox(HiveBoxNames.settingsBox);
  }








/*
  /** 一時データを保存する
   * @param questions 質問リスト
   * @param question 現在の質問
   */
  Future<void> saveQuestionsData(List<String> questions, String question) async {
    final box = Hive.box(HiveBoxNames.tempStorage);
    await box.put('questions', questions);
    await box.put('question', question);
  }

  /**　質問と選択した文章を保存する
   * @param newKey　質問文
   * @param newValue　選んだ文章
   */
  Future<void> saveQuestionsAndChoices(String newKey, String newValue) async {
    // Boxを開く
    final box = Hive.box(HiveBoxNames.mapStringStorage);

    // 既存のデータを取得
    Map<String, String> existingData = box.get('questionsAndChoices') ?? {};

    // 新しいデータを追加
    existingData[newKey] = newValue;

    // 更新して保存
    await box.put('questionsAndChoices', existingData);
  }

  /**　質問と選択した文章を取得する
   *
   */
  Map<String, String> getQuestionsAndChoices() {
    final box = Hive.box(HiveBoxNames.mapStringStorage);
    var data = box.get('questionsAndChoices');

    if (data is Map<dynamic, dynamic>) {
      return data!.map((key, value) => MapEntry(key.toString(), value.toString()));
    }
    // すべてのデータを取得
    return {};
  }

  /** 保存された質問リストを取得する
   * @return 質問のリスト。データがない場合は空のリストを返す
   */
  List<String> getQuestions() {
    final box = Hive.box(HiveBoxNames.tempStorage);
    return box.get('questions', defaultValue: <String>[]);
  }

  /** 現在の質問を取得する
   * @return 現在の質問。データがない場合は空文字列を返す
   */
  String getQuestion() {
    final box = Hive.box(HiveBoxNames.tempStorage);
    return box.get('question', defaultValue: '');
  }

  /** 一時データをすべてクリアする
   * 現在の質問リストとボックス内のすべてのデータを削除する
   */
  Future<void> clearAllData() async {
    final box = Hive.box(HiveBoxNames.tempStorage);
    final box2 = Hive.box(HiveBoxNames.mapStringStorage);
    currentQuestions = [];
    await box.clear();
    await box2.clear();
    print('データを消去した');
  }


  Future<void> DeleteChoices() async {
    final box = Hive.box(HiveBoxNames.mapStringStorage);
    if (box.containsKey('choices')) {
      await box.delete('choices');
    }
  }

 */
}