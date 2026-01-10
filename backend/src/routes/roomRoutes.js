const express = require('express');
const router = express.Router();
const roomController = require('../controllers/roomController');
const authMiddleware = require('../middleware/authMiddleware');

// Toutes les routes protégées
router.use(authMiddleware.authenticate);

// GET /api/rooms - Liste des salles
router.get('/',
  authMiddleware.authorize('supervisor', 'admin'),
  roomController.getAll
);

// GET /api/rooms/filters/options - Options de filtres
router.get('/filters/options',
  authMiddleware.authorize('supervisor', 'admin'),
  roomController.getFilterOptions
);

// GET /api/rooms/available - Salles disponibles
router.get('/available',
  authMiddleware.authorize('supervisor', 'admin'),
  roomController.getAvailable
);

// GET /api/rooms/stats/building - Statistiques par bâtiment
router.get('/stats/building',
  authMiddleware.authorize('admin'),
  roomController.getBuildingStats
);

// GET /api/rooms/code/:code - Par code
router.get('/code/:code',
  authMiddleware.authorize('supervisor', 'admin'),
  roomController.getByCode
);

// POST /api/rooms - Créer (admin)
router.post('/',
  authMiddleware.authorize('admin'),
  roomController.create
);

// GET /api/rooms/:id - Détails
router.get('/:id',
  authMiddleware.authorize('supervisor', 'admin'),
  roomController.getById
);

// PUT /api/rooms/:id - Mettre à jour (admin)
router.put('/:id',
  authMiddleware.authorize('admin'),
  roomController.update
);

// DELETE /api/rooms/:id - Désactiver (admin)
router.delete('/:id',
  authMiddleware.authorize('admin'),
  roomController.delete
);

module.exports = router;