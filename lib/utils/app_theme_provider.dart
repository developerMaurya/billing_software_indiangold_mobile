import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppTheme with ChangeNotifier {
  static const String _themeKey = 'app_theme_color';
  String _currentThemeName = 'Green';

  // Define Theme Colors Map
  final Map<String, ThemeColors> _themes = {
    'Green': ThemeColors(
      primary: Colors.green,
      secondary: Colors.green.shade700,
      background: Colors.grey.shade50,
      cardColor: Colors.white,
      textColor: Colors.black87,
      headingColor: Colors.green.shade900,
    ),
    'Blue': ThemeColors(
      primary: Colors.blue,
      secondary: Colors.blue.shade800,
      background: Colors.blue.shade50,
      cardColor: Colors.white,
      textColor: Colors.blueGrey.shade900,
      headingColor: Colors.blue.shade900,
    ),
    'Sky': ThemeColors(
      primary: Colors.lightBlue,
      secondary: Colors.lightBlue.shade700,
      background: Colors.lightBlue.shade50,
      cardColor: Colors.white,
      textColor: Colors.black87,
      headingColor: Colors.lightBlue.shade900,
    ),
    'Warm': ThemeColors(
      primary: Colors.orange,
      secondary: Colors.deepOrange,
      background: Colors.orange.shade50,
      cardColor: Colors.white,
      textColor: Colors.brown.shade900,
      headingColor: Colors.deepOrange.shade900,
    ),
    'Brown': ThemeColors(
      primary: Colors.brown,
      secondary: Colors.brown.shade700,
      background: Colors.brown.shade50,
      cardColor: Colors.white,
      textColor: Colors.brown.shade900,
      headingColor: Colors.brown.shade900,
    ),
    'Black': ThemeColors(
      primary: Colors.black87,
      secondary: Colors.black,
      background: Colors.grey.shade200,
      cardColor: Colors.white,
      textColor: Colors.black,
      headingColor: Colors.black,
    ),
    'White': ThemeColors(
      primary: Colors.grey,
      secondary: Colors.grey.shade700,
      background: Colors.white,
      cardColor: Colors.grey.shade50,
      textColor: Colors.black87,
      headingColor: Colors.black54,
    ),
  };

  AppTheme() {
    _loadTheme();
  }

  ThemeColors get colors => _themes[_currentThemeName]!;
  String get currentTheme => _currentThemeName;
  List<String> get availableThemes => _themes.keys.toList();

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _currentThemeName = prefs.getString(_themeKey) ?? 'Green';
    notifyListeners();
  }

  Future<void> setTheme(String themeName) async {
    if (_themes.containsKey(themeName)) {
      _currentThemeName = themeName;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, themeName);
      notifyListeners();
    }
  }

  // Get MaterialColor from Color (Helper)
  MaterialColor getMaterialColor() {
    return _createMaterialColor(colors.primary);
  }

  MaterialColor _createMaterialColor(Color color) {
    List strengths = <double>[.05];
    Map<int, Color> swatch = {};
    final int r = color.red, g = color.green, b = color.blue;

    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }
    for (var strength in strengths) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }
    return MaterialColor(color.value, swatch);
  }
}

class ThemeColors {
  final Color primary;
  final Color secondary;
  final Color background;
  final Color cardColor;
  final Color textColor;
  final Color headingColor;

  ThemeColors({
    required this.primary,
    required this.secondary,
    required this.background,
    required this.cardColor,
    required this.textColor,
    required this.headingColor,
  });
}
