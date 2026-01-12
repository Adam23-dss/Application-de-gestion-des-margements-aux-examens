import 'package:flutter/material.dart';
import 'package:frontend1/data/models/course_model.dart';
import 'package:provider/provider.dart';
import 'package:frontend1/presentation/providers/auth_provider.dart';
import 'package:frontend1/presentation/providers/course_provider.dart';
import 'package:frontend1/presentation/widgets/custom_app_bar.dart';
import 'package:frontend1/presentation/widgets/course_card.dart';
import 'package:frontend1/core/themes/app_colors.dart';

class CoursesPage extends StatefulWidget {
  const CoursesPage({super.key});

  @override
  State<CoursesPage> createState() => _CoursesPageState();
}

class _CoursesPageState extends State<CoursesPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CourseProvider>().loadCourses();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final courseProvider = context.watch<CourseProvider>();

    // Vérifier que l'utilisateur est admin
    if (authProvider.user?.isAdmin != true) {
      return const Scaffold(
        body: Center(
          child: Text('Accès non autorisé'),
        ),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Gestion des Cours',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => courseProvider.loadCourses(),
            tooltip: 'Actualiser',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddCourseDialog,
            tooltip: 'Ajouter un cours',
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher un cours...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _isSearching || _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          courseProvider.searchCourses('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _isSearching = value.isNotEmpty;
                });
                if (value.length >= 2) {
                  courseProvider.searchCourses(value);
                } else if (value.isEmpty) {
                  courseProvider.loadCourses();
                }
              },
            ),
          ),

          // Filtres
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: courseProvider.selectedUfr,
                    decoration: InputDecoration(
                      labelText: 'UFR',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Toutes les UFR'),
                      ),
                      ...courseProvider.ufrOptions.map((ufr) {
                        return DropdownMenuItem(
                          value: ufr,
                          child: Text(ufr),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) {
                      courseProvider.setUfrFilter(value);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: courseProvider.selectedDepartment,
                    decoration: InputDecoration(
                      labelText: 'Département',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Tous les départements'),
                      ),
                      ...courseProvider.departmentOptions.map((dept) {
                        return DropdownMenuItem(
                          value: dept,
                          child: Text(dept),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) {
                      courseProvider.setDepartmentFilter(value);
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Liste des cours
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => courseProvider.loadCourses(),
              child: _buildCourseList(courseProvider),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseList(CourseProvider courseProvider) {
    if (courseProvider.isLoading && courseProvider.courses.isEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 10,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
          );
        },
      );
    }

    if (courseProvider.courses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.menu_book,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              courseProvider.isSearching
                  ? 'Aucun cours trouvé'
                  : 'Aucun cours disponible',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            if (!courseProvider.isSearching) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: _showAddCourseDialog,
                child: const Text('Ajouter le premier cours'),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: courseProvider.courses.length + 1,
      itemBuilder: (context, index) {
        if (index == courseProvider.courses.length) {
          if (courseProvider.hasMore && !courseProvider.isLoadingMore) {
            courseProvider.loadMoreCourses();
          }
          if (courseProvider.isLoadingMore) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }
          if (courseProvider.hasMore) {
            return Container();
          }
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Fin de la liste',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        final course = courseProvider.courses[index];
        return CourseCard(
          course: course,
          onTap: () => _showCourseDetails(course),
          onEdit: () => _showEditCourseDialog(course),
          onDelete: () => _showDeleteDialog(course),
        );
      },
    );
  }

  void _showAddCourseDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddCourseDialog(),
    );
  }

  void _showEditCourseDialog(CourseModel course) {
    showDialog(
      context: context,
      builder: (context) => EditCourseDialog(course: course),
    );
  }

  void _showCourseDetails(CourseModel course) {
    showDialog(
      context: context,
      builder: (context) => CourseDetailsDialog(course: course),
    );
  }

  void _showDeleteDialog(CourseModel course) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le cours'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer le cours "${course.code} - ${course.name}" ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<CourseProvider>().deleteCourse(course.id);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

class AddCourseDialog extends StatefulWidget {
  const AddCourseDialog({super.key});

  @override
  State<AddCourseDialog> createState() => _AddCourseDialogState();
}

class _AddCourseDialogState extends State<AddCourseDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ufrController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _creditsController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _ufrController.dispose();
    _departmentController.dispose();
    _creditsController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter un cours'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Code cours *',
                  hintText: 'INF101',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Le code est requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom du cours *',
                  hintText: 'Introduction à la programmation',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Le nom est requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ufrController,
                decoration: const InputDecoration(
                  labelText: 'UFR *',
                  hintText: 'Sciences',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'L\'UFR est requise';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _departmentController,
                decoration: const InputDecoration(
                  labelText: 'Département *',
                  hintText: 'Informatique',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Le département est requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _creditsController,
                decoration: const InputDecoration(
                  labelText: 'Crédits ECTS',
                  hintText: '6',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Description du cours...',
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitForm,
          child: _isSubmitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Ajouter'),
        ),
      ],
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);

      try {
        final courseProvider = context.read<CourseProvider>();
        await courseProvider.createCourse(
          code: _codeController.text.trim(),
          name: _nameController.text.trim(),
          ufr: _ufrController.text.trim(),
          department: _departmentController.text.trim(),
          credits: _creditsController.text.isNotEmpty
              ? int.tryParse(_creditsController.text)
              : null,
          description: _descriptionController.text.trim(),
        );

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cours ajouté avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isSubmitting = false);
        }
      }
    }
  }
}

class EditCourseDialog extends StatefulWidget {
  final CourseModel course;

  const EditCourseDialog({super.key, required this.course});

  @override
  State<EditCourseDialog> createState() => _EditCourseDialogState();
}

class _EditCourseDialogState extends State<EditCourseDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _ufrController;
  late TextEditingController _departmentController;
  late TextEditingController _creditsController;
  late TextEditingController _descriptionController;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.course.name);
    _ufrController = TextEditingController(text: widget.course.ufr);
    _departmentController = TextEditingController(text: widget.course.department);
    _creditsController = TextEditingController(
      text: widget.course.credits?.toString() ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.course.description ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ufrController.dispose();
    _departmentController.dispose();
    _creditsController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Modifier le cours'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom du cours *',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Le nom est requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ufrController,
                decoration: const InputDecoration(
                  labelText: 'UFR *',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'L\'UFR est requise';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _departmentController,
                decoration: const InputDecoration(
                  labelText: 'Département *',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Le département est requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _creditsController,
                decoration: const InputDecoration(
                  labelText: 'Crédits ECTS',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitForm,
          child: _isSubmitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Mettre à jour'),
        ),
      ],
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);

      try {
        final courseProvider = context.read<CourseProvider>();
        await courseProvider.updateCourse(
          courseId: widget.course.id,
          name: _nameController.text.trim(),
          ufr: _ufrController.text.trim(),
          department: _departmentController.text.trim(),
          credits: _creditsController.text.isNotEmpty
              ? int.tryParse(_creditsController.text)
              : null,
          description: _descriptionController.text.trim(),
        );

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cours mis à jour avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isSubmitting = false);
        }
      }
    }
  }
}

class CourseDetailsDialog extends StatelessWidget {
  final CourseModel course;

  const CourseDetailsDialog({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Détails du cours: ${course.code}'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailRow('Code:', course.code),
            _buildDetailRow('Nom:', course.name),
            if (course.ufr != null) _buildDetailRow('UFR:', course.ufr!),
            if (course.department != null) 
              _buildDetailRow('Département:', course.department!),
            if (course.credits != null)
              _buildDetailRow('Crédits ECTS:', course.credits!.toString()),
            if (course.description != null && course.description!.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Description:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                course.description!,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fermer'),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}