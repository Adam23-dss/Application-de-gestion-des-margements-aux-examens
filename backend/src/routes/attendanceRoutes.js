const express = require('express');
const router = express.Router();
const attendanceController = require('../controllers/attendanceController');
const authMiddleware = require('../middleware/authMiddleware');

// Toutes les routes protégées
router.use(authMiddleware.authenticate);

/**
 * @route   POST /api/attendance/validate
 * @desc    Valider une présence
 * @access  Private (supervisor, admin)
 */
router.post('/validate',
  authMiddleware.authorize('supervisor', 'admin'), // CORRECTION: authorize
  attendanceController.validate
);

/**
 * @route   GET /api/attendance/exam/:id
 * @desc    Obtenir les présences d'un examen
 * @access  Private (supervisor, admin)
 */
router.get('/exam/:id',
  authMiddleware.authorize('supervisor', 'admin'), // CORRECTION: authorize
  attendanceController.getByExam
);

/**
 * @route   GET /api/attendance/stats/:examId
 * @desc    Statistiques de présence d'un examen
 * @access  Private (supervisor, admin)
 */
router.get('/stats/:examId',
  authMiddleware.authorize('supervisor', 'admin'), // CORRECTION: authorize
  attendanceController.getStats
);

// // Routes supplémentaires pour plus tard
// router.get('/student/:id', attendanceController.getStudentHistory);
// router.put('/:id', attendanceController.updateStatus);
// router.post('/bulk', attendanceController.bulkValidate);

module.exports = router;