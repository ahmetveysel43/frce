// lib/data/repositories_impl/usb_repository_impl.dart
import 'package:izforce/core/services/mock_usb_service.dart';
import 'package:izforce/data/repositories/usb_repository.dart';
import '../../domain/entities/force_data.dart';
import '../../core/errors/failures.dart';
import '../../domain/repositories/athlete_repository.dart'; // Either için

class UsbRepositoryImpl implements UsbRepository {
  final MockUsbService _mockUsbService = MockUsbService();

  @override
  Future<Either<Failure, bool>> initialize() async {
    try {
      final result = await _mockUsbService.initialize();
      return Right(result);
    } catch (e) {
      return Left(DataProcessingFailure('USB initialization failed: $e'));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getAvailableDevices() async {
    try {
      final devices = await _mockUsbService.getAvailableDevices();
      return Right(devices);
    } catch (e) {
      return Left(DataProcessingFailure('Failed to get devices: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> connectToDevice(String deviceId) async {
    try {
      final result = await _mockUsbService.connectToDevice(deviceId);
      return Right(result);
    } catch (e) {
      return Left(DataProcessingFailure('Failed to connect: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> disconnect() async {
    try {
      await _mockUsbService.disconnect();
      return const Right(null);
    } catch (e) {
      return Left(DataProcessingFailure('Failed to disconnect: $e'));
    }
  }

  @override
  Stream<ForceData>? get realTimeDataStream => _mockUsbService.forceDataStream;

  @override
  bool get isConnected => _mockUsbService.isConnected;
}