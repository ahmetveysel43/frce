enum TestType {
  counterMovementJump,
  squatJump,
  dropJump,
  balance,
  isometric,
  landing,
}

class TestConstants {
  // Test İsimleri
  static const Map<TestType, String> testNames = {
    TestType.counterMovementJump: 'Counter Movement Jump',
    TestType.squatJump: 'Squat Jump',
    TestType.dropJump: 'Drop Jump',
    TestType.balance: 'Balance Test',
    TestType.isometric: 'Isometric Test',
    TestType.landing: 'Landing Test',
  };
  
  // Test Süreleri
  static const Map<TestType, Duration> testDurations = {
    TestType.counterMovementJump: Duration(seconds: 10),
    TestType.squatJump: Duration(seconds: 8),
    TestType.dropJump: Duration(seconds: 12),
    TestType.balance: Duration(seconds: 60),
    TestType.isometric: Duration(seconds: 5),
    TestType.landing: Duration(seconds: 8),
  };
  
  // Test Açıklamaları
  static const Map<TestType, String> testDescriptions = {
    TestType.counterMovementJump: 'Aşağı çömerek maksimal sıçrama',
    TestType.squatJump: 'Durağan konumdan maksimal sıçrama',
    TestType.dropJump: 'Yüksekten atlayıp tekrar sıçrama',
    TestType.balance: 'Tek ayak denge testi',
    TestType.isometric: 'Statik kuvvet testi',
    TestType.landing: 'İniş dinamikleri testi',
  };
  
  // Private constructor
  TestConstants._();
}