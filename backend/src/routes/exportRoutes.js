const express = require('express');
const router = express.Router();
const exportController = require('../controllers/exportController');
const authMiddleware = require('../middleware/authMiddleware');

// Toutes les routes protégées
router.use(authMiddleware.authenticate);

/**
 * @route   GET /api/exports/attendance/:id/pdf
 * @desc    Exporter les présences d'un examen en PDF
 * @access  Private (supervisor, admin)
 */
router.get('/attendance/:id/pdf',
  authMiddleware.authorize('supervisor', 'admin'),
  exportController.exportAttendancePDF
);

/**
 * @route   GET /api/exports/attendance/:id/excel
 * @desc    Exporter les présences d'un examen en Excel
 * @access  Private (supervisor, admin)
 */
router.get('/attendance/:id/excel',
  authMiddleware.authorize('supervisor', 'admin'),
  exportController.exportAttendanceExcel
);

/**
 * @route   GET /api/exports/students/pdf
 * @desc    Exporter la liste des étudiants en PDF
 * @access  Private (admin only)
 */
router.get('/students/pdf',
  authMiddleware.authorize('admin'),
  exportController.exportStudentsPDF
);

/**
 * @route   GET /api/exports/students/excel
 * @desc    Exporter la liste des étudiants en Excel
 * @access  Private (admin only)
 */
router.get('/students/excel',
  authMiddleware.authorize('admin'),
  exportController.exportStudentsExcel
);

module.exports = router;