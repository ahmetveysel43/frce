class Validators {
  /// Force değerinin geçerli olup olmadığını kontrol et
  static bool isValidForceValue(double force) {
    return force.isFinite && force >= -10000 && force <= 10000; // Newton
  }

  /// Test süresinin geçerli olup olmadığını kontrol et
  static bool isValidTestDuration(Duration duration) {
    return duration.inSeconds >= 1 && duration.inMinutes <= 10;
  }

  /// Sporcu yaşının geçerli olup olmadığını kontrol et
  static bool isValidAge(int age) {
    return age >= 5 && age <= 120;
  }

  /// Boy değerinin geçerli olup olmadığını kontrol et (cm)
  static bool isValidHeight(double height) {
    return height >= 50 && height <= 250;
  }

  /// Kilo değerinin geçerli olup olmadığını kontrol et (kg)
  static bool isValidWeight(double weight) {
    return weight >= 10 && weight <= 300;
  }

  /// Sampling rate'in geçerli olup olmadığını kontrol et
  static bool isValidSamplingRate(int samplingRate) {
    return samplingRate >= 100 && samplingRate <= 2000;
  }

  /// Force data listesinin geçerli olup olmadığını kontrol et
  static bool isValidForceDataList(List<double> forces) {
    if (forces.isEmpty || forces.length < 10) return false;
    
    return forces.every((force) => isValidForceValue(force));
  }

  /// Email formatının geçerli olup olmadığını kontrol et
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// İsim formatının geçerli olup olmadığını kontrol et
  static bool isValidName(String name) {
    return name.trim().length >= 2 && name.trim().length <= 50;
  }

  // Private constructor
  Validators._();
}