const db = require('../config/database');

class Room {
  // Récupérer toutes les salles
  static async findAll(page = 1, limit = 20, filters = {}) {
    const offset = (page - 1) * limit;
    
    let query = `
      SELECT id, code, name, building, floor, capacity, has_computer, is_active, created_at
      FROM rooms 
      WHERE is_active = true
    `;
    
    let countQuery = 'SELECT COUNT(*) FROM rooms WHERE is_active = true';
    const values = [];
    const countValues = [];
    let paramCount = 0;
    
    // Ajouter les filtres
    if (filters.building) {
      paramCount++;
      values.push(filters.building);
      countValues.push(filters.building);
      query += ` AND building = $${paramCount}`;
      countQuery += ` AND building = $${paramCount}`;
    }
    
    if (filters.minCapacity) {
      paramCount++;
      values.push(filters.minCapacity);
      countValues.push(filters.minCapacity);
      query += ` AND capacity >= $${paramCount}`;
      countQuery += ` AND capacity >= $${paramCount}`;
    }
    
    if (filters.hasComputer !== undefined) {
      paramCount++;
      values.push(filters.hasComputer);
      countValues.push(filters.hasComputer);
      query += ` AND has_computer = $${paramCount}`;
      countQuery += ` AND has_computer = $${paramCount}`;
    }
    
    if (filters.search) {
      paramCount++;
      const searchPattern = `%${filters.search}%`;
      values.push(searchPattern);
      countValues.push(searchPattern);
      query += ` AND (
        code ILIKE $${paramCount} OR
        name ILIKE $${paramCount} OR
        building ILIKE $${paramCount}
      )`;
      countQuery += ` AND (
        code ILIKE $${paramCount} OR
        name ILIKE $${paramCount} OR
        building ILIKE $${paramCount}
      )`;
    }
    
    // Ajouter pagination et tri
    query += ` ORDER BY building, floor, code LIMIT $${paramCount + 1} OFFSET $${paramCount + 2}`;
    values.push(limit, offset);
    
    try {
      const [roomsResult, countResult] = await Promise.all([
        db.query(query, values),
        db.query(countQuery, countValues)
      ]);
      
      return {
        rooms: roomsResult.rows,
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total: parseInt(countResult.rows[0].count),
          totalPages: Math.ceil(countResult.rows[0].count / limit)
        }
      };
    } catch (error) {
      console.error('Error in Room.findAll:', error);
      throw error;
    }
  }

  // Trouver par ID
  static async findById(id) {
    const query = `
      SELECT id, code, name, building, floor, capacity, has_computer, is_active, created_at
      FROM rooms 
      WHERE id = $1 AND is_active = true
    `;
    
    const result = await db.query(query, [id]);
    return result.rows[0];
  }

  // Trouver par code
  static async findByCode(code) {
    const query = `
      SELECT id, code, name, building, floor, capacity, has_computer, is_active
      FROM rooms 
      WHERE code = $1 AND is_active = true
    `;
    
    const result = await db.query(query, [code]);
    return result.rows[0];
  }

  // Créer une nouvelle salle
  static async create(roomData) {
    const { code, name, building, floor, capacity, has_computer = false } = roomData;
    
    const query = `
      INSERT INTO rooms (code, name, building, floor, capacity, has_computer)
      VALUES ($1, $2, $3, $4, $5, $6)
      RETURNING id, code, name, building, floor, capacity, has_computer, created_at
    `;
    
    const values = [code, name, building, floor, capacity, has_computer];
    
    try {
      const result = await db.query(query, values);
      return result.rows[0];
    } catch (error) {
      if (error.code === '23505') {
        throw new Error('Une salle avec ce code existe déjà');
      }
      throw error;
    }
  }

  // Mettre à jour une salle
  static async update(id, roomData) {
    const { name, building, floor, capacity, has_computer } = roomData;
    
    const query = `
      UPDATE rooms 
      SET name = $1, building = $2, floor = $3, 
          capacity = $4, has_computer = $5
      WHERE id = $6 AND is_active = true
      RETURNING id, code, name, building, floor, capacity, has_computer
    `;
    
    const values = [name, building, floor, capacity, has_computer, id];
    
    const result = await db.query(query, values);
    return result.rows[0];
  }

  // Désactiver une salle (soft delete)
  static async delete(id) {
    const query = `
      UPDATE rooms 
      SET is_active = false
      WHERE id = $1
      RETURNING id, code, name
    `;
    
    // Vérifier qu'aucun examen n'utilise cette salle
    const checkExamsQuery = 'SELECT COUNT(*) FROM exams WHERE room_id = $1';
    const checkResult = await db.query(checkExamsQuery, [id]);
    
    if (parseInt(checkResult.rows[0].count) > 0) {
      throw new Error('Cette salle est utilisée par des examens. Modifiez d\'abord les examens associés.');
    }
    
    const result = await db.query(query, [id]);
    return result.rows[0];
  }

  // Rechercher des salles disponibles pour une capacité et une date
  static async findAvailable(capacity, date, startTime, endTime) {
    const query = `
      SELECT r.*
      FROM rooms r
      WHERE r.is_active = true 
        AND r.capacity >= $1
        AND r.id NOT IN (
          SELECT e.room_id
          FROM exams e
          WHERE e.exam_date = $2
            AND (
              (e.start_time < $4 AND e.end_time > $3) OR
              (e.start_time >= $3 AND e.start_time < $4)
            )
            AND e.status IN ('scheduled', 'in_progress')
        )
      ORDER BY r.capacity, r.building, r.floor
    `;
    
    const values = [capacity, date, startTime, endTime];
    
    const result = await db.query(query, values);
    return result.rows;
  }

  // Compter les salles par bâtiment
  static async countByBuilding() {
    const query = `
      SELECT building, COUNT(*) as count
      FROM rooms 
      WHERE is_active = true
      GROUP BY building
      ORDER BY building
    `;
    
    const result = await db.query(query);
    return result.rows;
  }

  // Obtenir les options de filtres
  static async getFilterOptions() {
    const buildingQuery = 'SELECT DISTINCT building FROM rooms WHERE is_active = true ORDER BY building';
    const capacityQuery = 'SELECT DISTINCT capacity FROM rooms WHERE is_active = true ORDER BY capacity';
    
    const [buildingResult, capacityResult] = await Promise.all([
      db.query(buildingQuery),
      db.query(capacityQuery)
    ]);
    
    return {
      buildings: buildingResult.rows.map(row => row.building),
      capacities: capacityResult.rows.map(row => row.capacity)
    };
  }
}

module.exports = Room;