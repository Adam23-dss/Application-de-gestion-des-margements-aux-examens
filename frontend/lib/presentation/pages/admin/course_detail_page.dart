import 'package:flutter/material.dart';
import 'package:frontend1/presentation/pages/admin/edit_course_page.dart';
import 'package:provider/provider.dart';
import 'package:frontend1/core/themes/app_colors.dart';
import 'package:frontend1/presentation/widgets/custom_app_bar.dart';
import 'package:frontend1/presentation/providers/course_provider.dart';
import 'package:frontend1/data/models/course_model.dart';

class CourseDetailPage extends StatefulWidget {
  final int courseId;
  
  const CourseDetailPage({
    super.key,
    required this.courseId,
  });
  
  @override
  State<CourseDetailPage> createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends State<CourseDetailPage> {
  CourseModel? _course;
  bool _isLoading = true;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _loadCourse();
  }
  
  Future<void> _loadCourse() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final courseProvider = context.read<CourseProvider>();
      final course = await courseProvider.getCourseById(widget.courseId);
      
      setState(() {
        _course = course;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }
  
  Widget _buildInfoCard({
    required String title,
    required String value,
    IconData? icon,
    Color? iconColor,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            if (icon != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor?.withOpacity(0.1) ?? Colors.grey.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: iconColor ?? Colors.grey),
              ),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _deleteCourse() async {
    if (_course == null) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le cours'),
        content: Text(
          'Voulez-vous vraiment supprimer le cours "${_course!.name}" ? '
          'Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Supprimer',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        final courseProvider = context.read<CourseProvider>();
        await courseProvider.deleteCourse(_course!.id);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cours supprimé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.pop(context);
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
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Détails du cours',
        showBackButton: true,
        actions: _course != null
            ? [
                PopupMenuButton<String>(
                  itemBuilder: (context) => [
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
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        // TODO: Naviguer vers la page d'édition
                        Navigator.push(context, MaterialPageRoute(builder: (context)=> EditCoursePage(courseId: _course!.id)),);
                        break;
                      case 'delete':
                        _deleteCourse();
                        break;
                    }
                  },
                ),
              ]
            : null,
      ),
      
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
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
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadCourse,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : _course == null
                  ? const Center(child: Text('Cours non trouvé'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // En-tête
                          Center(
                            child: Column(
                              children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.menu_book,
                                    size: 40,
                                    color: Colors.blue,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _course!.name,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    _course!.code,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Informations du cours
                          const Text(
                            'Informations',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          _buildInfoCard(
                            title: 'Code cours',
                            value: _course!.code,
                            icon: Icons.code,
                            iconColor: Colors.blue,
                          ),
                          
                          if (_course!.ufr != null)
                            _buildInfoCard(
                              title: 'UFR',
                              value: _course!.ufr!,
                              icon: Icons.school,
                              iconColor: Colors.purple,
                            ),
                          
                          if (_course!.department != null)
                            _buildInfoCard(
                              title: 'Département',
                              value: _course!.department!,
                              icon: Icons.work_outline,
                              iconColor: Colors.deepOrange,
                            ),
                          
                          if (_course!.credits != null)
                            _buildInfoCard(
                              title: 'Crédits',
                              value: '${_course!.credits} crédits',
                              icon: Icons.credit_score,
                              iconColor: Colors.green,
                            ),
                          
                          if (_course!.description != null && _course!.description!.isNotEmpty)
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Description',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _course!.description!,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          
                          // Actions
                          const SizedBox(height: 32),
                          const Text(
                            'Actions',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  ListTile(
                                    leading: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.edit,
                                        color: Colors.orange,
                                      ),
                                    ),
                                    title: const Text('Modifier le cours'),
                                    subtitle: const Text('Modifier les informations du cours'),
                                    trailing: const Icon(Icons.chevron_right),
                                    onTap: () {
                                      // TODO: Naviguer vers la page d'édition
                                      Navigator.push(context, MaterialPageRoute(builder: (context)=> EditCoursePage(courseId: _course!.id)),);
                                    },
                                  ),
                                  
                                  const Divider(height: 1),
                                  
                                  ListTile(
                                    leading: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                    ),
                                    title: const Text(
                                      'Supprimer le cours',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                    subtitle: const Text(
                                      'Supprimer définitivement le cours',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                    trailing: const Icon(
                                      Icons.chevron_right,
                                      color: Colors.red,
                                    ),
                                    onTap: _deleteCourse,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
    );
  }
}