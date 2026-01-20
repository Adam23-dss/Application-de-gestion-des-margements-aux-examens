import 'package:flutter/material.dart';
import 'package:frontend1/presentation/pages/admin/edit_course_page.dart';
import 'package:provider/provider.dart';
import 'package:frontend1/presentation/widgets/custom_app_bar.dart';
import 'package:frontend1/presentation/providers/course_provider.dart';
import 'package:frontend1/presentation/pages/admin/create_course_page.dart';
import 'package:frontend1/presentation/pages/admin/course_detail_page.dart';
import 'package:frontend1/core/themes/app_colors.dart';
import 'package:frontend1/data/models/course_model.dart';

class ManageCoursesPage extends StatefulWidget {
  const ManageCoursesPage({super.key});

  @override
  State<ManageCoursesPage> createState() => _ManageCoursesPageState();
}

class _ManageCoursesPageState extends State<ManageCoursesPage> {
  final TextEditingController _searchController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final courseProvider = context.read<CourseProvider>();
      courseProvider.loadCourses();
      courseProvider.loadFilterOptions();
      courseProvider.loadUfrStats();
    });
    
    _searchController.addListener(() {
      final courseProvider = context.read<CourseProvider>();
      if (_searchController.text.isEmpty) {
        courseProvider.loadCourses();
      } else {
        courseProvider.searchCourses(_searchController.text);
      }
    });
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  void _showFilterDialog(BuildContext context) {
    final courseProvider = context.read<CourseProvider>();
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            String? selectedUfr = courseProvider.selectedUfr;
            String? selectedDepartment = courseProvider.selectedDepartment;
            
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
                    'Filtrer les cours',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
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
                      courseProvider.isLoadingFilters
                          ? const Center(child: CircularProgressIndicator())
                          : Wrap(
                              spacing: 8,
                              children: [
                                _buildFilterChip(
                                  'Toutes',
                                  selectedUfr == null,
                                  () => setState(() => selectedUfr = null),
                                ),
                                ...courseProvider.ufrOptions.map((ufr) {
                                  return _buildFilterChip(
                                    ufr,
                                    selectedUfr == ufr,
                                    () => setState(() => selectedUfr = ufr),
                                  );
                                }).toList(),
                              ],
                            ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Filtre par département
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
                      courseProvider.isLoadingFilters
                          ? const Center(child: CircularProgressIndicator())
                          : Wrap(
                              spacing: 8,
                              children: [
                                _buildFilterChip(
                                  'Tous',
                                  selectedDepartment == null,
                                  () => setState(() => selectedDepartment = null),
                                ),
                                ...courseProvider.departmentOptions.map((dept) {
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
                            courseProvider.setUfrFilter(selectedUfr);
                            courseProvider.setDepartmentFilter(selectedDepartment);
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
  
  Widget _buildCourseCard(BuildContext context, CourseModel course) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CourseDetailPage(courseId: course.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icône
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.menu_book,
                  color: Colors.blue,
                  size: 24,
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
                            course.name,
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
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            course.code,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (course.ufr != null && course.ufr!.isNotEmpty)
                      Row(
                        children: [
                          Icon(
                            Icons.school,
                            size: 12,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${course.ufr}${course.department != null ? ' - ${course.department}' : ''}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    if (course.credits != null)
                      Row(
                        children: [
                          Icon(
                            Icons.credit_score,
                            size: 12,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${course.credits} crédits',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
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
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text(
                          'Supprimer',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) async {
                  final courseProvider = context.read<CourseProvider>();
                  
                  switch (value) {
                    case 'view':
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CourseDetailPage(courseId: course.id),
                        ),
                      );
                      break;
                    
                    case 'edit':
                      // TODO: Naviguer vers la page d'édition
                      Navigator.push(context, MaterialPageRoute(builder: (context) => EditCoursePage(courseId: course.id)));
                      break;
                    
                    case 'delete':
                      await _showConfirmationDialog(
                        context,
                        'Supprimer le cours',
                        'Voulez-vous vraiment supprimer le cours "${course.name}" ?',
                        () async {
                          try {
                            await courseProvider.deleteCourse(course.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Cours supprimé avec succès'),
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
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Gestion des Cours',
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
              final courseProvider = context.read<CourseProvider>();
              courseProvider.clearFilters();
            },
            tooltip: 'Réinitialiser',
          ),
        ],
      ),
      
      body: Consumer<CourseProvider>(
        builder: (context, courseProvider, child) {
          if (courseProvider.isLoading && courseProvider.courses.isEmpty) {
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
                    hintText: 'Rechercher un cours...',
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
                              courseProvider.loadCourses();
                            },
                          )
                        : null,
                  ),
                ),
              ),
              
              // Statistiques rapides
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.grey[50],
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      'Total',
                      courseProvider.courses.length.toString(),
                      Colors.blue,
                      Icons.menu_book,
                    ),
                    _buildStatItem(
                      'UFRs',
                      courseProvider.ufrOptions.length.toString(),
                      Colors.purple,
                      Icons.school,
                    ),
                    _buildStatItem(
                      'Filtres',
                      courseProvider.selectedUfr != null || 
                      courseProvider.selectedDepartment != null
                          ? 'Actifs'
                          : 'Inactifs',
                      courseProvider.selectedUfr != null || 
                      courseProvider.selectedDepartment != null
                          ? Colors.orange
                          : Colors.grey,
                      courseProvider.selectedUfr != null || 
                      courseProvider.selectedDepartment != null
                          ? Icons.filter_alt
                          : Icons.filter_alt_off,
                    ),
                  ],
                ),
              ),
              
              // Liste des cours
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => courseProvider.loadCourses(),
                  child: courseProvider.courses.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.menu_book_outlined,
                                size: 64,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                courseProvider.isSearching
                                    ? 'Aucun cours trouvé'
                                    : courseProvider.selectedUfr != null ||
                                      courseProvider.selectedDepartment != null
                                        ? 'Aucun cours avec ces filtres'
                                        : 'Aucun cours',
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                              if (!courseProvider.isSearching &&
                                  courseProvider.selectedUfr == null &&
                                  courseProvider.selectedDepartment == null)
                                const SizedBox(height: 8),
                              if (!courseProvider.isSearching &&
                                  courseProvider.selectedUfr == null &&
                                  courseProvider.selectedDepartment == null)
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const CreateCoursePage(),
                                      ),
                                    );
                                  },
                                  child: const Text('Ajouter un cours'),
                                ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: courseProvider.courses.length +
                            (courseProvider.hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == courseProvider.courses.length) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: courseProvider.isLoadingMore
                                      ? const CircularProgressIndicator()
                                      : ElevatedButton(
                                          onPressed: courseProvider.loadMoreCourses,
                                          child: const Text('Charger plus'),
                                        ),
                                ),
                              );
                            }
                            
                            final course = courseProvider.courses[index];
                            return _buildCourseCard(context, course);
                          },
                        ),
                ),
              ),
            ],
          );
        },
      ),
      
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateCoursePage(),
            ),
          );
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
    );
  }
  
  Widget _buildStatItem(String label, String value, Color color, IconData icon) {
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
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
      ],
    );
  }
}