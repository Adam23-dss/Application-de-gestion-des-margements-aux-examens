import 'package:flutter/material.dart';
import 'package:frontend1/data/models/student_model.dart';
import 'package:frontend1/data/models/attendance_model.dart';
import 'package:frontend1/core/themes/app_colors.dart';

class StudentCard extends StatelessWidget {
  final StudentModel student;
  final AttendanceModel? attendance;
  final VoidCallback onTap;
  final VoidCallback? onValidate;
  final bool showValidationStatus;
  final bool showValidationActions;
  final bool isSelectable;
  final bool isSelected;
  
  const StudentCard({
    super.key,
    required this.student,
    this.attendance,
    required this.onTap,
    this.onValidate,
    this.showValidationStatus = true,
    this.showValidationActions = false,
    this.isSelectable = false,
    this.isSelected = false,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: AppColors.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Avatar/Photo étudiant
              _buildStudentAvatar(),
              
              const SizedBox(width: 12),
              
              // Informations étudiant
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
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isSelectable)
                          Icon(
                            isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                            color: isSelected ? AppColors.primary : Colors.grey[400],
                            size: 20,
                          ),
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    Text(
                      student.studentCode,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    
                    const SizedBox(height: 4),
                    
                    Row(
                      children: [
                        Icon(Icons.school, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${student.department} - ${student.ufr}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    
                    if (student.email != null && student.email!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.email, size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              student.email!,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    
                    if (showValidationStatus && attendance != null) ...[
                      const SizedBox(height: 8),
                      _buildAttendanceStatus(attendance!),
                    ],
                  ],
                ),
              ),
              
              // Actions
              if (showValidationActions && onValidate != null)
                _buildValidationActions(context),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildStudentAvatar() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          student.firstName.substring(0, 1).toUpperCase(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
  
  Widget _buildAttendanceStatus(AttendanceModel attendance) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: attendance.statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: attendance.statusColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            attendance.statusIcon,
            size: 14,
            color: attendance.statusColor,
          ),
          const SizedBox(width: 6),
          Text(
            attendance.statusLabel,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: attendance.statusColor,
            ),
          ),
          if (attendance.validationTime != null) ...[
            const SizedBox(width: 6),
            Text(
              '•',
              style: TextStyle(
                color: attendance.statusColor.withOpacity(0.5),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              _formatTime(attendance.validationTime!),
              style: TextStyle(
                fontSize: 11,
                color: attendance.statusColor.withOpacity(0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildValidationActions(BuildContext context) {
    final isPresent = attendance?.status == 'present';
    final isAbsent = attendance?.status == 'absent';
    final isLate = attendance?.status == 'late';
    
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (onValidate != null) {
          onValidate!();
        }
        // Note: La logique de validation spécifique sera gérée dans le parent
        _showValidationDialog(context, value);
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'present',
          child: Row(
            children: [
              Icon(Icons.check_circle, color: isPresent ? Colors.green : Colors.grey),
              const SizedBox(width: 8),
              const Text('Marquer présent'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'absent',
          child: Row(
            children: [
              Icon(Icons.cancel, color: isAbsent ? Colors.red : Colors.grey),
              const SizedBox(width: 8),
              const Text('Marquer absent'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'late',
          child: Row(
            children: [
              Icon(Icons.access_time, color: isLate ? Colors.orange : Colors.grey),
              const SizedBox(width: 8),
              const Text('Marquer en retard'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'excused',
          child: Row(
            children: [
              Icon(Icons.medical_services, color: Colors.purple),
              const SizedBox(width: 8),
              const Text('Marquer excusé'),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.more_vert,
          color: AppColors.primary,
          size: 20,
        ),
      ),
    );
  }
  
  void _showValidationDialog(BuildContext context, String status) {
    final statusMap = {
      'present': {'label': 'Présent', 'color': Colors.green, 'icon': Icons.check_circle},
      'absent': {'label': 'Absent', 'color': Colors.red, 'icon': Icons.cancel},
      'late': {'label': 'En retard', 'color': Colors.orange, 'icon': Icons.access_time},
      'excused': {'label': 'Excusé', 'color': Colors.purple, 'icon': Icons.medical_services},
    };
    
    final statusInfo = statusMap[status] ?? {'label': 'Inconnu', 'color': Colors.grey, 'icon': Icons.help};
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(statusInfo['icon'] as IconData, color: statusInfo['color'] as Color),
            const SizedBox(width: 8),
            Text('Confirmer la présence'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Marquer ${student.fullName} comme ${statusInfo['label']?.toString().toLowerCase()} ?',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              student.studentCode,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Appeler la validation via le parent
              onValidate?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: statusInfo['color'] as Color,
            ),
            child: const Text('Confirmer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final timeDate = DateTime(time.year, time.month, time.day);
    
    if (today.isAtSameMomentAs(timeDate)) {
      return 'Aujourd\'hui ${_formatHour(time)}';
    } else {
      return '${time.day}/${time.month} ${_formatHour(time)}';
    }
  }
  
  String _formatHour(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

// Variante compacte pour les listes denses
class CompactStudentCard extends StatelessWidget {
  final StudentModel student;
  final AttendanceModel? attendance;
  final VoidCallback onTap;
  
  const CompactStudentCard({
    super.key,
    required this.student,
    this.attendance,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              // Avatar mini
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    student.firstName.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Informations compactes
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.fullName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      student.studentCode,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Statut de présence
              if (attendance != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: attendance!.statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    attendance!.statusIcon,
                    size: 16,
                    color: attendance!.statusColor,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}