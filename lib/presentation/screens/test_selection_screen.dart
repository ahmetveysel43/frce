import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_constants.dart';
import '../../presentation/theme/app_theme.dart';
import '../../presentation/controllers/test_controller.dart';
import '../../presentation/controllers/athlete_controller.dart';
import '../../domain/entities/athlete.dart';

/// Test türü seçim ekranı
class TestSelectionScreen extends StatelessWidget {
  const TestSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: _buildAppBar(),
      body: GetBuilder<TestController>(
        builder: (testController) {
          return GetBuilder<AthleteController>(
            builder: (athleteController) {
              final selectedAthlete = athleteController.selectedAthlete;
              
              if (selectedAthlete == null) {
                return _buildNoAthleteSelected();
              }
              
              return Column(
                children: [
                  // Selected athlete info
                  _buildSelectedAthleteCard(selectedAthlete),
                  
                  // Test categories
                  Expanded( 
                    child: _buildTestCategories(selectedAthlete, testController),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.darkSurface,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Test Seçimi',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            'Uygulanacak test türünü seçin',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () => _showTestInfo(),
          icon: Icon(
            Icons.info_outline,
            color: AppTheme.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildNoAthleteSelected() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off,
              size: 64,
              color: AppTheme.errorColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Sporcu Seçilmedi',
              style: Get.textTheme.titleLarge?.copyWith(
                color: AppTheme.errorColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Test yapmak için önce bir sporcu seçmeniz gerekiyor.',
              style: Get.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Get.back(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Sporcu Seç'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedAthleteCard(Athlete athlete) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                _getInitials(athlete.fullName),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: AppTheme.successColor,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Seçili Sporcu',
                      style: TextStyle(
                        color: AppTheme.successColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  athlete.fullName,
                  style: Get.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (athlete.sport != null || athlete.age != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (athlete.sport != null) ...[
                        Text(
                          athlete.sport!,
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        if (athlete.age != null)
                          Text(
                            ' • ${athlete.age} yaş',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                      ] else if (athlete.age != null) ...[
                        Text(
                          '${athlete.age} yaş',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
          
          // Change athlete button
          TextButton.icon(
            onPressed: () => Get.back(),
            icon: Icon(Icons.swap_horiz, size: 16),
            label: Text('Değiştir'),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestCategories(Athlete athlete, TestController testController) {
    return SingleChildScrollView( // Outer SingleChildScrollView for the whole content
      padding: const EdgeInsets.all(16), // Padding for the whole content
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recommended tests section
          _buildRecommendedTestsSection(athlete, testController), // 'athlete' is the parameter
          const SizedBox(height: 24),
          
          // All test categories
          Text(
            'Tüm Test Kategorileri',
            style: Get.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          ...TestCategory.values.map((category) =>
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildTestCategoryCard(category, athlete, testController), // 'athlete' is the parameter
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedTestsSection(Athlete athlete, TestController testController) {
    final recommendedTests = athlete.recommendedTests;
    
    if (recommendedTests.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.recommend,
              color: AppTheme.primaryColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Önerilen Testler',
              style: Get.textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Sporcu profiline göre önerilen test türleri',
          style: Get.textTheme.bodyMedium?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.2, // Adjusted for better fit, originally 1.5
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: recommendedTests.length,
          itemBuilder: (context, index) {
            final testType = recommendedTests[index];
            return _buildRecommendedTestCard(testType, testController);
          },
        ),
      ],
    );
  }

  Widget _buildRecommendedTestCard(TestType testType, TestController testController) {
    return Card(
      color: AppTheme.primaryColor.withOpacity(0.1),
      child: InkWell(
        onTap: () => _selectTest(testType, testController),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.primaryColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Recommended badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'ÖNERİLEN',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              
              // Test icon
              Icon(
                _getTestTypeIcon(testType),
                color: AppTheme.primaryColor,
                size: 32,
              ),
              const SizedBox(height: 8),
              
              // Test name
              Text(
                testType.code,
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                testType.turkishName,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTestCategoryCard(TestCategory category, Athlete athlete, TestController testController) {
    final testsInCategory = TestType.values.where((test) => test.category == category).toList();
    
    return Card(
      color: AppTheme.darkCard,
      child: ExpansionTile(
        leading: Icon(
          _getCategoryIcon(category),
          color: _getCategoryColor(category),
          size: 28,
        ),
        title: Text(
          category.turkishName,
          style: Get.textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '${testsInCategory.length} test türü',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
          ),
        ),
        iconColor: AppTheme.textSecondary,
        collapsedIconColor: AppTheme.textSecondary,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.4, // Adjusted for better fit, originally 1.8
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: testsInCategory.length,
              itemBuilder: (context, index) {
                final testType = testsInCategory[index];
                final isRecommended = athlete.recommendedTests.contains(testType);
                return _buildTestTypeCard(testType, testController, isRecommended);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestTypeCard(TestType testType, TestController testController, bool isRecommended) {
    return Card(
      color: AppTheme.darkBackground,
      child: InkWell(
        onTap: () => _selectTest(testType, testController),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: isRecommended
                ? Border.all(color: AppTheme.primaryColor.withOpacity(0.5))
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Recommended indicator
              if (isRecommended) ...[
                Icon(
                  Icons.star,
                  color: AppTheme.primaryColor,
                  size: 12,
                ),
                const SizedBox(height: 4),
              ],
              
              // Test icon
              Icon(
                _getTestTypeIcon(testType),
                color: _getCategoryColor(testType.category),
                size: 24,
              ),
              const SizedBox(height: 6),
              
              // Test code
              Text(
                testType.code,
                style: TextStyle(
                  color: _getCategoryColor(testType.category),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              
              // Test name
              Text(
                testType.turkishName,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper methods
  String _getInitials(String fullName) {
    final parts = fullName.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
  }

  IconData _getCategoryIcon(TestCategory category) {
    switch (category) {
      case TestCategory.jump:
        return Icons.trending_up;
      case TestCategory.strength:
        return Icons.fitness_center;
      case TestCategory.balance:
        return Icons.balance;
      case TestCategory.agility:
        return Icons.speed;
    }
  }

  Color _getCategoryColor(TestCategory category) {
    switch (category) {
      case TestCategory.jump:
        return AppColors.chartColors[0]; // Blue
      case TestCategory.strength:
        return AppColors.chartColors[1]; // Orange
      case TestCategory.balance:
        return AppColors.chartColors[2]; // Green
      case TestCategory.agility:
        return AppColors.chartColors[3]; // Purple
    }
  }

  IconData _getTestTypeIcon(TestType testType) {
    switch (testType) {
      case TestType.counterMovementJump:
        return Icons.trending_up;
      case TestType.squatJump:
        return Icons.north;
      case TestType.dropJump:
        return Icons.south;
      case TestType.continuousJump:
        return Icons.repeat;
      case TestType.isometricMidThighPull:
        return Icons.fitness_center;
      case TestType.isometricSquat:
        return Icons.chair;
      case TestType.staticBalance:
        return Icons.balance;
      case TestType.dynamicBalance:
        return Icons.track_changes;
      case TestType.singleLegBalance:
        return Icons.accessibility;
      case TestType.lateralHop:
        return Icons.swap_horiz;
      case TestType.anteriorPosteriorHop:
        return Icons.swap_vert;
      case TestType.medialLateralHop:
        return Icons.compare_arrows;
    }
  }

   void _selectTest(TestType testType, TestController testController) {
    // Test seç
    testController.selectTestType(testType);
    
    // Success message
    Get.snackbar(
      'Test Seçildi',
      '${testType.turkishName} seçildi',
      backgroundColor: AppTheme.successColor,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
    
    // Test akışını kalibrasyon adımına ilerlet
    testController.proceedToCalibration(); 
    
    // Test yürütme ekranına git
    Get.toNamed('/test-execution'); 
  }

  void _showTestInfo() {
    Get.bottomSheet(
      Container(
        height: Get.height * 0.7,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textHint,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Title
            Text(
              'Test Türleri Hakkında',
              style: Get.textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            // Test categories info
            Expanded(
              child: ListView(
                children: [
                  _buildTestInfoCard(
                    category: TestCategory.jump,
                    description: 'Sıçrama performansını değerlendiren testler. Güç, hız ve koordinasyon ölçümü yapar.',
                    tests: ['CMJ - Karşı Hareket Sıçrama', 'SJ - Çömelme Sıçraması', 'DJ - Düşme Sıçraması'],
                  ),
                  const SizedBox(height: 16),
                  
                  _buildTestInfoCard(
                    category: TestCategory.strength,
                    description: 'Kas kuvveti ve güç üretim kapasitesini ölçen testler.',
                    tests: ['IMTP - İzometrik Orta Uyluk Çekişi', 'İzometrik Çömlek'],
                  ),
                  const SizedBox(height: 16),
                  
                  _buildTestInfoCard(
                    category: TestCategory.balance,
                    description: 'Denge ve postural kontrol yeteneklerini değerlendiren testler.',
                    tests: ['Statik Denge', 'Dinamik Denge', 'Tek Ayak Denge'],
                  ),
                  const SizedBox(height: 16),
                  
                  _buildTestInfoCard(
                    category: TestCategory.agility,
                    description: 'Çeviklik, hareketlilik ve yön değiştirme becerisini ölçen testler.',
                    tests: ['Yanal Sıçrama', 'Ön-Arka Sıçrama', 'İç-Dış Sıçrama'],
                  ),
                ],
              ),
            ),
            
            // Close button
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Get.back(),
                child: Text('Anladım'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestInfoCard({
    required TestCategory category,
    required String description,
    required List<String> tests,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getCategoryColor(category).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category header
          Row(
            children: [
              Icon(
                _getCategoryIcon(category),
                color: _getCategoryColor(category),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                category.turkishName,
                style: Get.textTheme.titleMedium?.copyWith(
                  color: _getCategoryColor(category),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Description
          Text(
            description,
            style: Get.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          
          // Tests list
          Text(
            'Test Türleri:',
            style: Get.textTheme.bodySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          ...tests.map((test) => Padding(
            padding: const EdgeInsets.only(left: 8, top: 2),
            child: Row(
              children: [
                Icon(
                  Icons.circle,
                  size: 4,
                  color: _getCategoryColor(category),
                ),
                const SizedBox(width: 8),
                Text(
                  test,
                  style: Get.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
