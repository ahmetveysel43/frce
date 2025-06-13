import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../utils/app_logger.dart';

/// Dosya paylaşma servisi
/// PDF'leri ve diğer dosyaları kullanıcıların erişebileceği şekilde paylaşır
class FileShareService {
  /// PDF dosyasını paylaş
  static Future<void> sharePDFFile({
    required File pdfFile,
    String? subject,
    String? text,
  }) async {
    try {
      AppLogger.info('📤 PDF dosyası paylaşılıyor: ${pdfFile.path}');
      
      // Dosya varlığını kontrol et
      if (!await pdfFile.exists()) {
        throw Exception('PDF dosyası bulunamadı: ${pdfFile.path}');
      }
      
      final fileSize = await pdfFile.length();
      AppLogger.info('📊 PDF boyutu: $fileSize bytes');
      
      // XFile ile paylaş
      final xFile = XFile(
        pdfFile.path,
        mimeType: 'application/pdf',
        name: pdfFile.path.split('/').last,
        length: fileSize,
      );
      
      await Share.shareXFiles(
        [xFile],
        subject: subject ?? 'izForce Performans Raporu',
        text: text ?? 'izForce uygulaması ile oluşturulan performans raporu.',
      );
      
      AppLogger.success('✅ PDF başarıyla paylaşıldı');
      
    } catch (e, stackTrace) {
      AppLogger.error('PDF paylaşma hatası', e, stackTrace);
      rethrow;
    }
  }
  
  /// PDF bytes'ını geçici dosya olarak kaydet ve paylaş
  static Future<void> sharePDFBytes({
    required Uint8List pdfBytes,
    required String fileName,
    String? subject,
    String? text,
  }) async {
    try {
      AppLogger.info('📤 PDF bytes paylaşılıyor: $fileName');
      
      // Geçici dosya oluştur
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$fileName');
      
      AppLogger.info('📁 Geçici dosya: ${tempFile.path}');
      
      // PDF bytes'ını dosyaya yaz
      await tempFile.writeAsBytes(pdfBytes);
      
      // Dosya varlığını kontrol et
      final exists = await tempFile.exists();
      final fileSize = exists ? await tempFile.length() : 0;
      
      AppLogger.info('✅ Geçici dosya oluşturuldu: $exists, Boyut: $fileSize bytes');
      
      if (!exists || fileSize == 0) {
        throw Exception('Geçici PDF dosyası oluşturulamadı');
      }
      
      // Dosyayı paylaş
      await sharePDFFile(
        pdfFile: tempFile,
        subject: subject,
        text: text,
      );
      
    } catch (e, stackTrace) {
      AppLogger.error('PDF bytes paylaşma hatası', e, stackTrace);
      rethrow;
    }
  }
  
  /// CSV dosyasını paylaş
  static Future<void> shareCSVFile({
    required File csvFile,
    String? subject,
    String? text,
  }) async {
    try {
      AppLogger.info('📊 CSV dosyası paylaşılıyor: ${csvFile.path}');
      
      if (!await csvFile.exists()) {
        throw Exception('CSV dosyası bulunamadı: ${csvFile.path}');
      }
      
      final xFile = XFile(
        csvFile.path,
        mimeType: 'text/csv',
        name: csvFile.path.split('/').last,
      );
      
      await Share.shareXFiles(
        [xFile],
        subject: subject ?? 'izForce Test Verileri',
        text: text ?? 'izForce uygulaması ile dışa aktarılan test verileri.',
      );
      
      AppLogger.success('✅ CSV başarıyla paylaşıldı');
      
    } catch (e, stackTrace) {
      AppLogger.error('CSV paylaşma hatası', e, stackTrace);
      rethrow;
    }
  }
  
  /// JSON dosyasını paylaş
  static Future<void> shareJSONFile({
    required File jsonFile,
    String? subject,
    String? text,
  }) async {
    try {
      AppLogger.info('📄 JSON dosyası paylaşılıyor: ${jsonFile.path}');
      
      if (!await jsonFile.exists()) {
        throw Exception('JSON dosyası bulunamadı: ${jsonFile.path}');
      }
      
      final xFile = XFile(
        jsonFile.path,
        mimeType: 'application/json',
        name: jsonFile.path.split('/').last,
      );
      
      await Share.shareXFiles(
        [xFile],
        subject: subject ?? 'izForce Test Verileri',
        text: text ?? 'izForce uygulaması ile dışa aktarılan test verileri.',
      );
      
      AppLogger.success('✅ JSON başarıyla paylaşıldı');
      
    } catch (e, stackTrace) {
      AppLogger.error('JSON paylaşma hatası', e, stackTrace);
      rethrow;
    }
  }
  
  /// Metin paylaş (Basit bilgi paylaşımı için)
  static Future<void> shareText({
    required String text,
    String? subject,
  }) async {
    try {
      AppLogger.info('📝 Metin paylaşılıyor: ${text.length} karakter');
      
      await Share.share(
        text,
        subject: subject ?? 'izForce Raporu',
      );
      
      AppLogger.success('✅ Metin başarıyla paylaşıldı');
      
    } catch (e, stackTrace) {
      AppLogger.error('Metin paylaşma hatası', e, stackTrace);
      rethrow;
    }
  }

  /// Metin özeti paylaş (AI Insights için)
  static Future<void> shareTextSummary({
    required String text,
    String? subject,
  }) async {
    try {
      AppLogger.info('🤖 AI özeti paylaşılıyor: ${text.length} karakter');
      
      await Share.share(
        text,
        subject: subject ?? 'izForce AI Insights',
      );
      
      AppLogger.success('✅ AI özeti başarıyla paylaşıldı');
      
    } catch (e, stackTrace) {
      AppLogger.error('AI özeti paylaşma hatası', e, stackTrace);
      rethrow;
    }
  }
  
  /// Çoklu dosya paylaş
  static Future<void> shareMultipleFiles({
    required List<XFile> files,
    String? subject,
    String? text,
  }) async {
    try {
      AppLogger.info('📤 ${files.length} dosya paylaşılıyor');
      
      // Tüm dosyaların varlığını kontrol et
      for (final file in files) {
        final fileExists = await File(file.path).exists();
        if (!fileExists) {
          throw Exception('Dosya bulunamadı: ${file.path}');
        }
      }
      
      await Share.shareXFiles(
        files,
        subject: subject ?? 'izForce Rapor ve Veriler',
        text: text ?? 'izForce uygulaması ile oluşturulan rapor ve veriler.',
      );
      
      AppLogger.success('✅ ${files.length} dosya başarıyla paylaşıldı');
      
    } catch (e, stackTrace) {
      AppLogger.error('Çoklu dosya paylaşma hatası', e, stackTrace);
      rethrow;
    }
  }
  
  /// Dosyayı cihazın Downloads klasörüne kopyala (Android için)
  static Future<File?> copyToDownloads({
    required File sourceFile,
    String? customFileName,
  }) async {
    try {
      AppLogger.info('📥 Dosya Downloads klasörüne kopyalanıyor: ${sourceFile.path}');
      
      if (!await sourceFile.exists()) {
        throw Exception('Kaynak dosya bulunamadı: ${sourceFile.path}');
      }
      
      // Downloads klasörünü bul
      Directory? downloadsDir;
      
      // Android için external storage Downloads
      try {
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          // /storage/emulated/0/Download yolunu oluştur
          final downloadPath = externalDir.path.replaceAll('/Android/data/com.example.izforce/files', '/Download');
          downloadsDir = Directory(downloadPath);
          
          if (!await downloadsDir.exists()) {
            // Alternatif Downloads yolu
            downloadsDir = Directory('/storage/emulated/0/Download');
          }
        }
      } catch (e) {
        AppLogger.warning('External storage Downloads erişilemedi: $e');
      }
      
      // Fallback: Documents klasörü
      if (downloadsDir == null || !await downloadsDir.exists()) {
        final documentsDir = await getApplicationDocumentsDirectory();
        downloadsDir = Directory('${documentsDir.parent.path}/Documents');
        
        if (!await downloadsDir.exists()) {
          await downloadsDir.create(recursive: true);
        }
      }
      
      final fileName = customFileName ?? sourceFile.path.split('/').last;
      final targetFile = File('${downloadsDir.path}/$fileName');
      
      AppLogger.info('📁 Hedef klasör: ${downloadsDir.path}');
      AppLogger.info('📄 Hedef dosya: ${targetFile.path}');
      
      // Dosyayı kopyala
      await sourceFile.copy(targetFile.path);
      
      final exists = await targetFile.exists();
      final fileSize = exists ? await targetFile.length() : 0;
      
      AppLogger.info('✅ Dosya kopyalandı: $exists, Boyut: $fileSize bytes');
      AppLogger.success('Dosya Downloads klasörüne kaydedildi: ${targetFile.path}');
      
      return targetFile;
      
    } catch (e, stackTrace) {
      AppLogger.error('Downloads kopyalama hatası', e, stackTrace);
      return null;
    }
  }
  
  /// Paylaşma öncesi dosya hazırlama
  static Future<File> prepareFileForSharing(File sourceFile) async {
    try {
      AppLogger.info('🔧 Dosya paylaşım için hazırlanıyor: ${sourceFile.path}');
      
      if (!await sourceFile.exists()) {
        throw Exception('Kaynak dosya bulunamadı: ${sourceFile.path}');
      }
      
      // Geçici klasörde paylaşım için kopyasını oluştur
      final tempDir = await getTemporaryDirectory();
      final fileName = sourceFile.path.split('/').last;
      final shareFile = File('${tempDir.path}/share_$fileName');
      
      await sourceFile.copy(shareFile.path);
      
      AppLogger.info('✅ Paylaşım dosyası hazırlandı: ${shareFile.path}');
      return shareFile;
      
    } catch (e, stackTrace) {
      AppLogger.error('Dosya hazırlama hatası', e, stackTrace);
      rethrow;
    }
  }
}