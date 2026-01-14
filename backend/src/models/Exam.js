const db = require('../config/database');

class Exam {
  // Récupérer tous les examens
  static async findAll(page = 1, limit = 20, filters = {}) {
    const offset = (page - 1) * limit;
    
    let query = `
      SELECT e.id, e.name, e.description, e.exam_date, e.start_time, e.end_time,
             e.status, e.total_students, e.created_at,
             c.code as course_code, c.name as course_name,
             r.code as room_code, r.name as room_name,
             u.first_name as supervisor_first_name, u.last_name as supervisor_last_name
      FROM exams e
      LEFT JOIN courses c ON e.course_id = c.id
      LEFT JOIN rooms r ON e.room_id = r.id
      LEFT JOIN users u ON e.supervisor_id = u.id
      WHERE 1=1
    `;
    
    let countQuery = `
      SELECT COUNT(*) 
      FROM exams e
      WHERE 1=1
    `;
    
    const values = [];
    const countValues = [];
    let paramCount = 0;
    
    // Ajouter les filtres
    if (filters.status) {
      paramCount++;
      values.push(filters.status);
      countValues.push(filters.status);
      query += ` AND e.status = $${paramCount}`;
      countQuery += ` AND e.status = $${paramCount}`;
    }
    
    if (filters.course_id) {
      paramCount++;
      values.push(filters.course_id);
      countValues.push(filters.course_id);
      query += ` AND e.course_id = $${paramCount}`;
      countQuery += ` AND e.course_id = $${paramCount}`;
    }
    
    if (filters.start_date) {
      paramCount++;
      values.push(filters.start_date);
      countValues.push(filters.start_date);
      query += ` AND e.exam_date >= $${paramCount}`;
      countQuery += ` AND e.exam_date >= $${paramCount}`;
    }
    
    if (filters.end_date) {
      paramCount++;
      values.push(filters.end_date);
      countValues.push(filters.end_date);
      query += ` AND e.exam_date <= $${paramCount}`;
      countQuery += ` AND e.exam_date <= $${paramCount}`;
    }
    
    // Ajouter pagination et tri
    query += ` ORDER BY e.exam_date DESC, e.start_time DESC 
               LIMIT $${paramCount + 1} OFFSET $${paramCount + 2}`;
    values.push(limit, offset);
    
    const [examsResult, countResult] = await Promise.all([
      db.query(query, values),
      db.query(countQuery, countValues)
    ]);
    
    return {
      exams: examsResult.rows,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total: parseInt(countResult.rows[0].count),
        totalPages: Math.ceil(countResult.rows[0].count / limit)
      }
    };
  }

  // Trouver par ID
  static async findById(id) {
    const query = `
      SELECT e.*, 
             c.code as course_code, c.name as course_name,
             r.code as room_code, r.name as room_name, r.capacity,
             u.first_name as supervisor_first_name, u.last_name as supervisor_last_name,
             u.email as supervisor_email
      FROM exams e
      LEFT JOIN courses c ON e.course_id = c.id
      LEFT JOIN rooms r ON e.room_id = r.id
      LEFT JOIN users u ON e.supervisor_id = u.id
      WHERE e.id = $1
    `;
    
    const result = await db.query(query, [id]);
    return result.rows[0];
  }

  // Créer un nouvel examen
  static async create(examData) {
    const { course_id, name, description, exam_date, start_time, end_time, 
            room_id, supervisor_id } = examData;
    
    const query = `
      INSERT INTO exams (course_id, name, description, exam_date, start_time, 
                        end_time, room_id, supervisor_id)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
      RETURNING id, name, exam_date, start_time, end_time, status, created_at
    `;
    
    const values = [course_id, name, description, exam_date, start_time, 
                   end_time, room_id, supervisor_id];
    
    try {
      const result = await db.query(query, values);
      return result.rows[0];
    } catch (error) {
      if (error.code === '23503') { // Violation clé étrangère
        if (error.constraint.includes('course_id')) {
          throw new Error('Cours non trouvé');
        } else if (error.constraint.includes('room_id')) {
          throw new Error('Salle non trouvée');
        } else if (error.constraint.includes('supervisor_id')) {
          throw new Error('Surveillant non trouvé');
        }
      }
      throw error;
    }
  }

  // Mettre à jour un examen
  static async update(id, examData) {
    const fields = [];
    const values = [];
    let paramCount = 0;
    
    // Construire dynamiquement la requête
    for (const [key, value] of Object.entries(examData)) {
      if (value !== undefined) {
        paramCount++;
        fields.push(`${key} = $${paramCount}`);
        values.push(value);
      }
    }
    
    if (fields.length === 0) {
      throw new Error('Aucune donnée à mettre à jour');
    }
    
    // Ajouter updated_at
    fields.push(`updated_at = CURRENT_TIMESTAMP`);
    
    // Ajouter l'ID
    paramCount++;
    values.push(id);
    
    const query = `
      UPDATE exams 
      SET ${fields.join(', ')}
      WHERE id = $${paramCount}
      RETURNING id, name, exam_date, status, updated_at
    `;
    
    const result = await db.query(query, values);
    return result.rows[0];
  }

  // Supprimer un examen (soft delete via status)
  static async delete(id) {
    const query = `
      UPDATE exams 
      SET status = 'cancelled', updated_at = CURRENT_TIMESTAMP
      WHERE id = $1
      RETURNING id, name
    `;
    
    const result = await db.query(query, [id]);
    return result.rows[0];
  }

  // Changer le statut d'un examen
  static async updateStatus(id, status) {
    const query = `
      UPDATE exams 
      SET status = $1, updated_at = CURRENT_TIMESTAMP
      WHERE id = $2
      RETURNING id, name, status
    `;
    
    const result = await db.query(query, [status, id]);
    return result.rows[0];
  }

  // Récupérer les étudiants inscrits à un examen
  static async getStudents(examId) {
    const query = `
      SELECT s.id, s.student_code, s.first_name, s.last_name, s.ufr, s.department,
             er.registration_date,
             a.status as attendance_status, a.validation_time
      FROM exam_registrations er
      JOIN students s ON er.student_id = s.id
      LEFT JOIN attendance a ON a.exam_id = er.exam_id AND a.student_id = er.student_id
      WHERE er.exam_id = $1 AND s.is_active = true
      ORDER BY s.last_name, s.first_name
    `;
    
    const result = await db.query(query, [examId]);
    return result.rows;
  }

  // Ajouter un étudiant à un examen
  static async addStudent(examId, studentId) {
    const query = `
      INSERT INTO exam_registrations (exam_id, student_id)
      VALUES ($1, $2)
      ON CONFLICT (exam_id, student_id) DO NOTHING
      RETURNING id, registration_date
    `;
    
    // Mettre à jour le compteur total_students
    const updateCountQuery = `
      UPDATE exams 
      SET total_students = (
        SELECT COUNT(*) 
        FROM exam_registrations 
        WHERE exam_id = $1
      )
      WHERE id = $1
    `;
    
    try {
      await db.query('BEGIN');
      
      const result = await db.query(query, [examId, studentId]);
      await db.query(updateCountQuery, [examId]);
      
      await db.query('COMMIT');
      return result.rows[0];
    } catch (error) {
      await db.query('ROLLBACK');
      throw error;
    }
  }

  // Retirer un étudiant d'un examen
  static async removeStudent(examId, studentId) {
    const query = `
      DELETE FROM exam_registrations 
      WHERE exam_id = $1 AND student_id = $2
      RETURNING id
    `;
    
    const updateCountQuery = `
      UPDATE exams 
      SET total_students = (
        SELECT COUNT(*) 
        FROM exam_registrations 
        WHERE exam_id = $1
      )
      WHERE id = $1
    `;
    
    try {
      await db.query('BEGIN');
      
      const result = await db.query(query, [examId, studentId]);
      await db.query(updateCountQuery, [examId]);
      
      await db.query('COMMIT');
      return result.rows[0];
    } catch (error) {
      await db.query('ROLLBACK');
      throw error;
    }
  }

  // Statistiques d'un examen
  static async getStatistics(examId) {
    const query = `
      SELECT 
        COUNT(*) as total_students,
        COUNT(CASE WHEN a.status = 'present' THEN 1 END) as present_count,
        COUNT(CASE WHEN a.status = 'absent' THEN 1 END) as absent_count,
        COUNT(CASE WHEN a.status = 'late' THEN 1 END) as late_count,
        COUNT(CASE WHEN a.status = 'excused' THEN 1 END) as excused_count,
        ROUND(
          COUNT(CASE WHEN a.status = 'present' THEN 1 END)::FLOAT / 
          NULLIF(COUNT(*), 0) * 100, 2
        ) as attendance_rate
      FROM exam_registrations er
      LEFT JOIN attendance a ON a.exam_id = er.exam_id AND a.student_id = er.student_id
      WHERE er.exam_id = $1
    `;
    
    const result = await db.query(query, [examId]);
    return result.rows[0];
  }
}

module.exports = Exam;