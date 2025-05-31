import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_constants.dart';
import '../../presentation/theme/app_theme.dart';
import '../../presentation/controllers/test_controller.dart';
import '../../presentation/controllers/athlete_controller.dart';
import '../../presentation/widgets/force_plate_widget.dart';
import '../../presentation/widgets/metrics_display_widget.dart';
import '../../presentation/widgets/phase_indicator_widget.dart';

/// Test yürütme ekranı - Kalibrasyon'dan sonuçlara kadar tüm süreç
class TestExecutionScreen extends StatelessWidget {
  const TestExecutionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: GetBuilder<TestController>(
        builder: (testController) {
          return GetBuilder<AthleteController>(
            builder: (athleteController) {
              final currentStep = testController.currentStep;
              
              return WillPopScope(
                onWillPop: () => _onWillPop(testController),
                child: SafeArea(
                  child: Column(
                    children: [
                      // Custom app bar
                      _buildCustomAppBar(testController, athleteController),
                      
                      // Progress indicator
                      _buildProgressIndicator(testController),
                      
                      // Main content based on current step
                      Expanded(
                        child: _buildStepContent(currentStep, testController, athleteController),
                      ),
                      
                      // Bottom navigation/actions
                      _buildBottomActions(currentStep, testController),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildCustomAppBar(TestController testController, AthleteController athleteController) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            onPressed: () => _onBackPressed(testController),
            icon: Icon(
              Icons.arrow_back,
              color: Colors.white,
            ),
          ),
          
          // Title and subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getStepTitle(testController.currentStep),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  children: [
                    if (athleteController.selectedAthlete != null) ...[
                      Icon(
                        Icons.person,
                        size: 14,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        athleteController.selectedAthlete!.fullName,
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    if (testController.selectedTestType != null) ...[
                      Text(
                        ' • ',
                        style: TextStyle(
                          color: AppTheme.textHint,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        testController.selectedTestType!.code,
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          
          // Connection status
          _buildConnectionIndicator(testController),
        ],
      ),
    );
  }

  Widget _buildConnectionIndicator(TestController testController) {
    final isConnected = testController.isConnected;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isConnected 
            ? AppTheme.successColor.withOpacity(0.2)
            : AppTheme.errorColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isConnected ? Icons.wifi : Icons.wifi_off,
            size: 12,
            color: isConnected ? AppTheme.successColor : AppTheme.errorColor,
          ),
          const SizedBox(width: 4),
          Text(
            isConnected ? 'Bağlı' : 'Offline',
            style: TextStyle(
              color: isConnected ? AppTheme.successColor : AppTheme.errorColor,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(TestController testController) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Step indicators
          Row(
            children: TestStep.values.asMap().entries.map((entry) {
              final index = entry.key;
              final step = entry.value;
              final isCurrent = step == testController.currentStep;
              final isCompleted = _isStepCompleted(step, testController.currentStep);
              
              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStepIndicator(
                        step: step,
                        isCurrent: isCurrent,
                        isCompleted: isCompleted,
                      ),
                    ),
                    if (index < TestStep.values.length - 1)
                      _buildStepConnector(isCompleted),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          
          // Progress bar
          LinearProgressIndicator(
            value: testController.overallProgress,
            backgroundColor: AppTheme.darkDivider,
            valueColor: AlwaysStoppedAnimation(AppTheme.primaryColor),
            minHeight: 4,
          ),
          const SizedBox(height: 8),
          
          // Progress text
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'İlerleme',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
              Text(
                '${(testController.overallProgress * 100).toStringAsFixed(0)}% Tamamlandı',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator({
    required TestStep step,
    required bool isCurrent,
    required bool isCompleted,
  }) {
    final color = isCurrent 
        ? AppTheme.primaryColor
        : isCompleted 
            ? AppTheme.successColor
            : AppTheme.textHint;
    
    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isCurrent || isCompleted 
                ? color.withOpacity(0.2)
                : AppTheme.darkBackground,
            border: Border.all(
              color: color,
              width: isCurrent ? 2 : 1,
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isCompleted 
                ? Icons.check
                : _getStepIcon(step),
            color: color,
            size: isCurrent ? 14 : 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _getStepShortName(step),
          style: TextStyle(
            color: color,
            fontSize: 9,
            fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStepConnector(bool isCompleted) {
    return Container(
      height: 2,
      width: 16,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: isCompleted ? AppTheme.successColor : AppTheme.darkDivider,
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }

  Widget _buildStepContent(TestStep currentStep, TestController testController, AthleteController athleteController) {
    switch (currentStep) {
      case TestStep.deviceConnection:
        return _buildDeviceConnectionStep(testController);
      case TestStep.athleteSelection:
        return _buildAthleteSelectionStep(testController, athleteController);
      case TestStep.testSelection:
        return _buildTestSelectionStep(testController);
      case TestStep.calibration:
        return _buildCalibrationStep(testController);
      case TestStep.weightMeasurement:
        return _buildWeightMeasurementStep(testController);
      case TestStep.testExecution:
        return _buildTestExecutionStep(testController);
      case TestStep.results:
        return _buildResultsStep(testController);
    }
  }

  Widget _buildDeviceConnectionStep(TestController testController) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              testController.isConnected ? Icons.check_circle : Icons.link,
              size: 80,
              color: testController.isConnected ? AppTheme.successColor : AppTheme.primaryColor,
            ),
            const SizedBox(height: 24),
            Text(
              testController.isConnected ? 'Cihaz Bağlandı' : 'Cihaza Bağlan',
              style: Get.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              testController.isConnected 
                  ? 'Force plate cihazı başarıyla bağlandı. Devam etmek için İleri butonuna tıklayın.'
                  : 'Test yapmak için önce force plate cihazına bağlanmanız gerekiyor.',
              style: Get.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (!testController.isConnected)
              ElevatedButton.icon(
                onPressed: () => testController.connectToDevice('USB_ForcePlate_001'),
                icon: testController.connectionStatus == ConnectionStatus.connecting
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : Icon(Icons.link),
                label: Text(testController.connectionStatus == ConnectionStatus.connecting 
                    ? 'Bağlanıyor...' 
                    : 'Cihaza Bağlan'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAthleteSelectionStep(TestController testController, AthleteController athleteController) {
    final selectedAthlete = athleteController.selectedAthlete;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selectedAthlete != null ? Icons.check_circle : Icons.person_add,
              size: 80,
              color: selectedAthlete != null ? AppTheme.successColor : AppTheme.primaryColor,
            ),
            const SizedBox(height: 24),
            Text(
              selectedAthlete != null ? 'Sporcu Seçildi' : 'Sporcu Seç',
              style: Get.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (selectedAthlete != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.darkCard,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      selectedAthlete.fullName,
                      style: Get.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (selectedAthlete.sport != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        selectedAthlete.sport!,
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              )
            else
              Text(
                'Test yapmak için bir sporcu seçmeniz gerekiyor.',
                style: Get.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 32),
            if (selectedAthlete == null)
              ElevatedButton.icon(
                onPressed: () => Get.toNamed('/athlete-selection'),
                icon: Icon(Icons.person),
                label: Text('Sporcu Seç'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestSelectionStep(TestController testController) {
    final selectedTest = testController.selectedTestType;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selectedTest != null ? Icons.check_circle : Icons.analytics,
              size: 80,
              color: selectedTest != null ? AppTheme.successColor : AppTheme.primaryColor,
            ),
            const SizedBox(height: 24),
            Text(
              selectedTest != null ? 'Test Seçildi' : 'Test Türü Seç',
              style: Get.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (selectedTest != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.darkCard,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      selectedTest.turkishName,
                      style: Get.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      selectedTest.code,
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )
            else
              Text(
                'Uygulanacak test türünü seçmeniz gerekiyor.',
                style: Get.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 32),
            if (selectedTest == null)
              ElevatedButton.icon(
                onPressed: () => Get.toNamed('/test-selection'),
                icon: Icon(Icons.analytics),
                label: Text('Test Seç'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalibrationStep(TestController testController) {
    return Obx(() {
      final isCalibrated = testController.isCalibrated;
      final progress = testController.calibrationProgress;
      final isLoading = testController.isLoading;
      
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Calibration status
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Calibration icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: isCalibrated 
                          ? AppTheme.successColor.withOpacity(0.2)
                          : AppTheme.primaryColor.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isCalibrated ? Icons.check_circle : Icons.tune,
                      size: 50,
                      color: isCalibrated ? AppTheme.successColor : AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  Text(
                    isCalibrated ? 'Kalibrasyon Tamamlandı' : 'Platform Kalibrasyonu',
                    style: Get.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  
                  Text(
                    isCalibrated 
                        ? 'Force plate kalibrasyonu başarıyla tamamlandı. Devam etmek için İleri butonuna tıklayın.'
                        : 'Doğru ölçüm için platformların sıfır noktasını kalibre edeceğiz. Platform üzerinde kimse yokken kalibrasyon başlatın.',
                    style: Get.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  
                  // Progress indicator
                  if (isLoading) ...[
                    SizedBox(
                      width: 200,
                      child: Column(
                        children: [
                          LinearProgressIndicator(
                            value: progress,
                            backgroundColor: AppTheme.darkDivider,
                            valueColor: AlwaysStoppedAnimation(AppTheme.primaryColor),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${(progress * 100).toStringAsFixed(0)}% Tamamlandı',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else if (!isCalibrated) ...[
                    ElevatedButton.icon(
                      onPressed: () => testController.startCalibration(),
                      icon: Icon(Icons.play_arrow),
                      label: Text('Kalibrasyonu Başlat'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Force plate visualization
            const ForcePlateWidget(
              width: double.infinity,
              height: 150,
              showCOP: false,
              showForceValues: false,
              showAsymmetry: false,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildWeightMeasurementStep(TestController testController) {
    return Obx(() {
      final isWeightStable = testController.isWeightStable;
      final measuredWeight = testController.measuredWeight;
      
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Weight measurement status
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Weight icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: isWeightStable 
                          ? AppTheme.successColor.withOpacity(0.2)
                          : AppTheme.warningColor.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isWeightStable ? Icons.check_circle : Icons.monitor_weight,
                      size: 50,
                      color: isWeightStable ? AppTheme.successColor : AppTheme.warningColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  Text(
                    testController.weightStatus,
                    style: Get.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  
                  if (measuredWeight != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.darkCard,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.monitor_weight,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${measuredWeight.toStringAsFixed(1)} kg',
                            style: Get.textTheme.headlineMedium?.copyWith(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  Text(
                    isWeightStable 
                        ? 'Ağırlık ölçümü kararlı. Test başlatmaya hazırsınız.'
                        : 'Platformlara çıkın ve sabit durun. Ağırlığınız ölçülüyor...',
                    style: Get.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  // Weight stability indicator
                  if (!isWeightStable && measuredWeight != null) ...[
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(AppTheme.warningColor),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Stabilite bekleniyor...',
                          style: TextStyle(
                            color: AppTheme.warningColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    // Debug için manuel stabil yapma butonu
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        // Test için manuel olarak stabil yap
                        testController._isWeightStable.value = true;
                        testController.update();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.warningColor,
                      ),
                      child: Text('Debug: Manuel Stabil Yap'),
                    ),
                  ],
                ],
              ),
            ),
            
            // Force plate visualization
            const ForcePlateWidget(
              width: double.infinity,
              height: 150,
              showCOP: true,
              showForceValues: true,
              showAsymmetry: true,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildTestExecutionStep(TestController testController) {
    return Obx(() {
      final isTestRunning = testController.isTestRunning;
      final testDuration = testController.testDuration;
      final currentPhase = testController.currentPhase;
      
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Test status and timer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.darkCard,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  // Status indicator
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isTestRunning 
                          ? AppTheme.successColor.withOpacity(0.2)
                          : AppTheme.primaryColor.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isTestRunning ? Icons.play_circle : Icons.play_circle_outline,
                      color: isTestRunning ? AppTheme.successColor : AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isTestRunning ? 'Test Devam Ediyor' : 'Test Başlatmaya Hazır',
                          style: Get.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${testDuration.inSeconds}.${(testDuration.inMilliseconds % 1000 ~/ 100)}s',
                          style: Get.textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Sample count
                  Text(
                    '${testController.sampleCount} örnek',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Phase indicator
            PhaseIndicatorWidget(
              style: PhaseIndicatorStyle.horizontal,
              height: 80,
            ),
            const SizedBox(height: 16),
            
            // Force plate visualization
            const ForcePlateWidget(
              width: double.infinity,
              height: 200,
              showCOP: true,
              showForceValues: true,
              showAsymmetry: true,
            ),
            const SizedBox(height: 16),
            
            // Real-time metrics
            Expanded(
              child: MetricsDisplayWidget(
                isRealTime: true,
                style: MetricDisplayStyle.grid,
                maxMetrics: 6,
                priorityMetrics: const [
                  'peakForce',
                  'currentForce',
                  'asymmetryIndex',
                  'sampleCount',
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildResultsStep(TestController testController) {
    return Obx(() {
      final testResults = testController.testResults;
      
      if (testController.isProcessingResults) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  valueColor: AlwaysStoppedAnimation(AppTheme.primaryColor),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Sonuçlar İşleniyor...',
                style: Get.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Metrikler hesaplanıyor ve kaydediliyor',
                style: Get.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        );
      }
      
      if (testResults == null) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 80,
                color: AppTheme.errorColor,
              ),
              const SizedBox(height: 24),
              Text(
                'Sonuç Bulunamadı',
                style: Get.textTheme.titleLarge?.copyWith(
                  color: AppTheme.errorColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Test sonuçları işlenirken bir hata oluştu.',
                style: Get.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        );
      }
      
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Results header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.darkCard,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.analytics,
                    color: AppTheme.successColor,
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Test Tamamlandı!',
                          style: Get.textTheme.titleLarge?.copyWith(
                            color: AppTheme.successColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${testResults.testType.turkishName} • ${testResults.duration.inSeconds}s',
                          style: Get.textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Quality badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Color(int.parse(testResults.quality.colorHex.replaceFirst('#', '0xFF'))).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      testResults.quality.turkishName,
                      style: TextStyle(
                        color: Color(int.parse(testResults.quality.colorHex.replaceFirst('#', '0xFF'))),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Test metrics
            Expanded(
              child: MetricsDisplayWidget(
                metrics: testResults.metrics,
                isRealTime: false,
                style: MetricDisplayStyle.detailed,
                maxMetrics: 12,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildBottomActions(TestStep currentStep, TestController testController) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button
          if (_canGoBack(currentStep))
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => testController.goToPreviousStep(),
                icon: Icon(Icons.arrow_back),
                label: Text('Geri'),
              ),
            ),
          
          if (_canGoBack(currentStep)) const SizedBox(width: 16),
          
          // Main action button
          Expanded(
            flex: 2,
            child: _buildMainActionButton(currentStep, testController),
          ),
        ],
      ),
    );
  }

  Widget _buildMainActionButton(TestStep currentStep, TestController testController) {
    return Obx(() {
      switch (currentStep) {
        case TestStep.deviceConnection:
          if (!testController.isConnected) {
            return ElevatedButton.icon(
              onPressed: testController.connectionStatus == ConnectionStatus.connecting 
                  ? null 
                  : () => testController.connectToDevice('USB_ForcePlate_001'),
              icon: testController.connectionStatus == ConnectionStatus.connecting
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : Icon(Icons.link),
              label: Text(testController.connectionStatus == ConnectionStatus.connecting 
                  ? 'Bağlanıyor...' 
                  : 'Bağlan'),
            );
          }
          return ElevatedButton.icon(
            onPressed: () => testController.proceedToAthleteSelection(),
            icon: Icon(Icons.arrow_forward),
            label: Text('İleri'),
          );
          
        case TestStep.athleteSelection:
          return ElevatedButton.icon(
            onPressed: testController.selectedAthlete != null 
                ? () => testController.proceedToTestSelection()
                : null,
            icon: Icon(Icons.arrow_forward),
            label: Text('İleri'),
          );
          
        case TestStep.testSelection:
          return ElevatedButton.icon(
            onPressed: testController.selectedTestType != null 
                ? () => testController.proceedToCalibration()
                : null,
            icon: Icon(Icons.arrow_forward),
            label: Text('İleri'),
          );
          
        case TestStep.calibration:
          if (!testController.isCalibrated) {
            return ElevatedButton.icon(
              onPressed: testController.isLoading 
                  ? null 
                  : () async {
                      // Kalibrasyon başlat
                      await testController.startCalibration();
                      // Kalibrasyon tamamlandıktan sonra otomatik geçiş yapılacak
                    },
              icon: testController.isLoading 
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : Icon(Icons.tune),
              label: Text(testController.isLoading ? 'Kalibrasyon...' : 'Kalibre Et'),
            );
          }
          return ElevatedButton.icon(
            onPressed: () => testController.proceedToWeightMeasurement(),
            icon: Icon(Icons.arrow_forward),
            label: Text('İleri'),
          );
          
        case TestStep.weightMeasurement:
          if (!testController.isWeightStable) {
            return ElevatedButton(
              onPressed: null,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white54),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('Stabilite Bekleniyor...'),
                ],
              ),
            );
          }
          return ElevatedButton.icon(
            onPressed: () => testController.proceedToTestExecution(),
            icon: Icon(Icons.arrow_forward),
            label: Text('Test Başlat'),
          );
          
        case TestStep.testExecution:
          if (!testController.isTestRunning) {
            return ElevatedButton.icon(
              onPressed: () => testController.startTest(),
              icon: Icon(Icons.play_arrow),
              label: Text('Testi Başlat'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successColor,
              ),
            );
          } else {
            return ElevatedButton.icon(
              onPressed: () => testController.stopTest(),
              icon: Icon(Icons.stop),
              label: Text('Testi Durdur'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
              ),
            );
          }
          
        case TestStep.results:
          return Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _shareResults(testController),
                  icon: Icon(Icons.share),
                  label: Text('Paylaş'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _finishTest(testController),
                  icon: Icon(Icons.check),
                  label: Text('Bitir'),
                ),
              ),
            ],
          );
      }
    });
  }

  // Helper methods
  String _getStepTitle(TestStep step) {
    switch (step) {
      case TestStep.deviceConnection:
        return 'Cihaz Bağlantısı';
      case TestStep.athleteSelection:
        return 'Sporcu Seçimi';
      case TestStep.testSelection:
        return 'Test Seçimi';
      case TestStep.calibration:
        return 'Kalibrasyon';
      case TestStep.weightMeasurement:
        return 'Ağırlık Ölçümü';
      case TestStep.testExecution:
        return 'Test Yürütme';
      case TestStep.results:
        return 'Test Sonuçları';
    }
  }

  String _getStepShortName(TestStep step) {
    switch (step) {
      case TestStep.deviceConnection:
        return 'Bağlantı';
      case TestStep.athleteSelection:
        return 'Sporcu';
      case TestStep.testSelection:
        return 'Test';
      case TestStep.calibration:
        return 'Kalibr.';
      case TestStep.weightMeasurement:
        return 'Ağırlık';
      case TestStep.testExecution:
        return 'Yürütme';
      case TestStep.results:
        return 'Sonuç';
    }
  }

  IconData _getStepIcon(TestStep step) {
    switch (step) {
      case TestStep.deviceConnection:
        return Icons.link;
      case TestStep.athleteSelection:
        return Icons.person;
      case TestStep.testSelection:
        return Icons.analytics;
      case TestStep.calibration:
        return Icons.tune;
      case TestStep.weightMeasurement:
        return Icons.monitor_weight;
      case TestStep.testExecution:
        return Icons.play_arrow;
      case TestStep.results:
        return Icons.assessment;
    }
  }

  bool _isStepCompleted(TestStep step, TestStep currentStep) {
    final stepIndex = TestStep.values.indexOf(step);
    final currentIndex = TestStep.values.indexOf(currentStep);
    return stepIndex < currentIndex;
  }

  bool _canGoBack(TestStep currentStep) {
    return currentStep != TestStep.deviceConnection && 
           currentStep != TestStep.results;
  }

  Future<bool> _onWillPop(TestController testController) async {
    if (testController.isTestRunning) {
      final shouldStop = await Get.dialog<bool>(
        AlertDialog(
          backgroundColor: AppTheme.darkCard,
          title: Text('Test Devam Ediyor', style: TextStyle(color: Colors.white)),
          content: Text(
            'Test devam ediyor. Çıkmak istediğinizden emin misiniz? Test durdurulacak.',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () => Get.back(result: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
              ),
              child: Text('Test Durdur ve Çık'),
            ),
          ],
        ),
      );
      
      if (shouldStop == true) {
        testController.stopTest();
        return true;
      }
      return false;
    }
    
    return true;
  }

  void _onBackPressed(TestController testController) {
    if (testController.isTestRunning) {
      Get.snackbar(
        'Uyarı',
        'Test devam ederken geri gidemezsiniz',
        backgroundColor: AppTheme.warningColor,
        colorText: Colors.white,
      );
      return;
    }
    
    Get.back();
  }

  void _shareResults(TestController testController) {
    // TODO: Implement share functionality
    Get.snackbar(
      'Bilgi',
      'Paylaşma özelliği yakında gelecek',
      backgroundColor: AppTheme.primaryColor,
      colorText: Colors.white,
    );
  }

  void _finishTest(TestController testController) {
    // Ana sayfaya dön
    Get.offAllNamed('/');
    
    Get.snackbar(
      'Tebrikler!',
      'Test başarıyla tamamlandı ve kaydedildi',
      backgroundColor: AppTheme.successColor,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }
}
