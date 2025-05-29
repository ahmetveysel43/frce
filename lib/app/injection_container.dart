// lib/app/injection_container.dart - Düzeltilmiş
import 'package:get_it/get_it.dart';
import '../data/repositories_impl/athlete_repository_impl.dart';
import '../data/repositories_impl/usb_repository_impl.dart';
import '../domain/repositories/athlete_repository.dart';
import '../data/repositories/usb_repository.dart';
import '../domain/usecases/manage_athlete_usecase.dart';
import '../domain/usecases/calculate_metrics_usecase.dart';
import '../presentation/controllers/athlete_controller.dart';
import '../presentation/controllers/test_controller.dart';
import '../presentation/controllers/usb_controller.dart';
import '../app/app_controller.dart';

final GetIt sl = GetIt.instance;

Future<void> initializeDependencies() async {
  _debugPrint('🔧 Starting dependency initialization...');
  
  try {
    // ✅ Clear existing registrations to avoid conflicts
    if (sl.isRegistered<AthleteRepository>()) {
      await sl.reset();
    }
    
    // Repositories - Singleton
    sl.registerLazySingleton<AthleteRepository>(
      () => AthleteRepositoryImpl(),
    );
    
    sl.registerLazySingleton<UsbRepository>(
      () => UsbRepositoryImpl(),
    );

    // Use Cases - Singleton
    sl.registerLazySingleton<ManageAthleteUseCase>(
      () => ManageAthleteUseCase(sl<AthleteRepository>()),
    );
    
    sl.registerLazySingleton<CalculateMetricsUseCase>(
      () => const CalculateMetricsUseCase(),
    );

    // Controllers - Singleton (Global state için)
    sl.registerLazySingleton<AppController>(
      () => AppController(sl<AthleteRepository>()),
    );
    
    // ✅ UsbController - Singleton (Global USB state)
    sl.registerLazySingleton<UsbController>(
      () => UsbController(),
    );
    
    // ✅ AthleteController - Factory (Her kullanımda yeni instance)
    sl.registerFactory<AthleteController>(
      () => AthleteController(sl<ManageAthleteUseCase>()),
    );
    
    sl.registerFactory<TestController>(
      () => TestController(sl<CalculateMetricsUseCase>()),
    );

    // Initialize repositories with mock data
    await _initializeRepositories();

    _debugPrint('✅ Dependency initialization completed successfully');
  } catch (e, stackTrace) {
    _debugPrint('❌ Failed to initialize dependencies: $e');
    _debugPrint('Stack trace: $stackTrace');
    rethrow;
  }
}

Future<void> _initializeRepositories() async {
  try {
    // Initialize mock data for athlete repository
    final athleteRepo = sl<AthleteRepository>();
    if (athleteRepo is AthleteRepositoryImpl) {
      await athleteRepo.addMockData();
      _debugPrint('✅ Mock athlete data initialized');
    }

    // Initialize USB controller
    final usbController = sl<UsbController>();
    await usbController.initialize();
    _debugPrint('✅ USB controller initialized');
    
  } catch (e) {
    _debugPrint('❌ Repository initialization error: $e');
    rethrow;
  }
}

void _debugPrint(String message) {
  // ignore: avoid_print
  print('[IzForce] $message');
}

// ✅ Reset dependencies for testing (optional)
Future<void> resetDependencies() async {
  _debugPrint('🔄 Resetting dependencies...');
  await sl.reset();
}

// ✅ Check registration status (optional)
void checkRegistrations() {
  _debugPrint('📋 Checking registrations:');
  _debugPrint('  - AthleteRepository: ${sl.isRegistered<AthleteRepository>()}');
  _debugPrint('  - UsbRepository: ${sl.isRegistered<UsbRepository>()}');
  _debugPrint('  - AppController: ${sl.isRegistered<AppController>()}');
  _debugPrint('  - UsbController: ${sl.isRegistered<UsbController>()}');
  _debugPrint('  - AthleteController: ${sl.isRegistered<AthleteController>()}');
}