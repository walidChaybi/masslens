import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';

abstract final class NutritionColors {
  static const canvas = AppColors.canvas;
  static const surface = AppColors.surface;
  static const surfaceHigh = AppColors.navySoft;
  static const text = AppColors.ink;
  static const muted = AppColors.inkMuted;
  static const protein = AppColors.aqua;
  static const carbs = Color(0xFFE39B2A);
  static const fat = AppColors.coral;
  static const amber = Color(0xFFC98412);
  static const cta = AppColors.ink;
  static const onCta = Colors.white;
  static const line = AppColors.line;
}

const SystemUiOverlayStyle nutritionSystemUiOverlayStyle =
    appSystemUiOverlayStyle;
