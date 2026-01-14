import 'package:flutter/material.dart';
import 'package:frontend1/presentation/providers/auth_provider.dart';
import 'package:frontend1/presentation/providers/exam_provider.dart';
import 'package:frontend1/presentation/widgets/custom_app_bar.dart';
import 'package:frontend1/core/themes/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class CreateExamPage extends StatefulWidget {
  const CreateExamPage({super.key});

  @override
  State<CreateExamPage> createState() => _CreateExamPageState();
}

class _CreateExamPageState extends State<CreateExamPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _maxStudentsController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 12, minute: 0);

  String _selectedType = 'exam';
  int? _selectedRoomId;
  int? _selectedCourseId;
  List<int> _selectedSupervisorIds = [];
  
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    // Charger toutes les données au démarrage
    _loadResources();
  }

  Future<void> _loadResources() async {
    try {
      final examProvider = context.read<ExamProvider>();
      await examProvider.loadAllResources();
    } catch (e) {
      print('❌ Error loading resources: $e');
      _showErrorSnackbar('Erreur chargement données');
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectStartTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );

    if (picked != null) {
      setState(() => _startTime = picked);
    }
  }

  Future<void> _selectEndTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );

    if (picked != null) {
      setState(() => _endTime = picked);
    }
  }

  Future<void> _createExam() async {
    if (!_formKey.currentState!.validate()) return;

    // Validation des champs obligatoires
    if (_selectedRoomId == null) {
      _showErrorSnackbar('Veuillez sélectionner une salle');
      return;
    }

    if (_selectedCourseId == null) {
      _showErrorSnackbar('Veuillez sélectionner un cours');
      return;
    }

    setState(() => _isCreating = true);

    try {
      final examProvider = context.read<ExamProvider>();
      final authProvider = context.read<AuthProvider>();
      
      // Préparer les données pour l'API
      final examData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'exam_date': DateFormat('yyyy-MM-dd').format(_selectedDate),
        'start_time': '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}',
        'end_time': '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}',
        'room_id': _selectedRoomId,
        'course_id': _selectedCourseId,
        'exam_type': _selectedType,
        'status': 'scheduled',
        'supervisor_id': authProvider.user?.id, // Superviseur principal
      };

      // Ajouter les superviseurs supplémentaires si sélectionnés
      if (_selectedSupervisorIds.isNotEmpty) {
        examData['additional_supervisor_ids'] = _selectedSupervisorIds;
      }

      // Ajouter les champs optionnels
      if (_durationController.text.isNotEmpty) {
        examData['duration_minutes'] = int.tryParse(_durationController.text);
      }
      
      if (_maxStudentsController.text.isNotEmpty) {
        examData['max_students'] = int.tryParse(_maxStudentsController.text);
      }

      print('📤 Création examen avec données: $examData');
      
      await examProvider.createExam(examData);

      _showSuccessSnackbar('Examen créé avec succès !');
      
      // Rafraîchir la liste des examens
      examProvider.loadExams();
      
      // Retour à la liste
      if (mounted) {
        Navigator.pop(context);
      }
      
    } catch (e) {
      print('❌ Error creating exam: $e');
      _showErrorSnackbar('Erreur: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    _maxStudentsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Nouvel Examen',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isCreating ? null : _createExam,
            tooltip: 'Enregistrer',
          ),
        ],
      ),

      body: Consumer<ExamProvider>(
        builder: (context, examProvider, child) {
          final isLoading = examProvider.isLoading;
          final rooms = examProvider.rooms;
          final courses = examProvider.courses;
          final supervisors = examProvider.supervisors;

          if (isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Chargement des données...'),
                ],
              ),
            );
          }

          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Informations de base
                  _buildSectionTitle('Informations de base'),

                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nom de l\'examen *',
                      hintText: 'Ex: Mathématiques - Session 1',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.event),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez saisir un nom';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Description détaillée de l\'examen...',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 3,
                    keyboardType: TextInputType.multiline,
                  ),

                  const SizedBox(height: 24),

                  // Date et heure
                  _buildSectionTitle('Date et heure'),

                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectDate(context),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Date de l\'examen *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.calendar_today),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  DateFormat('dd/MM/yyyy').format(_selectedDate),
                                ),
                                const Icon(Icons.arrow_drop_down),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      Expanded(
                        child: InkWell(
                          onTap: () => _selectStartTime(context),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Heure de début *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.access_time),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_startTime.format(context)),
                                const Icon(Icons.arrow_drop_down),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      Expanded(
                        child: InkWell(
                          onTap: () => _selectEndTime(context),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Heure de fin',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.access_time),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_endTime.format(context)),
                                const Icon(Icons.arrow_drop_down),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Sélection de la salle
                  _buildSectionTitle('Salle *'),

                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _selectedRoomId,
                        hint: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('Sélectionner une salle'),
                        ),
                        isExpanded: true,
                        icon: const Padding(
                          padding: EdgeInsets.only(right: 12),
                          child: Icon(Icons.arrow_drop_down),
                        ),
                        items: rooms.map((room) {
                          return DropdownMenuItem<int>(
                            value: room['id'] as int,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    room['name'] as String,
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                  Text(
                                    'Capacité: ${room['capacity']} places',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedRoomId = value);
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Sélection du cours
                  _buildSectionTitle('Cours *'),

                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _selectedCourseId,
                        hint: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('Sélectionner un cours'),
                        ),
                        isExpanded: true,
                        icon: const Padding(
                          padding: EdgeInsets.only(right: 12),
                          child: Icon(Icons.arrow_drop_down),
                        ),
                        items: courses.map((course) {
                          return DropdownMenuItem<int>(
                            value: course['id'] as int,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    course['name'] as String,
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                  Text(
                                    'Code: ${course['code'] ?? 'N/A'}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedCourseId = value);
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Type d'examen
                  _buildSectionTitle('Type d\'examen'),

                  Wrap(
                    spacing: 12,
                    children: [
                      _buildExamTypeOption('exam', 'Examen', Icons.assignment),
                      _buildExamTypeOption('test', 'Test', Icons.quiz),
                      _buildExamTypeOption('project', 'Projet', Icons.work),
                      _buildExamTypeOption('oral', 'Oral', Icons.mic),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Superviseurs supplémentaires
                  _buildSectionTitle('Superviseurs supplémentaires'),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (supervisors.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(8),
                          child: Text(
                            'Aucun superviseur disponible',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      else
                        ...supervisors.map((supervisor) {
                          final isSelected = _selectedSupervisorIds.contains(
                            supervisor['id'] as int,
                          );
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: CheckboxListTile(
                              title: Text(
                                supervisor['full_name']?.toString() ?? 
                                supervisor['name']?.toString() ?? 
                                'Superviseur',
                              ),
                              subtitle: Text(
                                supervisor['email']?.toString() ?? 
                                supervisor['username']?.toString() ?? 
                                'Email non disponible',
                              ),
                              value: isSelected,
                              onChanged: (selected) {
                                setState(() {
                                  if (selected == true) {
                                    _selectedSupervisorIds.add(
                                      supervisor['id'] as int,
                                    );
                                  } else {
                                    _selectedSupervisorIds.remove(
                                      supervisor['id'] as int,
                                    );
                                  }
                                });
                              },
                              secondary: const Icon(Icons.person),
                            ),
                          );
                        }).toList(),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Capacité et durée
                  _buildSectionTitle('Paramètres supplémentaires'),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _maxStudentsController,
                          decoration: const InputDecoration(
                            labelText: 'Nombre max d\'étudiants',
                            hintText: 'Ex: 50',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.people),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      Expanded(
                        child: TextFormField(
                          controller: _durationController,
                          decoration: const InputDecoration(
                            labelText: 'Durée (minutes)',
                            hintText: 'Ex: 180',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.timer),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Informations de validation
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      final currentUser = authProvider.user;
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[100]!),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info, color: Colors.blue, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Informations',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Superviseur principal: ${currentUser?.fullName ?? currentUser?.email ?? 'Vous'}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  if (_selectedSupervisorIds.isNotEmpty)
                                    Text(
                                      '${_selectedSupervisorIds.length} superviseur(s) supplémentaire(s)',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  // Boutons d'action
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isCreating ? null : _createExam,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isCreating
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_circle, size: 24),
                                    SizedBox(width: 12),
                                    Text(
                                      'Créer l\'examen',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(color: Colors.grey[300]!),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.cancel, size: 24),
                              SizedBox(width: 12),
                              Text(
                                'Annuler',
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildExamTypeOption(String value, String label, IconData icon) {
    final isSelected = _selectedType == value;
    
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedType = value),
      selectedColor: AppColors.primary.withOpacity(0.2),
      backgroundColor: Colors.grey[100],
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : Colors.black,
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