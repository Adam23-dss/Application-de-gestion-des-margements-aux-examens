const db = require('../config/database');

class Course {
  // Récupérer tous les cours
  static async findAll(page = 1, limit = 20, filters = {}) {
    const offset = (page - 1) * limit;
    
    let query = `
      SELECT id, code, name, ufr, department, credits, description, created_at
      FROM courses 
      WHERE 1=1
    `;
    
    let countQuery = 'SELECT COUNT(*) FROM courses WHERE 1=1';
    const values = [];
    const countValues = [];
    let paramCount = 0;
    
    // Ajouter les filtres
    if (filters.ufr) {
      paramCount++;
      values.push(filters.ufr);
      countValues.push(filters.ufr);
      query += ` AND ufr = $${paramCount}`;
      countQuery += ` AND ufr = $${paramCount}`;
    }
    
    if (filters.department) {
      paramCount++;
      values.push(filters.department);
      countValues.push(filters.department);
      query += ` AND department = $${paramCount}`;
      countQuery += ` AND department = $${paramCount}`;
    }
    
    if (filters.search) {
      paramCount++;
      const searchPattern = `%${filters.search}%`;
      values.push(searchPattern);
      countValues.push(searchPattern);
      query += ` AND (
        code ILIKE $${paramCount} OR
        name ILIKE $${paramCount} OR
        ufr ILIKE $${paramCount} OR
        department ILIKE $${paramCount}
      )`;
      countQuery += ` AND (
        code ILIKE $${paramCount} OR
        name ILIKE $${paramCount} OR
        ufr ILIKE $${paramCount} OR
        department ILIKE $${paramCount}
      )`;
    }
    
    // Ajouter pagination et tri
    query += ` ORDER BY name LIMIT $${paramCount + 1} OFFSET $${paramCount + 2}`;
    values.push(limit, offset);
    
    try {
      const [coursesResult, countResult] = await Promise.all([
        db.query(query, values),
        db.query(countQuery, countValues)
      ]);
      
      return {
        courses: coursesResult.rows,
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total: parseInt(countResult.rows[0].count),
          totalPages: Math.ceil(countResult.rows[0].count / limit)
        }
      };
    } catch (error) {
      console.error('Error in Course.findAll:', error);
      throw error;
    }
  }

  // Trouver par ID
  static async findById(id) {
    const query = `
      SELECT id, code, name, ufr, department, credits, description, created_at
      FROM courses 
      WHERE id = $1
    `;
    
    const result = await db.query(query, [id]);
    return result.rows[0];
  }

  // Trouver par code
  static async findByCode(code) {
    const query = `
      SELECT id, code, name, ufr, department, credits, description
      FROM courses 
      WHERE code = $1
    `;
    
    const result = await db.query(query, [code]);
    return result.rows[0];
  }

  // Créer un nouveau cours
  static async create(courseData) {
    const { code, name, ufr, department, credits, description } = courseData;
    
    const query = `
      INSERT INTO courses (code, name, ufr, department, credits, description)
      VALUES ($1, $2, $3, $4, $5, $6)
      RETURNING id, code, name, ufr, department, credits, description, created_at
    `;
    
    const values = [code, name, ufr, department, credits, description];
    
    try {
      const result = await db.query(query, values);
      return result.rows[0];
    } catch (error) {
      if (error.code === '23505') {
        throw new Error('Un cours avec ce code existe déjà');
      }
      throw error;
    }
  }

  // Mettre à jour un cours
  static async update(id, courseData) {
    const { name, ufr, department, credits, description } = courseData;
    
    const query = `
      UPDATE courses 
      SET name = $1, ufr = $2, department = $3, 
          credits = $4, description = $5
      WHERE id = $6
      RETURNING id, code, name, ufr, department, credits, description
    `;
    
    const values = [name, ufr, department, credits, description, id];
    
    const result = await db.query(query, values);
    return result.rows[0];
  }

  // Supprimer un cours
  static async delete(id) {
    const query = `
      DELETE FROM courses 
      WHERE id = $1
      RETURNING id, code, name
    `;
    
    // Vérifier qu'aucun examen n'utilise ce cours
    const checkExamsQuery = 'SELECT COUNT(*) FROM exams WHERE course_id = $1';
    const checkResult = await db.query(checkExamsQuery, [id]);
    
    if (parseInt(checkResult.rows[0].count) > 0) {
      throw new Error('Ce cours est utilisé par des examens. Supprimez d\'abord les examens associés.');
    }
    
    const result = await db.query(query, [id]);
    return result.rows[0];
  }

  // Rechercher des cours
  static async search(searchTerm, page = 1, limit = 20) {
    const result = await this.findAll(page, limit, { search: searchTerm });
    return result;
  }

  // Compter les cours par UFR
  static async countByUfr() {
    const query = `
      SELECT ufr, COUNT(*) as count
      FROM courses 
      GROUP BY ufr
      ORDER BY count DESC
    `;
    
    const result = await db.query(query);
    return result.rows;
  }

  // Obtenir les options de filtres
  static async getFilterOptions() {
    const ufrQuery = 'SELECT DISTINCT ufr FROM courses ORDER BY ufr';
    const deptQuery = 'SELECT DISTINCT department FROM courses ORDER BY department';
    
    const [ufrResult, deptResult] = await Promise.all([
      db.query(ufrQuery),
      db.query(deptQuery)
    ]);
    
    return {
      ufr: ufrResult.rows.map(row => row.ufr),
      departments: deptResult.rows.map(row => row.department)
    };
  }
}

module.exports = Course;