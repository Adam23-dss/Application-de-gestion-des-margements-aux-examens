const express = require('express');
const router = express.Router();
const statsController = require('../controllers/statsController');
const authMiddleware = require('../middleware/authMiddleware');

// Toutes les routes protégées
router.use(authMiddleware.authenticate); // CORRECTION: authenticateToken

/**
 * @route   GET /api/stats/dashboard
 * @desc    Statistiques globales du dashboard
 * @access  Private (supervisor, admin)
 */
router.get('/dashboard',
  authMiddleware.authorize('supervisor', 'admin'), // CORRECTION: authorize
  statsController.getDashboardStats
);

/**
 * @route   GET /api/stats/exam/:id
 * @desc    Statistiques détaillées d'un examen
 * @access  Private (supervisor, admin)
 */
router.get('/exam/:id',
  authMiddleware.authorize('supervisor', 'admin'), // CORRECTION: authorize
  statsController.getExamStats
);

/**
 * @route   GET /api/stats/daily
 * @route   GET /api/stats/daily/:date
 * @desc    Statistiques journalières (date optionnelle)
 * @access  Private (supervisor, admin)
 */
router.get('/daily', // Route sans paramètre
  authMiddleware.authorize('supervisor', 'admin'), // CORRECTION: authorize
  statsController.getDailyStats
);

router.get('/daily/:date', // Route avec paramètre
  authMiddleware.authorize('supervisor', 'admin'), // CORRECTION: authorize
  statsController.getDailyStats
);

/**
 * @route   GET /api/stats/student/:id
 * @desc    Statistiques d'un étudiant
 * @access  Private (supervisor, admin)
 */
router.get('/student/:id',
  authMiddleware.authorize('supervisor', 'admin'), // CORRECTION: authorize
  statsController.getStudentStats
);

/**
 * @route   GET /api/stats/ufr
 * @desc    Statistiques par UFR
 * @access  Private (admin only)
 */
router.get('/ufr',
  authMiddleware.authorize('admin'), // CORRECTION: authorize
  statsController.getUfrStats
);

module.exports = router;