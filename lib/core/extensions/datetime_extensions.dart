extension DateTimeExtensions on DateTime {
  /// Tarih formatını string'e çevir (gün/ay/yıl)
  String toDateString() {
    return '${day.toString().padLeft(2, '0')}/'
           '${month.toString().padLeft(2, '0')}/'
           '$year';
  }
  
  /// Saat formatını string'e çevir (saat:dakika)
  String toTimeString() {
    return '${hour.toString().padLeft(2, '0')}:'
           '${minute.toString().padLeft(2, '0')}';
  }
  
  /// Tam tarih-saat formatı
  String toFullString() {
    return '${toDateString()} ${toTimeString()}';
  }
  
  /// Yaş hesapla
  int calculateAge() {
    final now = DateTime.now();
    int age = now.year - year;
    
    if (now.month < month || (now.month == month && now.day < day)) {
      age--;
    }
    
    return age;
  }
  
  /// Bugünden kaç gün önce/sonra
  int daysDifference() {
    final now = DateTime.now();
    return difference(now).inDays;
  }
  
  /// Bugün mü?
  bool get isToday {
    final now = DateTime.now();
    return day == now.day && month == now.month && year == now.year;
  }
  
  /// Dün mü?
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return day == yesterday.day && 
           month == yesterday.month && 
           year == yesterday.year;
  }
  
  /// Bu hafta mı?
  bool get isThisWeek {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));
    
    return isAfter(weekStart) && isBefore(weekEnd);
  }
  
  /// Dosya adı için güvenli format
  String toFileNameString() {
    return '$year${month.toString().padLeft(2, '0')}'
           '${day.toString().padLeft(2, '0')}_'
           '${hour.toString().padLeft(2, '0')}'
           '${minute.toString().padLeft(2, '0')}'
           '${second.toString().padLeft(2, '0')}';
  }
}