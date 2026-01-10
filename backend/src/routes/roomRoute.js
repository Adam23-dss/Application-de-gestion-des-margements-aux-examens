const express = require('express');
const router = express.Router();
const roomController = require('../controllers/roomController');
const authMiddleware = require('../middleware/authMiddleware');

// Toutes les routes protégées
router.use(authMiddleware.authenticateToken);

// GET /api/rooms - Liste des salles
router.get('/',
  authMiddleware.authorizeRoles('supervisor', 'admin'),
  roomController.getAll
);

// GET /api/rooms/filters/options - Options de filtres
router.get('/filters/options',
  authMiddleware.authorizeRoles('supervisor', 'admin'),
  roomController.getFilterOptions
);

// GET /api/rooms/available - Salles disponibles
router.get('/available',
  authMiddleware.authorizeRoles('supervisor', 'admin'),
  roomController.getAvailable
);

// GET /api/rooms/stats/building - Statistiques par bâtiment
router.get('/stats/building',
  authMiddleware.authorizeRoles('admin'),
  roomController.getBuildingStats
);

// GET /api/rooms/code/:code - Par code
router.get('/code/:code',
  authMiddleware.authorizeRoles('supervisor', 'admin'),
  roomController.getByCode
);

// POST /api/rooms - Créer (admin)
router.post('/',
  authMiddleware.authorizeRoles('admin'),
  roomController.create
);

// GET /api/rooms/:id - Détails
router.get('/:id',
  authMiddleware.authorizeRoles('supervisor', 'admin'),
  roomController.getById
);

// PUT /api/rooms/:id - Mettre à jour (admin)
router.put('/:id',
  authMiddleware.authorizeRoles('admin'),
  roomController.update
);

// DELETE /api/rooms/:id - Désactiver (admin)
router.delete('/:id',
  authMiddleware.authorizeRoles('admin'),
  roomController.delete
);

module.exports = router;