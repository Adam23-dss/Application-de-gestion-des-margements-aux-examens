import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend1/presentation/providers/exam_provider.dart';
import 'package:frontend1/presentation/providers/auth_provider.dart';
import 'package:frontend1/data/models/exam_model.dart';
import 'package:frontend1/presentation/widgets/custom_app_bar.dart';
import 'package:frontend1/core/themes/app_colors.dart';
import 'package:frontend1/presentation/pages/admin/create_exam_page.dart';
import 'package:frontend1/presentation/pages/admin/edit_exam_page.dart';

class ManageExamsPage extends StatefulWidget {
  const ManageExamsPage({super.key});

  @override
  State<ManageExamsPage> createState() => _ManageExamsPageState();
}

class _ManageExamsPageState extends State<ManageExamsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _filterStatus = 'all';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadExams();
  }

  Future<void> _loadExams() async {
    setState(() => _isLoading = true);
    final examProvider = context.read<ExamProvider>();
    await examProvider.loadExams();
    setState(() => _isLoading = false);
  }

  void _showDeleteDialog(ExamModel exam) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text(
          'Voulez-vous vraiment supprimer l\'examen "${exam.name}" ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteExam(exam.id);
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

  Future<void> _deleteExam(int examId) async {
    try {
      final examProvider = context.read<ExamProvider>();
      await examProvider.deleteExam(examId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Examen supprimé avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _toggleExamStatus(ExamModel exam) {
    final newStatus = exam.status == 'active' ? 'inactive' : 'active';
    // TODO: Appel API pour changer le statut
  }

  List<ExamModel> _getFilteredExams(List<ExamModel> exams) {
    var filtered = exams;

    // Filtre par statut
    if (_filterStatus != 'all') {
      filtered = filtered
          .where((exam) => exam.status == _filterStatus)
          .toList();
    }

    // Filtre par recherche
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((exam) {
        return exam.name.toLowerCase().contains(query) ||
            exam.description?.toLowerCase().contains(query) == true;
      }).toList();
    }

    // Tri par date
    filtered.sort((a, b) => b.examDate.compareTo(a.examDate));

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final examProvider = context.watch<ExamProvider>();
    final authProvider = context.watch<AuthProvider>();
    final exams = _getFilteredExams(examProvider.exams);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Gestion des Examens',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadExams,
            tooltip: 'Actualiser',
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateExamPage()),
          );
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nouvel examen'),
      ),

      body: Column(
        children: [
          // Filtres et recherche
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Barre de recherche
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Rechercher un examen...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),

                const SizedBox(height: 12),

                // Filtres par statut
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('Tous'),
                        selected: _filterStatus == 'all',
                        onSelected: (_) {
                          setState(() => _filterStatus = 'all');
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Programmé'),
                        selected: _filterStatus == 'scheduled',
                        onSelected: (_) {
                          setState(() => _filterStatus = 'scheduled');
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('En cours'),
                        selected: _filterStatus == 'in_progress',
                        onSelected: (_) {
                          setState(() => _filterStatus = 'in_progress');
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Terminé'),
                        selected: _filterStatus == 'completed',
                        onSelected: (_) {
                          setState(() => _filterStatus = 'completed');
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Annulé'),
                        selected: _filterStatus == 'cancelled',
                        onSelected: (_) {
                          setState(() => _filterStatus = 'cancelled');
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Statistiques rapides
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.grey[50],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem(
                  examProvider.exams.length.toString(),
                  'Total',
                  Icons.event,
                ),
                _buildStatItem(
                  examProvider.exams
                      .where((e) => e.status == 'scheduled')
                      .length
                      .toString(),
                  'Programmés',
                  Icons.schedule,
                ),
                _buildStatItem(
                  examProvider.exams
                      .where((e) => e.status == 'in_progress')
                      .length
                      .toString(),
                  'En cours',
                  Icons.play_arrow,
                ),
                _buildStatItem(
                  examProvider.exams
                      .where((e) => e.status == 'completed')
                      .length
                      .toString(),
                  'Terminés',
                  Icons.check_circle,
                ),
              ],
            ),
          ),

          // Liste des examens
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : exams.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _loadExams,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: exams.length,
                      itemBuilder: (context, index) {
                        final exam = exams[index];
                        return _buildExamCard(exam, examProvider);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 24, color: AppColors.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            'Aucun examen trouvé',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Créez votre premier examen en cliquant sur le bouton "+" ci-dessous',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  // Mettre à jour ManageExamsPage - utiliser les champs réels
  // Dans la méthode _buildExamCard :

  Widget _buildExamCard(ExamModel exam, ExamProvider examProvider) {
    Color getStatusColor() {
      switch (exam.status) {
        case 'scheduled':
          return Colors.blue;
        case 'in_progress':
          return Colors.green;
        case 'completed':
          return Colors.grey;
        case 'cancelled':
          return Colors.red;
        default:
          return Colors.grey;
      }
    }

    String getStatusLabel() {
      switch (exam.status) {
        case 'scheduled':
          return 'Programmé';
        case 'in_progress':
          return 'En cours';
        case 'completed':
          return 'Terminé';
        case 'cancelled':
          return 'Annulé';
        default:
          return exam.status;
      }
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditExamPage(examId: exam.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      exam.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: getStatusColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: getStatusColor().withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      getStatusLabel(),
                      style: TextStyle(
                        color: getStatusColor(),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Informations examen - UTILISER LES CHAMPS RÉELS
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    '${exam.formattedDate} • ${exam.startTime}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              // Utiliser roomName au lieu de location
              if (exam.roomName != null && exam.roomName!.isNotEmpty)
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      exam.roomName!,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),

              const SizedBox(height: 4),

              // Utiliser courseName si disponible
              if (exam.courseName != null && exam.courseName!.isNotEmpty)
                Row(
                  children: [
                    Icon(Icons.school, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      exam.courseName!,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),

              const SizedBox(height: 4),

              Row(
                children: [
                  Icon(Icons.people, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    '${exam.totalStudents} étudiants',
                    style: TextStyle(color: Colors.grey[600]),
                  ),

                  // Afficher le pourcentage de présence si disponible
                  if (exam.presentCount != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 16,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${exam.presentCount}/${exam.totalStudents} (${exam.attendancePercentage.toStringAsFixed(1)}%)',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Bouton modifier
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditExamPage(examId: exam.id),
                        ),
                      );
                    },
                    tooltip: 'Modifier',
                  ),

                  // Bouton dupliquer
                  IconButton(
                    icon: const Icon(Icons.content_copy, size: 20),
                    onPressed: () => _duplicateExam(exam),
                    tooltip: 'Dupliquer',
                  ),

                  // Bouton supprimer (seulement pour les examens non actifs)
                  if (exam.status != 'in_progress')
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20),
                      onPressed: () => _showDeleteDialog(exam),
                      tooltip: 'Supprimer',
                      color: Colors.red[400],
                    ),

                  // Bouton actions supplémentaires
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'attendance',
                        child: Row(
                          children: [
                            Icon(Icons.list_alt, size: 20),
                            SizedBox(width: 8),
                            Text('Voir les présences'),
                          ],
                        ),
                      ),
                      if (exam.status == 'scheduled' ||
                          exam.status == 'in_progress')
                        PopupMenuItem(
                          value: 'change_status',
                          child: Row(
                            children: [
                              Icon(Icons.switch_access_shortcut, size: 20),
                              SizedBox(width: 8),
                              Text('Changer statut'),
                            ],
                          ),
                        ),
                      if (exam.status == 'scheduled')
                        PopupMenuItem(
                          value: 'generate_qr',
                          child: Row(
                            children: [
                              Icon(Icons.qr_code, size: 20),
                              SizedBox(width: 8),
                              Text('Générer QR codes'),
                            ],
                          ),
                        ),
                    ],
                    onSelected: (value) {
                      switch (value) {
                        case 'attendance':
                          // TODO: Naviguer vers les présences
                          break;
                        case 'change_status':
                          _showChangeStatusDialog(exam);
                          break;
                        case 'generate_qr':
                          _generateQRCodes(exam);
                          break;
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Ajouter ces méthodes dans _ManageExamsPageState :
  Future<void> _duplicateExam(ExamModel exam) async {
    try {
      final examProvider = context.read<ExamProvider>();

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Duplication en cours...'),
            ],
          ),
        ),
      );

      await examProvider.duplicateExam(exam.id, {
        'name': '${exam.name} (Copie)',
        'exam_date': DateTime.now()
            .add(const Duration(days: 7))
            .toIso8601String(),
      });

      Navigator.pop(context); // Fermer le loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Examen dupliqué avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      Navigator.pop(context); // Fermer le loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showChangeStatusDialog(ExamModel exam) {
    final availableStatuses = [
      'scheduled',
      'in_progress',
      'completed',
      'cancelled',
    ];
    final currentStatus = exam.status;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Changer le statut'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: availableStatuses.map((status) {
              return RadioListTile<String>(
                title: Text(_getStatusLabel(status)),
                value: status,
                groupValue: currentStatus,
                onChanged: (value) {
                  Navigator.pop(context);
                  _updateExamStatus(exam.id, value!);
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateExamStatus(int examId, String status) async {
    try {
      final examProvider = context.read<ExamProvider>();
      await examProvider.updateExam(examId, {'status': status});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Statut changé en ${_getStatusLabel(status)}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'scheduled':
        return 'Programmé';
      case 'in_progress':
        return 'En cours';
      case 'completed':
        return 'Terminé';
      case 'cancelled':
        return 'Annulé';
      default:
        return status;
    }
  }

  Future<void> _generateQRCodes(ExamModel exam) async {
    try {
      final examProvider = context.read<ExamProvider>();
      final result = await examProvider.generateQRCodes(exam.id);

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('QR codes générés avec succès'),
            backgroundColor: Colors.green,
          ),
        );

        // TODO: Télécharger ou afficher les QR codes
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${result['message']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
