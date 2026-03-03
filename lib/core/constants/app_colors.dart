import 'package:flutter/material.dart';

class AppColors {
  // Primary branding (Professional Slate/Blue to fit a corporate vibe)
  static const Color primary = Color(0xFF1E3A8A); // Deep Blue
  static const Color secondary = Color(0xFF3B82F6); // Lighter Blue

  // Backgrounds & Surfaces
  static const Color background = Color(0xFFF8FAFC); // Very light grey/blue
  static const Color surface = Colors.white; // Card backgrounds

  // Text Colors
  static const Color textPrimary = Color(0xFF0F172A); // Almost black
  static const Color textSecondary = Color(0xFF64748B); // Slate grey

  // Status Colors (Crucial for an invoicing app)
  static const Color success = Color(0xFF10B981); // Paid (Green)
  static const Color warning = Color(
    0xFFF59E0B,
  ); // Pending/Partially Paid (Orange)
  static const Color error = Color(0xFFEF4444); // Overdue (Red)

  // Borders and Dividers
  static const Color border = Color(0xFFE2E8F0);
}
