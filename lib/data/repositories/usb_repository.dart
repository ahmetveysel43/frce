// lib/domain/repositories/usb_repository.dart
import 'package:izforce/domain/entities/force_data.dart';
import 'package:izforce/domain/repositories/athlete_repository.dart';
import '../../core/errors/failures.dart';


abstract class UsbRepository {
  Future<Either<Failure, bool>> initialize();
  Future<Either<Failure, List<String>>> getAvailableDevices();
  Future<Either<Failure, bool>> connectToDevice(String deviceId);
  Future<Either<Failure, void>> disconnect();
  Stream<ForceData>? get realTimeDataStream;
  bool get isConnected;
}