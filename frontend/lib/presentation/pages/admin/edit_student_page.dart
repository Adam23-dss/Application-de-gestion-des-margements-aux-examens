import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend1/core/themes/app_colors.dart';
import 'package:frontend1/presentation/widgets/custom_app_bar.dart';
import 'package:frontend1/presentation/providers/student_provider.dart';
import 'package:frontend1/data/models/student_model.dart';

class EditStudentPage extends StatefulWidget {
  final int studentId;
  
  const EditStudentPage({
    super.key,
    required this.studentId,
  });
  
  @override
  State<EditStudentPage> createState() => _EditStudentPageState();
}

class _EditStudentPageState extends State<EditStudentPage> {
  final _formKey = GlobalKey<FormState>();
  late StudentModel _student;
  
  // Contrôleurs
  late TextEditingController _studentCodeController;
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _promotionController;
  
  // Variables pour les dropdowns
  String _selectedUfr = '';
  String _selectedDepartment = '';
  
  // Données dynamiques - MISE À JOUR ICI
  // Liste complète des UFRs possibles
  final List<String> _ufrList = [
    'Sciences',  // Ajouté pour correspondre au backend
    'UFR SEG',
    'UFR LSH',
    'UFR STAPS',
    'UFR Sciences et Technologies',
    'UFR Droit et Science Politique',
    'UFR Médecine et Pharmacie',
    'UFR IUT',
    'Lettres',  // Ajouté pour correspondre au backend
    'Arts',     // Ajouté pour correspondre au backend
  ];
  
  // Mise à jour des départements
  final Map<String, List<String>> _departmentsByUfr = {
    'Sciences': ['Informatique', 'Mathématiques', 'Physique', 'Chimie'],  // Ajouté
    'Lettres': ['Philosophie', 'Lettres', 'Histoire'],  // Ajouté
    'Arts': ['Communication'],  // Ajouté
    'UFR SEG': ['GEA', 'MIAGE', 'Economie-Gestion', 'CAAE'],
    'UFR LSH': ['Lettres', 'Histoire', 'Philosophie', 'Langues'],
    'UFR Sciences et Technologies': ['Mathématiques', 'Informatique', 'Physique', 'Chimie'],
    'UFR Droit et Science Politique': ['Droit', 'Science Politique', 'Administration Publique'],
  };

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isActive = true;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _loadStudent();
  }
  
  Future<void> _loadStudent() async {
    try {
      final studentProvider = context.read<StudentProvider>();
      final student = await studentProvider.getStudentById(widget.studentId);
      
      if (student == null) {
        throw Exception('Étudiant non trouvé');
      }
      
      setState(() {
        _student = student;
        _isActive = student.isActive;
        
        // Initialiser les contrôleurs
        _studentCodeController = TextEditingController(text: student.studentCode);
        _firstNameController = TextEditingController(text: student.firstName);
        _lastNameController = TextEditingController(text: student.lastName);
        _emailController = TextEditingController(text: student.email ?? '');
        _promotionController = TextEditingController(text: student.promotion ?? '');
        
        // Initialiser les dropdowns
        _selectedUfr = student.ufr;
        _selectedDepartment = student.department;
        
        _isLoading = false;
      });
      
      // DEBUG
      print('🎯 Étudiant chargé:');
      print('  UFR: $_selectedUfr');
      print('  Département: $_selectedDepartment');
      print('  Liste UFR disponible: $_ufrList');
      print('  UFR dans la liste: ${_ufrList.contains(_selectedUfr)}');
      
    } catch (e) {
      print('❌ Erreur chargement étudiant: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }
  
  @override
  void dispose() {
    _studentCodeController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _promotionController.dispose();
    super.dispose();
  }
  
  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (_selectedUfr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Veuillez sélectionner une UFR'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (_selectedDepartment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Veuillez sélectionner un département'),
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
      final studentProvider = context.read<StudentProvider>();
      
      final studentData = {
        'student_code': _studentCodeController.text.trim().toUpperCase(),
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'email': _emailController.text.trim().isNotEmpty
            ? _emailController.text.trim().toLowerCase()
            : null,
        'ufr': _selectedUfr,
        'department': _selectedDepartment,
        'promotion': _promotionController.text.trim().isNotEmpty
            ? _promotionController.text.trim()
            : null,
        'is_active': _isActive,
      };
      
      print('📤 Données envoyées: $studentData');
      
      final updatedStudent = await studentProvider.updateStudent(
        widget.studentId,
        studentData,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Étudiant ${updatedStudent.fullName} mis à jour avec succès'),
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
    String? debugInfo,
  }) {
    if (debugInfo != null) {
      print('🔍 $debugInfo');
      print('  Valeur: $value');
      print('  Items: $items');
      print('  Contient valeur: ${items.contains(value)}');
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
    
    // Chercher dans les différentes clés possibles
    if (_departmentsByUfr.containsKey(_selectedUfr)) {
      return _departmentsByUfr[_selectedUfr]!;
    }
    
    // Si pas trouvé, retourner une liste vide ou un département par défaut
    print('⚠️ UFR "$_selectedUfr" non trouvée dans _departmentsByUfr');
    return [_selectedDepartment]; // Garder le département actuel
  }
  
  // Méthode pour vérifier si une UFR existe
  bool _ufrExistsInList(String ufr) {
    final exists = _ufrList.contains(ufr);
    print('🔍 UFR "$ufr" existe dans liste: $exists');
    return exists;
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: CustomAppBar(
          title: 'Modifier l\'étudiant',
          showBackButton: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    if (_errorMessage != null) {
      return Scaffold(
        appBar: CustomAppBar(
          title: 'Modifier l\'étudiant',
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
                onPressed: _loadStudent,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }
    
    // Vérifier si l'UFR existe dans la liste
    final ufrExists = _ufrExistsInList(_selectedUfr);
    final availableDepartments = _getAvailableDepartments();
    
    print('🏗️ Building EditStudentPage:');
    print('  UFR sélectionnée: $_selectedUfr');
    print('  UFR existe: $ufrExists');
    print('  Département sélectionné: $_selectedDepartment');
    print('  Départements disponibles: $availableDepartments');
    
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Modifier l\'étudiant',
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
                'Mettez à jour les informations de l\'étudiant',
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              
              // Code étudiant
              _buildTextField(
                label: 'Code étudiant',
                controller: _studentCodeController,
                required: true,
                hintText: 'ex: ETU00123',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Le code étudiant est requis';
                  }
                  if (value.length < 3) {
                    return 'Le code doit contenir au moins 3 caractères';
                  }
                  return null;
                },
              ),
              
              // Nom et prénom
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      label: 'Prénom',
                      controller: _firstNameController,
                      required: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      label: 'Nom',
                      controller: _lastNameController,
                      required: true,
                    ),
                  ),
                ],
              ),
              
              // Email
              _buildTextField(
                label: 'Email',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                hintText: 'etudiant@univ.edu',
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return 'Email invalide';
                    }
                  }
                  return null;
                },
              ),
              
              // UFR avec debug info
              _buildDropdown(
                label: 'UFR',
                value: ufrExists ? _selectedUfr : '',
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
              if (!ufrExists && _selectedUfr.isNotEmpty)
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
              
              // Département (seulement si UFR sélectionnée)
              if (_selectedUfr.isNotEmpty)
                _buildDropdown(
                  label: 'Département',
                  value: _selectedDepartment,
                  items: availableDepartments.isEmpty 
                      ? [_selectedDepartment] // Garder le département actuel s'il n'est pas dans la liste
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
                  availableDepartments.isNotEmpty && 
                  !availableDepartments.contains(_selectedDepartment) &&
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
              
              // Promotion - Champ texte simple pour l'année
              _buildTextField(
                label: 'Promotion (Année)',
                controller: _promotionController,
                keyboardType: TextInputType.number,
                hintText: 'ex: 2024',
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final year = int.tryParse(value);
                    if (year == null || year < 2000 || year > 2100) {
                      return 'Veuillez entrer une année valide (2000-2100)';
                    }
                  }
                  return null;
                },
              ),
              
              // Statut actif
              SwitchListTile(
                title: const Text('Étudiant actif'),
                subtitle: const Text('L\'étudiant pourra participer aux examens'),
                value: _isActive,
                onChanged: (value) {
                  setState(() {
                    _isActive = value;
                  });
                },
                activeColor: AppColors.primary,
              ),
              
              const SizedBox(height: 16),
              
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