import 'package:shared_preferences/shared_preferences.dart';

class ViewModePrefs {
  static const _key = 'isGridMode';

  static Future<void> saveIsGrid(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }

  static Future<bool> loadIsGrid() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false; // 기본값: 리스트 보기
  }
}
