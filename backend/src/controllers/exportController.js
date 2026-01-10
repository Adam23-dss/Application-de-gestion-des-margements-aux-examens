const PDFService = require('../services/pdfService');
const ExcelService = require('../services/excelService');
const Exam = require('../models/Exam');
const Attendance = require('../models/Attendance');

class ExportController {
  // GET /api/exports/attendance/:id/pdf - Export PDF
  static async exportAttendancePDF(req, res, next) {
    try {
      const examId = req.params.id;
      
      // Récupérer l'examen et les présences
      const exam = await Exam.findById(examId);
      if (!exam) {
        return res.status(404).json({
          success: false,
          error: 'EXAM_NOT_FOUND',
          message: 'Examen non trouvé'
        });
      }
      
      const attendanceList = await Attendance.findByExam(examId);
      
      // Générer le PDF
      const pdfBuffer = await PDFService.generateExamReport(exam, attendanceList);
      
      // Configurer la réponse
      res.set({
        'Content-Type': 'application/pdf',
        'Content-Disposition': `attachment; filename="presence-examen-${examId}.pdf"`,
        'Content-Length': pdfBuffer.length
      });
      
      res.send(pdfBuffer);
      
    } catch (error) {
      console.error('PDF export error:', error);
      next(error);
    }
  }

  // GET /api/exports/attendance/:id/excel - Export Excel
  static async exportAttendanceExcel(req, res, next) {
    try {
      const examId = req.params.id;
      
      // Récupérer l'examen et les présences
      const exam = await Exam.findById(examId);
      if (!exam) {
        return res.status(404).json({
          success: false,
          error: 'EXAM_NOT_FOUND',
          message: 'Examen non trouvé'
        });
      }
      
      const attendanceList = await Attendance.findByExam(examId);
      
      // Générer le Excel
      const excelBuffer = await ExcelService.generateExamExcel(exam, attendanceList);
      
      // Configurer la réponse
      res.set({
        'Content-Type': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        'Content-Disposition': `attachment; filename="presence-examen-${examId}.xlsx"`,
        'Content-Length': excelBuffer.length
      });
      
      res.send(excelBuffer);
      
    } catch (error) {
      console.error('Excel export error:', error);
      next(error);
    }
  }

  // GET /api/exports/students/pdf - Export étudiants
  static async exportStudentsPDF(req, res, next) {
    try {
      // Ici tu pourrais exporter la liste complète des étudiants
      // Pour l'instant retourne un message
      res.json({
        success: true,
        message: 'Export PDF étudiants (à implémenter)'
      });
      
    } catch (error) {
      next(error);
    }
  }

  // GET /api/exports/students/excel - Export étudiants Excel
  static async exportStudentsExcel(req, res, next) {
    try {
      res.json({
        success: true,
        message: 'Export Excel étudiants (à implémenter)'
      });
      
    } catch (error) {
      next(error);
    }
  }
}

module.exports = ExportController;