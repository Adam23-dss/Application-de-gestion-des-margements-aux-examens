const express = require('express');
const router = express.Router();
const courseController = require('../controllers/courseController');
const authMiddleware = require('../middleware/authMiddleware');

// Toutes les routes protégées
router.use(authMiddleware.authenticate);

// GET /api/courses - Liste des cours
router.get('/',
  authMiddleware.authorize('supervisor', 'admin'),
  courseController.getAll
);

// GET /api/courses/filters/options - Options de filtres
router.get('/filters/options',
  authMiddleware.authorize('supervisor', 'admin'),
  courseController.getFilterOptions
);

// GET /api/courses/search - Recherche
router.get('/search',
  authMiddleware.authorize('supervisor', 'admin'),
  courseController.search
);

// GET /api/courses/stats/ufr - Statistiques par UFR
router.get('/stats/ufr',
  authMiddleware.authorize('admin'),
  courseController.getUfrStats
);

// GET /api/courses/code/:code - Par code
router.get('/code/:code',
  authMiddleware.authorize('supervisor', 'admin'),
  courseController.getByCode
);

// POST /api/courses - Créer (admin)
router.post('/',
  authMiddleware.authorize('admin'),
  courseController.create
);

// GET /api/courses/:id - Détails
router.get('/:id',
  authMiddleware.authorize('supervisor', 'admin'),
  courseController.getById
);

// PUT /api/courses/:id - Mettre à jour (admin)
router.put('/:id',
  authMiddleware.authorize('admin'),
  courseController.update
);

// DELETE /api/courses/:id - Supprimer (admin)
router.delete('/:id',
  authMiddleware.authorize('admin'),
  courseController.delete
);

module.exports = router;