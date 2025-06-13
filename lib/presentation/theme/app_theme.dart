import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// izForce tema sistemi
class AppTheme {
  AppTheme._();

  // Mevcut renkler
  static const List<Color> availableColors = [
    Color(0xFF00BCD4), // Cyan (varsayılan)
    Color(0xFF4CAF50), // Green
    Color(0xFFF44336), // Red
    Color(0xFFFF9800), // Orange
    Color(0xFF9C27B0), // Purple
    Color(0xFFE91E63), // Pink
  ];

  // Ana renkler
  static const Color primaryColor = Color(0xFF00BCD4); // Cyan
  static const Color accentColor = Color(0xFF4CAF50);  // Green
  static const Color errorColor = Color(0xFFF44336);   // Red
  static const Color warningColor = Color(0xFFFF9800); // Orange
  static const Color successColor = Color(0xFF4CAF50); // Green

  // Dark theme colors
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkCard = Color(0xFF2C2C2C);
  static const Color darkDivider = Color(0xFF3C3C3C);

  // Light theme colors
  static const Color lightBackground = Color(0xFFF5F5F5);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);

  // Background colors
  static const Color backgroundColor = Color(0xFFF5F7FA);
  static const Color secondaryColor = Color(0xFF01579B);

  // Text colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0BEC5);
  static const Color textHint = Color(0xFF616161);

  // 🎯 PROFESSIONAL SPORTS PERFORMANCE COLORS
  // Inspired by Hawkin Dynamics, MyLift, PUSH Band color schemes
  
  // Performance level colors
  static const Color excellentPerformance = Color(0xFF4CAF50);  // Green
  static const Color goodPerformance = Color(0xFF8BC34A);       // Light Green
  static const Color averagePerformance = Color(0xFFFF9800);    // Orange
  static const Color belowAveragePerformance = Color(0xFFFF5722); // Deep Orange
  static const Color poorPerformance = Color(0xFFF44336);       // Red

  // Chart colors for professional appearance
  static const List<Color> professionalChartColors = [
    Color(0xFF00BCD4), // Primary Cyan
    Color(0xFF4CAF50), // Success Green
    Color(0xFFFF9800), // Warning Orange
    Color(0xFFF44336), // Error Red
    Color(0xFF9C27B0), // Purple
    Color(0xFF2196F3), // Blue
    Color(0xFFE91E63), // Pink
    Color(0xFF607D8B), // Blue Grey
  ];

  // Force plate specific colors
  static const Color forcePositive = Color(0xFF4CAF50);   // Green for positive forces
  static const Color forceNegative = Color(0xFFFF5722);   // Orange for negative forces
  static const Color velocityHigh = Color(0xFF2196F3);    // Blue for high velocity
  static const Color velocityLow = Color(0xFF9C27B0);     // Purple for low velocity
  static const Color powerOptimal = Color(0xFF00BCD4);    // Cyan for optimal power
  
  // Status colors for real-time feedback
  static const Color connectionGood = Color(0xFF4CAF50);   // Green
  static const Color connectionWarning = Color(0xFFFF9800); // Orange
  static const Color connectionError = Color(0xFFF44336);   // Red
  
  // Performance zone colors (VBT inspired)
  static const Color strengthZone = Color(0xFFF44336);      // Red (>90% 1RM)
  static const Color powerZone = Color(0xFFFF9800);         // Orange (70-90% 1RM)
  static const Color speedZone = Color(0xFF4CAF50);         // Green (50-70% 1RM)
  static const Color speedStrengthZone = Color(0xFF00BCD4); // Cyan (30-50% 1RM)
  
  /// Seçilen rengi al
  static Color getPrimaryColor(int colorIndex) {
    return availableColors[colorIndex % availableColors.length];
  }

  /// Performance-based color selection (like professional sports apps)
  static Color getPerformanceColor(double normalizedValue) {
    if (normalizedValue >= 0.8) return excellentPerformance;
    if (normalizedValue >= 0.6) return goodPerformance;
    if (normalizedValue >= 0.4) return averagePerformance;
    if (normalizedValue >= 0.2) return belowAveragePerformance;
    return poorPerformance;
  }

  /// Get chart color by index from professional palette
  static Color getChartColor(int index) {
    return professionalChartColors[index % professionalChartColors.length];
  }

  /// Get VBT zone color based on velocity
  static Color getVBTZoneColor(double velocity) {
    if (velocity >= 1.0) return speedZone;           // >1.0 m/s
    if (velocity >= 0.75) return speedStrengthZone;  // 0.75-1.0 m/s
    if (velocity >= 0.5) return powerZone;           // 0.5-0.75 m/s
    return strengthZone;                             // <0.5 m/s
  }

  /// Get connection status color
  static Color getConnectionColor(bool isConnected, bool hasWarning) {
    if (!isConnected) return connectionError;
    if (hasWarning) return connectionWarning;
    return connectionGood;
  }
  

  /// Dark theme (default)
  static ThemeData darkTheme([int colorIndex = 0]) {
    final primaryColor = getPrimaryColor(colorIndex);
    final colorScheme = ColorScheme.dark(
      primary: primaryColor,
      secondary: accentColor,
      error: errorColor,
      surface: darkSurface,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onError: Colors.white,
      onSurface: textPrimary,
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      brightness: Brightness.dark,
      
      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Cards
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // Bottom navigation
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        selectedItemColor: primaryColor,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: BorderSide(color: primaryColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      // Input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor),
        ),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: textHint),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: darkDivider,
        thickness: 1,
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: darkCard,
        selectedColor: primaryColor,
        labelStyle: const TextStyle(color: textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),

      // Progress indicators
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primaryColor,
      ),

      // Slider
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryColor,
        inactiveTrackColor: darkDivider,
        thumbColor: primaryColor,
        overlayColor: primaryColor.withValues(alpha: 0.2),
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor.withValues(alpha: 0.5);
          }
          return darkDivider;
        }),
      ),

      // Text theme
      textTheme: _textTheme,
    );
  }

  /// Light theme
  static ThemeData lightTheme([int colorIndex = 0]) {
    final primaryColor = getPrimaryColor(colorIndex);
    final colorScheme = ColorScheme.light(
      primary: primaryColor,
      secondary: accentColor,
      error: errorColor,
      surface: lightSurface,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onError: Colors.white,
      onSurface: Colors.black87,
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      brightness: Brightness.light,
      
      appBarTheme: const AppBarTheme(
        backgroundColor: lightSurface,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),

      cardTheme: CardThemeData(
        color: lightCard,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      textTheme: _textTheme.apply(
        bodyColor: Colors.black87,
        displayColor: Colors.black87,
      ),
    );
  }

  /// Text theme
  static const TextTheme _textTheme = TextTheme(
    displayLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      letterSpacing: -0.5,
    ),
    displayMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      letterSpacing: -0.25,
    ),
    displaySmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w600,
    ),
    headlineLarge: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w600,
    ),
    headlineMedium: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
    ),
    headlineSmall: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
    ),
    titleLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
    titleMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),
    titleSmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.normal,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.normal,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.normal,
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
    ),
    labelSmall: TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w500,
    ),
  );
}

/// Özel renkler
class AppColors {
  AppColors._();

  // Force plate specific colors
  static const Color leftPlatform = Color(0xFF2196F3);   // Blue
  static const Color rightPlatform = Color(0xFFFF5722);  // Deep Orange
  static const Color totalForce = Color(0xFF9C27B0);     // Purple

  // Phase colors
  static const Color quietStanding = Color(0xFF607D8B);  // Blue Grey
  static const Color unloading = Color(0xFFFF9800);      // Orange
  static const Color braking = Color(0xFFF44336);        // Red
  static const Color propulsion = Color(0xFF4CAF50);     // Green
  static const Color flight = Color(0xFF2196F3);         // Blue
  static const Color landing = Color(0xFF9C27B0);        // Purple

  // Metric quality colors
  static const Color excellent = Color(0xFF4CAF50);      // Green
  static const Color good = Color(0xFF8BC34A);           // Light Green
  static const Color average = Color(0xFFFF9800);        // Orange
  static const Color poor = Color(0xFFF44336);           // Red

  // Chart colors - Professional sports performance palette
  static const List<Color> chartColors = [
    Color(0xFF2196F3), // Blue
    Color(0xFFFF5722), // Deep Orange
    Color(0xFF4CAF50), // Green
    Color(0xFF9C27B0), // Purple
    Color(0xFFFF9800), // Orange
    Color(0xFF607D8B), // Blue Grey
    Color(0xFFE91E63), // Pink
    Color(0xFF795548), // Brown
  ];

  // Enhanced chart colors for better readability and professionalism
  static const List<Color> professionalChartColors = [
    Color(0xFF00BCD4), // Primary Cyan
    Color(0xFF4CAF50), // Success Green
    Color(0xFFFF9800), // Warning Orange
    Color(0xFFF44336), // Error Red
    Color(0xFF9C27B0), // Purple
    Color(0xFF2196F3), // Blue
    Color(0xFFE91E63), // Pink
    Color(0xFF607D8B), // Blue Grey
  ];

  // Performance level colors (inspired by Hawkin Dynamics)
  static const Color excellentPerformance = Color(0xFF4CAF50);  // Green
  static const Color goodPerformance = Color(0xFF8BC34A);       // Light Green
  static const Color averagePerformance = Color(0xFFFF9800);    // Orange
  static const Color belowAveragePerformance = Color(0xFFFF5722); // Deep Orange
  static const Color poorPerformance = Color(0xFFF44336);       // Red

  // Gradient colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00BCD4), Color(0xFF0097A7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF4CAF50), Color(0xFF388E3C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient errorGradient = LinearGradient(
    colors: [Color(0xFFF44336), Color(0xFFD32F2F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Text stilleri
class AppTextStyles {
  AppTextStyles._();

  // Metric değerleri için
  static const TextStyle metricValue = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    fontFamily: 'RobotoMono',
  );

  static const TextStyle metricUnit = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppTheme.textSecondary,
  );

  // Chart labels
  static const TextStyle chartLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  // Platform labels
  static const TextStyle platformLabel = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.2,
  );

  // Test instructions
  static const TextStyle instruction = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    height: 1.5,
  );

  // Phase indicators
  static const TextStyle phaseText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );
}

/// Animation curves
class AppAnimations {
  AppAnimations._();

  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);

  static const Curve easeIn = Curves.easeIn;
  static const Curve easeOut = Curves.easeOut;
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve bounce = Curves.bounceOut;
}

/// Spacing values
class AppSpacing {
  AppSpacing._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

/// Border radius values
class AppRadius {
  AppRadius._();

  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double circle = 999.0;
}