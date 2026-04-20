import 'package:flutter/material.dart';
import 'package:billing_app/core/data/hive_database.dart';

/// Central accent color configuration for the app.
/// Read/write from the Hive settings box.
class AppColorConfig {
  static const String _key = 'accent_color';

  // Default accent color
  static const Color _defaultColor = Color(0xFF6C63FF);

  static const List<Color> palette = [
    Color(0xFF6C63FF), // Indigo
    Color(0xFF2196F3), // Blue
    Color(0xFF009688), // Teal
    Color(0xFF4CAF50), // Green
    Color(0xFFFF5722), // Deep Orange
    Color(0xFFE91E63), // Pink
    Color(0xFF9C27B0), // Purple
    Color(0xFFFF9800), // Orange
    Color(0xFF607D8B), // Blue Grey
    Color(0xFF000000), // Black
  ];

  /// Returns the current accent color from Hive (falls back to default).
  static Color get accentColor {
    final saved = HiveDatabase.settingsBox.get(_key) as int?;
    return saved != null ? Color(saved) : _defaultColor;
  }

  /// Persists the accent color to Hive.
  static Future<void> setAccentColor(Color color) async {
    await HiveDatabase.settingsBox.put(_key, color.toARGB32());
  }
}
