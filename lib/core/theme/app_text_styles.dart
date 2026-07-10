import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static const TextStyle titlePrimary = TextStyle(
    color: AppColors.primary,
    fontSize: 22,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle titleSecondary = TextStyle(
    color: AppColors.secondary,
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle bodyRegular = TextStyle(
    color: AppColors.secondary,
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle bodyMedium = TextStyle(
    color: AppColors.secondary,
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle hintStyle = TextStyle(
    color: AppColors.hint,
    fontSize: 14,
  );

  static const TextStyle showStyle = TextStyle(
    color: AppColors.show,
    fontSize: 14,
  );

  static const TextStyle buttonTextStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle textLink = TextStyle(
    color: AppColors.primary,
    fontWeight: FontWeight.bold,
  );
}
