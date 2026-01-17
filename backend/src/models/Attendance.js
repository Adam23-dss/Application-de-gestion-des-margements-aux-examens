const db = require("../config/database");

class Attendance {
  // Valider une présence
  static async validate(data) {
    const {
      exam_id,
      student_id,
      supervisor_id,
      status = "present",
      validation_method = "manual",
    } = data;

    const query = `
      INSERT INTO attendance (exam_id, student_id, supervisor_id, status, validation_method, validation_time)
      VALUES ($1, $2, $3, $4, $5, CURRENT_TIMESTAMP)
      ON CONFLICT (exam_id, student_id) 
      DO UPDATE SET 
        status = $4,
        supervisor_id = $3,
        validation_method = $5,
        validation_time = CURRENT_TIMESTAMP,
        updated_at = CURRENT_TIMESTAMP
      RETURNING id, exam_id, student_id, status, validation_time, validation_method
    `;

    const values = [
      exam_id,
      student_id,
      supervisor_id,
      status,
      validation_method,
    ];

    try {
      const result = await db.query(query, values);
      return result.rows[0];
    } catch (error) {
      console.error("Attendance.validate error:", error);

      if (error.code === "23503") {
        if (error.constraint.includes("exam_id"))
          throw new Error("Examen non trouvé");
        if (error.constraint.includes("student_id"))
          throw new Error("Étudiant non trouvé");
        if (error.constraint.includes("supervisor_id"))
          throw new Error("Surveillant non trouvé");
      }
      throw error;
    }
  }

  // Récupérer les présences d'un examen
  static async findByExam(examId) {
    try {
      const query = `
      SELECT 
        a.*,
        CONCAT(s.first_name, ' ', s.last_name) as student_name,
        s.student_code,
        s.email as student_email
      FROM attendance a
      LEFT JOIN students s ON a.student_id = s.id
      WHERE a.exam_id = $1
      ORDER BY 
        CASE 
          WHEN a.status = 'present' THEN 1
          WHEN a.status = 'late' THEN 2
          WHEN a.status = 'excused' THEN 3
          ELSE 4
        END,
        a.validation_time DESC
    `;

      const result = await db.query(query, [examId]);
      return result.rows;
    } catch (error) {
      console.error("Error in findByExam:", error);
      throw error;
    }
  }

  // Statistiques de présence
  static async getStats(examId) {
    const query = `
      SELECT 
        COUNT(*) as total,
        COUNT(CASE WHEN status = 'present' THEN 1 END) AS present,
        SUM(CASE WHEN status = 'absent' THEN 1 END) AS absent,
        SUM(CASE WHEN status = 'late' THEN 1 END) AS late,
        SUM(CASE WHEN status = 'excused' THEN 1 END) AS excused,
        ROUND(
          (COUNT(CASE WHEN status = 'present' THEN 1 END)::numeric / 
          NULLIF(COUNT(*), 0)::numeric) * 100, 2
        ) as attendance_rate
      FROM attendance 
      WHERE exam_id = $1
    `;

    const result = await db.query(query, [examId]);
    return result.rows[0];
  }
}

module.exports = Attendance;
