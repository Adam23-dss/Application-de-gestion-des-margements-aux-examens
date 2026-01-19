const Student = require('../models/Student');

class StudentController {
  // GET /api/students - Liste paginée avec filtres
  static async getAll(req, res, next) {
    try {
      const page = parseInt(req.query.page) || 1;
      const limit = parseInt(req.query.limit) || 20;
      
      const filters = {
        ufr: req.query.ufr,
        department: req.query.department,
        promotion: req.query.promotion,
        search: req.query.search
      };
      
      const result = await Student.findAll(page, limit, filters);
      
      res.json({
        success: true,
        data: result.students,
        pagination: result.pagination
      });
    } catch (error) {
      console.error('Error in StudentController.getAll:', error);
      next(error);
    }
  }

  // GET /api/students/:id - Détails étudiant
  static async getById(req, res, next) {
    try {
      const student = await Student.findById(req.params.id);
      
      if (!student) {
        return res.status(404).json({
          success: false,
          error: 'STUDENT_NOT_FOUND',
          message: 'Étudiant non trouvé'
        });
      }
      
      res.json({
        success: true,
        data: student
      });
    } catch (error) {
      console.error('Error in StudentController.getById:', error);
      next(error);
    }
  }

  // POST /api/students - Créer étudiant
  static async create(req, res, next) {
    try {
      const { student_code, first_name, last_name, email, ufr, department, promotion } = req.body;
      
      // Validation basique
      if (!student_code || !first_name || !last_name || !ufr || !department) {
        return res.status(400).json({
          success: false,
          error: 'MISSING_REQUIRED_FIELDS',
          message: 'Code étudiant, prénom, nom, UFR et département sont requis'
        });
      }
      
      // Validation format code étudiant
      const studentCodeRegex = /^[A-Z0-9]{4,20}$/;
      if (!studentCodeRegex.test(student_code)) {
        return res.status(400).json({
          success: false,
          error: 'INVALID_STUDENT_CODE',
          message: 'Code étudiant invalide. Format attendu: lettres/majuscules/chiffres (4-20 caractères)'
        });
      }
      
      const studentData = {
        student_code: student_code.toUpperCase(), // Standardiser en majuscules
        first_name,
        last_name,
        email,
        ufr,
        department,
        promotion
      };
      
      const student = await Student.create(studentData);
      
      res.status(201).json({
        success: true,
        message: 'Étudiant créé avec succès',
        data: student
      });
    } catch (error) {
      console.error('Error in StudentController.create:', error);
      
      if (error.message.includes('existe déjà')) {
        return res.status(409).json({
          success: false,
          error: 'DUPLICATE_STUDENT',
          message: error.message
        });
      }
      next(error);
    }
  }

  // PUT /api/students/:id - Mettre à jour
  static async update(req, res, next) {
    try {
      const { first_name, last_name, email, ufr, department, promotion } = req.body;
      
      // Vérifier qu'il y a au moins un champ à mettre à jour
      if (!first_name && !last_name && !email && !ufr && !department && !promotion) {
        return res.status(400).json({
          success: false,
          error: 'NO_DATA_PROVIDED',
          message: 'Aucune donnée fournie pour la mise à jour'
        });
      }
      
      const studentData = {
        first_name,
        last_name,
        email,
        ufr,
        department,
        promotion
      };
      
      const student = await Student.update(req.params.id, studentData);
      
      if (!student) {
        return res.status(404).json({
          success: false,
          error: 'STUDENT_NOT_FOUND',
          message: 'Étudiant non trouvé ou désactivé'
        });
      }
      
      res.json({
        success: true,
        message: 'Étudiant mis à jour avec succès',
        data: student
      });
    } catch (error) {
      console.error('Error in StudentController.update:', error);
      next(error);
    }
  }

  // DELETE /api/students/:id - Supprimer (soft delete)
  static async delete(req, res, next) {
    try {
      const student = await Student.delete(req.params.id);
      
      if (!student) {
        return res.status(404).json({
          success: false,
          error: 'STUDENT_NOT_FOUND',
          message: 'Étudiant non trouvé'
        });
      }
      
      res.json({
        success: true,
        message: 'Étudiant désactivé avec succès',
        data: { id: student.id, student_code: student.student_code }
      });
    } catch (error) {
      console.error('Error in StudentController.delete:', error);
      next(error);
    }
  }

  // GET /api/students/search - Recherche
  static async search(req, res, next) {
    try {
      const { q, page = 1, limit = 20 } = req.query;
      
      if (!q || q.trim().length < 2) {
        return res.status(400).json({
          success: false,
          error: 'INVALID_SEARCH_TERM',
          message: 'Le terme de recherche doit contenir au moins 2 caractères'
        });
      }
      
      const result = await Student.search(q.trim(), page, limit);
      
      res.json({
        success: true,
        data: result.students,
        pagination: result.pagination
      });
    } catch (error) {
      console.error('Error in StudentController.search:', error);
      next(error);
    }
  }

  // GET /api/students/code/:code - Par code étudiant
  static async getByCode(req, res, next) {
    try {
      const student = await Student.findByStudentCode(req.params.code);
      
      if (!student) {
        return res.status(404).json({
          success: false,
          error: 'STUDENT_NOT_FOUND',
          message: 'Étudiant non trouvé'
        });
      }
      
      res.json({
        success: true,
        data: student
      });
    } catch (error) {
      console.error('Error in StudentController.getByCode:', error);
      next(error);
    }
  }

  // GET /api/students/stats/ufr - Statistiques par UFR
  static async getUfrStats(req, res, next) {
    try {
      const stats = await Student.countByUfr();
      
      res.json({
        success: true,
        data: stats
      });
    } catch (error) {
      console.error('Error in StudentController.getUfrStats:', error);
      next(error);
    }
  }
  // GET /api/students/filters/options - Options de filtres
  static async getFilterOptions(req, res, next) {
    try {
      const options = await Student.getFilterOptions();
      
      res.json({
        success: true,
        data: options
      });
    } catch (error) {
      console.error('Error in StudentController.getFilterOptions:', error);
      next(error);
    }
  }
}

module.exports = StudentController;