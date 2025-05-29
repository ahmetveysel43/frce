import 'dart:developer' as dev;
import 'injection_container.dart';

class AppInitializer {
  static bool _isInitialized = false;
  
  static bool get isInitialized => _isInitialized;

  static Future<void> initialize() async {
    try {
      dev.log('🚀 Starting app initialization...');
      
      // Initialize dependencies
      await initializeDependencies();
      
      _isInitialized = true;
      dev.log('✅ App initialization completed successfully');
      
    } catch (error, stackTrace) {
      dev.log('❌ App initialization failed: $error');
      dev.log('Stack trace: $stackTrace');
      _isInitialized = false;
      rethrow;
    }
  }

  static void handleError(Object error, StackTrace stackTrace) {
    dev.log('💥 App Error: $error');
    dev.log('Stack trace: $stackTrace');
  }
}