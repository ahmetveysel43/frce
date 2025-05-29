// lib/app/injection_container.dart
import 'package:get_it/get_it.dart';
import '../data/repositories_impl/athlete_repository_impl.dart';
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
    
    sl.registerLazySingleton<AppController>(
      () => AppController(sl<AthleteRepository>()),
    );

    // Initialize mock data
    final athleteRepo = sl<AthleteRepository>();
    if (athleteRepo is AthleteRepositoryImpl) {
      await athleteRepo.addMockData();
    }

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