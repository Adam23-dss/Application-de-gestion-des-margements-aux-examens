const express = require('express');
const router = express.Router();
const courseController = require('../controllers/courseController');
const authMiddleware = require('../middleware/authMiddleware');

// Toutes les routes protégées
router.use(authMiddleware.authenticateToken);

// GET /api/courses - Liste des cours
router.get('/',
  authMiddleware.authorizeRoles('supervisor', 'admin'),
  courseController.getAll
);

// GET /api/courses/filters/options - Options de filtres
router.get('/filters/options',
  authMiddleware.authorizeRoles('supervisor', 'admin'),
  courseController.getFilterOptions
);

// GET /api/courses/search - Recherche
router.get('/search',
  authMiddleware.authorizeRoles('supervisor', 'admin'),
  courseController.search
);

// GET /api/courses/stats/ufr - Statistiques par UFR
router.get('/stats/ufr',
  authMiddleware.authorizeRoles('admin'),
  courseController.getUfrStats
);

// GET /api/courses/code/:code - Par code
router.get('/code/:code',
  authMiddleware.authorizeRoles('supervisor', 'admin'),
  courseController.getByCode
);

// POST /api/courses - Créer (admin)
router.post('/',
  authMiddleware.authorizeRoles('admin'),
  courseController.create
);

// GET /api/courses/:id - Détails
router.get('/:id',
  authMiddleware.authorizeRoles('supervisor', 'admin'),
  courseController.getById
);

// PUT /api/courses/:id - Mettre à jour (admin)
router.put('/:id',
  authMiddleware.authorizeRoles('admin'),
  courseController.update
);

// DELETE /api/courses/:id - Supprimer (admin)
router.delete('/:id',
  authMiddleware.authorizeRoles('admin'),
  courseController.delete
);

module.exports = router;