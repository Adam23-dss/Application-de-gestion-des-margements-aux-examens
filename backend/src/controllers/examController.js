const Exam = require('../models/Exam');
const Course = require('../models/Course');
const Room = require('../models/Room');
const User = require('../models/User');
const Attendance = require('../models/Attendance');

class ExamController {
  // GET /api/exams - Liste paginée
  static async getAll(req, res, next) {
    try {
      const page = parseInt(req.query.page) || 1;
      const limit = parseInt(req.query.limit) || 20;

      const filters = {
        status: req.query.status,
        course_id: req.query.course_id,
        start_date: req.query.start_date,
        end_date: req.query.end_date
      };

      const result = await Exam.findAll(page, limit, filters);

      res.json({
        success: true,
        data: result.exams,
        pagination: result.pagination
      });
    } catch (error) {
      next(error);
    }
  }

  // GET /api/exams/:id - Détails examen
  static async getById(req, res, next) {
    try {
      const exam = await Exam.findById(req.params.id);

      if (!exam) {
        return res.status(404).json({
          success: false,
          error: 'EXAM_NOT_FOUND',
          message: 'Examen non trouvé'
        });
      }

      res.json({
        success: true,
        data: exam
      });
    } catch (error) {
      next(error);
    }
  }

  // POST /api/exams - Créer examen
  static async create(req, res, next) {
    try {
      const {
        course_id,
        name,
        description,
        exam_date,
        start_time,
        end_time,
        room_id,
        supervisor_id
      } = req.body;

      // Validation basique
      if (!name || !exam_date || !start_time || !end_time) {
        return res.status(400).json({
          success: false,
          error: 'MISSING_REQUIRED_FIELDS',
          message: 'Nom, date, heure de début et fin sont requis'
        });
      }

      const examData = {
        course_id,
        name,
        description,
        exam_date,
        start_time,
        end_time,
        room_id,
        supervisor_id: supervisor_id || req.user.id // Utiliser l'ID de l'utilisateur connecté
      };

      const exam = await Exam.create(examData);

      res.status(201).json({
        success: true,
        message: 'Examen créé avec succès',
        data: exam
      });
    } catch (error) {
      if (error.message.includes('non trouvé')) {
        return res.status(404).json({
          success: false,
          error: 'RESOURCE_NOT_FOUND',
          message: error.message
        });
      }
      next(error);
    }
  }

  // PUT /api/exams/:id - Mettre à jour
  static async update(req, res, next) {
    try {
      const exam = await Exam.update(req.params.id, req.body);

      if (!exam) {
        return res.status(404).json({
          success: false,
          error: 'EXAM_NOT_FOUND',
          message: 'Examen non trouvé'
        });
      }

      res.json({
        success: true,
        message: 'Examen mis à jour avec succès',
        data: exam
      });
    } catch (error) {
      next(error);
    }
  }

  // DELETE /api/exams/:id - Annuler examen
  static async delete(req, res, next) {
    try {
      const exam = await Exam.delete(req.params.id);

      if (!exam) {
        return res.status(404).json({
          success: false,
          error: 'EXAM_NOT_FOUND',
          message: 'Examen non trouvé'
        });
      }

      res.json({
        success: true,
        message: 'Examen annulé avec succès',
        data: {
          id: exam.id,
          name: exam.name
        }
      });
    } catch (error) {
      next(error);
    }
  }

  // POST /api/exams/:id/start - Démarrer examen
  static async start(req, res, next) {
    try {
      const exam = await Exam.updateStatus(req.params.id, 'in_progress');

      if (!exam) {
        return res.status(404).json({
          success: false,
          error: 'EXAM_NOT_FOUND',
          message: 'Examen non trouvé'
        });
      }

      res.json({
        success: true,
        message: 'Examen démarré',
        data: exam
      });
    } catch (error) {
      next(error);
    }
  }

  // POST /api/exams/:id/end - Terminer examen
  static async end(req, res, next) {
    try {
      const exam = await Exam.updateStatus(req.params.id, 'completed');

      if (!exam) {
        return res.status(404).json({
          success: false,
          error: 'EXAM_NOT_FOUND',
          message: 'Examen non trouvé'
        });
      }

      res.json({
        success: true,
        message: 'Examen terminé',
        data: exam
      });
    } catch (error) {
      next(error);
    }
  }

  // GET /api/exams/:id/students - Étudiants inscrits
  static async getStudents(req, res, next) {
    try {
      const students = await Exam.getStudents(req.params.id);

      res.json({
        success: true,
        data: students
      });
    } catch (error) {
      next(error);
    }
  }

  // POST /api/exams/:id/students - Ajouter étudiant
  static async addStudent(req, res, next) {
    try {
      const {
        student_id
      } = req.body;

      if (!student_id) {
        return res.status(400).json({
          success: false,
          error: 'MISSING_STUDENT_ID',
          message: 'ID étudiant requis'
        });
      }

      const result = await Exam.addStudent(req.params.id, student_id);

      res.status(201).json({
        success: true,
        message: 'Étudiant ajouté à l\'examen',
        data: result
      });
    } catch (error) {
      next(error);
    }
  }

  // DELETE /api/exams/:id/students/:studentId - Retirer étudiant
  static async removeStudent(req, res, next) {
    try {
      const result = await Exam.removeStudent(req.params.id, req.params.studentId);

      if (!result) {
        return res.status(404).json({
          success: false,
          error: 'REGISTRATION_NOT_FOUND',
          message: 'Inscription non trouvée'
        });
      }

      res.json({
        success: true,
        message: 'Étudiant retiré de l\'examen',
        data: {
          id: result.id
        }
      });
    } catch (error) {
      next(error);
    }
  }

  // GET /api/exams/:id/statistics - Statistiques
  static async getStatistics(req, res, next) {
    try {
      const stats = await Exam.getStatistics(req.params.id);

      if (!stats || stats.length === 0) {
        return res.status(404).json({
          success: false,
          error: "NO_DATA",
          message: "Aucune statistique disponible"
        });
      }

      return res.json({
        success: true,
        data: stats[0]
      });

    } catch (error) {
      console.error("Statistics Error:", error.message);
      return res.status(500).json({
        success: false,
        error: "INTERNAL_SERVER_ERROR",
        message: error.message
      });
    }
  }

/**
   * Générer un QR code pour un étudiant dans un examen
   * POST /api/exams/:id/generate-qr
   */
  static async generateQRCode(req, res, next) {
    try {
      const { student_id } = req.body;
      const { id: examId } = req.params;
      const userId = req.user.id;

      if (!student_id) {
        return res.status(400).json({
          success: false,
          error: 'MISSING_STUDENT_ID',
          message: 'ID étudiant requis'
        });
      }

      // Générer le QR code
      const qrData = await Exam.generateQRCode(examId, student_id, userId);

      res.json({
        success: true,
        message: 'QR code généré avec succès',
        data: qrData
      });

    } catch (error) {
      console.error('Generate QR Code Error:', error);
      
      if (error.message.includes('non inscrit') || 
          error.message.includes('non trouvé')) {
        return res.status(404).json({
          success: false,
          error: 'NOT_FOUND',
          message: error.message
        });
      }

      next(error);
    }
  }

  /**
   * Générer des QR codes en masse
   * POST /api/exams/:id/generate-bulk-qr
   */
  static async generateBulkQRCodes(req, res, next) {
    try {
      const { student_ids } = req.body;
      const { id: examId } = req.params;
      const userId = req.user.id;

      if (!student_ids || !Array.isArray(student_ids) || student_ids.length === 0) {
        return res.status(400).json({
          success: false,
          error: 'INVALID_STUDENT_IDS',
          message: 'Liste d\'IDs étudiants requise'
        });
      }

      // Limiter le nombre pour éviter la surcharge
      if (student_ids.length > 100) {
        return res.status(400).json({
          success: false,
          error: 'TOO_MANY_STUDENTS',
          message: 'Maximum 100 étudiants à la fois'
        });
      }

      // Générer les QR codes
      const result = await Exam.generateBulkQRCodes(examId, student_ids, userId);

      res.json({
        success: true,
        message: `QR codes générés: ${result.total_generated} succès, ${result.total_failed} échecs`,
        data: {
          qr_codes: result.qr_codes,
          errors: result.errors,
          total_generated: result.total_generated,
          total_failed: result.total_failed
        }
      });

    } catch (error) {
      console.error('Generate Bulk QR Codes Error:', error);
      next(error);
    }
  }

  /**
   * Vérifier un QR code scanné
   * POST /api/exams/:id/verify-qr
   */
  static async verifyQRCode(req, res, next) {
    try {
      const { qr_data } = req.body;
      const { id: examId } = req.params;

      if (!qr_data) {
        return res.status(400).json({
          success: false,
          error: 'MISSING_QR_DATA',
          message: 'Données QR code requises'
        });
      }

      // Vérifier le QR code
      const verification = await Exam.verifyQRCode(qr_data, examId);

      if (!verification.is_valid) {
        return res.status(400).json({
          success: false,
          error: 'INVALID_QR_CODE',
          message: verification.error,
          data: verification
        });
      }

      // Si déjà présent, retourner l'information
      if (verification.existing_attendance) {
        return res.json({
          success: true,
          message: 'QR code valide (déjà enregistré)',
          data: {
            ...verification,
            already_attended: true,
            attendance_status: verification.existing_attendance.status,
            validation_time: verification.existing_attendance.validation_time
          }
        });
      }

      // QR code valide, étudiant peut être marqué présent
      res.json({
        success: true,
        message: 'QR code valide',
        data: {
          ...verification,
          can_validate: true
        }
      });

    } catch (error) {
      console.error('Verify QR Code Error:', error);
      next(error);
    }
  }

  /**
   * Valider une présence via QR code
   * POST /api/exams/:id/validate-qr
   */
  static async validateFromQRCode(req, res, next) {
    try {
      const { qr_data } = req.body;
      const { id: examId } = req.params;
      const userId = req.user.id;

      if (!qr_data) {
        return res.status(400).json({
          success: false,
          error: 'MISSING_QR_DATA',
          message: 'Données QR code requises'
        });
      }

      // 1. Vérifier le QR code
      const verification = await Exam.verifyQRCode(qr_data, examId);
      
      if (!verification.is_valid) {
        return res.status(400).json({
          success: false,
          error: 'INVALID_QR',
          message: verification.error
        });
      }

      const { student } = verification;

      // 2. Vérifier si déjà présent
      const existingAttendance = await Attendance.findByExamAndStudent(
        examId,
        student.id
      );

      if (existingAttendance) {
        return res.json({
          success: true,
          message: 'Étudiant déjà présent',
          data: {
            attendance: existingAttendance,
            student: student,
            already_present: true
          }
        });
      }

      // 3. Marquer présent
      const attendance = await Attendance.create({
        exam_id: examId,
        student_id: student.id,
        status: 'present',
        validation_method: 'qr_code',
        validated_by: userId
      });

      // 4. Mettre à jour l'historique QR
      await Exam.markQRCodeAsScanned(examId, student.id, userId, attendance.id);

      res.json({
        success: true,
        message: 'Présence validée par QR code',
        data: {
          attendance: attendance,
          student: student,
          qr_data: verification.qr_data
        }
      });

    } catch (error) {
      console.error('Validate from QR Code Error:', error);
      next(error);
    }
  }

  /**
   * Obtenir l'historique des QR codes
   * GET /api/exams/:id/qr-history
   */
  static async getQRCodeHistory(req, res, next) {
    try {
      const { id: examId } = req.params;
      const page = parseInt(req.query.page) || 1;
      const limit = parseInt(req.query.limit) || 20;

      const history = await Exam.getQRCodeHistory(examId, page, limit);

      res.json({
        success: true,
        data: history.qr_codes,
        pagination: history.pagination
      });

    } catch (error) {
      console.error('Get QR Code History Error:', error);
      next(error);
    }
  }

  /**
   * Obtenir les QR codes actifs
   * GET /api/exams/:id/active-qr-codes
   */
  static async getActiveQRCodes(req, res, next) {
    try {
      const { id: examId } = req.params;

      const activeQRCodes = await Exam.getActiveQRCodes(examId);

      res.json({
        success: true,
        data: activeQRCodes
      });

    } catch (error) {
      console.error('Get Active QR Codes Error:', error);
      next(error);
    }
  }
}

module.exports = ExamController;