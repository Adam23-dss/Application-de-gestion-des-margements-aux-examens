// lib/core/theme/colors.dart
import 'package:flutter/material.dart';

class AppColors {
  // Couleurs primaires (bleu universitaire)
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryVariant = Color(0xFF1D4ED8);
  static const Color secondary = Color(0xFF7C3AED);
  static const Color tertiary = Color(0xFF0EA5E9);
  
  // Couleurs de statut
  static const Color success = Color(0xFF10B981);  // Vert présence
  static const Color warning = Color(0xFFF59E0B);  // Orange retard
  static const Color error = Color(0xFFEF4444);    // Rouge absence
  static const Color info = Color(0xFF3B82F6);     // Bleu information
  
  // Couleurs neutres
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF1E293B);
  static const Color outline = Color(0xFFE2E8F0);
  
  // Couleurs texte
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textDisabled = Color(0xFF94A3B8);
  
  // Couleurs pour dark mode
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkOnSurface = Color(0xFFF1F5F9);
  
  // Couleurs spécifiques aux statuts de présence
  static const Color presentLight = Color(0xFFD1FAE5);
  static const Color presentDark = Color(0xFF047857);
  static const Color absentLight = Color(0xFFFEE2E2);
  static const Color absentDark = Color(0xFFB91C1C);
  static const Color lateLight = Color(0xFFFEF3C7);
  static const Color lateDark = Color(0xFFD97706);
  
  // Gradients
  static LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryVariant],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}