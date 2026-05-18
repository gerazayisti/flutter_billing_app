import 'package:flutter/material.dart';
import 'package:billing_app/core/data/hive_database.dart';
import 'app_theme.dart';

/// Couleur d'accent de l'application — fixée à la palette violette.
/// La clé Hive est conservée pour compatibilité, mais seules les
/// nuances de violet sont proposées dans les Paramètres.
class AppColorConfig {
  static const String _key = 'accent_color';

  static const Color _defaultColor = AppTheme.primaryColor;

  /// Nuances de violet proposées dans les Paramètres → apparence.
  static const List<Color> palette = [
    Color(0xFF6C63FF), // Violet (défaut)
    Color(0xFF4B44CC), // Violet foncé
    Color(0xFF8B7FF5), // Violet clair
    Color(0xFF9C27B0), // Indigo-Violet
    Color(0xFF000000), // Noir
  ];

  static Color get accentColor {
    final saved = HiveDatabase.settingsBox.get(_key) as int?;
    if (saved == null) return _defaultColor;
    final c = Color(saved);
    // Si une ancienne couleur non-violette était sauvegardée, ignorer.
    return palette.contains(c) ? c : _defaultColor;
  }

  static Future<void> setAccentColor(Color color) async {
    await HiveDatabase.settingsBox.put(_key, color.toARGB32());
  }
}
