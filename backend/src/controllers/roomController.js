const Room = require('../models/Room');

class RoomController {
  // GET /api/rooms - Liste paginée
  static async getAll(req, res, next) {
    try {
      const page = parseInt(req.query.page) || 1;
      const limit = parseInt(req.query.limit) || 20;
      
      const filters = {
        building: req.query.building,
        minCapacity: req.query.minCapacity,
        hasComputer: req.query.hasComputer,
        search: req.query.search
      };
      
      const result = await Room.findAll(page, limit, filters);
      
      res.json({
        success: true,
        data: result.rooms,
        pagination: result.pagination
      });
    } catch (error) {
      next(error);
    }
  }

  // GET /api/rooms/:id - Détails salle
  static async getById(req, res, next) {
    try {
      const room = await Room.findById(req.params.id);
      
      if (!room) {
        return res.status(404).json({
          success: false,
          error: 'ROOM_NOT_FOUND',
          message: 'Salle non trouvée'
        });
      }
      
      res.json({
        success: true,
        data: room
      });
    } catch (error) {
      next(error);
    }
  }

  // GET /api/rooms/code/:code - Par code salle
  static async getByCode(req, res, next) {
    try {
      const room = await Room.findByCode(req.params.code);
      
      if (!room) {
        return res.status(404).json({
          success: false,
          error: 'ROOM_NOT_FOUND',
          message: 'Salle non trouvée'
        });
      }
      
      res.json({
        success: true,
        data: room
      });
    } catch (error) {
      next(error);
    }
  }

  // POST /api/rooms - Créer salle
  static async create(req, res, next) {
    try {
      const { code, name, building, floor, capacity, has_computer } = req.body;
      
      if (!code || !name || !building || !capacity) {
        return res.status(400).json({
          success: false,
          error: 'MISSING_REQUIRED_FIELDS',
          message: 'Code, nom, bâtiment et capacité sont requis'
        });
      }
      
      if (capacity <= 0) {
        return res.status(400).json({
          success: false,
          error: 'INVALID_CAPACITY',
          message: 'La capacité doit être positive'
        });
      }
      
      const roomData = {
        code: code.toUpperCase(),
        name,
        building,
        floor: floor ? parseInt(floor) : null,
        capacity: parseInt(capacity),
        has_computer: Boolean(has_computer)
      };
      
      const room = await Room.create(roomData);
      
      res.status(201).json({
        success: true,
        message: 'Salle créée avec succès',
        data: room
      });
    } catch (error) {
      if (error.message.includes('existe déjà')) {
        return res.status(409).json({
          success: false,
          error: 'DUPLICATE_ROOM',
          message: error.message
        });
      }
      next(error);
    }
  }

  // PUT /api/rooms/:id - Mettre à jour
  static async update(req, res, next) {
    try {
      const { name, building, floor, capacity, has_computer } = req.body;
      
      const roomData = {
        name,
        building,
        floor: floor ? parseInt(floor) : null,
        capacity: capacity ? parseInt(capacity) : undefined,
        has_computer
      };
      
      const room = await Room.update(req.params.id, roomData);
      
      if (!room) {
        return res.status(404).json({
          success: false,
          error: 'ROOM_NOT_FOUND',
          message: 'Salle non trouvée'
        });
      }
      
      res.json({
        success: true,
        message: 'Salle mise à jour avec succès',
        data: room
      });
    } catch (error) {
      next(error);
    }
  }

  // DELETE /api/rooms/:id - Désactiver
  static async delete(req, res, next) {
    try {
      const room = await Room.delete(req.params.id);
      
      if (!room) {
        return res.status(404).json({
          success: false,
          error: 'ROOM_NOT_FOUND',
          message: 'Salle non trouvée'
        });
      }
      
      res.json({
        success: true,
        message: 'Salle désactivée avec succès',
        data: { id: room.id, code: room.code, name: room.name }
      });
    } catch (error) {
      if (error.message.includes('utilisée par des examens')) {
        return res.status(400).json({
          success: false,
          error: 'ROOM_IN_USE',
          message: error.message
        });
      }
      next(error);
    }
  }

  // GET /api/rooms/available - Salles disponibles
  static async getAvailable(req, res, next) {
    try {
      const { capacity, date, start_time, end_time } = req.query;
      
      if (!capacity || !date || !start_time || !end_time) {
        return res.status(400).json({
          success: false,
          error: 'MISSING_REQUIRED_PARAMS',
          message: 'Capacité, date, heure début et fin sont requis'
        });
      }
      
      const rooms = await Room.findAvailable(
        parseInt(capacity),
        date,
        start_time,
        end_time
      );
      
      res.json({
        success: true,
        data: rooms
      });
    } catch (error) {
      next(error);
    }
  }

  // GET /api/rooms/stats/building - Statistiques par bâtiment
  static async getBuildingStats(req, res, next) {
    try {
      const stats = await Room.countByBuilding();
      
      res.json({
        success: true,
        data: stats
      });
    } catch (error) {
      next(error);
    }
  }

  // GET /api/rooms/filters/options - Options de filtres
  static async getFilterOptions(req, res, next) {
    try {
      const options = await Room.getFilterOptions();
      
      res.json({
        success: true,
        data: options
      });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = RoomController;