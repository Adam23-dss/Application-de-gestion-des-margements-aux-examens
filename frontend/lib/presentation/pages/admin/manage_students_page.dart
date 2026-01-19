import 'package:flutter/material.dart';
import 'package:frontend1/presentation/pages/admin/edit_student_page.dart';
import 'package:provider/provider.dart';
import 'package:frontend1/presentation/providers/student_provider.dart';
import 'package:frontend1/presentation/widgets/custom_app_bar.dart';
import 'package:frontend1/presentation/pages/admin/create_student_page.dart';
import 'package:frontend1/presentation/pages/admin/student_detail_page.dart';
import 'package:frontend1/core/themes/app_colors.dart';
import 'package:frontend1/data/models/student_model.dart';
import 'package:intl/intl.dart';

class ManageStudentsPage extends StatefulWidget {
  const ManageStudentsPage({super.key});

  @override
  State<ManageStudentsPage> createState() => _ManageStudentsPageState();
}

class _ManageStudentsPageState extends State<ManageStudentsPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final studentProvider = context.read<StudentProvider>();
      studentProvider.loadStudents();
      studentProvider.loadUfrStats();
    });

    _searchController.addListener(() {
      final studentProvider = context.read<StudentProvider>();
      studentProvider.searchQuery = _searchController.text;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showFilterDialog(BuildContext context) {
    final studentProvider = context.read<StudentProvider>();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            String? selectedUfr = studentProvider.selectedUfr;
            String? selectedDepartment = studentProvider.selectedDepartment;
            String? selectedPromotion = studentProvider.selectedPromotion;

            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    'Filtrer les étudiants',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),

                  // Filtre par UFR
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'UFR',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          _buildFilterChip(
                            'Toutes',
                            selectedUfr == null,
                            () => setState(() {
                              selectedUfr = null;
                              selectedDepartment = null;
                            }),
                          ),
                          ...studentProvider.uniqueUfrs.map((ufr) {
                            return _buildFilterChip(
                              ufr,
                              selectedUfr == ufr,
                              () => setState(() {
                                selectedUfr = ufr;
                                selectedDepartment = null;
                              }),
                            );
                          }).toList(),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Filtre par département (seulement si UFR sélectionnée)
                  if (selectedUfr != null) ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Département',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            _buildFilterChip(
                              'Tous',
                              selectedDepartment == null,
                              () => setState(() => selectedDepartment = null),
                            ),
                            ...studentProvider.uniqueDepartments.map((dept) {
                              return _buildFilterChip(
                                dept,
                                selectedDepartment == dept,
                                () => setState(() => selectedDepartment = dept),
                              );
                            }).toList(),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Filtre par promotion
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Promotion',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          _buildFilterChip(
                            'Toutes',
                            selectedPromotion == null,
                            () => setState(() => selectedPromotion = null),
                          ),
                          ...studentProvider.uniquePromotions.map((promo) {
                            return _buildFilterChip(
                              promo,
                              selectedPromotion == promo,
                              () => setState(() => selectedPromotion = promo),
                            );
                          }).toList(),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Boutons d'action
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Annuler'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            studentProvider.selectedUfr = selectedUfr;
                            studentProvider.selectedDepartment =
                                selectedDepartment;
                            studentProvider.selectedPromotion =
                                selectedPromotion;
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Appliquer'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterChip(String label, bool selected, VoidCallback onTap) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary.withOpacity(0.2),
      backgroundColor: Colors.grey[100],
      labelStyle: TextStyle(
        color: selected ? AppColors.primary : Colors.black,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Gestion des Étudiants',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
            tooltip: 'Filtrer',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final studentProvider = context.read<StudentProvider>();
              studentProvider.resetFilters();
            },
            tooltip: 'Réinitialiser',
          ),
        ],
      ),

      body: Consumer<StudentProvider>(
        builder: (context, studentProvider, child) {
          if (studentProvider.isLoading && studentProvider.students.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // Barre de recherche
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Rechercher un étudiant...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              studentProvider.searchQuery = '';
                            },
                          )
                        : null,
                  ),
                ),
              ),

              // Statistiques rapides
              if (studentProvider.basicStats.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  color: Colors.grey[50],
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        'Total',
                        (studentProvider.basicStats['total'] ?? 0).toString(),
                        Colors.blue,
                        Icons.people,
                      ),
                      _buildStatItem(
                        'Actifs',
                        (studentProvider.basicStats['active_count'] ?? 0)
                            .toString(),
                        Colors.green,
                        Icons.check_circle,
                      ),
                      _buildStatItem(
                        'UFRs',
                        (studentProvider.basicStats['ufr_count'] ?? 0)
                            .toString(),
                        Colors.purple,
                        Icons.school,
                      ),
                    ],
                  ),
                ),

              // Liste des étudiants
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => studentProvider.loadStudents(),
                  child: studentProvider.filteredStudents.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.school_outlined,
                                size: 64,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                studentProvider.searchQuery.isNotEmpty ||
                                        studentProvider.selectedUfr != null ||
                                        studentProvider.selectedDepartment !=
                                            null ||
                                        studentProvider.selectedPromotion !=
                                            null
                                    ? 'Aucun étudiant trouvé'
                                    : 'Aucun étudiant',
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                              if (studentProvider.searchQuery.isEmpty &&
                                  studentProvider.selectedUfr == null &&
                                  studentProvider.selectedDepartment == null &&
                                  studentProvider.selectedPromotion == null)
                                const SizedBox(height: 8),
                              if (studentProvider.searchQuery.isEmpty &&
                                  studentProvider.selectedUfr == null &&
                                  studentProvider.selectedDepartment == null &&
                                  studentProvider.selectedPromotion == null)
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const CreateStudentPage(),
                                      ),
                                    );
                                  },
                                  child: const Text('Ajouter un étudiant'),
                                ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: studentProvider.filteredStudents.length,
                          itemBuilder: (context, index) {
                            final student =
                                studentProvider.filteredStudents[index];
                            return _buildStudentCard(context, student);
                          },
                        ),
                ),
              ),
            ],
          );
        },
      ),

      // Bouton d'action
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateStudentPage()),
          );
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text('Ajouter'),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildStudentCard(BuildContext context, StudentModel student) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StudentDetailPage(studentId: student.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 24,
                backgroundColor: student.isActive
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                child: Icon(
                  Icons.school,
                  color: student.isActive ? Colors.green : Colors.red,
                ),
              ),

              const SizedBox(width: 16),

              // Informations
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            student.fullName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: student.isActive
                                ? Colors.green.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            student.isActive ? 'Actif' : 'Inactif',
                            style: TextStyle(
                              fontSize: 10,
                              color: student.isActive
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      student.studentCode,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.school, size: 12, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${student.ufr} - ${student.department}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (student.promotion != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              student.promotion!,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Menu d'actions
              PopupMenuButton<String>(
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'view',
                    child: Row(
                      children: [
                        Icon(Icons.visibility, size: 20),
                        SizedBox(width: 8),
                        Text('Voir détails'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 8),
                        Text('Modifier'),
                      ],
                    ),
                  ),
                  // PopupMenuItem(
                  //   value: student.isActive ? 'deactivate' : 'activate',
                  //   child: Row(
                  //     children: [
                  //       Icon(
                  //         student.isActive
                  //             ? Icons.person_off
                  //             : Icons.person_add,
                  //         size: 20,
                  //       ),
                  //       const SizedBox(width: 8),
                  //       Text(student.isActive ? 'Désactiver' : 'Activer'),
                  //     ],
                  //   ),
                  // ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Supprimer', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) async {
                  final studentProvider = context.read<StudentProvider>();

                  switch (value) {
                    case 'view':
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              StudentDetailPage(studentId: student.id),
                        ),
                      );
                      break;

                    case 'edit':
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              EditStudentPage(studentId: student.id),
                        ),
                      );
                      // TODO: Naviguer vers la page d'édition
                      break;


                    case 'deactivate':
                    case 'activate':
                      final bool activate = value == 'activate';
                      await _showConfirmationDialog(
                        context,
                        activate
                            ? 'Activer l\'étudiant'
                            : 'Désactiver l\'étudiant',
                        activate
                            ? 'Voulez-vous vraiment activer cet étudiant ?'
                            : 'Voulez-vous vraiment désactiver cet étudiant ?',
                        () async {
                          try {
                            await studentProvider.updateStudent(student.id, {
                              'is_active': activate,
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  activate
                                      ? 'Étudiant activé avec succès'
                                      : 'Étudiant désactivé avec succès',
                                ),
                                backgroundColor: Colors.green,
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
                        },
                      );
                      break;

                    case 'delete':
                      await _showConfirmationDialog(
                        context,
                        'Supprimer l\'étudiant',
                        'Voulez-vous vraiment supprimer cet étudiant ? Cette action est irréversible.',
                        () async {
                          try {
                            await studentProvider.deleteStudent(student.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Étudiant supprimé avec succès'),
                                backgroundColor: Colors.green,
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
                        },
                      );
                      break;
                  }
                },
                child: const Icon(Icons.more_vert),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showConfirmationDialog(
    BuildContext context,
    String title,
    String message,
    VoidCallback onConfirm,
  ) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: const Text('Confirmer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
