import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_constants.dart';
import '../../presentation/theme/app_theme.dart';
import '../../presentation/controllers/athlete_controller.dart';
import '../../domain/entities/athlete.dart';

/// Sporcu ekleme dialog'u
class AddAthleteDialog extends StatefulWidget {
  final Athlete? athlete; // Edit mode için

  const AddAthleteDialog({
    super.key,
    this.athlete,
  });

  @override
  State<AddAthleteDialog> createState() => _AddAthleteDialogState();
}

class _AddAthleteDialogState extends State<AddAthleteDialog> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _sportController = TextEditingController();
  final _positionController = TextEditingController();
  final _notesController = TextEditingController();
  
  DateTime? _dateOfBirth;
  Gender? _selectedGender;
  AthleteLevel? _selectedLevel;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.athlete != null) {
      final athlete = widget.athlete!;
      _firstNameController.text = athlete.firstName;
      _lastNameController.text = athlete.lastName;
      _emailController.text = athlete.email ?? '';
      _heightController.text = athlete.height?.toString() ?? '';
      _weightController.text = athlete.weight?.toString() ?? '';
      _sportController.text = athlete.sport ?? '';
      _positionController.text = athlete.position ?? '';
      _notesController.text = athlete.notes ?? '';
      _dateOfBirth = athlete.dateOfBirth;
      _selectedGender = athlete.gender;
      _selectedLevel = athlete.level;
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _sportController.dispose();
    _positionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.athlete != null;
    
    return Dialog(
      backgroundColor: AppTheme.darkCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: Get.width * 0.9,
        height: Get.height * 0.85,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Icon(
                  isEdit ? Icons.edit : Icons.person_add,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isEdit ? 'Sporcuyu Düzenle' : 'Yeni Sporcu Ekle',
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
            const SizedBox(height: 24),
            
            // Form
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Basic info section
                      _buildSectionHeader('Temel Bilgiler'),
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextFormField(
                              controller: _firstNameController,
                              label: 'Ad',
                              icon: Icons.person,
                              validator: (value) {
                                if (value?.isEmpty ?? true) {
                                  return 'Ad gerekli';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextFormField(
                              controller: _lastNameController,
                              label: 'Soyad',
                              icon: Icons.person_outline,
                              validator: (value) {
                                if (value?.isEmpty ?? true) {
                                  return 'Soyad gerekli';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      _buildTextFormField(
                        controller: _emailController,
                        label: 'E-posta (opsiyonel)',
                        icon: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value?.isNotEmpty == true && !GetUtils.isEmail(value!)) {
                            return 'Geçersiz e-posta adresi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Date of birth and gender
                      Row(
                        children: [
                          Expanded(
                            child: _buildDatePicker(),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildGenderDropdown(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Physical info section
                      _buildSectionHeader('Fiziksel Bilgiler'),
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextFormField(
                              controller: _heightController,
                              label: 'Boy (cm)',
                              icon: Icons.height,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value?.isNotEmpty == true) {
                                  final height = double.tryParse(value!);
                                  if (height == null || height < 50 || height > 250) {
                                    return 'Boy 50-250 cm arası olmalı';
                                  }
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextFormField(
                              controller: _weightController,
                              label: 'Kilo (kg)',
                              icon: Icons.monitor_weight,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value?.isNotEmpty == true) {
                                  final weight = double.tryParse(value!);
                                  if (weight == null || weight < 20 || weight > 300) {
                                    return 'Kilo 20-300 kg arası olmalı';
                                  }
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Sport info section
                      _buildSectionHeader('Spor Bilgileri'),
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(
                            child: _buildSportDropdown(),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildLevelDropdown(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      _buildTextFormField(
                        controller: _positionController,
                        label: 'Pozisyon (opsiyonel)',
                        icon: Icons.sports,
                      ),
                      const SizedBox(height: 24),
                      
                      // Notes section
                      _buildSectionHeader('Notlar'),
                      const SizedBox(height: 16),
                      
                      _buildTextFormField(
                        controller: _notesController,
                        label: 'Notlar (opsiyonel)',
                        icon: Icons.note,
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Actions
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => Get.back(),
                    child: const Text('İptal'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveAthlete,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : Text(isEdit ? 'Güncelle' : 'Kaydet'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: Get.textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.textSecondary),
        prefixIcon: Icon(icon, color: AppTheme.textSecondary),
        filled: true,
        fillColor: AppTheme.darkBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.darkDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.errorColor),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () => _selectDate(),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.darkBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.darkDivider),
        ),
        child: Row(
          children: [
            const Icon(Icons.cake, color: AppTheme.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Doğum Tarihi',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _dateOfBirth != null
                        ? '${_dateOfBirth!.day}.${_dateOfBirth!.month}.${_dateOfBirth!.year}'
                        : 'Seçiniz',
                    style: TextStyle(
                      color: _dateOfBirth != null ? Colors.white : AppTheme.textHint,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<Gender>(
      value: _selectedGender,
      style: const TextStyle(color: Colors.white),
      dropdownColor: AppTheme.darkCard,
      decoration: InputDecoration(
        labelText: 'Cinsiyet',
        labelStyle: const TextStyle(color: AppTheme.textSecondary),
        prefixIcon: const Icon(Icons.people_alt, color: AppTheme.textSecondary),
        filled: true,
        fillColor: AppTheme.darkBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.darkDivider),
        ),
      ),
      items: Gender.values.map((gender) => DropdownMenuItem(
        value: gender,
        child: Text(gender.turkishName),
      )).toList(),
      onChanged: (value) => setState(() => _selectedGender = value),
    );
  }

  Widget _buildSportDropdown() {
    final sports = [
      'Basketbol',
      'Voleybol',
      'Futbol',
      'Atletizm',
      'Halter',
      'Güreş',
      'Jimnastik',
      'Tenis',
      'Yüzme',
      'Diğer',
    ];

    return DropdownButtonFormField<String>(
      value: sports.contains(_sportController.text) ? _sportController.text : null,
      style: const TextStyle(color: Colors.white),
      dropdownColor: AppTheme.darkCard,
      decoration: InputDecoration(
        labelText: 'Spor Dalı',
        labelStyle: const TextStyle(color: AppTheme.textSecondary),
        prefixIcon: const Icon(Icons.sports, color: AppTheme.textSecondary),
        filled: true,
        fillColor: AppTheme.darkBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.darkDivider),
        ),
      ),
      items: sports.map((sport) => DropdownMenuItem(
        value: sport,
        child: Text(sport),
      )).toList(),
      onChanged: (value) => setState(() => _sportController.text = value ?? ''),
    );
  }

  Widget _buildLevelDropdown() {
    return DropdownButtonFormField<AthleteLevel>(
      value: _selectedLevel,
      style: const TextStyle(color: Colors.white),
      dropdownColor: AppTheme.darkCard,
      decoration: InputDecoration(
        labelText: 'Seviye',
        labelStyle: const TextStyle(color: AppTheme.textSecondary),
        prefixIcon: const Icon(Icons.star, color: AppTheme.textSecondary),
        filled: true,
        fillColor: AppTheme.darkBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.darkDivider),
        ),
      ),
      items: AthleteLevel.values.map((level) => DropdownMenuItem(
        value: level,
        child: Text(level.turkishName),
      )).toList(),
      onChanged: (value) => setState(() => _selectedLevel = value),
    );
  }

  void _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primaryColor,
              surface: AppTheme.darkCard,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      setState(() => _dateOfBirth = date);
    }
  }

  void _saveAthlete() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final athleteController = Get.find<AthleteController>();
      
      if (widget.athlete != null) {
        // Update existing athlete
        final updatedAthlete = widget.athlete!.copyWith(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
          dateOfBirth: _dateOfBirth,
          gender: _selectedGender,
          height: _heightController.text.isEmpty ? null : double.tryParse(_heightController.text),
          weight: _weightController.text.isEmpty ? null : double.tryParse(_weightController.text),
          sport: _sportController.text.trim().isEmpty ? null : _sportController.text.trim(),
          position: _positionController.text.trim().isEmpty ? null : _positionController.text.trim(),
          level: _selectedLevel,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          updatedAt: DateTime.now(),
        );

        final success = await athleteController.updateAthlete(updatedAthlete);
        if (success) {
          Get.back(result: updatedAthlete);
          Get.snackbar(
            'Başarılı',
            'Sporcu bilgileri güncellendi',
            backgroundColor: AppTheme.successColor,
            colorText: Colors.white,
          );
        } else {
          // Hata mesajını controller'dan al
          final errorMessage = athleteController.errorMessage ?? 'Sporcu güncellenemedi';
          Get.snackbar(
            'Hata',
            errorMessage,
            backgroundColor: AppTheme.errorColor,
            colorText: Colors.white,
            duration: const Duration(seconds: 4),
          );
        }
      } else {
        // Create new athlete
        final newAthlete = Athlete.create(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
          dateOfBirth: _dateOfBirth,
          gender: _selectedGender,
          height: _heightController.text.isEmpty ? null : double.tryParse(_heightController.text),
          weight: _weightController.text.isEmpty ? null : double.tryParse(_weightController.text),
          sport: _sportController.text.trim().isEmpty ? null : _sportController.text.trim(),
          position: _positionController.text.trim().isEmpty ? null : _positionController.text.trim(),
          level: _selectedLevel,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        );

        final success = await athleteController.addAthlete(newAthlete);
        if (success) {
          Get.back(result: newAthlete);
          Get.snackbar(
            'Başarılı',
            'Yeni sporcu eklendi',
            backgroundColor: AppTheme.successColor,
            colorText: Colors.white,
          );
        } else {
          // Hata mesajını controller'dan al
          final errorMessage = athleteController.errorMessage ?? 'Sporcu eklenemedi';
          Get.snackbar(
            'Hata',
            errorMessage,
            backgroundColor: AppTheme.errorColor,
            colorText: Colors.white,
            duration: const Duration(seconds: 4),
          );
        }
      }
    } catch (e) {
      Get.snackbar(
        'Hata',
        'Bir hata oluştu: $e',
        backgroundColor: AppTheme.errorColor,
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

}