const Exam = require('../models/Exam');
const Course = require('../models/Course');
const Room = require('../models/Room');
const User = require('../models/User');

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
}

module.exports = ExamController;