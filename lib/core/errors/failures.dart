import 'package:equatable/equatable.dart';

/// Base failure class for error handling
abstract class Failure extends Equatable {
  final String message;
  final String? code;

  const Failure(this.message, {this.code});

  @override
  List<Object?> get props => [message, code];
}

/// Bluetooth related failures
class BluetoothFailure extends Failure {
  const BluetoothFailure(super.message, {super.code});
}

/// Data processing related failures
class DataProcessingFailure extends Failure {
  const DataProcessingFailure(super.message, {super.code});
}

/// Calibration related failures
class CalibrationFailure extends Failure {
  const CalibrationFailure(super.message, {super.code});
}

/// Test execution related failures
class TestFailure extends Failure {
  const TestFailure(super.message, {super.code});
}

/// Database related failures
class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message, {super.code});
}

/// File operations related failures
class FileFailure extends Failure {
  const FileFailure(super.message, {super.code});
}

/// Permission related failures
class PermissionFailure extends Failure {
  const PermissionFailure(super.message, {super.code});
}

/// Network related failures
class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.code});
}

/// Validation related failures
class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.code});
}