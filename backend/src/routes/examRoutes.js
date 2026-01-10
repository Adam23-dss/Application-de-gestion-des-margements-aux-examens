const express = require('express');
const router = express.Router();
const examController = require('../controllers/examController');
const authMiddleware = require('../middleware/authMiddleware');
const validationMiddleware = require('../middleware/validationMiddleware');

// 🔒 Toutes les routes sont protégées
router.use(authMiddleware.authenticate);

// 📋 ROUTES EXAMENS

/**
 * @route   GET /api/exams
 * @desc    Liste paginée des examens
 * @access  Private (supervisor, admin)
 * @query   page, limit, status, course_id, start_date, end_date
 */
router.get('/', 
  authMiddleware.authorize('supervisor', 'admin'),
  examController.getAll
);

/**
 * @route   POST /api/exams
 * @desc    Créer un nouvel examen
 * @access  Private (admin only)
 */
router.post('/',
  authMiddleware.authorize('admin'),
  validationMiddleware.validateExam,
  examController.create
);

/**
 * @route   GET /api/exams/:id
 * @desc    Obtenir les détails d'un examen
 * @access  Private (supervisor, admin)
 */
router.get('/:id',
  authMiddleware.authorize('supervisor', 'admin'),
  examController.getById
);

/**
 * @route   PUT /api/exams/:id
 * @desc    Mettre à jour un examen
 * @access  Private (admin only)
 */
router.put('/:id',
  authMiddleware.authorize('admin'),
  validationMiddleware.validateExamUpdate,
  examController.update
);

/**
 * @route   DELETE /api/exams/:id
 * @desc    Annuler un examen
 * @access  Private (admin only)
 */
router.delete('/:id',
  authMiddleware.authorize('admin'),
  examController.delete
);

/**
 * @route   POST /api/exams/:id/start
 * @desc    Démarrer un examen
 * @access  Private (supervisor, admin)
 */
router.post('/:id/start',
  authMiddleware.authorize('supervisor', 'admin'),
  examController.start
);

/**
 * @route   POST /api/exams/:id/end
 * @desc    Terminer un examen
 * @access  Private (supervisor, admin)
 */
router.post('/:id/end',
  authMiddleware.authorize('supervisor', 'admin'),
  examController.end
);

/**
 * @route   GET /api/exams/:id/students
 * @desc    Obtenir les étudiants inscrits à un examen
 * @access  Private (supervisor, admin)
 */
router.get('/:id/students',
  authMiddleware.authorize('supervisor', 'admin'),
  examController.getStudents
);

/**
 * @route   POST /api/exams/:id/students
 * @desc    Ajouter un étudiant à un examen
 * @access  Private (admin only)
 */
router.post('/:id/students',
  authMiddleware.authorize('admin'),
  examController.addStudent
);

/**
 * @route   DELETE /api/exams/:id/students/:studentId
 * @desc    Retirer un étudiant d'un examen
 * @access  Private (admin only)
 */
router.delete('/:id/students/:studentId',
  authMiddleware.authorize('admin'),
  examController.removeStudent
);

/**
 * @route   GET /api/exams/:id/statistics
 * @desc    Obtenir les statistiques d'un examen
 * @access  Private (supervisor, admin)
 */
router.get('/:id/statistics',
  authMiddleware.authorize('supervisor', 'admin'),
  examController.getStatistics
);

module.exports = router;