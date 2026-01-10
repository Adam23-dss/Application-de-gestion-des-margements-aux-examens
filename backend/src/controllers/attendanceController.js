const Attendance = require('../models/Attendance');
const Exam = require('../models/Exam');
const Student = require('../models/Student');

class AttendanceController {
  // POST /api/attendance/validate - Valider une présence
  static async validate(req, res, next) {
    try {
      console.log('📝 Attendance validate called with:', req.body);
      
      const { exam_id, student_code, status = 'present', validation_method = 'manual' } = req.body;
      
      if (!exam_id || !student_code) {
        return res.status(400).json({
          success: false,
          error: 'MISSING_REQUIRED_FIELDS',
          message: 'ID examen et code étudiant requis'
        });
      }
      
      // Vérifier que l'examen existe et est en cours
      const exam = await Exam.findById(exam_id); // CORRECTION: exam_id, pas examId
      if (!exam) {
        return res.status(404).json({
          success: false,
          error: 'EXAM_NOT_FOUND',
          message: 'Examen non trouvé'
        });
      }
      
      if (exam.status !== 'in_progress') {
        return res.status(400).json({
          success: false,
          error: 'EXAM_NOT_IN_PROGRESS',
          message: 'L\'examen n\'est pas en cours'
        });
      }
      
      // Trouver l'étudiant par son code
      const student = await Student.findByStudentCode(student_code);
      if (!student) {
        return res.status(404).json({
          success: false,
          error: 'STUDENT_NOT_FOUND',
          message: 'Étudiant non trouvé'
        });
      }
      
      // Vérifier que l'étudiant est inscrit à l'examen
      const examStudents = await Exam.getStudents(exam_id);
      const isRegistered = examStudents.some(s => s.id === student.id);
      
      if (!isRegistered) {
        return res.status(400).json({
          success: false,
          error: 'STUDENT_NOT_REGISTERED',
          message: 'L\'étudiant n\'est pas inscrit à cet examen'
        });
      }
      
      // Valider la présence
      const attendanceData = {
        exam_id,
        student_id: student.id,
        supervisor_id: req.user.id,
        status,
        validation_method
      };
      
      const attendance = await Attendance.validate(attendanceData);
      
      // Émettre un événement WebSocket
      if (req.app.get('io')) {
        req.app.get('io').emit('attendance-updated', {
          exam_id,
          student_id: student.id,
          status,
          timestamp: new Date().toISOString()
        });
      }
      
      res.json({
        success: true,
        message: `Présence ${status === 'present' ? 'validée' : 'modifiée'} avec succès`,
        data: attendance
      });
      
    } catch (error) {
      console.error('AttendanceController.validate error:', error);
      next(error);
    }
  }

  // GET /api/attendance/exam/:id - Présences par examen
  static async getByExam(req, res, next) {
    try {
      const attendance = await Attendance.findByExam(req.params.id);
      
      res.json({
        success: true,
        data: attendance
      });
    } catch (error) {
      next(error);
    }
  }

  // GET /api/attendance/stats/:examId - Statistiques
  static async getStats(req, res, next) {
    try {
      const stats = await Attendance.getStats(req.params.examId);
      
      res.json({
        success: true,
        data: stats
      });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = AttendanceController;