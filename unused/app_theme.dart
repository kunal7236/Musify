// import 'package:flutter/material.dart';
// import '../constants/app_colors.dart';
// import '../constants/app_constants.dart';

// /// Centralized theme configuration for the Musify app
// /// Provides consistent styling across the application
// class AppTheme {
//   // Private constructor to prevent instantiation
//   AppTheme._();

//   /// Light theme data
//   static ThemeData get lightTheme {
//     return ThemeData(
//       useMaterial3: true,
//       brightness: Brightness.light,
//       primaryColor: AppColors.primary,
//       scaffoldBackgroundColor: AppColors.backgroundPrimary,
//       colorScheme: ColorScheme.fromSeed(
//         seedColor: AppColors.accent,
//         brightness: Brightness.light,
//       ),
//       appBarTheme: _appBarTheme,
//       elevatedButtonTheme: _elevatedButtonTheme,
//       cardTheme: _cardTheme,
//       inputDecorationTheme: _inputDecorationTheme,
//       textTheme: _textTheme,
//     );
//   }

//   /// Dark theme data
//   static ThemeData get darkTheme {
//     return ThemeData(
//       useMaterial3: true,
//       brightness: Brightness.dark,
//       primaryColor: AppColors.primary,
//       scaffoldBackgroundColor: AppColors.backgroundPrimary,
//       colorScheme: ColorScheme.fromSeed(
//         seedColor: AppColors.accent,
//         brightness: Brightness.dark,
//       ),
//       appBarTheme: _appBarTheme,
//       elevatedButtonTheme: _elevatedButtonTheme,
//       cardTheme: _cardTheme,
//       inputDecorationTheme: _inputDecorationTheme,
//       textTheme: _textTheme,
//     );
//   }

//   /// App bar theme
//   static AppBarTheme get _appBarTheme {
//     return const AppBarTheme(
//       backgroundColor: Colors.transparent,
//       elevation: 0,
//       centerTitle: true,
//       titleTextStyle: TextStyle(
//         color: AppColors.textPrimary,
//         fontSize: 20,
//         fontWeight: FontWeight.w600,
//       ),
//       iconTheme: IconThemeData(
//         color: AppColors.iconPrimary,
//       ),
//     );
//   }

//   /// Elevated button theme
//   static ElevatedButtonThemeData get _elevatedButtonTheme {
//     return ElevatedButtonThemeData(
//       style: ElevatedButton.styleFrom(
//         backgroundColor: AppColors.cardBackground,
//         foregroundColor: AppColors.accent,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
//         ),
//         padding: const EdgeInsets.symmetric(
//           horizontal: AppConstants.largePadding,
//           vertical: AppConstants.defaultPadding,
//         ),
//       ),
//     );
//   }

//   /// Card theme
//   static CardThemeData get _cardTheme {
//     return CardThemeData(
//       color: AppColors.cardBackground,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
//       ),
//       elevation: 2,
//     );
//   }

//   /// Input decoration theme
//   static InputDecorationTheme get _inputDecorationTheme {
//     return InputDecorationTheme(
//       fillColor: AppColors.backgroundSecondary,
//       filled: true,
//       border: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(AppConstants.borderRadius),
//         borderSide: BorderSide.none,
//       ),
//       hintStyle: const TextStyle(
//         color: AppColors.textSecondary,
//       ),
//     );
//   }

//   /// Text theme
//   static TextTheme get _textTheme {
//     return const TextTheme(
//       displayLarge: TextStyle(
//         color: AppColors.textPrimary,
//         fontSize: 32,
//         fontWeight: FontWeight.bold,
//       ),
//       displayMedium: TextStyle(
//         color: AppColors.textPrimary,
//         fontSize: 28,
//         fontWeight: FontWeight.w600,
//       ),
//       displaySmall: TextStyle(
//         color: AppColors.textPrimary,
//         fontSize: 24,
//         fontWeight: FontWeight.w500,
//       ),
//       headlineLarge: TextStyle(
//         color: AppColors.textPrimary,
//         fontSize: 22,
//         fontWeight: FontWeight.w600,
//       ),
//       headlineMedium: TextStyle(
//         color: AppColors.textPrimary,
//         fontSize: 20,
//         fontWeight: FontWeight.w500,
//       ),
//       headlineSmall: TextStyle(
//         color: AppColors.textPrimary,
//         fontSize: 18,
//         fontWeight: FontWeight.w500,
//       ),
//       titleLarge: TextStyle(
//         color: AppColors.textPrimary,
//         fontSize: 16,
//         fontWeight: FontWeight.w600,
//       ),
//       titleMedium: TextStyle(
//         color: AppColors.textPrimary,
//         fontSize: 14,
//         fontWeight: FontWeight.w500,
//       ),
//       titleSmall: TextStyle(
//         color: AppColors.textPrimary,
//         fontSize: 12,
//         fontWeight: FontWeight.w500,
//       ),
//       bodyLarge: TextStyle(
//         color: AppColors.textPrimary,
//         fontSize: 16,
//       ),
//       bodyMedium: TextStyle(
//         color: AppColors.textPrimary,
//         fontSize: 14,
//       ),
//       bodySmall: TextStyle(
//         color: AppColors.textSecondary,
//         fontSize: 12,
//       ),
//     );
//   }
// }
