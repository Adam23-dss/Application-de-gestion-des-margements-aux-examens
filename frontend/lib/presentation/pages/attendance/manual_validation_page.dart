import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend1/presentation/providers/auth_provider.dart';
import 'package:frontend1/presentation/providers/attendance_provider.dart';
import 'package:frontend1/data/models/student_model.dart';
import 'package:frontend1/presentation/widgets/custom_app_bar.dart';
import 'package:frontend1/presentation/widgets/student_card.dart';
import 'package:frontend1/core/themes/app_colors.dart';

class ManualValidationPage extends StatefulWidget {
  final int examId;
  final StudentModel? student;
  
  const ManualValidationPage({
    super.key,
    required this.examId,
    this.student,
  });
  
  @override
  State<ManualValidationPage> createState() => _ManualValidationPageState();
}

class _ManualValidationPageState extends State<ManualValidationPage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _studentCodeController = TextEditingController();
  final FocusNode _studentCodeFocusNode = FocusNode();
  
  String _selectedStatus = 'present';
  String _validationMethod = 'manual';
  String? _notes;
  
  bool _isSearching = false;
  bool _isValidating = false;
  List<StudentModel> _searchResults = [];
  StudentModel? _selectedStudent;
  
  @override
  void initState() {
    super.initState();
    
    // Si un étudiant est spécifié, le sélectionner
    if (widget.student != null) {
      _selectedStudent = widget.student;
      _studentCodeController.text = widget.student!.studentCode;
    }
    
    // Focus sur le champ de code étudiant
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.student == null) {
        _studentCodeFocusNode.requestFocus();
      }
    });
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _studentCodeController.dispose();
    _studentCodeFocusNode.dispose();
    super.dispose();
  }
  
  Future<void> _searchStudents(String query) async {
    if (query.length < 2) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }
    
    setState(() {
      _isSearching = true;
    });
    
    try {
      final attendanceProvider = context.read<AttendanceProvider>();
      final results = await attendanceProvider.searchStudent(query);
      
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      _showErrorSnackbar('Erreur de recherche: $e');
    }
  }
  
  Future<void> _validateAttendance() async {
    if (_selectedStudent == null) {
      _showErrorSnackbar('Veuillez sélectionner un étudiant');
      return;
    }
    
    if (_studentCodeController.text.isEmpty) {
      _showErrorSnackbar('Veuillez entrer un code étudiant');
      return;
    }
    
    setState(() {
      _isValidating = true;
    });
    
    try {
      final attendanceProvider = context.read<AttendanceProvider>();
      
      await attendanceProvider.validateAttendance(
        examId: widget.examId,
        studentCode: _studentCodeController.text.trim().toUpperCase(),
        status: _selectedStatus,
        validationMethod: _validationMethod,
      );
      
      _showSuccessSnackbar(
        'Présence ${_getStatusLabel(_selectedStatus)} validée pour ${_selectedStudent!.fullName}',
      );
      
      // Réinitialiser le formulaire
      _resetForm();
      
      // Retourner à la page précédente après un délai
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.pop(context);
        }
      });
      
    } catch (e) {
      _showErrorSnackbar('Erreur: $e');
    } finally {
      setState(() {
        _isValidating = false;
      });
    }
  }
  
  void _selectStudent(StudentModel student) {
    setState(() {
      _selectedStudent = student;
      _studentCodeController.text = student.studentCode;
      _searchResults = [];
      _searchController.clear();
    });
    
    // Cacher le clavier
    FocusScope.of(context).unfocus();
  }
  
  void _resetForm() {
    setState(() {
      _selectedStudent = null;
      _studentCodeController.clear();
      _notes = null;
      _searchResults = [];
      _selectedStatus = 'present';
    });
  }
  
  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  String _getStatusLabel(String status) {
    switch (status) {
      case 'present':
        return 'présent';
      case 'absent':
        return 'absent';
      case 'late':
        return 'en retard';
      case 'excused':
        return 'excusé';
      default:
        return status;
    }
  }
  
  Color _getStatusColor(String status) {
    switch (status) {
      case 'present':
        return Colors.green;
      case 'absent':
        return Colors.red;
      case 'late':
        return Colors.orange;
      case 'excused':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Validation Manuelle',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Informations examen
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Validation de présence',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Surveillant: ${authProvider.user?.fullName ?? 'Non connecté'}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Examen ID: ${widget.examId}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Recherche étudiant
            const Text(
              'Rechercher un étudiant',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Nom, prénom ou code étudiant...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchResults = [];
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: _searchStudents,
            ),
            
            // Résultats de recherche
            if (_isSearching)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            
            if (_searchResults.isNotEmpty)
              _buildSearchResults(),
            
            const SizedBox(height: 24),
            
            // Code étudiant manuel
            const Text(
              'Ou saisir le code manuellement',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            
            TextField(
              controller: _studentCodeController,
              focusNode: _studentCodeFocusNode,
              decoration: InputDecoration(
                hintText: 'Ex: ETU12345',
                prefixIcon: const Icon(Icons.badge),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                letterSpacing: 1,
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  _validateAttendance();
                }
              },
            ),
            
            const SizedBox(height: 8),
            
            if (_selectedStudent != null)
              StudentCard(
                student: _selectedStudent!,
                onTap: () {},
                showValidationStatus: false,
              ),
            
            const SizedBox(height: 24),
            
            // Statut de présence
            const Text(
              'Statut de présence',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildStatusOption('present', 'Présent', Icons.check_circle),
                _buildStatusOption('absent', 'Absent', Icons.cancel),
                _buildStatusOption('late', 'En retard', Icons.access_time),
                _buildStatusOption('excused', 'Excusé', Icons.medical_services),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Méthode de validation
            const Text(
              'Méthode de validation',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildValidationMethodOption('manual', 'Manuelle', Icons.touch_app),
                _buildValidationMethodOption('qr_code', 'QR Code', Icons.qr_code),
                _buildValidationMethodOption('nfc', 'NFC', Icons.nfc),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Notes (optionnel)
            const Text(
              'Notes (optionnel)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            
            TextField(
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Ajouter une note...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _notes = value;
                });
              },
            ),
            
            const SizedBox(height: 32),
            
            // Bouton de validation
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isValidating ? null : _validateAttendance,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isValidating
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, size: 24),
                          SizedBox(width: 12),
                          Text(
                            'Valider la présence',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Bouton annuler
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: Colors.grey[300]!),
                ),
                child: const Text(
                  'Annuler',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSearchResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          'Résultats (${_searchResults.length})',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        ..._searchResults.map((student) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: StudentCard(
              student: student,
              onTap: () => _selectStudent(student),
              showValidationStatus: false,
              showValidationActions: false,
            ),
          );
        }).toList(),
      ],
    );
  }
  
  Widget _buildStatusOption(String value, String label, IconData icon) {
    final isSelected = _selectedStatus == value;
    
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: isSelected ? Colors.white : _getStatusColor(value)),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedStatus = value;
        });
      },
      selectedColor: _getStatusColor(value),
      backgroundColor: Colors.grey[100],
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? _getStatusColor(value) : Colors.grey[300]!,
          width: isSelected ? 0 : 1,
        ),
      ),
    );
  }
  
  Widget _buildValidationMethodOption(String value, String label, IconData icon) {
    final isSelected = _validationMethod == value;
    
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: isSelected ? Colors.white : Colors.grey[700]),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _validationMethod = value;
        });
      },
      selectedColor: AppColors.primary,
      backgroundColor: Colors.grey[100],
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppColors.primary : Colors.grey[300]!,
          width: isSelected ? 0 : 1,
        ),
      ),
    );
  }
}

// Page pour validation rapide (QR/NFC)
class QuickValidationPage extends StatefulWidget {
  final int examId;
  final String initialCode;
  final String validationMethod;
  
  const QuickValidationPage({
    super.key,
    required this.examId,
    this.initialCode = '',
    this.validationMethod = 'qr_code',
  });
  
  @override
  State<QuickValidationPage> createState() => _QuickValidationPageState();
}

class _QuickValidationPageState extends State<QuickValidationPage> {
  late String _studentCode;
  late String _validationMethod;
  
  @override
  void initState() {
    super.initState();
    _studentCode = widget.initialCode;
    _validationMethod = widget.validationMethod;
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: _validationMethod == 'qr_code' ? 'Scan QR Code' : 'Scan NFC',
        showBackButton: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _validationMethod == 'qr_code' ? Icons.qr_code_scanner : Icons.nfc,
                size: 120,
                color: AppColors.primary.withOpacity(0.5),
              ),
              const SizedBox(height: 32),
              const Text(
                'Prêt à scanner',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _validationMethod == 'qr_code'
                    ? 'Scannez le QR code de l\'étudiant'
                    : 'Approchez la carte étudiante NFC',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),
              
              if (_studentCode.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Code détecté:',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _studentCode,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Valider la présence
                  },
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Valider la présence'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(200, 50),
                  ),
                ),
              ],
              
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),
              
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ManualValidationPage(
                        examId: widget.examId,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.keyboard),
                label: const Text('Saisie manuelle'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}