// lib/presentation/screens/athlete_form_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/entities/athlete.dart';
import '../../domain/usecases/manage_athlete_usecase.dart';
import '../../presentation/controllers/athlete_controller.dart';
import '../../app/injection_container.dart';

class AthleteFormScreen extends StatefulWidget {
  final Athlete? athlete; // null ise yeni atlet, dolu ise düzenleme

  const AthleteFormScreen({
    super.key,
    this.athlete,
  });

  @override
  State<AthleteFormScreen> createState() => _AthleteFormScreenState();
}

class _AthleteFormScreenState extends State<AthleteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _sportController = TextEditingController();
  final _positionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _notesController = TextEditingController();

  Gender _selectedGender = Gender.male;
  DateTime _selectedBirthDate = DateTime.now().subtract(const Duration(days: 365 * 20)); // 20 yaş varsayılan
  bool _isLoading = false;
  bool get _isEditing => widget.athlete != null;

  // Spor dalları listesi
  final List<String> _sports = [
    'Futbol',
    'Basketbol',
    'Voleybol',
    'Tenis',
    'Atletizm',
    'Yüzme',
    'Hentbol',
    'Buz Hokeyi',
    'Amerikan Futbolu',
    'Ragbi',
    'Diğer',
  ];

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (_isEditing) {
      final athlete = widget.athlete!;
      _firstNameController.text = athlete.firstName;
      _lastNameController.text = athlete.lastName;
      _selectedGender = athlete.gender == 'M' ? Gender.male : Gender.female;
      _selectedBirthDate = DateTime.now().subtract(Duration(days: athlete.age * 365));
      _heightController.text = athlete.height?.toString() ?? '';
      _weightController.text = athlete.weight?.toString() ?? '';
      _sportController.text = athlete.sport ?? '';
      _positionController.text = athlete.position ?? '';
      _phoneController.text = athlete.phone ?? '';
      _emailController.text = athlete.email ?? '';
      _notesController.text = athlete.notes ?? '';
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _sportController.dispose();
    _positionController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveAthlete() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final controller = sl<AthleteController>();
      
      bool success;
      if (_isEditing) {
        final updatedAthlete = widget.athlete!.copyWith(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          age: DateTime.now().year - _selectedBirthDate.year,
          gender: _selectedGender == Gender.male ? 'M' : 'F',
          height: _heightController.text.isNotEmpty ? double.parse(_heightController.text) : null,
          weight: _weightController.text.isNotEmpty ? double.parse(_weightController.text) : null,
          sport: _sportController.text.isNotEmpty ? _sportController.text.trim() : null,
          position: _positionController.text.isNotEmpty ? _positionController.text.trim() : null,
          phone: _phoneController.text.isNotEmpty ? _phoneController.text.trim() : null,
          email: _emailController.text.isNotEmpty ? _emailController.text.trim() : null,
          notes: _notesController.text.isNotEmpty ? _notesController.text.trim() : null,
        );
        success = await controller.updateAthlete(updatedAthlete);
      } else {
        success = await controller.addAthlete(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          birthDate: _selectedBirthDate,
          gender: _selectedGender,
          height: _heightController.text.isNotEmpty ? double.parse(_heightController.text) : 0,
          weight: _weightController.text.isNotEmpty ? double.parse(_weightController.text) : 0,
          sport: _sportController.text.isNotEmpty ? _sportController.text.trim() : null,
          position: _positionController.text.isNotEmpty ? _positionController.text.trim() : null,
          notes: _notesController.text.isNotEmpty ? _notesController.text.trim() : null,
        );
      }

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isEditing ? 'Atlet güncellendi' : 'Atlet eklendi'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Hata: ${controller.errorMessage}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 80)),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
    );
    
    if (picked != null) {
      setState(() {
        _selectedBirthDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Atlet Düzenle' : 'Yeni Atlet',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveAthlete,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    _isEditing ? 'Güncelle' : 'Kaydet',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Kişisel Bilgiler
              _buildSectionCard(
                'Kişisel Bilgiler',
                Icons.person,
                [
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextFormField(
                          controller: _firstNameController,
                          label: 'Ad',
                          validator: (value) {
                            if (value?.trim().isEmpty ?? true) {
                              return 'Ad zorunludur';
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
                          validator: (value) {
                            if (value?.trim().isEmpty ?? true) {
                              return 'Soyad zorunludur';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildBirthDateField()),
                      const SizedBox(width: 12),
                      Expanded(child: _buildGenderSelector()),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Fiziksel Özellikler
              _buildSectionCard(
                'Fiziksel Özellikler',
                Icons.fitness_center,
                [
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextFormField(
                          controller: _heightController,
                          label: 'Boy (cm)',
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))],
                          validator: (value) {
                            if (value?.isNotEmpty == true) {
                              final height = double.tryParse(value!);
                              if (height == null || height < 100 || height > 250) {
                                return 'Geçerli boy girin (100-250cm)';
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
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))],
                          validator: (value) {
                            if (value?.isNotEmpty == true) {
                              final weight = double.tryParse(value!);
                              if (weight == null || weight < 30 || weight > 200) {
                                return 'Geçerli kilo girin (30-200kg)';
                              }
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Spor Bilgileri
              _buildSectionCard(
                'Spor Bilgileri',
                Icons.sports,
                [
                  _buildSportDropdown(),
                  const SizedBox(height: 16),
                  _buildTextFormField(
                    controller: _positionController,
                    label: 'Pozisyon / Uzmanlık',
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // İletişim Bilgileri
              _buildSectionCard(
                'İletişim Bilgileri',
                Icons.contact_phone,
                [
                  _buildTextFormField(
                    controller: _phoneController,
                    label: 'Telefon',
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value?.isNotEmpty == true && value!.length < 10) {
                        return 'Geçerli telefon numarası girin';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextFormField(
                    controller: _emailController,
                    label: 'E-posta',
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value?.isNotEmpty == true && !value!.contains('@')) {
                        return 'Geçerli e-posta adresi girin';
                      }
                      return null;
                    },
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Notlar
              _buildSectionCard(
                'Notlar',
                Icons.notes,
                [
                  _buildTextFormField(
                    controller: _notesController,
                    label: 'Ek notlar',
                    maxLines: 3,
                  ),
                ],
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  Widget _buildBirthDateField() {
    final age = DateTime.now().year - _selectedBirthDate.year;
    
    return InkWell(
      onTap: _selectBirthDate,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey[50],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Doğum Tarihi',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${_selectedBirthDate.day}/${_selectedBirthDate.month}/${_selectedBirthDate.year} ($age yaş)',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cinsiyet',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: RadioListTile<Gender>(
                title: const Text('Erkek'),
                value: Gender.male,
                groupValue: _selectedGender,
                onChanged: (value) {
                  setState(() => _selectedGender = value!);
                },
                contentPadding: EdgeInsets.zero,
              ),
            ),
            Expanded(
              child: RadioListTile<Gender>(
                title: const Text('Kadın'),
                value: Gender.female,
                groupValue: _selectedGender,
                onChanged: (value) {
                  setState(() => _selectedGender = value!);
                },
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSportDropdown() {
    return DropdownButtonFormField<String>(
      value: _sports.contains(_sportController.text) ? _sportController.text : null,
      decoration: InputDecoration(
        labelText: 'Spor Dalı',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      items: _sports.map((sport) {
        return DropdownMenuItem(
          value: sport,
          child: Text(sport),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _sportController.text = value ?? '';
        });
      },
    );
  }
}