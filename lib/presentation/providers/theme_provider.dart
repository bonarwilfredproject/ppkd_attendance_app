import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _key = 'dark_mode';

  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadFromPrefs();
  }

  void toggle() {
    _isDarkMode = !_isDarkMode;
    _saveToPrefs();
    notifyListeners();
  }

  // ── shared colors ──────────────────────────────────────────
  static const _accent = Color(0xFF5B7BFF);
  static const _accentLight = Color(0xFF7B9AFF);

  // ── light theme ────────────────────────────────────────────
  ThemeData get lightTheme => ThemeData(
    brightness: Brightness.light,
    primaryColor: _accent,
    scaffoldBackgroundColor: const Color(0xFFF5F5F5),
    colorScheme: const ColorScheme.light(
      primary: _accent,
      secondary: Color(0xFFD4E600),
      surface: Colors.white,
      onSurface: Colors.black87,
      onPrimary: Colors.white,
      outline: Color(0xFFEEEEEE),
    ),
    cardColor: Colors.white,
    dividerColor: const Color(0xFFEEEEEE),
    hintColor: const Color(0xFF999999),
    // ── text theme
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFF222222)),
      bodyMedium: TextStyle(color: Color(0xFF333333)),
      bodySmall: TextStyle(color: Color(0xFF666666)),
      titleLarge: TextStyle(color: Color(0xFF222222)),
      titleMedium: TextStyle(color: Color(0xFF222222)),
      labelLarge: TextStyle(color: Color(0xFF222222)),
    ),
    // ── input fields
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFEEEEEE),
      hintStyle: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 13),
      labelStyle: const TextStyle(color: Color(0xFF888888), fontSize: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _accent, width: 1.5),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    // ── dialogs
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      titleTextStyle: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF222222),
      ),
      contentTextStyle: const TextStyle(fontSize: 14, color: Color(0xFF555555)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    // ── date picker
    datePickerTheme: DatePickerThemeData(
      backgroundColor: Colors.white,
      headerBackgroundColor: _accent,
      headerForegroundColor: Colors.white,
      dayForegroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return Colors.white;
        return const Color(0xFF222222);
      }),
      yearForegroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return Colors.white;
        return const Color(0xFF222222);
      }),
      todayForegroundColor: WidgetStateProperty.all(_accent),
      surfaceTintColor: Colors.transparent,
    ),
    // ── appbar
    appBarTheme: const AppBarTheme(
      backgroundColor: _accent,
      foregroundColor: Colors.white,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFFD4E600),
    ),
    // ── dropdown
    dropdownMenuTheme: DropdownMenuThemeData(
      textStyle: const TextStyle(fontSize: 14, color: Color(0xFF222222)),
    ),
  );

  // ── dark theme ─────────────────────────────────────────────
  ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    primaryColor: _accentLight,
    scaffoldBackgroundColor: const Color(0xFF121212),
    colorScheme: const ColorScheme.dark(
      primary: _accentLight,
      secondary: Color(0xFFB8CC00),
      surface: Color(0xFF1E1E1E),
      onSurface: Color(0xFFE0E0E0),
      onPrimary: Colors.white,
      outline: Color(0xFF2C2C2C),
    ),
    cardColor: const Color(0xFF1E1E1E),
    dividerColor: const Color(0xFF2C2C2C),
    hintColor: const Color(0xFF888888),
    // ── text theme
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFFE0E0E0)),
      bodyMedium: TextStyle(color: Color(0xFFCCCCCC)),
      bodySmall: TextStyle(color: Color(0xFFAAAAAA)),
      titleLarge: TextStyle(color: Color(0xFFE0E0E0)),
      titleMedium: TextStyle(color: Color(0xFFE0E0E0)),
      labelLarge: TextStyle(color: Color(0xFFE0E0E0)),
    ),
    // ── input fields
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2A2A2A),
      hintStyle: const TextStyle(color: Color(0xFF777777), fontSize: 13),
      labelStyle: const TextStyle(color: Color(0xFF999999), fontSize: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _accentLight, width: 1.5),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF3A3A3A)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    // ── dialogs
    dialogTheme: DialogThemeData(
      backgroundColor: const Color(0xFF1E1E1E),
      titleTextStyle: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFFE0E0E0),
      ),
      contentTextStyle: const TextStyle(fontSize: 14, color: Color(0xFFBBBBBB)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    // ── date picker
    datePickerTheme: DatePickerThemeData(
      backgroundColor: const Color(0xFF1E1E1E),
      headerBackgroundColor: const Color(0xFF1A237E),
      headerForegroundColor: Colors.white,
      dayForegroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return Colors.white;
        return const Color(0xFFE0E0E0);
      }),
      yearForegroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return Colors.white;
        return const Color(0xFFE0E0E0);
      }),
      todayForegroundColor: WidgetStateProperty.all(_accentLight),
      surfaceTintColor: Colors.transparent,
      rangePickerBackgroundColor: const Color(0xFF1E1E1E),
      rangePickerHeaderForegroundColor: Colors.white,
      rangePickerHeaderBackgroundColor: const Color(0xFF1A237E),
    ),
    // ── appbar
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1A237E),
      foregroundColor: Colors.white,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1E1E1E),
    ),
    // ── dropdown
    dropdownMenuTheme: DropdownMenuThemeData(
      textStyle: const TextStyle(fontSize: 14, color: Color(0xFFE0E0E0)),
    ),
  );

  ThemeData get currentTheme => _isDarkMode ? darkTheme : lightTheme;

  // ── persistence ────────────────────────────────────────────
  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_key) ?? false;
    notifyListeners();
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, _isDarkMode);
  }
}
