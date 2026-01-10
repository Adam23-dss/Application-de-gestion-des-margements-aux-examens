const Course = require('../models/Course');

class CourseController {
  // GET /api/courses - Liste paginée
  static async getAll(req, res, next) {
    try {
      const page = parseInt(req.query.page) || 1;
      const limit = parseInt(req.query.limit) || 20;
      
      const filters = {
        ufr: req.query.ufr,
        department: req.query.department,
        search: req.query.search
      };
      
      const result = await Course.findAll(page, limit, filters);
      
      res.json({
        success: true,
        data: result.courses,
        pagination: result.pagination
      });
    } catch (error) {
      next(error);
    }
  }

  // GET /api/courses/:id - Détails cours
  static async getById(req, res, next) {
    try {
      const course = await Course.findById(req.params.id);
      
      if (!course) {
        return res.status(404).json({
          success: false,
          error: 'COURSE_NOT_FOUND',
          message: 'Cours non trouvé'
        });
      }
      
      res.json({
        success: true,
        data: course
      });
    } catch (error) {
      next(error);
    }
  }

  // GET /api/courses/code/:code - Par code cours
  static async getByCode(req, res, next) {
    try {
      const course = await Course.findByCode(req.params.code);
      
      if (!course) {
        return res.status(404).json({
          success: false,
          error: 'COURSE_NOT_FOUND',
          message: 'Cours non trouvé'
        });
      }
      
      res.json({
        success: true,
        data: course
      });
    } catch (error) {
      next(error);
    }
  }

  // POST /api/courses - Créer cours
  static async create(req, res, next) {
    try {
      const { code, name, ufr, department, credits, description } = req.body;
      
      if (!code || !name || !ufr || !department) {
        return res.status(400).json({
          success: false,
          error: 'MISSING_REQUIRED_FIELDS',
          message: 'Code, nom, UFR et département sont requis'
        });
      }
      
      const courseData = {
        code: code.toUpperCase(),
        name,
        ufr,
        department,
        credits: credits ? parseInt(credits) : null,
        description
      };
      
      const course = await Course.create(courseData);
      
      res.status(201).json({
        success: true,
        message: 'Cours créé avec succès',
        data: course
      });
    } catch (error) {
      if (error.message.includes('existe déjà')) {
        return res.status(409).json({
          success: false,
          error: 'DUPLICATE_COURSE',
          message: error.message
        });
      }
      next(error);
    }
  }

  // PUT /api/courses/:id - Mettre à jour
  static async update(req, res, next) {
    try {
      const { name, ufr, department, credits, description } = req.body;
      
      const courseData = {
        name,
        ufr,
        department,
        credits: credits ? parseInt(credits) : null,
        description
      };
      
      const course = await Course.update(req.params.id, courseData);
      
      if (!course) {
        return res.status(404).json({
          success: false,
          error: 'COURSE_NOT_FOUND',
          message: 'Cours non trouvé'
        });
      }
      
      res.json({
        success: true,
        message: 'Cours mis à jour avec succès',
        data: course
      });
    } catch (error) {
      next(error);
    }
  }

  // DELETE /api/courses/:id - Supprimer
  static async delete(req, res, next) {
    try {
      const course = await Course.delete(req.params.id);
      
      if (!course) {
        return res.status(404).json({
          success: false,
          error: 'COURSE_NOT_FOUND',
          message: 'Cours non trouvé'
        });
      }
      
      res.json({
        success: true,
        message: 'Cours supprimé avec succès',
        data: { id: course.id, code: course.code, name: course.name }
      });
    } catch (error) {
      if (error.message.includes('utilisé par des examens')) {
        return res.status(400).json({
          success: false,
          error: 'COURSE_IN_USE',
          message: error.message
        });
      }
      next(error);
    }
  }

  // GET /api/courses/search - Recherche
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
      
      const result = await Course.search(q.trim(), page, limit);
      
      res.json({
        success: true,
        data: result.courses,
        pagination: result.pagination
      });
    } catch (error) {
      next(error);
    }
  }

  // GET /api/courses/stats/ufr - Statistiques par UFR
  static async getUfrStats(req, res, next) {
    try {
      const stats = await Course.countByUfr();
      
      res.json({
        success: true,
        data: stats
      });
    } catch (error) {
      next(error);
    }
  }

  // GET /api/courses/filters/options - Options de filtres
  static async getFilterOptions(req, res, next) {
    try {
      const options = await Course.getFilterOptions();
      
      res.json({
        success: true,
        data: options
      });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = CourseController;