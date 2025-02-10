/** Hiveを使用するためのパッケージをインポート */
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';



/** Hiveのボックス名を定義する定数クラス */
class HiveBoxNames {
  static const String tempStorage = 'tempStorage';
  static const String mapStringStorage = 'mapStringStorage';
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
  @override
  Future<void> initHive() async {
    await Hive.initFlutter();
    //既にボックスが空いてる状態で開かないようにする
    if (!Hive.isBoxOpen(HiveBoxNames.tempStorage)) {
      await Hive.openBox(HiveBoxNames.tempStorage);
    }
    if (!Hive.isBoxOpen(HiveBoxNames.mapStringStorage)) {
      await Hive.openBox(HiveBoxNames.mapStringStorage);
    }
  }

  /** 一時データを保存する
   * @param questions 質問リスト
   * @param question 現在の質問
   */
  @override
  Future<void> saveQuestionsData(List<String> questions, String question) async {
    final box = Hive.box(HiveBoxNames.tempStorage);
    await box.put('questions', questions);
    await box.put('question', question);
  }

  /**　質問と選択した文章を保存する
   * @param newKey　質問文
   * @param newValue　選んだ文章
   */
  @override
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
  @override
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
  @override
  List<String> getQuestions() {
    final box = Hive.box(HiveBoxNames.tempStorage);
    return box.get('questions', defaultValue: <String>[]);
  }

  /** 現在の質問を取得する
   * @return 現在の質問。データがない場合は空文字列を返す
   */
  @override
  String getQuestion() {
    final box = Hive.box(HiveBoxNames.tempStorage);
    return box.get('question', defaultValue: '');
  }

  /** 最初の心配事を保存する
   * @param firstWorry 保存する最初の心配事
   */
  @override
  Future<void> saveFirstWorry(String firstWorry) async {
    final box = Hive.box(HiveBoxNames.tempStorage);
    await box.put('firstWorry', firstWorry);
  }

  /** 最初の心配事を取得する
   * @return 最初の心配事。データがない場合は空文字列を返す
   */
  @override
  String getFirstWorry() {
    final box = Hive.box(HiveBoxNames.tempStorage);
    return box.get('firstWorry', defaultValue: '');
  }

  /** 入力された心配事を取得する
   * @return 入力された心配事。データがない場合は空文字列を返す
   */
  @override
  String getWorryInput() {
    final box = Hive.box(HiveBoxNames.tempStorage);
    return box.get('input', defaultValue: '');
  }

  /** 一時データをすべてクリアする
   * 現在の質問リストとボックス内のすべてのデータを削除する
   */
  @override
  Future<void> clearAllData() async {
    final box = Hive.box(HiveBoxNames.tempStorage);
    final box2 = Hive.box(HiveBoxNames.mapStringStorage);
    currentQuestions = [];
    await box.clear();
    await box2.clear();
    print('データを消去した');
  }

  /** ステージ番号と質問数を保存する
   * @param stageNumber 現在のステージ番号
   * @param questionCount 質問数
   */
  @override
  Future<void> saveStageNumber(int stageNumber, int questionCount) async {
    final box = Hive.box(HiveBoxNames.tempStorage);
    await box.put('stageNumber', stageNumber);
    await box.put('questionCount', questionCount);
  }

  /** ステージ番号を取得する
   * @return 現在のステージ番号。データがない場合は0を返す
   */
  @override
  int getStageNumber() {
    final box = Hive.box(HiveBoxNames.tempStorage);
    return box.get('stageNumber', defaultValue: 0);
  }

  /** 質問数を取得する
   * @return 現在の質問数。データがない場合は0を返す
   */
  @override
  int getQuestionCount() {
    final box = Hive.box(HiveBoxNames.tempStorage);
    return box.get('questionCount', defaultValue: 0);
  }

  /**　選んだ選択肢を保存する
   * 　@param choice 選択肢の文章
   */
  @override
  Future<void> saveChoice(String choice) async{
    final box = Hive.box(HiveBoxNames.tempStorage);
    await box.put('choice', choice);
  }

  /**　選んだ選択肢を取得する
   * 　@return choice 選択肢の文章
   */
  @override
  String getChoice(){
    final box = Hive.box(HiveBoxNames.tempStorage);
    return box.get('choice', defaultValue: '');
  }

  /**　生成した選択肢を表示するために保存する
   * 　@param choices　生成した選択肢の文章たち
   */
  @override
  Future<void> saveChoices(List<String> choices) async {
    final box = Hive.box(HiveBoxNames.tempStorage);
    await box.put('choices', choices);
  }

  /**　生成した選択肢を表示するために取得する
   * 　@return　保存された選択肢の文章たち
   */
  @override
  List<String> getChoices() {
    final box = Hive.box(HiveBoxNames.tempStorage);
    return box.get('choices', defaultValue: <String>[]);
  }

  @override
  Future<void> DeleteChoices() async {
    final box = Hive.box(HiveBoxNames.mapStringStorage);
    if (box.containsKey('choices')) {
      await box.delete('choices');
    }
  }
}