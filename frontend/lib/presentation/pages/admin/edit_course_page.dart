import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend1/core/themes/app_colors.dart';
import 'package:frontend1/presentation/widgets/custom_app_bar.dart';
import 'package:frontend1/presentation/providers/course_provider.dart';
import 'package:frontend1/data/models/course_model.dart';

class EditCoursePage extends StatefulWidget {
  final int courseId;
  
  const EditCoursePage({
    super.key,
    required this.courseId,
  });
  
  @override
  State<EditCoursePage> createState() => _EditCoursePageState();
}

class _EditCoursePageState extends State<EditCoursePage> {
  final _formKey = GlobalKey<FormState>();
  late CourseModel _course;
  
  // Contrôleurs
  late TextEditingController _codeController;
  late TextEditingController _nameController;
  late TextEditingController _creditsController;
  late TextEditingController _descriptionController;
  
  // Variables pour les dropdowns
  String _selectedUfr = '';
  String _selectedDepartment = '';
  
  // Données dynamiques
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

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _loadCourse();
  }
  
  Future<void> _loadCourse() async {
    try {
      final courseProvider = context.read<CourseProvider>();
      final course = await courseProvider.getCourseById(widget.courseId);
      
      if (course == null) {
        throw Exception('Cours non trouvé');
      }
      
      setState(() {
        _course = course;
        
        // Initialiser les contrôleurs
        _codeController = TextEditingController(text: course.code);
        _nameController = TextEditingController(text: course.name);
        _creditsController = TextEditingController(text: course.credits?.toString() ?? '');
        _descriptionController = TextEditingController(text: course.description ?? '');
        
        // Initialiser les dropdowns
        _selectedUfr = course.ufr ?? '';
        _selectedDepartment = course.department ?? '';
        
        _isLoading = false;
      });
      
      // DEBUG
      print('🎯 Cours chargé:');
      print('  UFR: $_selectedUfr');
      print('  Département: $_selectedDepartment');
      
    } catch (e) {
      print('❌ Erreur chargement cours: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }
  
  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _creditsController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
  
  Future<void> _saveChanges() async {
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
      _isSaving = true;
      _errorMessage = null;
    });
    
    try {
      final courseProvider = context.read<CourseProvider>();
      
      final courseData = {
        'name': _nameController.text.trim(),
        'ufr': _selectedUfr,
        'department': _selectedDepartment,
        if (_creditsController.text.isNotEmpty) 'credits': int.tryParse(_creditsController.text),
        if (_descriptionController.text.isNotEmpty) 'description': _descriptionController.text.trim(),
      };
      
      print('📤 Données envoyées: $courseData');
      
      final updatedCourse = await courseProvider.updateCourse(
        widget.courseId,
        courseData,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cours "${updatedCourse.name}" mis à jour avec succès'),
          backgroundColor: Colors.green,
        ),
      );
      
      Navigator.pop(context);
      
    } catch (e) {
      print('❌ Erreur sauvegarde: $e');
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
        _isSaving = false;
      });
    }
  }
  
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    bool required = false,
    bool readOnly = false,
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
          readOnly: readOnly,
          decoration: InputDecoration(
            hintText: hintText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: readOnly ? Colors.grey[100] : Colors.grey[50],
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
    String? debugInfo,
  }) {
    if (debugInfo != null) {
      print('🔍 $debugInfo');
      print('  Valeur: $value');
      print('  Items: $items');
    }
    
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
  
  // Méthode pour obtenir la liste des départements disponibles
  List<String> _getAvailableDepartments() {
    if (_selectedUfr.isEmpty) return [];
    
    if (_departmentsByUfr.containsKey(_selectedUfr)) {
      return _departmentsByUfr[_selectedUfr]!;
    }
    
    // Si l'UFR n'est pas dans la liste, garder le département actuel
    print('⚠️ UFR "$_selectedUfr" non trouvée dans _departmentsByUfr');
    return [_selectedDepartment];
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: CustomAppBar(
          title: 'Modifier le cours',
          showBackButton: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    if (_errorMessage != null) {
      return Scaffold(
        appBar: CustomAppBar(
          title: 'Modifier le cours',
          showBackButton: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadCourse,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }
    
    final availableDepartments = _getAvailableDepartments();
    
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Modifier le cours',
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
                'Modifier les informations',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Mettez à jour les informations du cours',
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              
              // Code cours (lecture seule)
              _buildTextField(
                label: 'Code cours',
                controller: _codeController,
                readOnly: true,
                hintText: 'ex: INF101',
              ),
              
              // Nom cours
              _buildTextField(
                label: 'Nom du cours',
                controller: _nameController,
                required: true,
                hintText: 'ex: Introduction à la programmation',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Le nom du cours est requis';
                  }
                  return null;
                },
              ),
              
              // UFR
              _buildDropdown(
                label: 'UFR',
                value: _selectedUfr,
                items: _ufrList,
                required: true,
                debugInfo: 'UFR Dropdown',
                onChanged: (value) {
                  setState(() {
                    _selectedUfr = value ?? '';
                    _selectedDepartment = ''; // Réinitialiser département
                    print('🔄 UFR changée: $_selectedUfr');
                  });
                },
              ),
              
              // Si l'UFR n'existe pas dans la liste, afficher un avertissement
              if (!_ufrList.contains(_selectedUfr) && _selectedUfr.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[100]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'UFR "$_selectedUfr" non standard. Veuillez en sélectionner une dans la liste.',
                          style: TextStyle(color: Colors.orange[700]),
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Département
              _buildDropdown(
                label: 'Département',
                value: _selectedDepartment,
                items: availableDepartments.isEmpty 
                    ? [_selectedDepartment] // Garder le département actuel
                    : availableDepartments,
                required: true,
                debugInfo: 'Département Dropdown',
                onChanged: (value) {
                  setState(() {
                    _selectedDepartment = value ?? '';
                    print('🔄 Département changé: $_selectedDepartment');
                  });
                },
              ),
              
              // Si le département n'est pas dans la liste standard, afficher un avertissement
              if (_selectedUfr.isNotEmpty && 
                  _departmentsByUfr.containsKey(_selectedUfr) &&
                  !_departmentsByUfr[_selectedUfr]!.contains(_selectedDepartment) &&
                  _selectedDepartment.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[100]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Département "$_selectedDepartment" non standard pour "$_selectedUfr".',
                          style: TextStyle(color: Colors.orange[700]),
                        ),
                      ),
                    ],
                  ),
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
                      onPressed: _isSaving ? null : () => Navigator.pop(context),
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
                      onPressed: _isSaving ? null : _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isSaving
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
                                Icon(Icons.save, size: 20),
                                SizedBox(width: 8),
                                Text('Enregistrer'),
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