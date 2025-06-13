import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_constants.dart';
import '../../presentation/theme/app_theme.dart';
import '../../presentation/controllers/athlete_controller.dart';
import '../../presentation/controllers/test_controller.dart';
import '../../presentation/widgets/add_athlete_dialog.dart';
import '../../domain/entities/athlete.dart';
import '../../core/utils/app_logger.dart';

/// Sporcu seçim ekranı (DÜZELTME VERSİYONU)
class AthleteSelectionScreen extends StatelessWidget {
 const AthleteSelectionScreen({super.key});

 @override
 Widget build(BuildContext context) {
   return Scaffold(
     backgroundColor: AppTheme.darkBackground,
     appBar: _buildAppBar(),
     body: GetBuilder<AthleteController>(
       builder: (controller) {
         return Column(
           children: [
             // Search and filter section
             _buildSearchAndFilter(controller),
             
             // Statistics section
             _buildQuickStats(controller),
             
             // Athletes list
             Expanded(
               child: _buildAthletesList(controller),
             ),
           ],
         );
       },
     ),
     floatingActionButton: _buildFloatingActionButton(),
   );
 }

 PreferredSizeWidget _buildAppBar() {
   return AppBar(
     backgroundColor: AppTheme.darkSurface,
     title: Column(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
         const Text(
           'Sporcu Seçimi',
           style: TextStyle(
             color: Colors.white,
             fontSize: 20,
             fontWeight: FontWeight.w600,
           ),
         ),
         GetBuilder<AthleteController>(
           builder: (controller) => Text(
             '${controller.filteredAthletes.length} sporcu listeleniyor',
             style: const TextStyle(
               color: AppTheme.textSecondary,
               fontSize: 12,
             ),
           ),
         ),
       ],
     ),
     actions: [
       // Sort button
       GetBuilder<AthleteController>(
         builder: (controller) => IconButton(
           onPressed: () => _showSortDialog(controller),
           icon: const Icon(
             Icons.sort,
             color: AppTheme.primaryColor,
           ),
         ),
       ),
       
       // Filter button
       GetBuilder<AthleteController>(
         builder: (controller) => IconButton(
           onPressed: () => _showFilterDialog(controller),
           icon: Stack(
             children: [
               const Icon(
                 Icons.filter_list,
                 color: AppTheme.primaryColor,
               ),
               if (_hasActiveFilters(controller))
                 Positioned(
                   right: 0,
                   top: 0,
                   child: Container(
                     width: 8,
                     height: 8,
                     decoration: const BoxDecoration(
                       color: AppTheme.errorColor,
                       shape: BoxShape.circle,
                     ),
                   ),
                 ),
             ],
           ),
         ),
       ),
     ],
   );
 }

 Widget _buildSearchAndFilter(AthleteController controller) {
   return Container(
     padding: const EdgeInsets.all(16),
     color: AppTheme.darkSurface,
     child: Column(
       children: [
         // Search bar
         TextField(
           onChanged: controller.updateSearchQuery,
           style: const TextStyle(color: Colors.white),
           decoration: InputDecoration(
             hintText: 'Sporcu ara (isim, email, spor dalı...)',
             hintStyle: const TextStyle(color: AppTheme.textHint),
             prefixIcon: const Icon(Icons.search, color: AppTheme.textHint),
             suffixIcon: controller.searchQuery.isNotEmpty
                 ? IconButton(
                     onPressed: () => controller.updateSearchQuery(''),
                     icon: const Icon(Icons.clear, color: AppTheme.textHint),
                   )
                 : null,
             filled: true,
             fillColor: AppTheme.darkCard,
             border: OutlineInputBorder(
               borderRadius: BorderRadius.circular(12),
               borderSide: BorderSide.none,
             ),
           ),
         ),
         
         // Active filters
         if (_hasActiveFilters(controller)) ...[
           const SizedBox(height: 12),
           _buildActiveFilters(controller),
         ],
       ],
     ),
   );
 }

 Widget _buildActiveFilters(AthleteController controller) {
   return Wrap(
     spacing: 8,
     runSpacing: 8,
     children: [
       if (controller.selectedSport != null)
         _buildFilterChip(
           label: 'Spor: ${controller.selectedSport}',
           onRemove: () => controller.filterBySport(null),
         ),
       if (controller.selectedLevel != null)
         _buildFilterChip(
           label: 'Seviye: ${controller.selectedLevel!.turkishName}',
           onRemove: () => controller.filterByLevel(null),
         ),
       if (controller.selectedGender != null)
         _buildFilterChip(
           label: 'Cinsiyet: ${controller.selectedGender!.turkishName}',
           onRemove: () => controller.filterByGender(null),
         ),
       
       // Clear all filters
       TextButton.icon(
         onPressed: controller.clearFilters,
         icon: const Icon(Icons.clear_all, size: 16),
         label: const Text('Tümünü Temizle'),
         style: TextButton.styleFrom(
           foregroundColor: AppTheme.errorColor,
           textStyle: const TextStyle(fontSize: 12),
         ),
       ),
     ],
   );
 }

 Widget _buildFilterChip({
   required String label,
   required VoidCallback onRemove,
 }) {
   return Chip(
     label: Text(
       label,
       style: const TextStyle(
         color: AppTheme.primaryColor,
         fontSize: 12,
       ),
     ),
     deleteIcon: const Icon(
       Icons.close,
       size: 16,
       color: AppTheme.primaryColor,
     ),
     onDeleted: onRemove,
     backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
     side: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
   );
 }

 Widget _buildQuickStats(AthleteController controller) {
   final stats = controller.athleteStats;
   
   return Container(
     margin: const EdgeInsets.all(16),
     padding: const EdgeInsets.all(16),
     decoration: BoxDecoration(
       color: AppTheme.darkCard,
       borderRadius: BorderRadius.circular(12),
     ),
     child: Row(
       children: [
         _buildStatItem(
           icon: Icons.people,
           label: 'Toplam',
           value: stats.totalCount.toString(),
           color: AppTheme.primaryColor,
         ),
         _buildStatDivider(),
         _buildStatItem(
           icon: Icons.male,
           label: 'Erkek',
           value: stats.maleCount.toString(),
           color: AppColors.leftPlatform,
         ),
         _buildStatDivider(),
         _buildStatItem(
           icon: Icons.female,
           label: 'Kadın',
           value: stats.femaleCount.toString(),
           color: AppColors.rightPlatform,
         ),
         _buildStatDivider(),
         _buildStatItem(
           icon: Icons.check_circle,
           label: 'Profil',
           value: '${stats.profileCompletionPercentage.toStringAsFixed(0)}%',
           color: AppTheme.successColor,
         ),
       ],
     ),
   );
 }

 Widget _buildStatItem({
   required IconData icon,
   required String label,
   required String value,
   required Color color,
 }) {
   return Expanded(
     child: Column(
       children: [
         Icon(icon, color: color, size: 20),
         const SizedBox(height: 4),
         Text(
           value,
           style: TextStyle(
             color: color,
             fontSize: 16,
             fontWeight: FontWeight.bold,
           ),
         ),
         Text(
           label,
           style: const TextStyle(
             color: AppTheme.textSecondary,
             fontSize: 11,
           ),
         ),
       ],
     ),
   );
 }

 Widget _buildStatDivider() {
   return Container(
     width: 1,
     height: 40,
     color: AppTheme.darkDivider,
     margin: const EdgeInsets.symmetric(horizontal: 8),
   );
 }

 Widget _buildAthletesList(AthleteController controller) {
   if (controller.isLoading) {
     return const Center(
       child: CircularProgressIndicator(
         color: AppTheme.primaryColor,
       ),
     );
   }

   if (controller.filteredAthletes.isEmpty) {
     return _buildEmptyState(controller);
   }

   return ListView.builder(
     padding: const EdgeInsets.all(16),
     itemCount: controller.filteredAthletes.length,
     itemBuilder: (context, index) {
       final athlete = controller.filteredAthletes[index];
       return Padding(
         padding: const EdgeInsets.only(bottom: 12),
         child: _buildAthleteCard(athlete, controller),
       );
     },
   );
 }

 Widget _buildEmptyState(AthleteController controller) {
   final hasSearch = controller.searchQuery.isNotEmpty;
   final hasFilters = _hasActiveFilters(controller);
   
   return Center(
     child: Padding(
       padding: const EdgeInsets.all(32),
       child: Column(
         mainAxisAlignment: MainAxisAlignment.center,
         children: [
           Icon(
             hasSearch || hasFilters ? Icons.search_off : Icons.people_outline,
             size: 64,
             color: AppTheme.textHint,
           ),
           const SizedBox(height: 16),
           Text(
             hasSearch || hasFilters 
                 ? 'Arama Sonucu Bulunamadı'
                 : 'Henüz Sporcu Eklenmemiş',
             style: Get.textTheme.titleMedium?.copyWith(
               color: AppTheme.textSecondary,
             ),
           ),
           const SizedBox(height: 8),
           Text(
             hasSearch || hasFilters
                 ? 'Farklı arama terimleri veya filtreler deneyin'
                 : 'İlk sporcuyu eklemek için + butonuna tıklayın',
             style: Get.textTheme.bodyMedium?.copyWith(
               color: AppTheme.textHint,
             ),
             textAlign: TextAlign.center,
           ),
           const SizedBox(height: 24),
           if (hasSearch || hasFilters)
             OutlinedButton.icon(
               onPressed: () {
                 controller.updateSearchQuery('');
                 controller.clearFilters();
               },
               icon: const Icon(Icons.clear),
               label: const Text('Filtreleri Temizle'),
             )
           else
             ElevatedButton.icon(
               onPressed: () => _showAddAthleteDialog(),
               icon: const Icon(Icons.add),
               label: const Text('İlk Sporcuyu Ekle'),
             ),
         ],
       ),
     ),
   );
 }

 Widget _buildAthleteCard(Athlete athlete, AthleteController controller) {
   return Card(
     color: AppTheme.darkCard,
     child: InkWell(
       onTap: () => _selectAthlete(athlete, controller),
       borderRadius: BorderRadius.circular(12),
       child: Padding(
         padding: const EdgeInsets.all(16),
         child: Column(
           children: [
             Row(
               children: [
                 // Avatar
                 _buildAthleteAvatar(athlete),
                 const SizedBox(width: 16),
                 
                 // Info
                 Expanded(
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       // Name
                       Text(
                         athlete.fullName,
                         style: Get.textTheme.titleMedium?.copyWith(
                           color: Colors.white,
                           fontWeight: FontWeight.w600,
                         ),
                       ),
                       const SizedBox(height: 4),
                       
                       // Sport and level
                       Row(
                         children: [
                           if (athlete.sport != null) ...[
                             const Icon(
                               Icons.sports,
                               size: 14,
                               color: AppTheme.textHint,
                             ),
                             const SizedBox(width: 4),
                             Text(
                               athlete.sport!,
                               style: const TextStyle(
                                 color: AppTheme.textSecondary,
                                 fontSize: 12,
                               ),
                             ),
                           ],
                           if (athlete.sport != null && athlete.level != null)
                             const Text(
                               ' • ',
                               style: TextStyle(
                                 color: AppTheme.textHint,
                                 fontSize: 12,
                               ),
                             ),
                           if (athlete.level != null)
                             Text(
                               athlete.level!.turkishName,
                               style: TextStyle(
                                 color: Color(int.parse(athlete.levelColor.replaceFirst('#', '0xFF'))),
                                 fontSize: 12,
                                 fontWeight: FontWeight.w500,
                               ),
                             ),
                         ],
                       ),
                       
                       // Age and profile completion
                       const SizedBox(height: 4),
                       Row(
                         children: [
                           if (athlete.age != null) ...[
                             const Icon(
                               Icons.cake,
                               size: 14,
                               color: AppTheme.textHint,
                             ),
                             const SizedBox(width: 4),
                             Text(
                               '${athlete.age} yaş',
                               style: const TextStyle(
                                 color: AppTheme.textSecondary,
                                 fontSize: 12,
                               ),
                             ),
                             const Text(
                               ' • ',
                               style: TextStyle(
                                 color: AppTheme.textHint,
                                 fontSize: 12,
                               ),
                             ),
                           ],
                           Icon(
                             athlete.isProfileComplete ? Icons.check_circle : Icons.circle_outlined,
                             size: 14,
                             color: athlete.isProfileComplete ? AppTheme.successColor : AppTheme.warningColor,
                           ),
                           const SizedBox(width: 4),
                           Text(
                             'Profil %${(athlete.profileCompletion * 100).toStringAsFixed(0)}',
                             style: TextStyle(
                               color: athlete.isProfileComplete ? AppTheme.successColor : AppTheme.warningColor,
                               fontSize: 12,
                               fontWeight: FontWeight.w500,
                             ),
                           ),
                         ],
                       ),
                     ],
                   ),
                 ),
                 
                 // Actions
                 PopupMenuButton<String>(
                   icon: const Icon(Icons.more_vert, color: AppTheme.textHint),
                   color: AppTheme.darkCard,
                   onSelected: (action) => _handleAthleteAction(action, athlete, controller),
                   itemBuilder: (context) => [
                     const PopupMenuItem(
                       value: 'view',
                       child: Row(
                         children: [
                           Icon(Icons.visibility, size: 18, color: AppTheme.textSecondary),
                           SizedBox(width: 8),
                           Text('Görüntüle', style: TextStyle(color: Colors.white)),
                         ],
                       ),
                     ),
                     const PopupMenuItem(
                       value: 'edit',
                       child: Row(
                         children: [
                           Icon(Icons.edit, size: 18, color: AppTheme.primaryColor),
                           SizedBox(width: 8),
                           Text('Düzenle', style: TextStyle(color: Colors.white)),
                         ],
                       ),
                     ),
                     const PopupMenuItem(
                       value: 'history',
                       child: Row(
                         children: [
                           Icon(Icons.history, size: 18, color: AppTheme.accentColor),
                           SizedBox(width: 8),
                           Text('Test Geçmişi', style: TextStyle(color: Colors.white)),
                         ],
                       ),
                     ),
                     const PopupMenuItem(
                       value: 'delete',
                       child: Row(
                         children: [
                           Icon(Icons.delete, size: 18, color: AppTheme.errorColor),
                           SizedBox(width: 8),
                           Text('Sil', style: TextStyle(color: AppTheme.errorColor)),
                         ],
                       ),
                     ),
                   ],
                 ),
               ],
             ),
             
             // Quick metrics (if available)
             if (athlete.height != null || athlete.weight != null) ...[
               const SizedBox(height: 12),
               _buildQuickMetrics(athlete),
             ],
           ],
         ),
       ),
     ),
   );
 }

 Widget _buildAthleteAvatar(Athlete athlete) {
   return Container(
     width: 50,
     height: 50,
     decoration: BoxDecoration(
       color: _getAvatarColor(athlete),
       borderRadius: BorderRadius.circular(12),
     ),
     child: Center(
       child: Text(
         _getInitials(athlete.fullName),
         style: const TextStyle(
           color: Colors.white,
           fontSize: 18,
           fontWeight: FontWeight.bold,
         ),
       ),
     ),
   );
 }

 Widget _buildQuickMetrics(Athlete athlete) {
   return Container(
     padding: const EdgeInsets.all(12),
     decoration: BoxDecoration(
       color: AppTheme.darkBackground,
       borderRadius: BorderRadius.circular(8),
     ),
     child: Row(
       children: [
         if (athlete.height != null) ...[
           _buildQuickMetric(
             icon: Icons.height,
             value: '${athlete.height!.toStringAsFixed(0)} cm',
             color: AppTheme.textSecondary,
           ),
           if (athlete.weight != null) _buildQuickMetricDivider(),
         ],
         if (athlete.weight != null) ...[
           _buildQuickMetric(
             icon: Icons.monitor_weight,
             value: '${athlete.weight!.toStringAsFixed(1)} kg',
             color: AppTheme.textSecondary,
           ),
           if (athlete.bmi != null) _buildQuickMetricDivider(),
         ],
         if (athlete.bmi != null)
           _buildQuickMetric(
             icon: Icons.analytics,
             value: 'BMI ${athlete.bmi!.toStringAsFixed(1)}',
             color: _getBMIColor(athlete.bmi!),
           ),
       ],
     ),
   );
 }

 Widget _buildQuickMetric({
   required IconData icon,
   required String value,
   required Color color,
 }) {
   return Expanded(
     child: Row(
       mainAxisAlignment: MainAxisAlignment.center,
       children: [
         Icon(icon, size: 14, color: color),
         const SizedBox(width: 4),
         Text(
           value,
           style: TextStyle(
             color: color,
             fontSize: 11,
             fontWeight: FontWeight.w500,
           ),
         ),
       ],
     ),
   );
 }

 Widget _buildQuickMetricDivider() {
   return Container(
     width: 1,
     height: 20,
     color: AppTheme.darkDivider,
     margin: const EdgeInsets.symmetric(horizontal: 8),
   );
 }

 Widget _buildFloatingActionButton() {
   return FloatingActionButton.extended(
     onPressed: () => _showAddAthleteDialog(),
     backgroundColor: AppTheme.primaryColor,
     icon: const Icon(Icons.add, color: Colors.white),
     label: const Text(
       'Sporcu Ekle',
       style: TextStyle(
         color: Colors.white,
         fontWeight: FontWeight.w600,
       ),
     ),
   );
 }

 // Helper methods
 bool _hasActiveFilters(AthleteController controller) {
   return controller.selectedSport != null ||
          controller.selectedLevel != null ||
          controller.selectedGender != null;
 }

 Color _getAvatarColor(Athlete athlete) {
   final colors = [
     AppTheme.primaryColor,
     AppTheme.accentColor,
     AppColors.chartColors[2],
     AppColors.chartColors[3],
     AppColors.chartColors[4],
   ];
   return colors[athlete.fullName.hashCode % colors.length];
 }

 String _getInitials(String fullName) {
   final parts = fullName.split(' ');
   if (parts.length >= 2) {
     return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
   }
   return fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
 }

 Color _getBMIColor(double bmi) {
   if (bmi < 18.5 || bmi > 30) return AppTheme.errorColor;
   if (bmi > 25) return AppTheme.warningColor;
   return AppTheme.successColor;
 }

 // DÜZELTME: Sporcu seçim metodunu yeniden yaz
 void _selectAthlete(Athlete athlete, AthleteController controller) {
   final testController = Get.find<TestController>();
   
   AppLogger.info('👤 ATHLETE SELECTED: ${athlete.fullName}');
   
   // Sporcu seç
   controller.selectAthlete(athlete);
   testController.selectAthlete(athlete);
   
   // Success message
   Get.snackbar(
     'Sporcu Seçildi',
     '${athlete.fullName} test için seçildi',
     backgroundColor: AppTheme.successColor,
     colorText: Colors.white,
     duration: const Duration(seconds: 2),
   );
   
   AppLogger.info('✅ Athlete selected, navigating to test selection...');
   
   // Test seçim ekranına git
   Get.toNamed('/test-selection');
 }

 void _handleAthleteAction(String action, Athlete athlete, AthleteController controller) {
   switch (action) {
     case 'view':
       _showAthleteDetails(athlete);
       break;
     case 'edit':
       _showEditAthleteDialog(athlete);
       break;
     case 'history':
       _showTestHistory(athlete, controller);
       break;
     case 'delete':
       _confirmDeleteAthlete(athlete, controller);
       break;
   }
 }

 void _showSortDialog(AthleteController controller) {
   Get.dialog(
     AlertDialog(
       backgroundColor: AppTheme.darkCard,
       title: const Text('Sıralama', style: TextStyle(color: Colors.white)),
       content: Column(
         mainAxisSize: MainAxisSize.min,
         children: AthleteSortBy.values.map((sortBy) {
           return RadioListTile<AthleteSortBy>(
             title: Text(
               sortBy.turkishName,
               style: const TextStyle(color: Colors.white),
             ),
             value: sortBy,
             groupValue: controller.sortBy,
             activeColor: AppTheme.primaryColor,
             onChanged: (value) {
               Get.back();
               if (value != null) {
                 controller.updateSortBy(value);
               }
             },
           );
         }).toList(),
       ),
       actions: [
         TextButton(
           onPressed: () => Get.back(),
           child: const Text('İptal'),
         ),
       ],
     ),
   );
 }

 void _showFilterDialog(AthleteController controller) {
   Get.bottomSheet(
     Container(
       padding: const EdgeInsets.all(24),
       decoration: const BoxDecoration(
         color: AppTheme.darkCard,
         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
       ),
       child: Column(
         mainAxisSize: MainAxisSize.min,
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           Text(
             'Filtreler',
             style: Get.textTheme.titleLarge?.copyWith(
               color: Colors.white,
               fontWeight: FontWeight.bold,
             ),
           ),
           const SizedBox(height: 20),
           
           // Sport filter
           const Text('Spor Dalı', style: TextStyle(color: AppTheme.textSecondary)),
           const SizedBox(height: 8),
           DropdownButtonFormField<String>(
             value: controller.selectedSport,
             style: const TextStyle(color: Colors.white),
             dropdownColor: AppTheme.darkCard,
             decoration: InputDecoration(
               filled: true,
               fillColor: AppTheme.darkBackground,
               border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
             ),
             items: [
               const DropdownMenuItem(value: null, child: Text('Tümü')),
               ...controller.availableSports.map((sport) => 
                 DropdownMenuItem(value: sport, child: Text(sport)),
               ),
             ],
             onChanged: controller.filterBySport,
           ),
           const SizedBox(height: 16),
           
           // Level filter
           const Text('Seviye', style: TextStyle(color: AppTheme.textSecondary)),
           const SizedBox(height: 8),
           DropdownButtonFormField<AthleteLevel>(
             value: controller.selectedLevel,
             style: const TextStyle(color: Colors.white),
             dropdownColor: AppTheme.darkCard,
             decoration: InputDecoration(
               filled: true,
               fillColor: AppTheme.darkBackground,
               border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
             ),
             items: [
               const DropdownMenuItem(value: null, child: Text('Tümü')),
               ...AthleteLevel.values.map((level) => 
                 DropdownMenuItem(value: level, child: Text(level.turkishName)),
               ),
             ],
             onChanged: controller.filterByLevel,
           ),
           const SizedBox(height: 16),
           
           // Gender filter
           const Text('Cinsiyet', style: TextStyle(color: AppTheme.textSecondary)),
           const SizedBox(height: 8),
           DropdownButtonFormField<Gender>(
             value: controller.selectedGender,
             style: const TextStyle(color: Colors.white),
             dropdownColor: AppTheme.darkCard,
             decoration: InputDecoration(
               filled: true,
               fillColor: AppTheme.darkBackground,
               border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
             ),
             items: [
               const DropdownMenuItem(value: null, child: Text('Tümü')),
               ...Gender.values.map((gender) => 
                 DropdownMenuItem(value: gender, child: Text(gender.turkishName)),
               ),
             ],
             onChanged: controller.filterByGender,
           ),
           const SizedBox(height: 24),
           
           // Actions
           Row(
             children: [
               Expanded(
                 child: OutlinedButton(
                   onPressed: () {
                     controller.clearFilters();
                     Get.back();
                   },
                   child: const Text('Temizle'),
                 ),
               ),
               const SizedBox(width: 12),
               Expanded(
                 child: ElevatedButton(
                   onPressed: () => Get.back(),
                   child: const Text('Uygula'),
                 ),
               ),
             ],
           ),
         ],
       ),
     ),
   );
 }

 void _showAddAthleteDialog() async {
   final result = await Get.dialog<Athlete>(
     const AddAthleteDialog(),
     barrierDismissible: false,
   );
   if (result != null) {
     AppLogger.info('✅ Yeni sporcu eklendi: ${result.fullName}');
   }
 }

 void _showAthleteDetails(Athlete athlete) {
   Get.bottomSheet(
     Container(
       padding: const EdgeInsets.all(24),
       decoration: const BoxDecoration(
         color: AppTheme.darkCard,
         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
       ),
       child: Column(
         mainAxisSize: MainAxisSize.min,
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           // Header
           Row(
             children: [
               _buildAthleteAvatar(athlete),
               const SizedBox(width: 16),
               Expanded(
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Text(
                       athlete.fullName,
                       style: Get.textTheme.titleLarge?.copyWith(
                         color: Colors.white,
                         fontWeight: FontWeight.bold,
                       ),
                     ),
                     if (athlete.sport != null)
                       Text(
                         athlete.sport!,
                         style: const TextStyle(
                           color: AppTheme.primaryColor,
                           fontSize: 14,
                         ),
                       ),
                   ],
                 ),
               ),
               IconButton(
                 onPressed: () => Get.back(),
                 icon: const Icon(Icons.close, color: AppTheme.textHint),
               ),
             ],
           ),
           const SizedBox(height: 24),
           
           // Details
           _buildDetailRow(Icons.email, 'E-posta', athlete.email ?? 'Belirtilmemiş'),
           _buildDetailRow(Icons.cake, 'Doğum Tarihi', 
               athlete.dateOfBirth != null 
                   ? '${athlete.dateOfBirth!.day}.${athlete.dateOfBirth!.month}.${athlete.dateOfBirth!.year}'
                   : 'Belirtilmemiş'),
           _buildDetailRow(Icons.height, 'Boy', 
               athlete.height != null ? '${athlete.height} cm' : 'Belirtilmemiş'),
           _buildDetailRow(Icons.monitor_weight, 'Kilo', 
               athlete.weight != null ? '${athlete.weight} kg' : 'Belirtilmemiş'),
           if (athlete.position != null)
             _buildDetailRow(Icons.sports, 'Pozisyon', athlete.position!),
           if (athlete.notes != null)
             _buildDetailRow(Icons.note, 'Notlar', athlete.notes!),
           
           const SizedBox(height: 24),
           
           // Actions
           Row(
             children: [
               Expanded(
                 child: OutlinedButton.icon(
                   onPressed: () {
                     Get.back();
                     _showEditAthleteDialog(athlete);
                   },
                   icon: const Icon(Icons.edit),
                   label: const Text('Düzenle'),
                 ),
               ),
               const SizedBox(width: 16),
               Expanded(
                 child: ElevatedButton.icon(
                   onPressed: () {
                     Get.back();
                     _selectAthlete(athlete, Get.find<AthleteController>());
                   },
                   icon: const Icon(Icons.check),
                   label: const Text('Seç'),
                 ),
               ),
             ],
           ),
         ],
       ),
     ),
     isScrollControlled: true,
   );
 }
 
 Widget _buildDetailRow(IconData icon, String label, String value) {
   return Padding(
     padding: const EdgeInsets.only(bottom: 16),
     child: Row(
       children: [
         Icon(icon, color: AppTheme.textSecondary, size: 20),
         const SizedBox(width: 12),
         Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             Text(
               label,
               style: const TextStyle(
                 color: AppTheme.textSecondary,
                 fontSize: 12,
               ),
             ),
             Text(
               value,
               style: const TextStyle(
                 color: Colors.white,
                 fontSize: 14,
                 fontWeight: FontWeight.w500,
               ),
             ),
           ],
         ),
       ],
     ),
   );
 }

 void _showEditAthleteDialog(Athlete athlete) async {
   final result = await Get.dialog<Athlete>(
     AddAthleteDialog(athlete: athlete),
     barrierDismissible: false,
   );
   if (result != null) {
     AppLogger.info('✅ Sporcu güncellendi: ${result.fullName}');
   }
 }

 void _showTestHistory(Athlete athlete, AthleteController controller) {
   if (controller.athleteTestHistory.isEmpty) {
     Get.snackbar(
       'Test Geçmişi',
       '${athlete.fullName} için henüz test sonucu bulunmuyor',
       backgroundColor: AppTheme.warningColor,
       colorText: Colors.white,
     );
     return;
   }
   
   Get.dialog(
     Dialog(
       backgroundColor: AppTheme.darkCard,
       shape: RoundedRectangleBorder(
         borderRadius: BorderRadius.circular(16),
       ),
       child: Container(
         width: Get.width * 0.9,
         height: Get.height * 0.7,
         padding: const EdgeInsets.all(24),
         child: Column(
           children: [
             // Header
             Row(
               children: [
                 const Icon(Icons.history, color: AppTheme.primaryColor),
                 const SizedBox(width: 12),
                 Expanded(
                   child: Text(
                     '${athlete.fullName} - Test Geçmişi',
                     style: Get.textTheme.titleLarge?.copyWith(
                       color: Colors.white,
                       fontWeight: FontWeight.bold,
                     ),
                   ),
                 ),
                 IconButton(
                   onPressed: () => Get.back(),
                   icon: const Icon(Icons.close, color: AppTheme.textHint),
                 ),
               ],
             ),
             const SizedBox(height: 16),
             
             // Test list
             Expanded(
               child: ListView.builder(
                 itemCount: controller.athleteTestHistory.length,
                 itemBuilder: (context, index) {
                   final test = controller.athleteTestHistory[index];
                   return Card(
                     color: AppTheme.darkBackground,
                     margin: const EdgeInsets.only(bottom: 8),
                     child: ListTile(
                       leading: Container(
                         width: 40,
                         height: 40,
                         decoration: BoxDecoration(
                           color: AppTheme.primaryColor.withValues(alpha: 0.2),
                           borderRadius: BorderRadius.circular(8),
                         ),
                         child: const Icon(
                           Icons.analytics,
                           color: AppTheme.primaryColor,
                           size: 20,
                         ),
                       ),
                       title: Text(
                         test.testType.turkishName,
                         style: const TextStyle(
                           color: Colors.white,
                           fontWeight: FontWeight.w600,
                         ),
                       ),
                       subtitle: Text(
                         '${test.testDate.day}.${test.testDate.month}.${test.testDate.year}',
                         style: const TextStyle(color: AppTheme.textSecondary),
                       ),
                       trailing: Column(
                         mainAxisAlignment: MainAxisAlignment.center,
                         crossAxisAlignment: CrossAxisAlignment.end,
                         children: [
                           Text(
                             test.status.turkishName,
                             style: TextStyle(
                               color: test.status == TestStatus.completed 
                                   ? AppTheme.successColor 
                                   : AppTheme.warningColor,
                               fontSize: 12,
                               fontWeight: FontWeight.w600,
                             ),
                           ),
                           if (test.metrics.isNotEmpty)
                             Text(
                               '${test.metrics.length} metrik',
                               style: const TextStyle(
                                 color: AppTheme.textHint,
                                 fontSize: 10,
                               ),
                             ),
                         ],
                       ),
                       onTap: () {
                         Get.back();
                         Get.toNamed('/results', arguments: test);
                       },
                     ),
                   );
                 },
               ),
             ),
           ],
         ),
       ),
     ),
   );
 }

 void _confirmDeleteAthlete(Athlete athlete, AthleteController controller) {
   Get.dialog(
     AlertDialog(
       backgroundColor: AppTheme.darkCard,
       title: const Text('Sporcuyu Sil', style: TextStyle(color: Colors.white)),
       content: Text(
         '${athlete.fullName} isimli sporcuyu silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.',
         style: const TextStyle(color: AppTheme.textSecondary),
       ),
       actions: [
         TextButton(
           onPressed: () => Get.back(),
           child: const Text('İptal'),
         ),
         ElevatedButton(
           onPressed: () async {
             Get.back();
             final success = await controller.deleteAthlete(athlete.id);
             if (success) {
               Get.snackbar(
                 'Başarılı',
                 '${athlete.fullName} başarıyla silindi',
                 backgroundColor: AppTheme.successColor,
                 colorText: Colors.white,
               );
             }
           },
           style: ElevatedButton.styleFrom(
             backgroundColor: AppTheme.errorColor,
           ),
           child: const Text('Sil'),
         ),
       ],
     ),
   );
 }
}