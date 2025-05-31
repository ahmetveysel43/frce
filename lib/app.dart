import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'presentation/theme/app_theme.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/athlete_selection_screen.dart';
import 'presentation/screens/test_selection_screen.dart';
import 'presentation/screens/test_execution_screen.dart';
import 'presentation/screens/results_screen.dart';
import 'core/constants/app_constants.dart';

/// izForce - Ana uygulama widget'ı
/// GetX router ve theme management ile
class IzForceApp extends StatelessWidget {
  const IzForceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      // Uygulama bilgileri
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      
      // Tema ayarları
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark, // izForce default olarak dark theme
      
      // Dil ve lokalizasyon
      locale: const Locale('tr', 'TR'), // Türkçe default
      fallbackLocale: const Locale('en', 'US'),
      supportedLocales: const [
        Locale('tr', 'TR'), // Türkçe
        Locale('en', 'US'), // İngilizce
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      
      // Çeviri dosyaları (GetX translations)
      translations: IzForceTranslations(),
      
      // Route yönetimi
      initialRoute: AppRoutes.home,
      getPages: AppRoutes.pages,
      
      // Global ayarlar
      defaultTransition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 300),
      
      // Error handling
      unknownRoute: GetPage(
        name: '/not-found',
        page: () => const NotFoundScreen(),
      ),
      
      // App lifecycle
      builder: (context, child) {
        return MediaQuery(
          // Text scaling'i sınırla (force plate kullanımı için)
          data: MediaQuery.of(context).copyWith(
            textScaleFactor: 1.0, // Sabit text boyutu
          ),
          child: child!,
        );
      },
    );
  }
}

/// izForce çeviri sistemi
class IzForceTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    // Türkçe
    'tr_TR': {
      // Ana menü
      'app_name': 'izForce',
      'home': 'Ana Sayfa',
      'athletes': 'Sporcular',
      'tests': 'Testler',
      'results': 'Sonuçlar',
      'settings': 'Ayarlar',
      
      // Test kategorileri
      'jump_tests': 'Sıçrama Testleri',
      'strength_tests': 'Kuvvet Testleri',
      'balance_tests': 'Denge Testleri',
      'agility_tests': 'Çeviklik Testleri',
      
      // Test türleri
      'cmj': 'Karşı Hareket Sıçrama',
      'squat_jump': 'Çömelme Sıçraması',
      'drop_jump': 'Düşme Sıçraması',
      'imtp': 'İzometrik Orta Uyluk Çekişi',
      
      // Butonlar
      'start': 'Başla',
      'stop': 'Durdur',
      'pause': 'Duraklat',
      'resume': 'Devam Et',
      'save': 'Kaydet',
      'cancel': 'İptal',
      'next': 'İleri',
      'back': 'Geri',
      'finish': 'Bitir',
      
      // Durumlar
      'connecting': 'Bağlanıyor...',
      'connected': 'Bağlandı',
      'disconnected': 'Bağlantı Kesildi',
      'ready': 'Hazır',
      'testing': 'Test Ediliyor',
      'completed': 'Tamamlandı',
      'error': 'Hata',
      
      // Metrikler
      'jump_height': 'Sıçrama Yüksekliği',
      'peak_force': 'Tepe Kuvvet',
      'average_force': 'Ortalama Kuvvet',
      'rfd': 'Kuvvet Gelişim Hızı',
      'asymmetry': 'Asimetri',
      'contact_time': 'Temas Süresi',
      'flight_time': 'Uçuş Süresi',
      
      // Birimler
      'cm': 'cm',
      'kg': 'kg',
      'n': 'N',
      'ms': 'ms',
      'percent': '%',
      'n_per_s': 'N/s',
      
      // Mesajlar
      'select_athlete': 'Sporcu Seçin',
      'select_test': 'Test Türü Seçin',
      'stand_on_platform': 'Platformlara Çıkın',
      'hold_still': 'Sabit Durun',
      'prepare_for_test': 'Test İçin Hazırlanın',
      'test_completed': 'Test Tamamlandı',
      
      // Hatalar
      'connection_failed': 'Bağlantı Başarısız',
      'test_failed': 'Test Başarısız',
      'save_failed': 'Kaydetme Başarısız',
      'no_data': 'Veri Bulunamadı',
    },
    
    // İngilizce
    'en_US': {
      // Main menu
      'app_name': 'izForce',
      'home': 'Home',
      'athletes': 'Athletes',
      'tests': 'Tests',
      'results': 'Results',
      'settings': 'Settings',
      
      // Test categories
      'jump_tests': 'Jump Tests',
      'strength_tests': 'Strength Tests',
      'balance_tests': 'Balance Tests',
      'agility_tests': 'Agility Tests',
      
      // Test types
      'cmj': 'Countermovement Jump',
      'squat_jump': 'Squat Jump',
      'drop_jump': 'Drop Jump',
      'imtp': 'Isometric Mid-Thigh Pull',
      
      // Buttons
      'start': 'Start',
      'stop': 'Stop',
      'pause': 'Pause',
      'resume': 'Resume',
      'save': 'Save',
      'cancel': 'Cancel',
      'next': 'Next',
      'back': 'Back',
      'finish': 'Finish',
      
      // States
      'connecting': 'Connecting...',
      'connected': 'Connected',
      'disconnected': 'Disconnected',
      'ready': 'Ready',
      'testing': 'Testing',
      'completed': 'Completed',
      'error': 'Error',
      
      // Metrics
      'jump_height': 'Jump Height',
      'peak_force': 'Peak Force',
      'average_force': 'Average Force',
      'rfd': 'Rate of Force Development',
      'asymmetry': 'Asymmetry',
      'contact_time': 'Contact Time',
      'flight_time': 'Flight Time',
      
      // Units
      'cm': 'cm',
      'kg': 'kg',
      'n': 'N',
      'ms': 'ms',
      'percent': '%',
      'n_per_s': 'N/s',
      
      // Messages
      'select_athlete': 'Select Athlete',
      'select_test': 'Select Test Type',
      'stand_on_platform': 'Stand on Platform',
      'hold_still': 'Hold Still',
      'prepare_for_test': 'Prepare for Test',
      'test_completed': 'Test Completed',
      
      // Errors
      'connection_failed': 'Connection Failed',
      'test_failed': 'Test Failed',
      'save_failed': 'Save Failed',
      'no_data': 'No Data Found',
    },
  };
}

/// izForce route yönetimi
class AppRoutes {
  static const String home = '/';
  static const String athleteSelection = '/athlete-selection';
  static const String testSelection = '/test-selection';
  static const String testExecution = '/test-execution';
  static const String results = '/results';
  static const String settings = '/settings';
  
  static List<GetPage> get pages => [
    // Ana sayfa
    GetPage(
      name: home,
      page: () => const HomeScreen(),
      transition: Transition.fadeIn,
    ),
    
    // Sporcu seçimi
    GetPage(
      name: athleteSelection,
      page: () => const AthleteSelectionScreen(),
      transition: Transition.rightToLeft,
    ),
    
    // Test seçimi
    GetPage(
      name: testSelection,
      page: () => const TestSelectionScreen(),
      transition: Transition.rightToLeft,
    ),
    
    // Test execution
    GetPage(
      name: testExecution,
      page: () => const TestExecutionScreen(),
      transition: Transition.downToUp,
      fullscreenDialog: true, // Tam ekran modal
    ),
    
    // Results
    GetPage(
      name: results,
      page: () => const ResultsScreen(),
      transition: Transition.rightToLeft,
    ),
  ];
}

/// 404 Not Found ekranı
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Get.theme.scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 404 Icon
            Icon(
              Icons.error_outline,
              size: 120,
              color: Get.theme.primaryColor,
            ),
            const SizedBox(height: 24),
            
            // Başlık
            Text(
              '404',
              style: Get.textTheme.displayLarge?.copyWith(
                color: Get.theme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            // Açıklama
            Text(
              'Sayfa Bulunamadı',
              style: Get.textTheme.headlineSmall?.copyWith(
                color: Get.theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            
            Text(
              'Aradığınız sayfa mevcut değil.',
              style: Get.textTheme.bodyMedium?.copyWith(
                color: Get.theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 48),
            
            // Ana sayfaya dön butonu
            ElevatedButton.icon(
              onPressed: () => Get.offAllNamed(AppRoutes.home),
              icon: const Icon(Icons.home),
              label: const Text('Ana Sayfaya Dön'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Global snackbar helper'ları
class IzForceSnackbar {
  /// Başarı mesajı
  static void success(String message) {
    Get.snackbar(
      'Başarılı',
      message,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      icon: const Icon(Icons.check_circle, color: Colors.white),
      duration: const Duration(seconds: 3),
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }
  
  /// Hata mesajı
  static void error(String message) {
    Get.snackbar(
      'Hata',
      message,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      icon: const Icon(Icons.error, color: Colors.white),
      duration: const Duration(seconds: 5),
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }
  
  /// Uyarı mesajı
  static void warning(String message) {
    Get.snackbar(
      'Uyarı',
      message,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
      icon: const Icon(Icons.warning, color: Colors.white),
      duration: const Duration(seconds: 4),
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }
  
  /// Bilgi mesajı
  static void info(String message) {
    Get.snackbar(
      'Bilgi',
      message,
      backgroundColor: Get.theme.primaryColor,
      colorText: Colors.white,
      icon: const Icon(Icons.info, color: Colors.white),
      duration: const Duration(seconds: 3),
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }
}

/// Global dialog helper'ları
class IzForceDialog {
  /// Onay dialogu
  static Future<bool> confirm({
    required String title,
    required String message,
    String? confirmText,
    String? cancelText,
  }) async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(cancelText ?? 'İptal'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            child: Text(confirmText ?? 'Onayla'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
  
  /// Loading dialogu
  static void showLoading({String? message}) {
    Get.dialog(
      AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(message),
            ],
          ],
        ),
      ),
      barrierDismissible: false,
    );
  }
  
  /// Loading'i kapat
  static void hideLoading() {
    if (Get.isDialogOpen == true) {
      Get.back();
    }
  }
}

/// Global extension'lar
extension IzForceContext on BuildContext {
  /// Theme shortcuts
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
  
  /// MediaQuery shortcuts
  Size get screenSize => MediaQuery.of(this).size;
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  EdgeInsets get padding => MediaQuery.of(this).padding;
  EdgeInsets get viewInsets => MediaQuery.of(this).viewInsets;
  
  /// Navigation shortcuts
  void pop<T>([T? result]) => Navigator.of(this).pop(result);
  Future<T?> push<T>(Widget page) => Navigator.of(this).push(
    MaterialPageRoute(builder: (_) => page),
  );
}

/// Responsive helper
class ResponsiveHelper {
  static bool isPhone(BuildContext context) => context.screenWidth < 600;
  static bool isTablet(BuildContext context) => 
      context.screenWidth >= 600 && context.screenWidth < 1200;
  static bool isDesktop(BuildContext context) => context.screenWidth >= 1200;
  
  static T responsive<T>(
    BuildContext context, {
    required T phone,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context) && desktop != null) return desktop;
    if (isTablet(context) && tablet != null) return tablet;
    return phone;
  }
}