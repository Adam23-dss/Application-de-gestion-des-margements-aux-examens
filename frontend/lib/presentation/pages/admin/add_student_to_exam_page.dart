// presentation/pages/admin/add_student_to_exam_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend1/presentation/widgets/custom_app_bar.dart';
import 'package:frontend1/presentation/widgets/student_card.dart';
import 'package:frontend1/presentation/providers/exam_registration_provider.dart';
import 'package:frontend1/presentation/providers/exam_provider.dart';
import 'package:frontend1/data/models/exam_model.dart';
import 'package:frontend1/data/models/student_model.dart';
import 'package:frontend1/core/themes/app_colors.dart';

class AddStudentToExamPage extends StatefulWidget {
  final int examId;
  
  const AddStudentToExamPage({
    super.key,
    required this.examId,
  });
  
  @override
  State<AddStudentToExamPage> createState() => _AddStudentToExamPageState();
}

class _AddStudentToExamPageState extends State<AddStudentToExamPage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  
  List<StudentModel> _selectedStudents = [];
  ExamModel? _exam;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
    
    _searchController.addListener(() {
      final provider = context.read<ExamRegistrationProvider>();
      provider.searchQuery = _searchController.text;
    });
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _notesController.dispose();
    super.dispose();
  }
  
  Future<void> _loadData() async {
    // Charger les détails de l'examen
    final examProvider = context.read<ExamProvider>();
    _exam = examProvider.exams.firstWhere(
      (exam) => exam.id == widget.examId,
      orElse: () => ExamModel(
        id: 0,
        name: 'Examen inconnu',
        examDate: DateTime.now(),
        startTime: '00:00',
        endTime: '00:00',
        status: 'scheduled',
        totalStudents: 0,
      ),
    );
    
    // Charger les étudiants déjà inscrits
    final registrationProvider = context.read<ExamRegistrationProvider>();
    await registrationProvider.loadExamStudents(widget.examId);
    
    if (mounted) {
      setState(() {});
    }
  }
  
  Future<void> _addStudent(StudentModel student) async {
    final provider = context.read<ExamRegistrationProvider>();
    
    try {
      await provider.addStudentToExam(
        examId: widget.examId,
        studentId: student.id,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );
      
      _selectedStudents.add(student);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${student.fullName} ajouté à l\'examen'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Effacer la recherche
      _searchController.clear();
      _notesController.clear();
      provider.searchQuery = '';
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<void> _removeStudent(StudentModel student) async {
    final provider = context.read<ExamRegistrationProvider>();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Retirer l\'étudiant'),
        content: Text('Voulez-vous retirer ${student.fullName} de cet examen ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Retirer',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        await provider.removeStudentFromExam(
          examId: widget.examId,
          studentId: student.id,
        );
        
        _selectedStudents.removeWhere((s) => s.id == student.id);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${student.fullName} retiré de l\'examen'),
            backgroundColor: Colors.orange,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _addMultipleStudents() async {
    final provider = context.read<ExamRegistrationProvider>();
    
    if (provider.availableStudents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucun étudiant sélectionné'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajout multiple'),
        content: Text(
          'Ajouter ${provider.availableStudents.length} étudiants à l\'examen ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        final studentIds = provider.availableStudents.map((s) => s.id).toList();
        
        await provider.bulkRegisterStudents(
          examId: widget.examId,
          studentIds: studentIds,
          notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${studentIds.length} étudiants ajoutés avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Réinitialiser
        _searchController.clear();
        _notesController.clear();
        provider.searchQuery = '';
        
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Widget _buildExamHeader() {
    if (_exam == null) return const SizedBox();
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _exam!.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            
            Row(
              children: [
                const Icon(Icons.event, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(_exam!.formattedDate),
                const SizedBox(width: 16),
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(_exam!.formattedTime),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Row(
              children: [
                const Icon(Icons.people, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text('${_exam!.totalStudents} étudiants inscrits'),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSearchSection(ExamRegistrationProvider provider) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rechercher des étudiants',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            
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
                          provider.searchQuery = '';
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            
            const SizedBox(height: 8),
            
            const Text(
              'Notes (optionnel)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Ajouter des notes pour cet ajout...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            if (provider.availableStudents.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _addMultipleStudents,
                  icon: const Icon(Icons.group_add),
                  label: const Text('Ajouter tous les étudiants affichés'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSearchResults(ExamRegistrationProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (provider.availableStudents.isEmpty && _searchController.text.length >= 2) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Aucun étudiant trouvé',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }
    
    if (provider.availableStudents.isEmpty) {
      return const SizedBox();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Résultats (${provider.availableStudents.length})',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: provider.availableStudents.length,
          itemBuilder: (context, index) {
            final student = provider.availableStudents[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: StudentCard(
                student: student,
                onTap: () => _addStudent(student),
                showValidationStatus: false,
                showValidationActions: false,
                trailing: ElevatedButton.icon(
                  onPressed: () => _addStudent(student),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Ajouter'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(100, 40),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
  
  Widget _buildRegisteredStudents(ExamRegistrationProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Étudiants inscrits (${provider.examStudents.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (provider.examStudents.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: () {
                    // TODO: Exporter la liste des étudiants
                  },
                  tooltip: 'Exporter la liste',
                ),
            ],
          ),
        ),
        
        if (provider.examStudents.isEmpty)
          const Center(
            child: Column(
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Aucun étudiant inscrit',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: provider.examStudents.length,
            itemBuilder: (context, index) {
              final student = provider.examStudents[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: StudentCard(
                  student: student,
                  onTap: () {},
                  showValidationStatus: false,
                  showValidationActions: false,
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                    onPressed: () => _removeStudent(student),
                    tooltip: 'Retirer de l\'examen',
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final registrationProvider = context.watch<ExamRegistrationProvider>();
    
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Ajouter des étudiants',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadData(),
            tooltip: 'Actualiser',
          ),
        ],
      ),
      
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildExamHeader(),
            const SizedBox(height: 20),
            _buildSearchSection(registrationProvider),
            const SizedBox(height: 20),
            _buildSearchResults(registrationProvider),
            const SizedBox(height: 20),
            _buildRegisteredStudents(registrationProvider),
          ],
        ),
      ),
      
      floatingActionButton: _selectedStudents.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () {
                // Afficher un résumé des ajouts
                _showSummaryDialog();
              },
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.check_circle),
              label: Text('${_selectedStudents.length} ajoutés'),
            )
          : null,
    );
  }
  
  void _showSummaryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Résumé des ajouts'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, size: 48, color: Colors.green),
              const SizedBox(height: 16),
              Text(
                '${_selectedStudents.length} étudiant(s) ajouté(s)',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              if (_selectedStudents.isNotEmpty) ...[
                const Text('Liste des étudiants ajoutés :'),
                const SizedBox(height: 8),
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _selectedStudents.length,
                    itemBuilder: (context, index) {
                      final student = _selectedStudents[index];
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(student.firstName.substring(0, 1)),
                        ),
                        title: Text(student.fullName),
                        subtitle: Text(student.studentCode),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _selectedStudents.clear();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}