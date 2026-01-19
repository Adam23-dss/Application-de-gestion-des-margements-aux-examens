import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend1/core/themes/app_colors.dart';
import 'package:frontend1/presentation/widgets/custom_app_bar.dart';
import 'package:frontend1/presentation/providers/student_provider.dart';

class CreateStudentPage extends StatefulWidget {
  const CreateStudentPage({super.key});

  @override
  State<CreateStudentPage> createState() => _CreateStudentPageState();
}

class _CreateStudentPageState extends State<CreateStudentPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Contrôleurs
  final TextEditingController _studentCodeController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _promotionController = TextEditingController();
  
  // Variables pour les dropdowns
  String _selectedUfr = '';
  String _selectedDepartment = '';
  
  // Liste des UFRs disponibles (devraient venir du backend)
  final List<String> _ufrList = [
    'UFR SEG',
    'UFR LSH',
    'UFR STAPS',
    'UFR Sciences et Technologies',
    'UFR Droit et Science Politique',
    'UFR Médecine et Pharmacie',
    'UFR IUT',
  ];
  
  // Liste des départements par UFR (exemple)
  final Map<String, List<String>> _departmentsByUfr = {
    'UFR SEG': ['GEA', 'MIAGE', 'Economie-Gestion', 'CAAE'],
    'UFR LSH': ['Lettres', 'Histoire', 'Philosophie', 'Langues'],
    'UFR Sciences et Technologies': ['Mathématiques', 'Informatique', 'Physique', 'Chimie'],
    'UFR Droit et Science Politique': ['Droit', 'Science Politique', 'Administration Publique'],
  };
  
  bool _isActive = true;
  bool _isLoading = false;
  String? _errorMessage;
  
  @override
  void dispose() {
    _studentCodeController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _promotionController.dispose();
    super.dispose();
  }
  
  Future<void> _createStudent() async {
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
      _isLoading = true;
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
      
      final newStudent = await studentProvider.createStudent(studentData);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Étudiant ${newStudent.fullName} créé avec succès'),
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
        title: 'Créer un Étudiant',
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
                'Informations de l\'étudiant',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Remplissez les informations de l\'étudiant',
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
              
              // UFR
              _buildDropdown(
                label: 'UFR',
                value: _selectedUfr,
                items: _ufrList,
                required: true,
                onChanged: (value) {
                  setState(() {
                    _selectedUfr = value ?? '';
                    _selectedDepartment = ''; // Réinitialiser département
                  });
                },
              ),
              
              // Département (seulement si UFR sélectionnée)
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
                      onPressed: _isLoading ? null : _createStudent,
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
                                Icon(Icons.person_add, size: 20),
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