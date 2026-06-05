import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const Color headerNav = Color(0xFFEAE0CE);
  static const Color bodyBg = Color(0xFFF2EDE4);
  static const Color cardSurface = Color(0xFFFAF6F0);
  static const Color accent = Color(0xFFD4BFA0);
  static const Color iconInactive = Color(0xFF8C6A45);
  static const Color textPrimary = Color(0xFF4A3220);
  static const Color textSecondary = Color(0xFF8C6A45);
  static const Color border = Color(0xFFD4BFA0);

  static const Color darkHeaderNav = Color(0xFF352A21);
  static const Color darkBodyBg = Color(0xFF211A15);
  static const Color darkCardSurface = Color(0xFF2D241D);
  static const Color darkAccent = Color(0xFFC4A987);
  static const Color darkIconInactive = Color(0xFFD4BFA0);
  static const Color darkTextPrimary = Color(0xFFF3E7D8);
  static const Color darkTextSecondary = Color(0xFFD4BFA0);
  static const Color darkBorder = Color(0xFF5B4635);

  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static Color headerNavFor(BuildContext context) {
    return isDark(context) ? darkHeaderNav : headerNav;
  }

  static Color bodyBgFor(BuildContext context) {
    return isDark(context) ? darkBodyBg : bodyBg;
  }

  static Color cardSurfaceFor(BuildContext context) {
    return isDark(context) ? darkCardSurface : cardSurface;
  }

  static Color accentFor(BuildContext context) {
    return isDark(context) ? darkAccent : accent;
  }

  static Color iconInactiveFor(BuildContext context) {
    return isDark(context) ? darkIconInactive : iconInactive;
  }

  static Color textPrimaryFor(BuildContext context) {
    return isDark(context) ? darkTextPrimary : textPrimary;
  }

  static Color textSecondaryFor(BuildContext context) {
    return isDark(context) ? darkTextSecondary : textSecondary;
  }

  static Color borderFor(BuildContext context) {
    return isDark(context) ? darkBorder : border;
  }
}
