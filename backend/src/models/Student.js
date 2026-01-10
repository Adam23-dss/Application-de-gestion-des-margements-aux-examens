const db = require('../config/database');

class Student {
  // Récupérer tous les étudiants (avec filtres)
  static async findAll(page = 1, limit = 20, filters = {}) {
    const offset = (page - 1) * limit;
    
    let query = `
      SELECT id, student_code, first_name, last_name, email, 
             ufr, department, promotion, is_active, created_at
      FROM students 
      WHERE is_active = true
    `;
    
    let countQuery = 'SELECT COUNT(*) FROM students WHERE is_active = true';
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
    
    if (filters.promotion) {
      paramCount++;
      values.push(filters.promotion);
      countValues.push(filters.promotion);
      query += ` AND promotion = $${paramCount}`;
      countQuery += ` AND promotion = $${paramCount}`;
    }
    
    if (filters.search) {
      paramCount++;
      const searchPattern = `%${filters.search}%`;
      values.push(searchPattern);
      countValues.push(searchPattern);
      query += ` AND (
        student_code ILIKE $${paramCount} OR
        first_name ILIKE $${paramCount} OR
        last_name ILIKE $${paramCount} OR
        email ILIKE $${paramCount} OR
        ufr ILIKE $${paramCount} OR
        department ILIKE $${paramCount}
      )`;
      countQuery += ` AND (
        student_code ILIKE $${paramCount} OR
        first_name ILIKE $${paramCount} OR
        last_name ILIKE $${paramCount} OR
        email ILIKE $${paramCount} OR
        ufr ILIKE $${paramCount} OR
        department ILIKE $${paramCount}
      )`;
    }
    
    // Ajouter pagination et tri
    query += ` ORDER BY last_name, first_name 
               LIMIT $${paramCount + 1} OFFSET $${paramCount + 2}`;
    values.push(limit, offset);
    
    try {
      const [studentsResult, countResult] = await Promise.all([
        db.query(query, values),
        db.query(countQuery, countValues)
      ]);
      
      return {
        students: studentsResult.rows,
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total: parseInt(countResult.rows[0].count),
          totalPages: Math.ceil(countResult.rows[0].count / limit)
        }
      };
    } catch (error) {
      console.error('Error in Student.findAll:', error);
      throw error;
    }
  }

  // Trouver par ID
  static async findById(id) {
    try {
      const query = `
        SELECT id, student_code, first_name, last_name, email, 
               ufr, department, promotion, is_active, created_at, updated_at
        FROM students 
        WHERE id = $1 AND is_active = true
      `;
      
      const result = await db.query(query, [id]);
      return result.rows[0];
    } catch (error) {
      console.error('Error in Student.findById:', error);
      throw error;
    }
  }

  // Trouver par code étudiant
  static async findByStudentCode(studentCode) {
    try {
      const query = `
        SELECT id, student_code, first_name, last_name, email, 
               ufr, department, promotion, is_active
        FROM students 
        WHERE student_code = $1 AND is_active = true
      `;
      
      const result = await db.query(query, [studentCode]);
      return result.rows[0];
    } catch (error) {
      console.error('Error in Student.findByStudentCode:', error);
      throw error;
    }
  }

  // Créer un nouvel étudiant
  static async create(studentData) {
    const { student_code, first_name, last_name, email, ufr, department, promotion } = studentData;
    
    try {
      const query = `
        INSERT INTO students (student_code, first_name, last_name, email, ufr, department, promotion)
        VALUES ($1, $2, $3, $4, $5, $6, $7)
        RETURNING id, student_code, first_name, last_name, email, ufr, department, promotion, created_at
      `;
      
      const values = [student_code, first_name, last_name, email, ufr, department, promotion];
      
      const result = await db.query(query, values);
      return result.rows[0];
    } catch (error) {
      console.error('Error in Student.create:', error);
      
      if (error.code === '23505') { // Violation contrainte unique
        if (error.constraint.includes('student_code')) {
          throw new Error('Ce code étudiant existe déjà');
        } else if (error.constraint.includes('email')) {
          throw new Error('Cet email étudiant existe déjà');
        }
      }
      throw error;
    }
  }

  // Mettre à jour un étudiant
  static async update(id, studentData) {
    const { first_name, last_name, email, ufr, department, promotion } = studentData;
    
    try {
      const query = `
        UPDATE students 
        SET first_name = $1, last_name = $2, email = $3, 
            ufr = $4, department = $5, promotion = $6,
            updated_at = CURRENT_TIMESTAMP
        WHERE id = $7 AND is_active = true
        RETURNING id, student_code, first_name, last_name, email, 
                  ufr, department, promotion, updated_at
      `;
      
      const values = [first_name, last_name, email, ufr, department, promotion, id];
      
      const result = await db.query(query, values);
      return result.rows[0];
    } catch (error) {
      console.error('Error in Student.update:', error);
      throw error;
    }
  }

  // Désactiver un étudiant (soft delete)
  static async delete(id) {
    try {
      const query = `
        UPDATE students 
        SET is_active = false, updated_at = CURRENT_TIMESTAMP
        WHERE id = $1
        RETURNING id, student_code
      `;
      
      const result = await db.query(query, [id]);
      return result.rows[0];
    } catch (error) {
      console.error('Error in Student.delete:', error);
      throw error;
    }
  }

  // Rechercher des étudiants (version simplifiée)
  static async search(searchTerm, page = 1, limit = 20) {
    try {
      const result = await this.findAll(page, limit, { search: searchTerm });
      return result;
    } catch (error) {
      console.error('Error in Student.search:', error);
      throw error;
    }
  }

  // Compter les étudiants par UFR
  static async countByUfr() {
    try {
      const query = `
        SELECT ufr, COUNT(*) as count
        FROM students 
        WHERE is_active = true
        GROUP BY ufr
        ORDER BY count DESC
      `;
      
      const result = await db.query(query);
      return result.rows;
    } catch (error) {
      console.error('Error in Student.countByUfr:', error);
      throw error;
    }
  }

  // Récupérer les options uniques pour les filtres
  static async getFilterOptions() {
    try {
      const ufrQuery = 'SELECT DISTINCT ufr FROM students WHERE is_active = true ORDER BY ufr';
      const deptQuery = 'SELECT DISTINCT department FROM students WHERE is_active = true ORDER BY department';
      const promoQuery = 'SELECT DISTINCT promotion FROM students WHERE is_active = true AND promotion IS NOT NULL ORDER BY promotion';
      
      const [ufrResult, deptResult, promoResult] = await Promise.all([
        db.query(ufrQuery),
        db.query(deptQuery),
        db.query(promoQuery)
      ]);
      
      return {
        ufr: ufrResult.rows.map(row => row.ufr),
        departments: deptResult.rows.map(row => row.department),
        promotions: promoResult.rows.map(row => row.promotion)
      };
    } catch (error) {
      console.error('Error in Student.getFilterOptions:', error);
      throw error;
    }
  }
}

module.exports = Student;