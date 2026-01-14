// lib/presentation/pages/admin/edit_exam_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:frontend1/presentation/providers/exam_provider.dart';
import 'package:frontend1/presentation/providers/auth_provider.dart';
import 'package:frontend1/data/models/exam_model.dart';
import 'package:frontend1/presentation/widgets/custom_app_bar.dart';
import 'package:frontend1/core/themes/app_colors.dart';

class EditExamPage extends StatefulWidget {
  final int examId;

  const EditExamPage({super.key, required this.examId});

  @override
  State<EditExamPage> createState() => _EditExamPageState();
}

class _EditExamPageState extends State<EditExamPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _roomController = TextEditingController();
  final TextEditingController _courseController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _maxStudentsController = TextEditingController();

  late DateTime _selectedDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;

  String _selectedType = 'exam';
  String _selectedStatus = 'scheduled';
  bool _isLoading = false;
  bool _isSaving = false;
  ExamModel? _exam;

  @override
  void initState() {
    super.initState();
    _loadExamDetails();

    // Initialiser avec des valeurs par défaut
    _selectedDate = DateTime.now();
    _startTime = const TimeOfDay(hour: 9, minute: 0);
    _endTime = const TimeOfDay(hour: 12, minute: 0);
  }

  Future<void> _loadExamDetails() async {
    setState(() => _isLoading = true);

    try {
      final examProvider = context.read<ExamProvider>();
      _exam = await examProvider.getExamDetails(widget.examId);

      if (_exam != null) {
        // Mettre à jour les contrôleurs avec les données de l'examen
        _nameController.text = _exam!.name;
        _descriptionController.text = _exam!.description ?? '';
        _roomController.text = _exam!.roomName ?? '';
        _courseController.text = _exam!.courseName ?? '';

        if (_exam!.examDate != null) {
          _selectedDate = _exam!.examDate;
        }

        // Parser l'heure de début
        if (_exam!.startTime.isNotEmpty) {
          final startParts = _exam!.startTime.split(':');
          if (startParts.length >= 2) {
            _startTime = TimeOfDay(
              hour: int.parse(startParts[0]),
              minute: int.parse(startParts[1]),
            );
          }
        }

        // Parser l'heure de fin
        if (_exam!.endTime.isNotEmpty) {
          final endParts = _exam!.endTime.split(':');
          if (endParts.length >= 2) {
            _endTime = TimeOfDay(
              hour: int.parse(endParts[0]),
              minute: int.parse(endParts[1]),
            );
          }
        }

        _selectedStatus = _exam!.status;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur chargement: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
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

  Future<void> _updateExam() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final examProvider = context.read<ExamProvider>();
      final authProvider = context.read<AuthProvider>();

      final examData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim() ??  '',
        'exam_date': DateFormat('yyyy-MM-dd').format(_selectedDate),
        'start_time':
            '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}',
        'end_time':
            '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}',
        // 'room_name': _roomController.text.trim(),
        // 'course_name': _courseController.text.trim(),
        // 'exam_type': _selectedType,
        'status': _selectedStatus,
        // AJOUTER ces champs si tu as les IDs :
        //'room_id': _exam!.roomId as String, // Si tu as un sélecteur de salles
        //'course_id': _exam!.courseId as String, // Si tu as un sélecteur de cours
      };

      // Ajouter duration_minutes si fourni
      if (_durationController.text.isNotEmpty) {
        examData['duration_minutes'] =
            int.tryParse(_durationController.text) as String;
      }

      // Ajouter max_students si fourni
      if (_maxStudentsController.text.isNotEmpty) {
        examData['max_students'] =
            int.tryParse(_maxStudentsController.text) as String;
      }

      await examProvider.updateExam(widget.examId, examData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Examen mis à jour avec succès !'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context); // Retour à la liste
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text(
          'Voulez-vous vraiment supprimer cet examen ? Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteExam();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteExam() async {
    try {
      final examProvider = context.read<ExamProvider>();
      await examProvider.deleteExam(widget.examId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Examen supprimé avec succès'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context); // Retour à la liste
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _roomController.dispose();
    _courseController.dispose();
    _durationController.dispose();
    _maxStudentsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: CustomAppBar(title: 'Modifier l\'examen', showBackButton: true),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Modifier l\'examen',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _showDeleteDialog,
            tooltip: 'Supprimer',
            color: Colors.red,
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isSaving ? null : _updateExam,
            tooltip: 'Enregistrer',
          ),
        ],
      ),

      body: _exam == null
          ? const Center(child: Text('Examen non trouvé'))
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // En-tête avec ID
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info, size: 20, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                            'ID: ${_exam!.id}',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _exam!.statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _exam!.statusColor.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              _exam!.statusLabel,
                              style: TextStyle(
                                color: _exam!.statusColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Informations de base
                    _buildSectionTitle('Informations de base'),

                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nom de l\'examen *',
                        hintText: 'Ex: Mathématiques - Session 1',
                        border: OutlineInputBorder(),
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
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    DateFormat(
                                      'dd/MM/yyyy',
                                    ).format(_selectedDate),
                                  ),
                                  const Icon(Icons.calendar_today),
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
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(_startTime.format(context)),
                                  const Icon(Icons.access_time),
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
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(_endTime.format(context)),
                                  const Icon(Icons.access_time),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Statut de l'examen
                    _buildSectionTitle('Statut de l\'examen'),

                    DropdownButtonFormField<String>(
                      value: _selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Statut',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'scheduled',
                          child: Row(
                            children: [
                              Icon(Icons.schedule, color: Colors.blue),
                              SizedBox(width: 8),
                              Text('Programmé'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'in_progress',
                          child: Row(
                            children: [
                              Icon(Icons.play_arrow, color: Colors.orange),
                              SizedBox(width: 8),
                              Text('En cours'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'completed',
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green),
                              SizedBox(width: 8),
                              Text('Terminé'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'cancelled',
                          child: Row(
                            children: [
                              Icon(Icons.cancel, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Annulé'),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedStatus = value ?? 'scheduled';
                        });
                      },
                    ),

                    const SizedBox(height: 24),

                    // Lieu et cours
                    _buildSectionTitle('Lieu et cours'),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _roomController,
                            decoration: const InputDecoration(
                              labelText: 'Salle',
                              hintText: 'Ex: Salle A201',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),

                        const SizedBox(width: 16),

                        Expanded(
                          child: TextFormField(
                            controller: _courseController,
                            decoration: const InputDecoration(
                              labelText: 'Cours/Matière',
                              hintText: 'Ex: Mathématiques',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Capacité et durée
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _maxStudentsController,
                            decoration: const InputDecoration(
                              labelText: 'Nombre max d\'étudiants',
                              hintText: 'Ex: 50',
                              border: OutlineInputBorder(),
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
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Statistiques (en lecture seule)
                    if (_exam!.totalStudents > 0)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('Statistiques'),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Total étudiants:'),
                                    Text(
                                      '${_exam!.totalStudents}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (_exam!.presentCount != null)
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Présents:'),
                                      Text(
                                        '${_exam!.presentCount}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                const SizedBox(height: 8),
                                if (_exam!.presentCount != null)
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Taux de présence:'),
                                      Text(
                                        '${_exam!.attendancePercentage.toStringAsFixed(1)}%',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),

                    // Boutons d'action
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _updateExam,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: _isSaving
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
                                : const Text(
                                    'Mettre à jour',
                                    style: TextStyle(fontSize: 16),
                                  ),
                          ),
                        ),

                        const SizedBox(width: 16),

                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Annuler'),
                          ),
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
}
