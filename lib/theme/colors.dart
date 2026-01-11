import 'package:flutter/material.dart';

class AppColors {
  // ----------------------------------------
  // 1. NEUTRALS (Tailwind "Gray")
  // Used for: Backgrounds, Text, Borders
  // ----------------------------------------
  static const Color white = Color(0xFFFFFFFF);
  
  static const Color gray50  = Color(0xFFF9FAFB); // Light Mode Background
  static const Color gray100 = Color(0xFFF3F4F6); // Borders / Light Mode Cards
  static const Color gray200 = Color(0xFFE5E7EB); // Borders
  static const Color gray400 = Color(0xFF9CA3AF); // Dark Mode Secondary Text
  static const Color gray500 = Color(0xFF6B7280); // Light Mode Secondary Text
  static const Color gray700 = Color(0xFF374151); // Dark Mode Borders/Inputs
  static const Color gray800 = Color(0xFF1F2937); // Dark Mode Cards/Nav
  static const Color gray900 = Color(0xFF111827); // Dark Mode Background

  // ----------------------------------------
  // 2. PRIMARY BRAND (Tailwind "Emerald")
  // Used for: Brand highlights, Rings, Active states
  // ----------------------------------------
  static const Color primary400 = Color(0xFF34D399); // Dark Mode Brand Text / Active Icons
  static const Color primary500 = Color(0xFF10B981); // Focus Rings / Active Tabs
  static const Color primary600 = Color(0xFF059669); // Light Mode Active Icons
  static const Color primary800 = Color(0xFF065F46); // Light Mode Brand Text

  // ----------------------------------------
  // 3. LIQUIDITY TRAFFIC LIGHT SYSTEM
  // ----------------------------------------

  // A. AVAILABLE (Tailwind "Green")
  static const Color green100 = Color(0xFFDCFCE7); // Light Mode Bg
  static const Color green300 = Color(0xFF86EFAC); // Dark Mode Text
  static const Color green800 = Color(0xFF166534); // Light Mode Text
  static const Color green900 = Color(0xFF14532D); // Dark Mode Bg (needs opacity)

  // B. CROWDED (Tailwind "Yellow")
  static const Color yellow100 = Color(0xFFFEF9C3); // Light Mode Bg
  static const Color yellow300 = Color(0xFFFDE047); // Dark Mode Text
  static const Color yellow800 = Color(0xFF854D0E); // Light Mode Text
  static const Color yellow900 = Color(0xFF713F12); // Dark Mode Bg (needs opacity)

  // C. EMPTY (Tailwind "Red")
  static const Color red100 = Color(0xFFFEE2E2); // Light Mode Bg
  static const Color red300 = Color(0xFFFCA5A5); // Dark Mode Text
  static const Color red800 = Color(0xFF991B1B); // Light Mode Text
  static const Color red900 = Color(0xFF7F1D1D); // Dark Mode Bg (needs opacity)
}
