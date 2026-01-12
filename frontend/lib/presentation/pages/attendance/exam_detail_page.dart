import 'package:flutter/material.dart';
import 'package:frontend1/data/models/student_model.dart';
import 'package:provider/provider.dart';
import 'package:frontend1/presentation/providers/exam_provider.dart';
import 'package:frontend1/presentation/providers/attendance_provider.dart';
import 'package:frontend1/presentation/widgets/custom_app_bar.dart';
import 'package:frontend1/presentation/widgets/student_card.dart';
import 'package:frontend1/presentation/pages/attendance/manual_validation_page.dart';

class ExamDetailPage extends StatefulWidget {
  final int examId;
  
  const ExamDetailPage({super.key, required this.examId});
  
  @override
  State<ExamDetailPage> createState() => _ExamDetailPageState();
}

class _ExamDetailPageState extends State<ExamDetailPage> {
  late Future<void> _loadData;
  
  @override
  void initState() {
    super.initState();
    _loadData = _loadExamData();
  }
  
  Future<void> _loadExamData() async {
    final examProvider = context.read<ExamProvider>();
    final attendanceProvider = context.read<AttendanceProvider>();
    
    await examProvider.selectExam(widget.examId);
    await attendanceProvider.loadExamAttendance(widget.examId);
  }
  
  Future<void> _refreshData() async {
    setState(() {
      _loadData = _loadExamData();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Détails Examen',
        showBackButton: true,
      ),
      body: FutureBuilder(
        future: _loadData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Erreur: ${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshData,
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }
          
          return _buildContent();
        },
      ),
    );
  }
  
  Widget _buildContent() {
    final examProvider = context.watch<ExamProvider>();
    final attendanceProvider = context.watch<AttendanceProvider>();
    
    if (examProvider.selectedExam == null) {
      return const Center(child: Text('Examen non trouvé'));
    }
    
    final exam = examProvider.selectedExam!;
    
    return Column(
      children: [
        // En-tête de l'examen
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[50],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                exam.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              
              if (exam.courseName != null) ...[
                Text(
                  'Cours: ${exam.courseName!}',
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(height: 4),
              ],
              
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text('${exam.formattedDate} à ${exam.startTime}'),
                ],
              ),
              const SizedBox(height: 4),
              
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(exam.roomName ?? 'Salle non spécifiée'),
                ],
              ),
              const SizedBox(height: 4),
              
              Row(
                children: [
                  Icon(Icons.people, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text('${exam.totalStudents} étudiants inscrits'),
                ],
              ),
            ],
          ),
        ),
        
        // Statistiques de présence
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard(
                'Présents',
                attendanceProvider.presentCount.toString(),
                Colors.green,
                Icons.check_circle,
              ),
              _buildStatCard(
                'Absents',
                attendanceProvider.absentCount.toString(),
                Colors.red,
                Icons.cancel,
              ),
              _buildStatCard(
                'En retard',
                attendanceProvider.lateCount.toString(),
                Colors.orange,
                Icons.access_time,
              ),
            ],
          ),
        ),
        
        // Barre de progression
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Taux de présence',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  Text(
                    '${attendanceProvider.attendancePercentage.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: attendanceProvider.attendancePercentage / 100,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  attendanceProvider.attendancePercentage > 75
                      ? Colors.green
                      : attendanceProvider.attendancePercentage > 50
                          ? Colors.orange
                          : Colors.red,
                ),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Liste des étudiants avec filtres
        Expanded(
          child: attendanceProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildStudentList(attendanceProvider),
        ),
      ],
    );
  }
  
  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
  
  Widget _buildStudentList(AttendanceProvider attendanceProvider) {
    final students = attendanceProvider.filteredStudents;
    
    if (students.isEmpty) {
      return const Center(
        child: Text('Aucun étudiant trouvé'),
      );
    }
    
    return Column(
      children: [
        // Filtres
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Rechercher un étudiant...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                  ),
                  onChanged: (value) {
                    attendanceProvider.searchQuery = value;
                  },
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                onSelected: (value) {
                  attendanceProvider.selectedStatus = value;
                },
                itemBuilder: (context) {
                  return [
                    const PopupMenuItem(
                      value: 'all',
                      child: Text('Tous'),
                    ),
                    const PopupMenuItem(
                      value: 'present',
                      child: Text('Présents'),
                    ),
                    const PopupMenuItem(
                      value: 'absent',
                      child: Text('Absents'),
                    ),
                    const PopupMenuItem(
                      value: 'late',
                      child: Text('En retard'),
                    ),
                  ];
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.filter_list),
                ),
              ),
            ],
          ),
        ),
        
        // Liste des étudiants
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await attendanceProvider.loadExamAttendance(widget.examId);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: students.length,
              itemBuilder: (context, index) {
                final student = students[index];
                return StudentCard(
                  student: student,
                  onTap: () {
                    _showStudentOptions(context, student);
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  void _showStudentOptions(BuildContext context, StudentModel student) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                student.fullName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                student.studentCode,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              
              // Options de validation
              _buildOptionTile(
                Icons.check_circle,
                'Marquer présent',
                Colors.green,
                () => _validateStudent(student, 'present'),
              ),
              _buildOptionTile(
                Icons.cancel,
                'Marquer absent',
                Colors.red,
                () => _validateStudent(student, 'absent'),
              ),
              _buildOptionTile(
                Icons.access_time,
                'Marquer en retard',
                Colors.orange,
                () => _validateStudent(student, 'late'),
              ),
              _buildOptionTile(
                Icons.edit,
                'Validation manuelle',
                Colors.blue,
                () => _openManualValidation(student),
              ),
              
              const SizedBox(height: 16),
              
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.grey[100],
                  foregroundColor: Colors.grey[800],
                ),
                child: const Text('Fermer'),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildOptionTile(
    IconData icon,
    String title,
    Color color,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      tileColor: Colors.grey[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
  
  Future<void> _validateStudent(
    StudentModel student,
    String status,
  ) async {
    final attendanceProvider = context.read<AttendanceProvider>();
    final examProvider = context.read<ExamProvider>();
    
    final exam = examProvider.selectedExam!;
    
    try {
      await attendanceProvider.validateAttendance(
        examId: exam.id,
        studentCode: student.studentCode,
        status: status,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$status: ${student.fullName}'),
          backgroundColor: status == 'present'
              ? Colors.green
              : status == 'absent'
                  ? Colors.red
                  : Colors.orange,
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
  
  void _openManualValidation(StudentModel student) {
    final examProvider = context.read<ExamProvider>();
    final exam = examProvider.selectedExam!;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ManualValidationPage(
          examId: exam.id,
          student: student,
        ),
      ),
    );
  }
}