const express = require('express');
const router = express.Router();
const studentController = require('../controllers/studentController');
const authMiddleware = require('../middleware/authMiddleware');
const validationMiddleware = require('../middleware/validationMiddleware');

// 🔒 Toutes les routes sont protégées par authentification
router.use(authMiddleware.authenticate);

// 📋 ROUTES ÉTUDIANTS

/**
 * @route   GET /api/students
 * @desc    Liste paginée des étudiants
 * @access  Private (supervisor, admin)
 * @query   page, limit
 */
router.get('/', 
  authMiddleware.authorize('supervisor', 'admin'),
  studentController.getAll
);

/**
 * @route   GET /api/students/search
 * @desc    Rechercher des étudiants
 * @access  Private (supervisor, admin)
 * @query   q (search term), page, limit
 */
router.get('/search',
  authMiddleware.authorize('supervisor', 'admin'),
  studentController.search
);

/**
 * @route   GET /api/students/code/:code
 * @desc    Obtenir un étudiant par son code
 * @access  Private (supervisor, admin)
 */
router.get('/code/:code',
  authMiddleware.authorize('supervisor', 'admin'),
  studentController.getByCode
);

/**
 * @route   POST /api/students
 * @desc    Créer un nouvel étudiant
 * @access  Private (admin only)
 */
router.post('/',
  authMiddleware.authorize('admin'),
  validationMiddleware.validateStudent,
  studentController.create
);

/**
 * @route   GET /api/students/:id
 * @desc    Obtenir les détails d'un étudiant
 * @access  Private (supervisor, admin)
 */
router.get('/:id',
  authMiddleware.authorize('supervisor', 'admin'),
  studentController.getById
);

/**
 * @route   PUT /api/students/:id
 * @desc    Mettre à jour un étudiant
 * @access  Private (admin only)
 */
router.put('/:id',
  authMiddleware.authorize('admin'),
  validationMiddleware.validateStudentUpdate,
  studentController.update
);

/**
 * @route   DELETE /api/students/:id
 * @desc    Désactiver un étudiant (soft delete)
 * @access  Private (admin only)
 */
router.delete('/:id',
  authMiddleware.authorize('admin'),
  studentController.delete
);

module.exports = router;