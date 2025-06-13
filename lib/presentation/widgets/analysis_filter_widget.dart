import 'package:flutter/material.dart';
import '../../data/models/athlete_model.dart';
import '../theme/app_theme.dart';

/// Gelişmiş filtreleme widget - sporcu, tarih, test türü, metrik
class AnalysisFilterWidget extends StatefulWidget {
  final List<AthleteModel> athletes;
  final String? selectedAthleteId;
  final String selectedTestType;
  final DateTimeRange? selectedDateRange;
  final String selectedMetric;
  final int resultCount;
  final Function(String?) onAthleteChanged;
  final Function(String) onTestTypeChanged;
  final Function(DateTimeRange?) onDateRangeChanged;
  final Function(String) onMetricChanged;
  final VoidCallback? onRefresh;
  final bool isExpanded;
  final bool isDarkTheme;

  const AnalysisFilterWidget({
    Key? key,
    required this.athletes,
    this.selectedAthleteId,
    required this.selectedTestType,
    this.selectedDateRange,
    required this.selectedMetric,
    required this.resultCount,
    required this.onAthleteChanged,
    required this.onTestTypeChanged,
    required this.onDateRangeChanged,
    required this.onMetricChanged,
    this.onRefresh,
    this.isExpanded = true,
    this.isDarkTheme = false,
  }) : super(key: key);

  @override
  State<AnalysisFilterWidget> createState() => _AnalysisFilterWidgetState();
}

class _AnalysisFilterWidgetState extends State<AnalysisFilterWidget> {
  bool _isExpanded = true;

  // Test türleri
  final List<String> _testTypes = [
    'Tümü', 'CMJ', 'SJ', 'DJ', 'IMTP', 'Denge Testleri', 'Çeviklik Testleri'
  ];
  
  // Test türüne göre metrikler - improved mapping
  final Map<String, List<String>> _testMetrics = {
    'Tümü': ['Tüm Metrikler'],
    'CMJ': [
      'Tüm Metrikler',
      'jumpHeight', // Jump Height (Sıçrama Yüksekliği)
      'peakForce', // Peak Force (Tepe Kuvvet)
      'peakPower', // Peak Power (Tepe Güç)
      'rfd', // RFD (Kuvvet Gelişim Hızı)
      'flightTime', // Flight Time (Uçuş Süresi)
      'contactTime', // Contact Time (Temas Süresi)
      'takeoffVelocity', // Takeoff Velocity (Kalkış Hızı)
      'asymmetryIndex', // Asymmetry Index (Asimetri İndeksi)
      'reactiveStrengthIndex', // Reactive Strength Index (RSI)
    ],
    'SJ': [
      'Tüm Metrikler',
      'jumpHeight', // Jump Height (Sıçrama Yüksekliği)
      'peakForce', // Peak Force (Tepe Kuvvet)
      'peakPower', // Peak Power (Tepe Güç)
      'rfd', // Concentric RFD (Konsantrik RFD)
      'flightTime', // Flight Time (Uçuş Süresi)
      'takeoffVelocity', // Takeoff Velocity (Kalkış Hızı)
      'asymmetryIndex', // Asymmetry Index (Asimetri İndeksi)
    ],
    'DJ': [
      'Tüm Metrikler',
      'jumpHeight', // Jump Height (Sıçrama Yüksekliği)
      'contactTime', // Contact Time (Temas Süresi)
      'reactiveStrengthIndex', // Reactive Strength Index (RSI)
      'peakForce', // Peak Landing Force (Pik İniş Kuvveti)
      'rfd', // Landing RFD (İniş RFD)
      'asymmetryIndex', // Landing Asymmetry (İniş Asimetrisi)
    ],
    'IMTP': [
      'Tüm Metrikler',
      'peakForce', // Peak Force (Tepe Kuvvet)
      'rfd0_50ms', // RFD 0-50ms
      'rfd0_100ms', // RFD 0-100ms
      'rfd0_200ms', // RFD 0-200ms
      'impulse100ms', // Impulse 0-100ms
      'impulse200ms', // Impulse 0-200ms
      'asymmetryIndex', // Asymmetry Index (Asimetri İndeksi)
      'relativeForce', // Relative Force (Relatif Kuvvet)
    ],
    'Denge Testleri': [
      'Tüm Metrikler',
      'copRange', // COP Range (COP Mesafesi)
      'copVelocity', // COP Velocity (COP Hızı)
      'copArea', // COP Area (COP Alanı)
      'stabilityIndex', // Stability Index (Stabilite İndeksi)
      'copRangeML', // Mediolateral Sway (Yanal Salınım)
      'copRangeAP', // Anteroposterior Sway (Ön-Arka Salınım)
    ],
    'Çeviklik Testleri': [
      'Tüm Metrikler',
      'hopDistance', // Hop Distance (Hop Mesafesi)
      'contactTime', // Contact Time (Temas Süresi)
      'stabilityIndex', // Landing Stability (İniş Stabilitesi)
      'asymmetryIndex', // Limb Symmetry Index (Bacak Simetri İndeksi)
    ],
  };
  
  // Metric display names for UI
  final Map<String, String> _metricDisplayNames = {
    'Tüm Metrikler': 'Tüm Metrikler',
    'jumpHeight': 'Sıçrama Yüksekliği (cm)',
    'peakForce': 'Tepe Kuvvet (N)',
    'peakPower': 'Tepe Güç (W)',
    'rfd': 'Kuvvet Gelişim Hızı (N/s)',
    'flightTime': 'Uçuş Süresi (ms)',
    'contactTime': 'Temas Süresi (ms)',
    'takeoffVelocity': 'Kalkış Hızı (m/s)',
    'asymmetryIndex': 'Asimetri İndeksi (%)',
    'reactiveStrengthIndex': 'Reaktif Güç İndeksi',
    'rfd0_50ms': 'RFD 0-50ms (N/s)',
    'rfd0_100ms': 'RFD 0-100ms (N/s)',
    'rfd0_200ms': 'RFD 0-200ms (N/s)',
    'impulse100ms': 'Impulse 0-100ms (Ns)',
    'impulse200ms': 'Impulse 0-200ms (Ns)',
    'relativeForce': 'Relatif Kuvvet',
    'copRange': 'COP Mesafesi (mm)',
    'copVelocity': 'COP Hızı (mm/s)',
    'copArea': 'COP Alanı (mm²)',
    'stabilityIndex': 'Stabilite İndeksi',
    'copRangeML': 'COP Yanal Mesafe (mm)',
    'copRangeAP': 'COP Ön-Arka Mesafe (mm)',
    'hopDistance': 'Hop Mesafesi (cm)',
  };

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isExpanded;
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            offset: const Offset(0, 2),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with toggle
          _buildHeader(),
          
          // Expandable content
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: _buildFilterContent(),
            sizeCurve: Curves.easeInOut,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return InkWell(
      onTap: _toggleExpansion,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.tune,
                color: AppTheme.primaryColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Analiz Filtreleri',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${widget.resultCount} test sonuçu',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.onRefresh != null)
                  IconButton(
                    onPressed: widget.onRefresh,
                    icon: const Icon(
                      Icons.refresh,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                    tooltip: 'Yenile',
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                const SizedBox(width: 8),
                AnimatedRotation(
                  turns: _isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: const Icon(
                    Icons.keyboard_arrow_down,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterContent() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          // Divider
          Divider(color: AppTheme.darkDivider),
          const SizedBox(height: 16),
          
          // Basit dropdown'lar
          _buildSimpleFilters(),
        ],
      ),
    );
  }

  Widget _buildSimpleFilters() {
    return Column(
      children: [
        // İlk satır: Sporcu ve Test Türü
        Row(
          children: [
            // Sporcu seçimi
            Expanded(
              child: _buildDropdownField<String?>(
                label: 'Sporcu',
                value: widget.selectedAthleteId,
                items: [
                  DropdownItem<String?>(value: null, label: 'Tüm Sporcular'),
                  ...widget.athletes.map((athlete) => 
                    DropdownItem<String?>(value: athlete.id, label: athlete.fullName)
                  ),
                ],
                onChanged: widget.onAthleteChanged,
              ),
            ),
            const SizedBox(width: 12),
            
            // Test türü seçimi
            Expanded(
              child: _buildDropdownField<String>(
                label: 'Test Türü',
                value: widget.selectedTestType,
                items: _testTypes.map((type) => 
                  DropdownItem<String>(value: type, label: type)
                ).toList(),
                onChanged: (value) {
                  if (value != null) {
                    widget.onTestTypeChanged(value);
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // İkinci satır: Tarih Aralığı ve Metrik
        Row(
          children: [
            // Tarih aralığı seçimi
            Expanded(
              child: _buildDateRangeField(),
            ),
            const SizedBox(width: 12),
            
            // Metrik seçimi (test türüne bağlı)
            Expanded(
              child: _buildDropdownField<String>(
                label: 'Metrik',
                value: widget.selectedMetric,
                items: _getAvailableMetrics().map((metric) => 
                  DropdownItem<String>(
                    value: metric, 
                    label: _getMetricDisplayName(metric)
                  )
                ).toList(),
                onChanged: (value) {
                  if (value != null) {
                    widget.onMetricChanged(value);
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Test türüne göre mevcut metrikleri getir
  List<String> _getAvailableMetrics() {
    final metrics = _testMetrics[widget.selectedTestType] ?? ['Tüm Metrikler'];
    
    // Ensure selected metric is available, otherwise reset to default
    if (!metrics.contains(widget.selectedMetric)) {
      // Call the callback to reset to first available metric
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (metrics.isNotEmpty) {
          widget.onMetricChanged(metrics.first);
        }
      });
    }
    
    return metrics;
  }
  
  // Get display name for metric
  String _getMetricDisplayName(String metric) {
    return _metricDisplayNames[metric] ?? metric;
  }

  // Tarih aralığı seçici
  Widget _buildDateRangeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tarih Aralığı',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: _selectDateRange,
          child: Container(
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.darkBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _getDateRangeText(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(
                  Icons.date_range,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 12),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Tarih aralığı seçimi
  Future<void> _selectDateRange() async {
    try {
      final now = DateTime.now();
      final DateTimeRange? picked = await showDateRangePicker(
        context: context,
        firstDate: now.subtract(const Duration(days: 365 * 2)), // 2 yıl öncesi
        lastDate: now,
        initialDateRange: widget.selectedDateRange ?? DateTimeRange(
          start: now.subtract(const Duration(days: 90)), // Son 3 ay
          end: now,
        ),
        locale: const Locale('tr', 'TR'),
        helpText: 'Tarih Aralığı Seçin',
        cancelText: 'İptal',
        confirmText: 'Tamam',
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: AppTheme.primaryColor,
                onPrimary: Colors.white,
                surface: AppTheme.darkCard,
                onSurface: Colors.white,
                background: AppTheme.darkBackground,
                onBackground: Colors.white,
              ),
              textTheme: Theme.of(context).textTheme.copyWith(
                bodyLarge: const TextStyle(color: Colors.white),
                bodyMedium: const TextStyle(color: Colors.white),
              ),
            ),
            child: child!,
          );
        },
      );

      if (picked != null && picked != widget.selectedDateRange) {
        // Validate date range
        if (picked.start.isAfter(picked.end)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Geçersiz tarih aralığı'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
        
        widget.onDateRangeChanged(picked);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tarih seçiminde hata oluştu'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  // Tarih aralığı metni
  String _getDateRangeText() {
    if (widget.selectedDateRange == null) {
      return 'Tarih aralığı seçin';
    }
    
    final start = widget.selectedDateRange!.start;
    final end = widget.selectedDateRange!.end;
    
    final startText = '${start.day}/${start.month}/${start.year}';
    final endText = '${end.day}/${end.month}/${end.year}';
    
    return '$startText - $endText';
  }
  
  Widget _buildDropdownField<T>({
    required String label,
    required T? value,
    required List<DropdownItem<T>> items,
    required Function(T?) onChanged,
  }) {
    // Ensure the value exists in items
    final validValue = items.any((item) => item.value == value) ? value : null;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 42,
          decoration: BoxDecoration(
            color: AppTheme.darkBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppTheme.primaryColor.withValues(alpha: 0.3),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: validValue,
              onChanged: (newValue) {
                if (newValue != null) {
                  onChanged(newValue);
                }
              },
              isExpanded: true,
              dropdownColor: AppTheme.darkCard,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
              ),
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: AppTheme.primaryColor,
                size: 20,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              menuMaxHeight: 300, // Limit dropdown height
              items: items.map((item) => 
                DropdownMenuItem<T>(
                  value: item.value,
                  child: Tooltip(
                    message: item.label,
                    child: Text(
                      item.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ),
              ).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class DropdownItem<T> {
  final T value;
  final String label;

  DropdownItem({
    required this.value,
    required this.label,
  });
}