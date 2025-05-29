class PhysicsConstants {
  // Yerçekimi
  static const double gravity = 9.81; // m/s²
  
  // Birim Dönüşümleri
  static const double kgToN = 9.81; // kg'i Newton'a çevirme
  static const double cmToM = 0.01; // cm'i metreye çevirme
  static const double msToS = 0.001; // milisaniyeyi saniyeye çevirme
  
  // Force Platform Kalibrasyonu
  static const double loadCellSensitivity = 2.0; // mV/V
  static const double amplifierGain = 1000.0;
  static const double adcResolution = 24; // bit
  static const double adcVoltageRange = 5.0; // Volt
  
  // Test Eşikleri
  static const double jumpTakeoffThreshold = 10.0; // N (body weight'in üstü)
  static const double landingThreshold = 5.0; // N
  static const double balanceStabilityThreshold = 2.0; // N standart sapma
  
  // Hareket Fazları
  static const double movementStartThreshold = 5.0; // N/s (force değişimi)
  static const double movementEndThreshold = 2.0; // N/s
  
  // Private constructor
  PhysicsConstants._();
}