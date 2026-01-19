import 'package:flutter/material.dart';
import 'package:frontend1/presentation/pages/admin/edit_student_page.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:frontend1/core/themes/app_colors.dart';
import 'package:frontend1/presentation/widgets/custom_app_bar.dart';
import 'package:frontend1/presentation/providers/student_provider.dart';
import 'package:frontend1/data/models/student_model.dart';

class StudentDetailPage extends StatefulWidget {
  final int studentId;
  
  const StudentDetailPage({
    super.key,
    required this.studentId,
  });
  
  @override
  State<StudentDetailPage> createState() => _StudentDetailPageState();
}

class _StudentDetailPageState extends State<StudentDetailPage> {
  StudentModel? _student;
  bool _isLoading = true;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _loadStudent();
  }
  
  Future<void> _loadStudent() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final studentProvider = context.read<StudentProvider>();
      final student = await studentProvider.getStudentById(widget.studentId);
      
      setState(() {
        _student = student;
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
  
  Widget _buildStatusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.check_circle : Icons.cancel,
            size: 12,
            color: isActive ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 4),
          Text(
            isActive ? 'Actif' : 'Inactif',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isActive ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }
  
  // Future<void> _toggleActiveStatus() async {
  //   if (_student == null) return;
    
  //   final studentProvider = context.read<StudentProvider>();
  //   final newStatus = !_student!.isActive;
    
  //   try {
  //     final updatedStudent = await studentProvider.updateStudent(
  //       _student!.id,
  //       {'is_active': newStatus},
  //     );
      
  //     setState(() {
  //       _student = updatedStudent;
  //     });
      
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text(
  //           newStatus
  //               ? 'Étudiant activé avec succès'
  //               : 'Étudiant désactivé avec succès',
  //         ),
  //         backgroundColor: Colors.green,
  //       ),
  //     );
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('Erreur: $e'),
  //         backgroundColor: Colors.red,
  //       ),
  //     );
  //   }
  // }

  
  Future<void> _deleteStudent() async {
    if (_student == null) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'étudiant'),
        content: const Text(
          'Voulez-vous vraiment supprimer cet étudiant ? '
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
        final studentProvider = context.read<StudentProvider>();
        await studentProvider.deleteStudent(_student!.id);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Étudiant supprimé avec succès'),
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
        title: 'Détails de l\'étudiant',
        showBackButton: true,
        actions: _student != null
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
                    PopupMenuItem(
                      value: _student!.isActive ? 'deactivate' : 'activate',
                      child: Row(
                        children: [
                          Icon(
                            _student!.isActive ? Icons.person_off : Icons.person_add,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(_student!.isActive ? 'Désactiver' : 'Activer'),
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
                        break;
                      // case 'deactivate':
                      // case 'activate':
                      //   _toggleActiveStatus();
                      //   break;
                      case 'delete':
                        _deleteStudent();
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
                        onPressed: _loadStudent,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : _student == null
                  ? const Center(child: Text('Étudiant non trouvé'))
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
                                    color: _student!.isActive
                                        ? Colors.blue.withOpacity(0.1)
                                        : Colors.grey.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.school,
                                    size: 40,
                                    color: _student!.isActive ? Colors.blue : Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _student!.fullName,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildStatusBadge(_student!.isActive),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Informations de base
                          const Text(
                            'Informations de base',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          _buildInfoCard(
                            title: 'Code étudiant',
                            value: _student!.studentCode,
                            icon: Icons.badge,
                            iconColor: Colors.blue,
                          ),
                          
                          _buildInfoCard(
                            title: 'Nom complet',
                            value: _student!.fullName,
                            icon: Icons.person,
                            iconColor: Colors.green,
                          ),
                          
                          if (_student!.email != null && _student!.email!.isNotEmpty)
                            _buildInfoCard(
                              title: 'Email',
                              value: _student!.email!,
                              icon: Icons.email,
                              iconColor: Colors.orange,
                            ),
                          
                          // Informations académiques
                          const SizedBox(height: 24),
                          const Text(
                            'Informations académiques',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          _buildInfoCard(
                            title: 'UFR',
                            value: _student!.ufr,
                            icon: Icons.school,
                            iconColor: Colors.purple,
                          ),
                          
                          _buildInfoCard(
                            title: 'Département',
                            value: _student!.department,
                            icon: Icons.work_outline,
                            iconColor: Colors.deepOrange,
                          ),
                          
                          if (_student!.promotion != null && _student!.promotion!.isNotEmpty)
                            _buildInfoCard(
                              title: 'Promotion',
                              value: _student!.promotion!,
                              icon: Icons.calendar_today,
                              iconColor: Colors.teal,
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
                                  // ListTile(
                                  //   leading: Container(
                                  //     padding: const EdgeInsets.all(8),
                                  //     decoration: BoxDecoration(
                                  //       color: _student!.isActive
                                  //           ? Colors.red.withOpacity(0.1)
                                  //           : Colors.green.withOpacity(0.1),
                                  //       shape: BoxShape.circle,
                                  //     ),
                                  //     child: Icon(
                                  //       _student!.isActive
                                  //           ? Icons.person_off
                                  //           : Icons.person_add,
                                  //       color: _student!.isActive
                                  //           ? Colors.red
                                  //           : Colors.green,
                                  //     ),
                                  //   ),
                                  //   title: Text(
                                  //     _student!.isActive
                                  //         ? 'Désactiver l\'étudiant'
                                  //         : 'Activer l\'étudiant',
                                  //   ),
                                  //   subtitle: Text(
                                  //     _student!.isActive
                                  //         ? 'L\'étudiant ne pourra plus participer aux examens'
                                  //         : 'L\'étudiant pourra participer aux examens',
                                  //   ),
                                  //   trailing: const Icon(Icons.chevron_right),
                                  //   onTap: _toggleActiveStatus,
                                  // ),
                                  
                                  const Divider(height: 1),
                                  
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
                                    title: const Text('Modifier l\'étudiant'),
                                    subtitle: const Text('Modifier les informations de l\'étudiant'),
                                    trailing: const Icon(Icons.chevron_right),
                                    onTap: () {
                                      // TODO: Naviguer vers la page d'édition
                                      Navigator.push(context, MaterialPageRoute(
                                        builder: (context) => EditStudentPage(studentId: _student!.id),
                                      ));
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
                                      'Supprimer l\'étudiant',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                    subtitle: const Text(
                                      'Supprimer définitivement l\'étudiant',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                    trailing: const Icon(
                                      Icons.chevron_right,
                                      color: Colors.red,
                                    ),
                                    onTap: _deleteStudent,
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