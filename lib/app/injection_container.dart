// lib/app/injection_container.dart - USB dependencies eklenmesi
import 'package:get_it/get_it.dart';
import 'package:izforce/data/repositories/usb_repository.dart';
import 'package:izforce/presentation/usb_controller.dart';
import '../data/repositories_impl/athlete_repository_impl.dart';
import '../data/repositories_impl/usb_repository_impl.dart'; // ✅ Yeni eklendi
import '../domain/repositories/athlete_repository.dart';
import '../domain/usecases/manage_athlete_usecase.dart';
import '../domain/usecases/calculate_metrics_usecase.dart';
import '../presentation/controllers/athlete_controller.dart';
import '../presentation/controllers/test_controller.dart';
import '../app/app_controller.dart';

final GetIt sl = GetIt.instance;

Future<void> initializeDependencies() async {
  debugPrint('🔧 Initializing dependencies...');
  
  try {
    // Repositories
    sl.registerLazySingleton<AthleteRepository>(
      () => AthleteRepositoryImpl(),
    );
    
    // ✅ USB Repository eklendi
    sl.registerLazySingleton<UsbRepository>(
      () => UsbRepositoryImpl(),
    );

    // Use Cases
    sl.registerLazySingleton<ManageAthleteUseCase>(
      () => ManageAthleteUseCase(sl<AthleteRepository>()),
    );
    
    sl.registerLazySingleton<CalculateMetricsUseCase>(
      () => const CalculateMetricsUseCase(),
    );

    // Controllers
    sl.registerLazySingleton<AthleteController>(
      () => AthleteController(sl<ManageAthleteUseCase>()),
    );
    
    sl.registerLazySingleton<TestController>(
      () => TestController(sl<CalculateMetricsUseCase>()),
    );
    
    // ✅ USB Controller eklendi
    sl.registerLazySingleton<UsbController>(
      () => UsbController(sl<UsbRepository>()),
    );
    
    sl.registerLazySingleton<AppController>(
      () => AppController(sl<AthleteRepository>()),
    );

    // Initialize mock data
    final athleteRepo = sl<AthleteRepository>();
    if (athleteRepo is AthleteRepositoryImpl) {
      await athleteRepo.addMockData();
    }

    // ✅ USB Initialize
    final usbController = sl<UsbController>();
    await usbController.initializeUsb();

    debugPrint('✅ Dependencies initialized successfully');
  } catch (e, stackTrace) {
    debugPrint('❌ Failed to initialize dependencies: $e');
    debugPrint('Stack trace: $stackTrace');
    rethrow;
  }
}

void debugPrint(String message) {
  // ignore: avoid_print
  print('[IzForce] $message');
}