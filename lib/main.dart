import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

import 'app.dart';
import 'core/database/database_helper.dart';
import 'core/utils/app_logger.dart';
import 'presentation/controllers/test_controller.dart';
import 'presentation/controllers/athlete_controller.dart';

/// izForce - Türkiye'nin özgün Force Plate analiz uygulaması
/// VALD ForceDecks ve Hawkin Dynamics'i geçen gelişmiş metrikler
/// 
/// Geliştirici: Türk mühendislik ekibi
/// Platform: Flutter Android
/// Hardware: 2 plaka, 8 load cell, USB dongle
void main() async {
  // Flutter binding'lerini başlat
  WidgetsFlutterBinding.ensureInitialized();

  // System UI ayarları (Türkçe uygulama için)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF1E1E1E),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Sadece portrait mode'da çalışsın
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Uygulama başlatma işlemleri
  await _initializeApp();

  // izForce uygulamasını başlat
  runApp(const IzForceApp());
}

/// Uygulama başlatma işlemlerini gerçekleştir
Future<void> _initializeApp() async {
  try {
    AppLogger.info('🚀 izForce uygulaması başlatılıyor...');

    // 1. Logger'ı başlat
    await _initializeLogger();
    
    // 2. Database'leri başlat
    await _initializeDatabases();
    
    // 3. GetX controller'larını başlat
    await _initializeControllers();
    
    // 4. Mock data'yı yükle (geliştirme aşaması)
    await _loadMockData();

    AppLogger.success('✅ izForce başarıyla başlatıldı!');
    
  } catch (e, stackTrace) {
    AppLogger.error('❌ Uygulama başlatma hatası: $e', stackTrace);
    
    // Kritik hata durumunda basit fallback
    runApp(
      MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.red,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.white, size: 64),
                const SizedBox(height: 16),
                const Text(
                  'izForce Başlatma Hatası',
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
                const SizedBox(height: 8),
                Text(
                  'Hata: $e',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Logger sistemini başlat
Future<void> _initializeLogger() async {
  try {
    AppLogger.initialize();
    AppLogger.info('📝 Logger sistemi başlatıldı');
  } catch (e) {
    debugPrint('Logger başlatma hatası: $e');
  }
}

/// Database sistemlerini başlat (SQLite + Hive)
Future<void> _initializeDatabases() async {
  try {
    AppLogger.info('🗄️  Database sistemleri başlatılıyor...');
    
    // Hive database'i başlat
    await Hive.initFlutter();
    
    // SQLite database'i başlat
    await DatabaseHelper.instance.initialize();
    
    // Database migration'ları çalıştır
    await DatabaseHelper.instance.runMigrations();
    
    AppLogger.success('✅ Database sistemleri hazır');
    
  } catch (e, stackTrace) {
    AppLogger.error('❌ Database başlatma hatası: $e', stackTrace);
    rethrow;
  }
}

/// GetX controller'larını dependency injection ile başlat
Future<void> _initializeControllers() async {
  try {
    AppLogger.info('🎮 Controllerlar başlatılıyor...');
    
    // Test Controller - Ana iş mantığı
    Get.put(TestController(), permanent: true);
    
    // Athlete Controller - Sporcu yönetimi
    Get.put(AthleteController(), permanent: true);
    
    AppLogger.success('✅ Controllerlar hazır');
    
  } catch (e, stackTrace) {
    AppLogger.error('❌ Controller başlatma hatası: $e', stackTrace);
    rethrow;
  }
}

/// Mock data'yı yükle (geliştirme aşaması için)
Future<void> _loadMockData() async {
  try {
    AppLogger.info('🎭 Mock data yükleniyor...');
    
    // Athlete Controller'dan mock data'yı yükle
    final athleteController = Get.find<AthleteController>();
    await athleteController.loadMockAthletes();
    
    // Test Controller'ı mock mode'a al
    final testController = Get.find<TestController>();
    testController.enableMockMode();
    
    AppLogger.success('✅ Mock data hazır (${athleteController.athletes.length} sporcu)');
    
  } catch (e, stackTrace) {
    AppLogger.warning('⚠️  Mock data yükleme hatası: $e', stackTrace);
    // Mock data hatası kritik değil, devam et
  }
}

/// Uygulama kapatılırken temizlik işlemleri
class AppLifecycleManager extends WidgetsBindingObserver {
  static final AppLifecycleManager _instance = AppLifecycleManager._internal();
  factory AppLifecycleManager() => _instance;
  AppLifecycleManager._internal();

  void initialize() {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        AppLogger.info('📱 Uygulama durakladı');
        _saveApplicationState();
        break;
      case AppLifecycleState.resumed:
        AppLogger.info('📱 Uygulama devam etti');
        _restoreApplicationState();
        break;
      case AppLifecycleState.detached:
        AppLogger.info('📱 Uygulama kapandı');
        _cleanupResources();
        break;
      default:
        break;
    }
  }

  /// Uygulama durumunu kaydet
  void _saveApplicationState() {
    try {
      // Test sürdürülüyorsa duraklat
      if (Get.isRegistered<TestController>()) {
        final testController = Get.find<TestController>();
        testController.pauseIfRunning();
      }
      
      AppLogger.info('💾 Uygulama durumu kaydedildi');
    } catch (e) {
      AppLogger.error('Durum kaydetme hatası: $e');
    }
  }

  /// Uygulama durumunu geri yükle
  void _restoreApplicationState() {
    try {
      // Test duraklayıp duraklatılmışsa devam et
      if (Get.isRegistered<TestController>()) {
        final testController = Get.find<TestController>();
        testController.resumeIfPaused();
      }
      
      AppLogger.info('📂 Uygulama durumu geri yüklendi');
    } catch (e) {
      AppLogger.error('Durum geri yükleme hatası: $e');
    }
  }

  /// Kaynakları temizle
  void _cleanupResources() {
    try {
      // Aktif testleri durdur
      if (Get.isRegistered<TestController>()) {
        final testController = Get.find<TestController>();
        testController.stopAllTests();
      }
      
      // Database bağlantılarını kapat
      DatabaseHelper.instance.close();
      
      // Hive box'larını kapat
      Hive.close();
      
      AppLogger.info('🧹 Kaynaklar temizlendi');
    } catch (e) {
      AppLogger.error('Kaynak temizleme hatası: $e');
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }
}

/// Uygulama başlatma durumu kontrol widget'ı
class AppInitializationWrapper extends StatefulWidget {
  final Widget child;
  
  const AppInitializationWrapper({
    super.key,
    required this.child,
  });

  @override
  State<AppInitializationWrapper> createState() => _AppInitializationWrapperState();
}

class _AppInitializationWrapperState extends State<AppInitializationWrapper> {
  bool _isInitialized = false;
  String _initializationError = '';

  @override
  void initState() {
    super.initState();
    _checkInitialization();
  }

  void _checkInitialization() {
    try {
      // Controller'ların hazır olup olmadığını kontrol et
      final testController = Get.find<TestController>();
      final athleteController = Get.find<AthleteController>();
      
      if (testController.isInitialized && athleteController.isInitialized) {
        setState(() {
          _isInitialized = true;
        });
      } else {
        // 100ms sonra tekrar kontrol et
        Future.delayed(const Duration(milliseconds: 100), _checkInitialization);
      }
    } catch (e) {
      setState(() {
        _initializationError = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_initializationError.isNotEmpty) {
      return _buildErrorScreen();
    }
    
    if (!_isInitialized) {
      return _buildLoadingScreen();
    }
    
    return widget.child;
  }

  Widget _buildLoadingScreen() {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF1E1E1E),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // izForce Logo
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFF00BCD4),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.analytics,
                  color: Colors.white,
                  size: 64,
                ),
              ),
              const SizedBox(height: 32),
              
              // Başlık
              const Text(
                'izForce',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              
              // Alt başlık
              const Text(
                'Force Plate Analiz Sistemi',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 48),
              
              // Loading indicator
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00BCD4)),
              ),
              const SizedBox(height: 16),
              
              const Text(
                'Sistem başlatılıyor...',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.red.shade900,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 64),
                const SizedBox(height: 24),
                const Text(
                  'Başlatma Hatası',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _initializationError,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    // Uygulamayı yeniden başlat
                    setState(() {
                      _initializationError = '';
                      _isInitialized = false;
                    });
                    _checkInitialization();
                  },
                  child: const Text('Tekrar Dene'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}