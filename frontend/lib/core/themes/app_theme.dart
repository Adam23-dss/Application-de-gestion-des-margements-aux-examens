import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  // 🎯 Spacing
  static const double paddingSmall = 8;
  static const double paddingMedium = 16;
  static const double paddingLarge = 24;

  static const double marginSmall = 8;
  static const double marginMedium = 16;
  static const double marginLarge = 24;

  // 🎨 Text styles
  static TextStyle subtitleStyle = const TextStyle(
    fontSize: 14,
    color: AppColors.textSecondary,
  );

  // 🎯 ThemeData
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
    ),
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: AppColors.primary,
  );

  // 🟢 Status helpers
  static Color getStatusColor(String status) {
    switch (status) {
      case 'present':
        return AppColors.success;
      case 'absent':
        return AppColors.error;
      case 'late':
        return AppColors.warning;
      case 'excused':
        return AppColors.info;
      default:
        return AppColors.textSecondary;
    }
  }

  static IconData getStatusIcon(String status) {
    switch (status) {
      case 'present':
        return Icons.check_circle;
      case 'absent':
        return Icons.cancel;
      case 'late':
        return Icons.access_time;
      case 'excused':
        return Icons.info;
      default:
        return Icons.help;
    }
  }
}
