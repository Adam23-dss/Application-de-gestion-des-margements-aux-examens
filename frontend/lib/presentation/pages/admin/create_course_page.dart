import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend1/core/themes/app_colors.dart';
import 'package:frontend1/presentation/widgets/custom_app_bar.dart';
import 'package:frontend1/presentation/providers/course_provider.dart';

class CreateCoursePage extends StatefulWidget {
  const CreateCoursePage({super.key});

  @override
  State<CreateCoursePage> createState() => _CreateCoursePageState();
}

class _CreateCoursePageState extends State<CreateCoursePage> {
  final _formKey = GlobalKey<FormState>();
  
  // Contrôleurs
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ufrController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _creditsController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  // Variables
  String _selectedUfr = '';
  String _selectedDepartment = '';
  
  // Données
  final List<String> _ufrList = [
    'Sciences',
    'Lettres',
    'Arts',
    'UFR SEG',
    'UFR LSH',
    'UFR STAPS',
    'UFR Sciences et Technologies',
    'UFR Droit et Science Politique',
    'UFR Médecine et Pharmacie',
    'UFR IUT',
  ];
  
  final Map<String, List<String>> _departmentsByUfr = {
    'Sciences': ['Informatique', 'Mathématiques', 'Physique', 'Chimie'],
    'Lettres': ['Philosophie', 'Lettres', 'Histoire'],
    'Arts': ['Communication'],
    'UFR SEG': ['GEA', 'MIAGE', 'Economie-Gestion', 'CAAE'],
    'UFR LSH': ['Lettres', 'Histoire', 'Philosophie', 'Langues'],
    'UFR Sciences et Technologies': ['Mathématiques', 'Informatique', 'Physique', 'Chimie'],
    'UFR Droit et Science Politique': ['Droit', 'Science Politique', 'Administration Publique'],
  };
  
  bool _isLoading = false;
  String? _errorMessage;
  
  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _ufrController.dispose();
    _departmentController.dispose();
    _creditsController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
  
  Future<void> _createCourse() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (_selectedUfr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une UFR'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (_selectedDepartment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un département'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final courseProvider = context.read<CourseProvider>();
      
      final courseData = {
        'code': _codeController.text.trim().toUpperCase(),
        'name': _nameController.text.trim(),
        'ufr': _selectedUfr,
        'department': _selectedDepartment,
        if (_creditsController.text.isNotEmpty) 'credits': int.tryParse(_creditsController.text),
        if (_descriptionController.text.isNotEmpty) 'description': _descriptionController.text.trim(),
      };
      
      final newCourse = await courseProvider.createCourse(courseData);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cours "${newCourse.name}" créé avec succès'),
          backgroundColor: Colors.green,
        ),
      );
      
      Navigator.pop(context);
      
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    bool required = false,
    String? hintText,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label${required ? ' *' : ''}',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hintText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          validator: validator ?? (value) {
            if (required && (value == null || value.isEmpty)) {
              return 'Ce champ est requis';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }
  
  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label${required ? ' *' : ''}',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButton<String>(
            value: value.isEmpty ? null : value,
            items: [
              DropdownMenuItem<String>(
                value: '',
                child: Text(
                  required ? 'Sélectionnez...' : 'Non spécifié',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ),
              ...items.map((item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
            ],
            onChanged: onChanged,
            isExpanded: true,
            underline: const SizedBox(),
            icon: const Icon(Icons.arrow_drop_down),
            hint: Text(
              required ? 'Sélectionnez...' : 'Non spécifié',
              style: TextStyle(color: Colors.grey[500]),
            ),
            style: const TextStyle(
              color: Colors.black,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Créer un Cours',
        showBackButton: true,
      ),
      
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Informations du cours',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Remplissez les informations du cours',
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              
              // Code cours
              _buildTextField(
                label: 'Code cours',
                controller: _codeController,
                required: true,
                hintText: 'ex: INF101',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Le code cours est requis';
                  }
                  if (value.length < 2) {
                    return 'Le code doit contenir au moins 2 caractères';
                  }
                  return null;
                },
              ),
              
              // Nom cours
              _buildTextField(
                label: 'Nom du cours',
                controller: _nameController,
                required: true,
                hintText: 'ex: Introduction à la programmation',
              ),
              
              // UFR
              _buildDropdown(
                label: 'UFR',
                value: _selectedUfr,
                items: _ufrList,
                required: true,
                onChanged: (value) {
                  setState(() {
                    _selectedUfr = value ?? '';
                    _selectedDepartment = '';
                  });
                },
              ),
              
              // Département
              if (_selectedUfr.isNotEmpty && _departmentsByUfr.containsKey(_selectedUfr))
                _buildDropdown(
                  label: 'Département',
                  value: _selectedDepartment,
                  items: _departmentsByUfr[_selectedUfr]!,
                  required: true,
                  onChanged: (value) {
                    setState(() {
                      _selectedDepartment = value ?? '';
                    });
                  },
                ),
              
              // Crédits
              _buildTextField(
                label: 'Crédits',
                controller: _creditsController,
                keyboardType: TextInputType.number,
                hintText: 'ex: 3',
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final credits = int.tryParse(value);
                    if (credits == null || credits <= 0) {
                      return 'Veuillez entrer un nombre valide';
                    }
                  }
                  return null;
                },
              ),
              
              // Description
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Description du cours...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
              
              // Message d'erreur
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[100]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 24),
              
              // Boutons d'action
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _createCourse,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add, size: 20),
                                SizedBox(width: 8),
                                Text('Créer'),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}