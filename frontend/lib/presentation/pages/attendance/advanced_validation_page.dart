// presentation/pages/attendance/advanced_validation_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend1/presentation/widgets/custom_app_bar.dart';
import 'package:frontend1/presentation/providers/attendance_provider.dart';
import 'package:frontend1/presentation/providers/exam_registration_provider.dart';
import 'package:frontend1/data/models/exam_model.dart';
import 'package:frontend1/data/models/student_model.dart';
import 'package:frontend1/data/models/attendance_model.dart';
import 'package:frontend1/core/themes/app_colors.dart';

class AdvancedValidationPage extends StatefulWidget {
  final int examId;
  
  const AdvancedValidationPage({super.key, required this.examId});
  
  @override
  State<AdvancedValidationPage> createState() => _AdvancedValidationPageState();
}

class _AdvancedValidationPageState extends State<AdvancedValidationPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'all';
  String _selectedValidationMethod = 'all';
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }
  
  Future<void> _loadData() async {
    final attendanceProvider = context.read<AttendanceProvider>();
    final registrationProvider = context.read<ExamRegistrationProvider>();
    
    await Future.wait([
      attendanceProvider.loadExamAttendance(widget.examId),
      registrationProvider.loadExamStudents(widget.examId),
    ]);
  }
  
  Widget _buildStatsCard(AttendanceProvider provider) {
    final stats = provider.stats;
    if (stats == null) return const SizedBox();
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('Total', stats['total']?.toString() ?? '0', Colors.blue),
            _buildStatItem('Présents', stats['present']?.toString() ?? '0', Colors.green),
            _buildStatItem('Absents', stats['absent']?.toString() ?? '0', Colors.red),
            _buildStatItem('Taux', '${stats['attendance_rate']?.toString() ?? '0'}%', AppColors.primary),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
  
  Widget _buildFilters() {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filtres',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Rechercher étudiant...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (value) {
                      final provider = context.read<AttendanceProvider>();
                      provider.searchQuery = value;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                
                // Filtre statut
                PopupMenuButton<String>(
                  onSelected: (value) {
                    setState(() => _selectedStatus = value);
                    final provider = context.read<AttendanceProvider>();
                    provider.selectedStatus = value;
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'all', child: Text('Tous les statuts')),
                    const PopupMenuItem(value: 'present', child: Text('Présents')),
                    const PopupMenuItem(value: 'absent', child: Text('Absents')),
                    const PopupMenuItem(value: 'late', child: Text('En retard')),
                    const PopupMenuItem(value: 'excused', child: Text('Excusés')),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.filter_list, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          _selectedStatus == 'all' ? 'Statut' : _selectedStatus,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildValidationTable(AttendanceProvider attendanceProvider, ExamRegistrationProvider registrationProvider) {
    final students = registrationProvider.examStudents;
    final attendanceRecords = attendanceProvider.attendanceRecords;
    
    if (students.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Aucun étudiant inscrit à cet examen',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Code')),
          DataColumn(label: Text('Nom')),
          DataColumn(label: Text('Statut')),
          DataColumn(label: Text('Validation')),
          DataColumn(label: Text('Heure')),
          DataColumn(label: Text('Actions')),
        ],
        rows: students.map((student) {
          final attendance = attendanceRecords.firstWhere(
            (a) => a.studentId == student.id,
            orElse: () => AttendanceModel(
              id: 0,
              examId: widget.examId,
              studentId: student.id,
              status: 'absent',
              studentName: student.fullName,
              studentCode: student.studentCode,
            ),
          );
          
          return DataRow(
            cells: [
              DataCell(Text(student.studentCode)),
              DataCell(Text(student.fullName)),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: attendance.statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    attendance.statusLabel,
                    style: TextStyle(
                      color: attendance.statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              DataCell(
                Text(
                  attendance.validationMethod == 'manual' 
                    ? 'Manuelle' 
                    : attendance.validationMethod ?? 'Non validé',
                ),
              ),
              DataCell(
                Text(
                  attendance.validationTime != null
                    ? '${attendance.validationTime!.hour}:${attendance.validationTime!.minute.toString().padLeft(2, '0')}'
                    : '--:--',
                ),
              ),
              DataCell(
                PopupMenuButton<String>(
                  itemBuilder: (context) => [
                    if (attendance.status != 'present')
                      const PopupMenuItem(value: 'present', child: Text('Marquer présent')),
                    if (attendance.status != 'absent')
                      const PopupMenuItem(value: 'absent', child: Text('Marquer absent')),
                    if (attendance.status != 'late')
                      const PopupMenuItem(value: 'late', child: Text('Marquer en retard')),
                    if (attendance.status != 'excused')
                      const PopupMenuItem(value: 'excused', child: Text('Marquer excusé')),
                  ],
                  onSelected: (status) async {
                    await _updateAttendance(student, status);
                  },
                  child: const Icon(Icons.more_vert),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
  
  Future<void> _updateAttendance(StudentModel student, String status) async {
    final provider = context.read<AttendanceProvider>();
    
    try {
      await provider.validateAttendance(
        examId: widget.examId,
        studentCode: student.studentCode,
        status: status,
        validationMethod: 'manual',
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${student.fullName} marqué comme ${_getStatusLabel(status)}'),
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
  }
  
  String _getStatusLabel(String status) {
    switch (status) {
      case 'present': return 'présent';
      case 'absent': return 'absent';
      case 'late': return 'en retard';
      case 'excused': return 'excusé';
      default: return status;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final attendanceProvider = context.watch<AttendanceProvider>();
    final registrationProvider = context.watch<ExamRegistrationProvider>();
    
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Validation avancée',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      
      body: Column(
        children: [
          _buildStatsCard(attendanceProvider),
          const SizedBox(height: 16),
          _buildFilters(),
          const SizedBox(height: 16),
          Expanded(
            child: attendanceProvider.isLoading || registrationProvider.isLoadingStudents
                ? const Center(child: CircularProgressIndicator())
                : _buildValidationTable(attendanceProvider, registrationProvider),
          ),
        ],
      ),
    );
  }
}