import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../data/models/test_result_model.dart';
import '../../data/models/athlete_model.dart';
import '../constants/app_constants.dart';
import '../utils/app_logger.dart';
import 'progress_analyzer.dart';
import 'test_comparison_service.dart';
import 'advanced_comparison_service.dart';
import 'file_share_service.dart';

/// PDF rapor oluşturma servisi
class PDFReportService {
  static pw.Font? _regularFont;
  static pw.Font? _boldFont;
  
  /// PDF fontlarını yükle
  static Future<void> _loadFonts() async {
    if (_regularFont == null || _boldFont == null) {
      try {
        final regularFontData = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
        final boldFontData = await rootBundle.load('assets/fonts/NotoSans-Bold.ttf');
        
        _regularFont = pw.Font.ttf(regularFontData);
        _boldFont = pw.Font.ttf(boldFontData);
        
        AppLogger.info('📝 PDF fontları yüklendi');
      } catch (e, stackTrace) {
        AppLogger.error('Font yükleme hatası', e, stackTrace);
        // Fallback olarak default font kullanılacak
      }
    }
  }

  /// PDF için varsayılan stil tanımlamaları
  static pw.TextStyle get _titleStyle => pw.TextStyle(
    fontSize: 24,
    fontWeight: pw.FontWeight.bold,
    font: _boldFont,
  );
  
  static pw.TextStyle get _headingStyle => pw.TextStyle(
    fontSize: 18,
    fontWeight: pw.FontWeight.bold,
    font: _boldFont,
  );
  
  static pw.TextStyle get _subheadingStyle => pw.TextStyle(
    fontSize: 14,
    fontWeight: pw.FontWeight.bold,
    font: _boldFont,
  );
  
  static pw.TextStyle get _normalStyle => pw.TextStyle(
    fontSize: 12,
    font: _regularFont,
  );
  
  static pw.TextStyle get _smallStyle => pw.TextStyle(
    fontSize: 10,
    color: PdfColors.grey700,
    font: _regularFont,
  );

  /// Kapsamlı performans raporu oluştur
  static Future<File> generatePerformanceReport({
    required AthleteModel athlete,
    required List<TestResultModel> results,
    required PerformanceAnalysis analysis,
    BenchmarkComparison? benchmarkComparison,
    List<TestComparisonModel>? comparisons,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      AppLogger.info('📊 PDF raporu oluşturuluyor: ${athlete.firstName} ${athlete.lastName}');
      
      // Fontları yükle
      await _loadFonts();
      
      final pdf = pw.Document();
      final now = DateTime.now();
      
      // PDF sayfası oluştur
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return [
              // Başlık
              _buildHeader(athlete, now),
              pw.SizedBox(height: 20),
              
              // Performans Özeti
              _buildPerformanceSummary(analysis, results),
              pw.SizedBox(height: 20),
              
              // Test Sonuçları Tablosu
              if (results.isNotEmpty) ...[
                _buildSectionTitle('Test Sonuçları'),
                pw.SizedBox(height: 10),
                _buildResultsTable(results),
                pw.SizedBox(height: 20),
              ],
              
              // Metrik Detayları
              if (results.isNotEmpty) ...[
                _buildSectionTitle('Performans Metrikleri'),
                pw.SizedBox(height: 10),
                _buildMetricsDetails(results.last),
                pw.SizedBox(height: 20),
              ],
              
              // Benchmark Karşılaştırması
              if (benchmarkComparison != null) ...[
                _buildSectionTitle('Benchmark Karşılaştırması'),
                pw.SizedBox(height: 10),
                _buildBenchmarkSection(benchmarkComparison),
                pw.SizedBox(height: 20),
              ],
              
              // Notlar
              _buildFooter(),
            ];
          },
        ),
      );
      
      // PDF'i kaydet
      Directory directory;
      try {
        // Önce external storage'ı dene
        // Android için external storage deneme (iOS'ta null döner)
        Directory? externalDir;
        try {
          externalDir = await getExternalStorageDirectory();
        } catch (e) {
          // iOS'ta mevcut değil, null olarak devam et
          externalDir = null;
        }
        if (externalDir != null) {
          directory = Directory('${externalDir.path}/Documents');
          if (!await directory.exists()) {
            await directory.create(recursive: true);
          }
        } else {
          // Fallback to app documents
          directory = await getApplicationDocumentsDirectory();
        }
      } catch (e) {
        // Fallback to app documents
        directory = await getApplicationDocumentsDirectory();
      }
      
      final fileName = 'performance_report_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${directory.path}/$fileName');
      
      AppLogger.info('📁 PDF kaydediliyor: ${file.path}');
      AppLogger.info('📂 Directory path: ${directory.path}');
      AppLogger.info('📂 Directory exists: ${await directory.exists()}');
      
      final pdfBytes = await pdf.save();
      AppLogger.info('📊 PDF size: ${pdfBytes.length} bytes');
      
      await file.writeAsBytes(pdfBytes);
      
      // Dosya varlığını kontrol et
      final exists = await file.exists();
      final fileSize = exists ? await file.length() : 0;
      
      AppLogger.info('✅ Dosya oluşturuldu: $exists, Boyut: $fileSize bytes');
      AppLogger.info('📱 Tam dosya yolu: ${file.absolute.path}');
      
      // Dizin içeriğini listele
      try {
        final files = await directory.list().toList();
        AppLogger.info('📂 Dizin içeriği: ${files.map((f) => f.path.split('/').last).join(', ')}');
      } catch (e) {
        AppLogger.warning('Dizin listelenemedi: $e');
      }
      
      AppLogger.success('PDF raporu oluşturuldu: ${file.path}');
      
      return file;
      
    } catch (e, stackTrace) {
      AppLogger.error('PDF raporu oluşturma hatası', e, stackTrace);
      rethrow;
    }
  }

  /// Başlık bölümü
  static pw.Widget _buildHeader(AthleteModel athlete, DateTime date) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('izForce Performans Raporu', style: _titleStyle),
            pw.Text(
              DateFormat('dd/MM/yyyy').format(date),
              style: _normalStyle,
            ),
          ],
        ),
        pw.Divider(thickness: 2),
        pw.SizedBox(height: 10),
        pw.Row(
          children: [
            pw.Text('Sporcu: ', style: _subheadingStyle),
            pw.Text('${athlete.firstName} ${athlete.lastName}', style: _normalStyle),
          ],
        ),
        if (athlete.dateOfBirth != null)
          pw.Row(
            children: [
              pw.Text('Yaş: ', style: _subheadingStyle),
              pw.Text('${_calculateAge(athlete.dateOfBirth!)}', style: _normalStyle),
            ],
          ),
        if (athlete.team != null && athlete.team!.isNotEmpty)
          pw.Row(
            children: [
              pw.Text('Takım: ', style: _subheadingStyle),
              pw.Text(athlete.team!, style: _normalStyle),
            ],
          ),
      ],
    );
  }

  /// Performans özeti
  static pw.Widget _buildPerformanceSummary(PerformanceAnalysis analysis, List<TestResultModel> results) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Performans Özeti', style: _headingStyle),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem('Güvenilirlik', '${analysis.testRetestReliability.toStringAsFixed(1)}%'),
              _buildSummaryItem('Test Sayısı', '${results.length}'),
              _buildSummaryItem('Trend', analysis.performanceTrend),
            ],
          ),
        ],
      ),
    );
  }

  /// Özet öğesi
  static pw.Widget _buildSummaryItem(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(label, style: _smallStyle),
        pw.SizedBox(height: 5),
        pw.Text(value, style: _subheadingStyle),
      ],
    );
  }

  /// Test sonuçları tablosu
  static pw.Widget _buildResultsTable(List<TestResultModel> results) {
    final sortedResults = List<TestResultModel>.from(results)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    final limitedResults = sortedResults.take(10).toList();
    
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      children: [
        // Başlık satırı
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _buildTableCell('Tarih', isHeader: true),
            _buildTableCell('Test Tipi', isHeader: true),
            _buildTableCell('Skor', isHeader: true),
            _buildTableCell('Süre', isHeader: true),
          ],
        ),
        // Veri satırları
        ...limitedResults.map((result) {
          return pw.TableRow(
            children: [
              _buildTableCell(DateFormat('dd/MM/yyyy').format(result.timestamp)),
              _buildTableCell(_getTestTypeName(_parseTestType(result.testType))),
              _buildTableCell('${(result.score ?? 0).toStringAsFixed(1)}%'),
              _buildTableCell('${(result.durationMs / 1000).toStringAsFixed(1)}s'),
            ],
          );
        }),
      ],
    );
  }

  /// Tablo hücresi
  static pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: isHeader ? _subheadingStyle : _normalStyle,
      ),
    );
  }

  /// Metrik detayları
  static pw.Widget _buildMetricsDetails(TestResultModel result) {
    final topMetrics = result.metrics.entries
        .take(6)
        .map((entry) => pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(entry.key, style: _normalStyle),
                pw.Text('${entry.value.toStringAsFixed(2)} ${_getMetricUnit(entry.key)}', 
                    style: _normalStyle),
              ],
            ))
        .toList();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Son Test Detayları (${DateFormat('dd/MM/yyyy').format(result.timestamp)})', 
            style: _smallStyle),
        pw.SizedBox(height: 10),
        ...topMetrics,
      ],
    );
  }

  /// Benchmark bölümü
  static pw.Widget _buildBenchmarkSection(BenchmarkComparison comparison) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Benchmark Karşılaştırması', style: _normalStyle),
        pw.SizedBox(height: 10),
        pw.Text('Genel performans değerlendirmesi yapılmıştır.', 
            style: _smallStyle),
      ],
    );
  }

  /// Bölüm başlığı
  static pw.Widget _buildSectionTitle(String title) {
    return pw.Text(title, style: _headingStyle);
  }

  /// Alt bilgi
  static pw.Widget _buildFooter() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Divider(),
        pw.SizedBox(height: 10),
        pw.Text(
          'Bu rapor izForce uygulaması tarafından otomatik olarak oluşturulmuştur.',
          style: _smallStyle,
        ),
        pw.Text(
          'Detaylı bilgi için: www.izforce.com',
          style: _smallStyle,
        ),
      ],
    );
  }

  /// Test karşılaştırma raporu oluştur
  static Future<Uint8List> generateTestComparisonReport({
    required AthleteModel athlete,
    required ComparisonResult comparison,
  }) async {
    try {
      AppLogger.info('📊 Test karşılaştırma raporu oluşturuluyor: ${athlete.firstName} ${athlete.lastName}');
      
      // Fontları yükle
      await _loadFonts();
      
      final pdf = pw.Document();
      
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return [
              // Başlık
              _buildComparisonHeader(athlete),
              pw.SizedBox(height: 20),
              
              // Karşılaştırma Özeti
              _buildComparisonSummary(comparison),
              pw.SizedBox(height: 20),
              
              // Metrik Karşılaştırmaları
              _buildMetricComparisons(comparison),
              pw.SizedBox(height: 20),
              
              // İçgörüler
              if (comparison.insights.isNotEmpty) ...[
                _buildInsights(comparison.insights),
                pw.SizedBox(height: 20),
              ],
              
              // Alt bilgi
              _buildFooter(),
            ];
          },
        ),
      );
      
      return pdf.save();
      
    } catch (e, stackTrace) {
      AppLogger.error('Test karşılaştırma raporu oluşturma hatası', e, stackTrace);
      rethrow;
    }
  }

  /// Karşılaştırma başlığı
  static pw.Widget _buildComparisonHeader(AthleteModel athlete) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Test Karşılaştırma Raporu', style: _titleStyle),
        pw.Divider(thickness: 2),
        pw.SizedBox(height: 10),
        pw.Text('${athlete.firstName} ${athlete.lastName}', style: _headingStyle),
        pw.Text(DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()), 
            style: _smallStyle),
      ],
    );
  }

  /// Karşılaştırma özeti
  static pw.Widget _buildComparisonSummary(ComparisonResult comparison) {
    final changeColor = comparison.percentChange > 0 ? PdfColors.green : 
                       comparison.percentChange < 0 ? PdfColors.red : PdfColors.grey800;
    
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          pw.Column(
            children: [
              pw.Text('Test 1', style: _smallStyle),
              pw.Text('${(comparison.test1.score ?? 0).toStringAsFixed(1)}%', 
                  style: _headingStyle),
              pw.Text(DateFormat('dd/MM').format(comparison.test1.timestamp), 
                  style: _smallStyle),
            ],
          ),
          pw.Column(
            children: [
              pw.Icon(
                comparison.percentChange > 0 ? const pw.IconData(0xe5d8) : 
                comparison.percentChange < 0 ? const pw.IconData(0xe5db) : 
                const pw.IconData(0xe5d9),
                color: changeColor,
                size: 30,
              ),
              pw.Text(
                '${comparison.percentChange > 0 ? '+' : ''}${comparison.percentChange.toStringAsFixed(1)}%',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: changeColor,
                ),
              ),
            ],
          ),
          pw.Column(
            children: [
              pw.Text('Test 2', style: _smallStyle),
              pw.Text('${(comparison.test2.score ?? 0).toStringAsFixed(1)}%', 
                  style: _headingStyle),
              pw.Text(DateFormat('dd/MM').format(comparison.test2.timestamp), 
                  style: _smallStyle),
            ],
          ),
        ],
      ),
    );
  }

  /// Metrik karşılaştırmaları
  static pw.Widget _buildMetricComparisons(ComparisonResult comparison) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Metrik Karşılaştırmaları', style: _headingStyle),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400),
          children: [
            // Başlık
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _buildTableCell('Metrik', isHeader: true),
                _buildTableCell('Test 1', isHeader: true),
                _buildTableCell('Test 2', isHeader: true),
                _buildTableCell('Değişim', isHeader: true),
              ],
            ),
            // Veriler
            ...comparison.metricComparisons.entries.map((entry) {
              final metric = entry.value;
              final changeColor = metric.percentChange > 0 ? PdfColors.green : 
                                 metric.percentChange < 0 ? PdfColors.red : PdfColors.black;
              
              return pw.TableRow(
                children: [
                  _buildTableCell(metric.metric),
                  _buildTableCell(metric.value1.toStringAsFixed(2)),
                  _buildTableCell(metric.value2.toStringAsFixed(2)),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      '${metric.percentChange > 0 ? '+' : ''}${metric.percentChange.toStringAsFixed(1)}%',
                      style: pw.TextStyle(color: changeColor, fontSize: 12),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  /// İçgörüler
  static pw.Widget _buildInsights(List<String> insights) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Analiz ve Öneriler', style: _headingStyle),
        pw.SizedBox(height: 10),
        ...insights.map((insight) => pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 5),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('• ', style: _normalStyle),
              pw.Expanded(
                child: pw.Text(insight, style: _normalStyle),
              ),
            ],
          ),
        )),
      ],
    );
  }

  /// Gelişmiş test karşılaştırma raporu oluştur
  static Future<Uint8List> generateAdvancedTestComparisonReport({
    required AthleteModel athlete,
    required ComprehensiveComparisonResult comparison,
  }) async {
    try {
      AppLogger.info('📊 Gelişmiş test karşılaştırma raporu oluşturuluyor: ${athlete.firstName} ${athlete.lastName}');
      
      // Fontları yükle
      await _loadFonts();
      
      final pdf = pw.Document();
      
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return [
              // Başlık
              _buildAdvancedHeader(athlete, comparison),
              pw.SizedBox(height: 20),
              
              // Genel Performans Skoru
              _buildOverallScore(comparison),
              pw.SizedBox(height: 20),
              
              // Temel Karşılaştırma
              _buildBasicComparisonSection(comparison.basicComparison),
              pw.SizedBox(height: 20),
              
              // Performans Profili
              _buildPerformanceProfile(comparison.performanceProfile),
              pw.SizedBox(height: 20),
              
              // Öneriler
              if (comparison.recommendations.isNotEmpty) ...[
                _buildRecommendations(comparison.recommendations),
                pw.SizedBox(height: 20),
              ],
              
              // İstatistiksel Analiz
              _buildStatisticalAnalysis(comparison.statisticalAnalysis),
              
              // Alt bilgi
              _buildFooter(),
            ];
          },
        ),
      );
      
      return pdf.save();
      
    } catch (e, stackTrace) {
      AppLogger.error('Gelişmiş test karşılaştırma raporu oluşturma hatası', e, stackTrace);
      rethrow;
    }
  }

  /// Gelişmiş başlık
  static pw.Widget _buildAdvancedHeader(AthleteModel athlete, ComprehensiveComparisonResult comparison) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Gelişmiş Performans Analizi', style: _titleStyle),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue100,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(15)),
              ),
              child: pw.Text(
                'Güven: ${(comparison.confidenceLevel * 100).toStringAsFixed(0)}%',
                style: _smallStyle,
              ),
            ),
          ],
        ),
        pw.Divider(thickness: 2),
        pw.SizedBox(height: 10),
        pw.Text('${athlete.firstName} ${athlete.lastName}', style: _headingStyle),
        pw.Text(DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()), 
            style: _smallStyle),
      ],
    );
  }

  /// Genel skor gösterimi
  static pw.Widget _buildOverallScore(ComprehensiveComparisonResult comparison) {
    final scoreColor = comparison.overallScore >= 80 ? PdfColors.green :
                      comparison.overallScore >= 60 ? PdfColors.orange :
                      PdfColors.red;
    
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: scoreColor, width: 2),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        children: [
          pw.Text('Genel Performans Skoru', style: _headingStyle),
          pw.SizedBox(height: 10),
          pw.Text(
            '${comparison.overallScore.toStringAsFixed(1)}/100',
            style: pw.TextStyle(
              fontSize: 36,
              fontWeight: pw.FontWeight.bold,
              color: scoreColor,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(_getScoreDescription(comparison.overallScore), 
              style: _normalStyle),
        ],
      ),
    );
  }

  /// Temel karşılaştırma bölümü
  static pw.Widget _buildBasicComparisonSection(BasicComparisonResult basic) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Performans Özeti', style: _headingStyle),
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
          children: [
            _buildComparisonStat('Genel Değişim', 
                '${basic.overallPercentChange > 0 ? '+' : ''}${basic.overallPercentChange.toStringAsFixed(1)}%',
                basic.overallPercentChange > 0 ? PdfColors.green : PdfColors.red),
            _buildComparisonStat('İyileşmeler', 
                '${basic.significantImprovements}',
                PdfColors.green),
            _buildComparisonStat('Düşüşler', 
                '${basic.significantDeclines}',
                PdfColors.red),
          ],
        ),
      ],
    );
  }

  /// Karşılaştırma istatistiği
  static pw.Widget _buildComparisonStat(String label, String value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(label, style: _smallStyle),
        pw.SizedBox(height: 5),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  /// Performans profili
  static pw.Widget _buildPerformanceProfile(dynamic profile) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Performans Profili', style: _headingStyle),
        pw.SizedBox(height: 10),
        pw.Container(
          padding: const pw.EdgeInsets.all(15),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                children: [
                  pw.Text('Güçlü Yön: ', style: _subheadingStyle),
                  pw.Text(profile.dominantStrength ?? 'Belirlenmedi', style: _normalStyle),
                ],
              ),
              pw.SizedBox(height: 5),
              pw.Row(
                children: [
                  pw.Text('Gelişim Alanı: ', style: _subheadingStyle),
                  pw.Text(profile.primaryWeakness ?? 'Belirlenmedi', style: _normalStyle),
                ],
              ),
              if (profile.recommendations != null && (profile.recommendations as List).isNotEmpty) ...[
                pw.SizedBox(height: 10),
                pw.Text('Profil Önerileri:', style: _subheadingStyle),
                ...(profile.recommendations as List).take(2).map((rec) => 
                  pw.Text('• $rec', style: _smallStyle)),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Öneriler bölümü
  static pw.Widget _buildRecommendations(List<dynamic> recommendations) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Antrenman Önerileri', style: _headingStyle),
        pw.SizedBox(height: 10),
        ...recommendations.take(3).map((rec) {
          final priorityColor = PdfColors.orange;
          
          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 10),
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border(
                left: pw.BorderSide(color: priorityColor, width: 3),
              ),
              color: PdfColors.grey50,
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(rec.title ?? 'Öneri', style: _subheadingStyle),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.orange100,
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                      ),
                      child: pw.Text(
                        'ORTA',
                        style: pw.TextStyle(fontSize: 10, color: priorityColor),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 5),
                pw.Text(rec.description ?? '', style: _smallStyle),
              ],
            ),
          );
        }),
      ],
    );
  }

  /// İstatistiksel analiz
  static pw.Widget _buildStatisticalAnalysis(dynamic stats) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('İstatistiksel Analiz', style: _headingStyle),
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Örneklem Büyüklüğü: ${stats.sampleSize ?? 0}', style: _normalStyle),
            pw.Text('Anlamlı Değişimler: ${stats.significantChanges?.length ?? 0}', style: _normalStyle),
          ],
        ),
        if (stats.pValue != null)
          pw.Text('P-değeri: ${stats.pValue!.toStringAsFixed(3)}', style: _smallStyle),
        if (stats.effectSize != null)
          pw.Text('Etki Büyüklüğü: ${stats.effectSize!.toStringAsFixed(2)}', style: _smallStyle),
      ],
    );
  }

  /// Raporu paylaş
  static Future<void> shareReport(Uint8List reportBytes, String fileName) async {
    try {
      AppLogger.info('📤 PDF raporu paylaşılıyor: $fileName');
      
      await FileShareService.sharePDFBytes(
        pdfBytes: reportBytes,
        fileName: fileName,
        subject: 'izForce Performans Raporu',
        text: 'Bu rapor izForce uygulaması tarafından otomatik olarak oluşturulmuştur.',
      );
      
      AppLogger.success('PDF raporu başarıyla paylaşıldı: $fileName');
      
    } catch (e, stackTrace) {
      AppLogger.error('PDF raporu paylaşma hatası', e, stackTrace);
      rethrow;
    }
  }

  /// PDF dosyasını paylaş
  static Future<void> shareGeneratedPDF({
    required File pdfFile,
    String? customSubject,
    String? customText,
  }) async {
    try {
      AppLogger.info('📤 PDF dosyası paylaşılıyor: ${pdfFile.path}');
      
      await FileShareService.sharePDFFile(
        pdfFile: pdfFile,
        subject: customSubject ?? 'izForce Performans Raporu',
        text: customText ?? 'Bu rapor izForce uygulaması tarafından otomatik olarak oluşturulmuştur. Detaylı performans analizi ve öneriler içerir.',
      );
      
      AppLogger.success('PDF dosyası başarıyla paylaşıldı');
      
    } catch (e, stackTrace) {
      AppLogger.error('PDF dosyası paylaşma hatası', e, stackTrace);
      rethrow;
    }
  }

  /// PDF oluştur ve otomatik paylaş
  static Future<File> generateAndSharePerformanceReport({
    required AthleteModel athlete,
    required List<TestResultModel> results,
    required PerformanceAnalysis analysis,
    BenchmarkComparison? benchmarkComparison,
    List<TestComparisonModel>? comparisons,
    Map<String, dynamic>? additionalData,
    bool autoShare = false,
  }) async {
    try {
      // Önce PDF'i oluştur
      final pdfFile = await generatePerformanceReport(
        athlete: athlete,
        results: results,
        analysis: analysis,
        benchmarkComparison: benchmarkComparison,
        comparisons: comparisons,
        additionalData: additionalData,
      );
      
      // Eğer otomatik paylaşım istenmişse
      if (autoShare) {
        await shareGeneratedPDF(
          pdfFile: pdfFile,
          customSubject: '${athlete.firstName} ${athlete.lastName} - Performans Raporu',
          customText: 'izForce ile oluşturulan detaylı performans analizi. ${results.length} test sonucu analiz edilmiştir.',
        );
      }
      
      return pdfFile;
      
    } catch (e, stackTrace) {
      AppLogger.error('PDF oluşturma ve paylaşma hatası', e, stackTrace);
      rethrow;
    }
  }

  /// Downloads klasörüne kaydet ve paylaş
  static Future<File?> saveToDownloadsAndShare({
    required File pdfFile,
    String? customFileName,
    bool autoShare = true,
  }) async {
    try {
      AppLogger.info('💾 PDF Downloads klasörüne kaydediliyor ve paylaşılıyor');
      
      // Downloads klasörüne kopyala
      final downloadedFile = await FileShareService.copyToDownloads(
        sourceFile: pdfFile,
        customFileName: customFileName,
      );
      
      if (downloadedFile != null && autoShare) {
        // Paylaş
        await shareGeneratedPDF(pdfFile: downloadedFile);
      }
      
      return downloadedFile;
      
    } catch (e, stackTrace) {
      AppLogger.error('Downloads kaydetme ve paylaşma hatası', e, stackTrace);
      return null;
    }
  }

  /// Yardımcı metodlar
  static int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month || 
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  static String _getTestTypeName(TestType type) {
    switch (type) {
      case TestType.counterMovementJump:
        return 'CMJ';
      case TestType.dropJump:
        return 'Drop Jump';
      default:
        return 'Test';
    }
  }

  static TestType _parseTestType(String typeStr) {
    switch (typeStr.toLowerCase()) {
      case 'cmj':
      case 'countermovementjump':
        return TestType.counterMovementJump;
      case 'dropjump':
      case 'drop_jump':
        return TestType.dropJump;
      default:
        return TestType.counterMovementJump;
    }
  }

  static String _getMetricUnit(String metric) {
    if (metric.toLowerCase().contains('height') || 
        metric.toLowerCase().contains('yükseklik')) return 'cm';
    if (metric.toLowerCase().contains('time') || 
        metric.toLowerCase().contains('süre')) return 's';
    if (metric.toLowerCase().contains('power') || 
        metric.toLowerCase().contains('güç')) return 'W';
    if (metric.toLowerCase().contains('force') || 
        metric.toLowerCase().contains('kuvvet')) return 'N';
    if (metric.toLowerCase().contains('velocity') || 
        metric.toLowerCase().contains('hız')) return 'm/s';
    return '';
  }

  static String _getScoreDescription(double score) {
    if (score >= 90) return 'Mükemmel Performans';
    if (score >= 80) return 'Çok İyi Performans';
    if (score >= 70) return 'İyi Performans';
    if (score >= 60) return 'Ortalama Performans';
    if (score >= 50) return 'Gelişim Gerektiren Performans';
    return 'Düşük Performans';
  }

  /// Test amaçlı basit PDF oluştur
  static Future<File> generateTestPDF() async {
    try {
      AppLogger.info('🧪 Test PDF oluşturuluyor...');
      
      // Fontları yükle
      await _loadFonts();
      
      final pdf = pw.Document();
      
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Column(
                children: [
                  pw.Text('Test PDF Raporu', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 20),
                  pw.Text('Bu bir test PDF dosyasıdır.'),
                  pw.Text('Oluşturma zamanı: ${DateTime.now()}'),
                  pw.SizedBox(height: 20),
                  pw.Text('Eğer bu dosyayı görebiliyorsanız, PDF oluşturma çalışıyor demektir.'),
                ],
              ),
            );
          },
        ),
      );
      
      // PDF'i kaydet
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'test_pdf_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${directory.path}/$fileName');
      
      AppLogger.info('🧪 Test PDF kaydediliyor: ${file.path}');
      
      final pdfBytes = await pdf.save();
      await file.writeAsBytes(pdfBytes);
      
      final exists = await file.exists();
      final fileSize = exists ? await file.length() : 0;
      
      AppLogger.info('🧪 Test PDF - Dosya var: $exists, Boyut: $fileSize bytes');
      AppLogger.success('Test PDF oluşturuldu: ${file.path}');
      
      return file;
      
    } catch (e, stackTrace) {
      AppLogger.error('Test PDF oluşturma hatası', e, stackTrace);
      rethrow;
    }
  }

  /// AI Insights raporu oluştur
  static Future<File> generateAIInsightsReport({
    required AthleteModel athlete,
    required List<TestResultModel> results,
    required Map<String, dynamic> insights,
    Map<String, dynamic>? scientificAnalysis,
    Map<String, dynamic>? forceVelocityProfile,
    Map<String, dynamic>? individualResponse,
    List<String>? recommendations,
  }) async {
    try {
      AppLogger.info('🤖 AI Insights raporu oluşturuluyor: ${athlete.firstName} ${athlete.lastName}');
      
      // Fontları yükle
      await _loadFonts();
      
      final pdf = pw.Document();
      final now = DateTime.now();
      
      // PDF sayfası oluştur
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return [
              // Başlık
              _buildAIInsightsHeader(athlete, now),
              pw.SizedBox(height: 20),
              
              // Genel AI Analiz Özeti
              _buildAIInsightsSummary(insights, results),
              pw.SizedBox(height: 20),
              
              // Bilimsel Analiz Bölümü
              if (scientificAnalysis != null) ...[
                _buildSectionTitle('Bilimsel Analiz'),
                pw.SizedBox(height: 10),
                _buildScientificAnalysisSection(scientificAnalysis),
                pw.SizedBox(height: 20),
              ],
              
              // Force-Velocity Profil
              if (forceVelocityProfile != null) ...[
                _buildSectionTitle('Force-Velocity Profilleme'),
                pw.SizedBox(height: 10),
                _buildForceVelocitySection(forceVelocityProfile),
                pw.SizedBox(height: 20),
              ],
              
              // Bireysel Yanıt Analizi
              if (individualResponse != null) ...[
                _buildSectionTitle('Bireysel Yanıt Variabilitesi'),
                pw.SizedBox(height: 10),
                _buildIndividualResponseSection(individualResponse),
                pw.SizedBox(height: 20),
              ],
              
              // AI Önerileri
              if (recommendations != null && recommendations.isNotEmpty) ...[
                _buildSectionTitle('Akıllı Öneriler'),
                pw.SizedBox(height: 10),
                _buildAIRecommendations(recommendations),
                pw.SizedBox(height: 20),
              ],
              
              // Alt bilgi
              _buildFooter(),
            ];
          },
        ),
      );
      
      // PDF'i kaydet
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'ai_insights_report_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${directory.path}/$fileName');
      
      AppLogger.info('📁 AI Insights PDF kaydediliyor: ${file.path}');
      AppLogger.info('📂 Directory path: ${directory.path}');
      
      final pdfBytes = await pdf.save();
      AppLogger.info('📊 AI PDF size: ${pdfBytes.length} bytes');
      
      await file.writeAsBytes(pdfBytes);
      
      // Dosya varlığını kontrol et
      final exists = await file.exists();
      final fileSize = exists ? await file.length() : 0;
      
      AppLogger.info('✅ AI Dosya oluşturuldu: $exists, Boyut: $fileSize bytes');
      AppLogger.success('AI Insights raporu oluşturuldu: ${file.path}');
      
      return file;
      
    } catch (e, stackTrace) {
      AppLogger.error('AI Insights raporu oluşturma hatası', e, stackTrace);
      rethrow;
    }
  }

  /// AI Insights başlığı
  static pw.Widget _buildAIInsightsHeader(AthleteModel athlete, DateTime date) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('🤖 AI Insights Raporu', style: _titleStyle),
            pw.Text(
              DateFormat('dd/MM/yyyy').format(date),
              style: _normalStyle,
            ),
          ],
        ),
        pw.Divider(thickness: 2),
        pw.SizedBox(height: 10),
        pw.Row(
          children: [
            pw.Text('Sporcu: ', style: _subheadingStyle),
            pw.Text('${athlete.firstName} ${athlete.lastName}', style: _normalStyle),
          ],
        ),
        if (athlete.sport != null)
          pw.Row(
            children: [
              pw.Text('Branş: ', style: _subheadingStyle),
              pw.Text(athlete.sport!, style: _normalStyle),
            ],
          ),
      ],
    );
  }

  /// AI analiz özeti
  static pw.Widget _buildAIInsightsSummary(Map<String, dynamic> insights, List<TestResultModel> results) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.blue300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        color: PdfColors.blue50,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('🎯 AI Analiz Özeti', style: _headingStyle),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildAISummaryItem('Toplam Test', '${results.length}'),
              _buildAISummaryItem('Analiz Skoru', '${insights['overallScore']?.toStringAsFixed(1) ?? "N/A"}/100'),
              _buildAISummaryItem('Güven Seviyesi', '${((insights['confidenceLevel'] ?? 0.0) * 100).toStringAsFixed(0)}%'),
            ],
          ),
          pw.SizedBox(height: 10),
          if (insights['summary'] != null)
            pw.Text('📊 ${insights['summary']}', style: _normalStyle),
        ],
      ),
    );
  }

  /// AI özet öğesi
  static pw.Widget _buildAISummaryItem(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(label, style: _smallStyle),
        pw.SizedBox(height: 5),
        pw.Text(value, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue600)),
      ],
    );
  }

  /// Bilimsel analiz bölümü
  static pw.Widget _buildScientificAnalysisSection(Map<String, dynamic> analysis) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.green300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        color: PdfColors.green50,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('🔬 Research-Grade Analiz', style: _subheadingStyle),
          pw.SizedBox(height: 8),
          if (analysis['effectSize'] != null)
            pw.Text('Effect Size: ${analysis['effectSize'].toStringAsFixed(3)}', style: _normalStyle),
          if (analysis['magnitudeBasedInference'] != null)
            pw.Text('MBI Sonucu: ${analysis['magnitudeBasedInference']}', style: _normalStyle),
          if (analysis['statisticalSignificance'] != null)
            pw.Text('İstatistiksel Anlamlılık: ${analysis['statisticalSignificance'] ? "Var" : "Yok"}', style: _normalStyle),
          if (analysis['powerAnalysis'] != null)
            pw.Text('Power Analizi: ${analysis['powerAnalysis'].toStringAsFixed(2)}', style: _normalStyle),
        ],
      ),
    );
  }

  /// Force-Velocity profil bölümü
  static pw.Widget _buildForceVelocitySection(Map<String, dynamic> fvProfile) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.orange300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        color: PdfColors.orange50,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('⚡ F-V Profil Analizi (Samozino et al., 2016)', style: _subheadingStyle),
          pw.SizedBox(height: 8),
          if (fvProfile['theoreticalMaxForce'] != null)
            pw.Text('Teorik Max Kuvvet: ${fvProfile['theoreticalMaxForce'].toStringAsFixed(0)} N', style: _normalStyle),
          if (fvProfile['theoreticalMaxVelocity'] != null)
            pw.Text('Teorik Max Hız: ${fvProfile['theoreticalMaxVelocity'].toStringAsFixed(2)} m/s', style: _normalStyle),
          if (fvProfile['maxPower'] != null)
            pw.Text('Max Güç: ${fvProfile['maxPower'].toStringAsFixed(0)} W', style: _normalStyle),
          if (fvProfile['forceDeficit'] != null)
            pw.Text('Kuvvet Eksikliği: ${fvProfile['forceDeficit'].toStringAsFixed(1)}%', style: _normalStyle),
          if (fvProfile['velocityDeficit'] != null)
            pw.Text('Hız Eksikliği: ${fvProfile['velocityDeficit'].toStringAsFixed(1)}%', style: _normalStyle),
        ],
      ),
    );
  }

  /// Bireysel yanıt bölümü
  static pw.Widget _buildIndividualResponseSection(Map<String, dynamic> irv) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.purple300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        color: PdfColors.purple50,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('👤 Bireysel Yanıt Analizi', style: _subheadingStyle),
          pw.SizedBox(height: 8),
          if (irv['responseClassification'] != null)
            pw.Text('Yanıt Sınıfı: ${irv['responseClassification']}', style: _normalStyle),
          if (irv['coefficientOfVariation'] != null)
            pw.Text('Variasyon Katsayısı: ${(irv['coefficientOfVariation'] * 100).toStringAsFixed(1)}%', style: _normalStyle),
          if (irv['minimumDetectableChange'] != null)
            pw.Text('Min. Tespit Edilebilir Değişim: ${irv['minimumDetectableChange'].toStringAsFixed(2)}%', style: _normalStyle),
          if (irv['trainingResponsiveness'] != null)
            pw.Text('Antrenman Yanıtı: ${irv['trainingResponsiveness']}', style: _normalStyle),
        ],
      ),
    );
  }

  /// AI önerileri
  static pw.Widget _buildAIRecommendations(List<String> recommendations) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('🎯 Personalized Öneriler', style: _subheadingStyle),
        pw.SizedBox(height: 10),
        ...recommendations.take(5).map((rec) => pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 8),
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            border: pw.Border(
              left: pw.BorderSide(color: PdfColors.blue400, width: 3),
            ),
          ),
          child: pw.Text(
            '• $rec',
            style: _normalStyle,
          ),
        )),
      ],
    );
  }

  /// Özel rapor oluştur
  static Future<File> generateCustomReport({
    required String title,
    required Map<String, dynamic> data,
    required List<String> sections,
    required Map<String, dynamic> formatting,
  }) async {
    try {
      AppLogger.info('📋 Özel rapor oluşturuluyor: $title');
      
      // Fontları yükle
      await _loadFonts();
      
      final pdf = pw.Document();
      final now = DateTime.now();
      
      // PDF sayfası oluştur
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return [
              // Başlık
              _buildCustomReportHeader(title, now),
              pw.SizedBox(height: 20),
              
              // Sporcu Bilgileri
              if (sections.contains('Sporcu Bilgileri') && data.containsKey('athleteInfo')) ...[ 
                _buildSectionTitle('Sporcu Bilgileri'),
                pw.SizedBox(height: 10),
                _buildAthleteInfoSection(data['athleteInfo']),
                pw.SizedBox(height: 20),
              ],
              
              // Test Özeti
              if (sections.contains('Test Özeti') && data.containsKey('testTypes')) ...[
                _buildSectionTitle('Test Özeti'),
                pw.SizedBox(height: 10),
                _buildTestSummarySection(data),
                pw.SizedBox(height: 20),
              ],
              
              // Performans Metrikleri
              if (sections.contains('Performans Metrikleri') && data.containsKey('metrics')) ...[
                _buildSectionTitle('Performans Metrikleri'),
                pw.SizedBox(height: 10),
                _buildMetricsSummarySection(data['metrics']),
                pw.SizedBox(height: 20),
              ],
              
              // Analiz Sonuçları
              if (sections.contains('Analiz Sonuçları')) ...[
                _buildSectionTitle('Analiz Sonuçları'),
                pw.SizedBox(height: 10),
                _buildAnalysisResultsSection(data),
                pw.SizedBox(height: 20),
              ],
              
              // Alt bilgi
              _buildFooter(),
            ];
          },
        ),
      );
      
      // PDF'i kaydet
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'custom_report_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${directory.path}/$fileName');
      
      AppLogger.info('📁 Özel rapor kaydediliyor: ${file.path}');
      
      final pdfBytes = await pdf.save();
      AppLogger.info('📊 Özel rapor boyutu: ${pdfBytes.length} bytes');
      
      await file.writeAsBytes(pdfBytes);
      
      // Dosya varlığını kontrol et
      final exists = await file.exists();
      final fileSize = exists ? await file.length() : 0;
      
      AppLogger.info('✅ Özel rapor oluşturuldu: $exists, Boyut: $fileSize bytes');
      AppLogger.success('Özel rapor oluşturuldu: ${file.path}');
      
      return file;
      
    } catch (e, stackTrace) {
      AppLogger.error('Özel rapor oluşturma hatası', e, stackTrace);
      rethrow;
    }
  }

  /// Özel rapor başlığı
  static pw.Widget _buildCustomReportHeader(String title, DateTime date) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Expanded(
              child: pw.Text(title, style: _titleStyle),
            ),
            pw.Text(
              DateFormat('dd/MM/yyyy').format(date),
              style: _normalStyle,
            ),
          ],
        ),
        pw.Divider(thickness: 2),
        pw.SizedBox(height: 10),
      ],
    );
  }

  /// Sporcu bilgi bölümü
  static pw.Widget _buildAthleteInfoSection(Map<String, dynamic> athleteInfo) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (athleteInfo['name'] != null)
            pw.Row(
              children: [
                pw.Text('Sporcu: ', style: _subheadingStyle),
                pw.Text(athleteInfo['name'].toString(), style: _normalStyle),
              ],
            ),
          if (athleteInfo['sport'] != null)
            pw.Row(
              children: [
                pw.Text('Branş: ', style: _subheadingStyle),
                pw.Text(athleteInfo['sport'].toString(), style: _normalStyle),
              ],
            ),
          if (athleteInfo['totalTests'] != null)
            pw.Row(
              children: [
                pw.Text('Toplam Test: ', style: _subheadingStyle),
                pw.Text(athleteInfo['totalTests'].toString(), style: _normalStyle),
              ],
            ),
        ],
      ),
    );
  }

  /// Test özet bölümü
  static pw.Widget _buildTestSummarySection(Map<String, dynamic> data) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (data['dateRange'] != null)
            pw.Text(
              'Tarih Aralığı: ${DateFormat('dd/MM/yyyy').format(data['dateRange']['from'])} - ${DateFormat('dd/MM/yyyy').format(data['dateRange']['to'])}',
              style: _normalStyle,
            ),
          pw.SizedBox(height: 10),
          if (data['testTypes'] != null && (data['testTypes'] as List).isNotEmpty)
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Test Türleri:', style: _subheadingStyle),
                pw.SizedBox(height: 5),
                ...(data['testTypes'] as List).map((testType) => 
                  pw.Text('• $testType', style: _normalStyle)),
              ],
            ),
        ],
      ),
    );
  }

  /// Metrik özet bölümü
  static pw.Widget _buildMetricsSummarySection(Map<String, dynamic> metrics) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Temel Metrikler', style: _subheadingStyle),
          pw.SizedBox(height: 10),
          ...metrics.entries.take(5).map((entry) => 
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 2),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(entry.key, style: _normalStyle),
                  pw.Text(
                    entry.value is double 
                      ? entry.value.toStringAsFixed(1)
                      : entry.value.toString(), 
                    style: _normalStyle
                  ),
                ],
              ),
            )),
        ],
      ),
    );
  }

  /// Analiz sonuçları bölümü
  static pw.Widget _buildAnalysisResultsSection(Map<String, dynamic> data) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Analiz Özeti', style: _subheadingStyle),
          pw.SizedBox(height: 10),
          pw.Text(
            'Bu özel rapor, seçilen kriterler doğrultusunda oluşturulmuştur.',
            style: _normalStyle,
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            'Detaylı analiz sonuçları ve öneriler için tam performans raporu incelenebilir.',
            style: _smallStyle,
          ),
        ],
      ),
    );
  }
}