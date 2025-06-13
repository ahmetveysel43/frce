import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/utils/app_logger.dart';
import 'test_controller.dart';

/// Ayarlar controller - Uygulama ayarlarını yönetir
class SettingsController extends GetxController {
  // Settings keys
  static const String _keyLanguage = 'language';
  static const String _keySoundEnabled = 'sound_enabled';
  static const String _keyVibrationEnabled = 'vibration_enabled';
  static const String _keySampleRate = 'sample_rate';
  static const String _keyCalibrationDuration = 'calibration_duration';
  static const String _keyWeightThreshold = 'weight_threshold';
  static const String _keyAutoSave = 'auto_save';
  static const String _keyMockMode = 'mock_mode';
  static const String _keyTheme = 'theme';
  static const String _keyPrimaryColor = 'primary_color';
  
  // Observable settings
  final _language = 'tr'.obs;
  final _soundEnabled = true.obs;
  final _vibrationEnabled = true.obs;
  final _sampleRate = 1000.obs;
  final _calibrationDuration = 3.obs;
  final _weightThreshold = 0.5.obs;
  final _autoSave = true.obs;
  final _mockMode = true.obs;
  final _isDarkMode = true.obs;
  final _primaryColorIndex = 0.obs;
  final _isInitialized = false.obs;
  
  // SharedPreferences instance
  SharedPreferences? _prefs;
  
  // Getters
  String get language => _language.value;
  bool get soundEnabled => _soundEnabled.value;
  bool get vibrationEnabled => _vibrationEnabled.value;
  int get sampleRate => _sampleRate.value;
  int get calibrationDuration => _calibrationDuration.value;
  double get weightThreshold => _weightThreshold.value;
  bool get autoSave => _autoSave.value;
  bool get mockMode => _mockMode.value;
  bool get isDarkMode => _isDarkMode.value;
  int get primaryColorIndex => _primaryColorIndex.value;
  bool get isInitialized => _isInitialized.value;
  
  @override
  void onInit() {
    super.onInit();
    _loadSettings();
  }
  
  /// Ayarları yükle
  Future<void> _loadSettings() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      
      _language.value = _prefs?.getString(_keyLanguage) ?? 'tr';
      _soundEnabled.value = _prefs?.getBool(_keySoundEnabled) ?? true;
      _vibrationEnabled.value = _prefs?.getBool(_keyVibrationEnabled) ?? true;
      _sampleRate.value = _prefs?.getInt(_keySampleRate) ?? 1000;
      _calibrationDuration.value = _prefs?.getInt(_keyCalibrationDuration) ?? 3;
      _weightThreshold.value = _prefs?.getDouble(_keyWeightThreshold) ?? 0.5;
      _autoSave.value = _prefs?.getBool(_keyAutoSave) ?? true;
      _mockMode.value = _prefs?.getBool(_keyMockMode) ?? true;
      _isDarkMode.value = _prefs?.getBool(_keyTheme) ?? true;
      _primaryColorIndex.value = _prefs?.getInt(_keyPrimaryColor) ?? 0;
      
      AppLogger.success('✅ Ayarlar yüklendi');
      
      // Initialization tamamlandı
      _isInitialized.value = true;
      
      // Widget'ları güncelle
      update();
    } catch (e) {
      AppLogger.error('Ayarlar yükleme hatası', e);
    }
  }
  
  /// Dil değiştir
  Future<void> setLanguage(String lang) async {
    _language.value = lang;
    await _prefs?.setString(_keyLanguage, lang);
    
    // Update locale
    if (lang == 'en') {
      Get.updateLocale(const Locale('en', 'US'));
    } else {
      Get.updateLocale(const Locale('tr', 'TR'));
    }
    
    AppLogger.info('🌐 Dil değiştirildi: $lang');
  }
  
  /// Ses ayarı
  Future<void> setSoundEnabled(bool enabled) async {
    _soundEnabled.value = enabled;
    await _prefs?.setBool(_keySoundEnabled, enabled);
    AppLogger.info('🔊 Ses ayarı: ${enabled ? "Açık" : "Kapalı"}');
  }
  
  /// Titreşim ayarı
  Future<void> setVibrationEnabled(bool enabled) async {
    _vibrationEnabled.value = enabled;
    await _prefs?.setBool(_keyVibrationEnabled, enabled);
    AppLogger.info('📳 Titreşim ayarı: ${enabled ? "Açık" : "Kapalı"}');
  }
  
  /// Örnekleme hızı
  Future<void> setSampleRate(int rate) async {
    _sampleRate.value = rate;
    await _prefs?.setInt(_keySampleRate, rate);
    AppLogger.info('📊 Örnekleme hızı: $rate Hz');
  }
  
  /// Kalibrasyon süresi
  Future<void> setCalibrationDuration(int seconds) async {
    _calibrationDuration.value = seconds;
    await _prefs?.setInt(_keyCalibrationDuration, seconds);
    AppLogger.info('⚖️ Kalibrasyon süresi: $seconds saniye');
  }
  
  /// Ağırlık eşiği
  Future<void> setWeightThreshold(double threshold) async {
    _weightThreshold.value = threshold;
    await _prefs?.setDouble(_keyWeightThreshold, threshold);
    AppLogger.info('⚖️ Ağırlık eşiği: $threshold kg');
  }
  
  /// Otomatik kayıt
  Future<void> setAutoSave(bool enabled) async {
    _autoSave.value = enabled;
    await _prefs?.setBool(_keyAutoSave, enabled);
    AppLogger.info('💾 Otomatik kayıt: ${enabled ? "Açık" : "Kapalı"}');
  }
  
  /// Mock mode
  Future<void> setMockMode(bool enabled) async {
    _mockMode.value = enabled;
    await _prefs?.setBool(_keyMockMode, enabled);
    
    // Update test controller
    final testController = Get.find<TestController>();
    if (enabled) {
      testController.enableMockMode();
    } else {
      testController.disableMockMode();
    }
    
    AppLogger.info('🎭 Mock mode: ${enabled ? "Açık" : "Kapalı"}');
  }
  
  /// Tema değiştir
  Future<void> setDarkMode(bool isDark) async {
    _isDarkMode.value = isDark;
    await _prefs?.setBool(_keyTheme, isDark);
    
    // GetBuilder için update tetikle
    update();
    
    AppLogger.info('🎨 Tema: ${isDark ? "Karanlık" : "Aydınlık"}');
  }
  
  /// Tema rengi değiştir
  Future<void> setPrimaryColor(int colorIndex) async {
    _primaryColorIndex.value = colorIndex;
    await _prefs?.setInt(_keyPrimaryColor, colorIndex);
    
    // Tema rengini güncellemek için rebuild tetikle
    update();
    
    AppLogger.info('🎨 Tema rengi değiştirildi: $colorIndex');
  }
  
  /// Varsayılan ayarlara dön
  Future<void> resetToDefaults() async {
    await setLanguage('tr');
    await setSoundEnabled(true);
    await setVibrationEnabled(true);
    await setSampleRate(1000);
    await setCalibrationDuration(3);
    await setWeightThreshold(0.5);
    await setAutoSave(true);
    await setMockMode(true);
    await setDarkMode(true);
    await setPrimaryColor(0);
    
    AppLogger.info('🔄 Varsayılan ayarlara dönüldü');
  }
  
  /// Tüm ayarları temizle
  Future<void> clearAllSettings() async {
    await _prefs?.clear();
    _loadSettings(); // Reload defaults
    AppLogger.info('🗑️ Tüm ayarlar temizlendi');
  }
}