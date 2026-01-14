const Exam = require('../models/Exam');
const Student = require('../models/Student');
const Attendance = require('../models/Attendance');
const db = require('../config/database');

class StatsController {
  // GET /api/stats/dashboard - Dashboard statistiques
  static async getDashboardStats(req, res, next) {
    try {
      const today = new Date().toISOString().split('T')[0];
      
      const queries = [
        // Total utilisateurs actifs
        db.query("SELECT COUNT(*) FROM users WHERE is_active = true"),
        
        // Total étudiants actifs
        db.query("SELECT COUNT(*) FROM students WHERE is_active = true"),
        
        // Examens aujourd'hui
        db.query("SELECT COUNT(*) FROM exams WHERE exam_date = $1 AND status != 'cancelled'", [today]),
        
        // Examens en cours
        db.query("SELECT COUNT(*) FROM exams WHERE status = 'in_progress'"),
        
        // Présences aujourd'hui
        db.query(`
          SELECT COUNT(DISTINCT a.student_id) 
          FROM attendance a 
          JOIN exams e ON a.exam_id = e.id 
          WHERE DATE(a.validation_time) = $1 
          AND a.status = 'present'
        `, [today]),
        
        // Total examens ce mois
        db.query(`
          SELECT COUNT(*) 
          FROM exams 
          WHERE DATE_TRUNC('month', exam_date) = DATE_TRUNC('month', CURRENT_DATE)
        `)
      ];
      
      const results = await Promise.all(queries);
      
      const stats = {
        totalUsers: parseInt(results[0].rows[0].count),
        totalStudents: parseInt(results[1].rows[0].count),
        todayExams: parseInt(results[2].rows[0].count),
        activeExams: parseInt(results[3].rows[0].count),
        todayPresent: parseInt(results[4].rows[0].count),
        monthlyExams: parseInt(results[5].rows[0].count)
      };
      
      res.json({
        success: true,
        data: stats
      });
      
    } catch (error) {
      next(error);
    }
  }

  // GET /api/stats/exam/:id - Statistiques détaillées examen
  static async getExamStats(req, res) {
    try {
      const examId = req.params.id;

      const query = `
      SELECT
        COUNT(*) AS total,
        SUM(CASE WHEN a.status = 'present' THEN 1 ELSE 0 END) AS present,
        SUM(CASE WHEN a.status = 'absent' THEN 1 ELSE 0 END) AS absent,
        SUM(CASE WHEN a.status = 'late' THEN 1 ELSE 0 END) AS late,
        SUM(CASE WHEN a.status = 'excused' THEN 1 ELSE 0 END) AS excused,
        ROUND(
          SUM(CASE WHEN a.status = 'present' THEN 1 ELSE 0 END)::numeric /
          NULLIF(COUNT(*), 0) * 100,
          2
        ) AS attendance_rate
      FROM exam_registrations er
      LEFT JOIN attendance a ON er.exam_id = a.exam_id
        AND er.student_id = a.student_id
      WHERE er.exam_id = $1
    `;

      const result = await db.query(query, [examId]);

      return res.status(200).json({
        success: true,
        stats: result.rows[0] // <= important
      });

    } catch (err) {
      console.error(err);
      return res.status(500).json({
        success: false,
        error: "SERVER_ERROR",
        message: err.message
      });
    }
  }


  // GET /api/stats/daily/:date? - Statistiques journalières
  static async getDailyStats(req, res, next) {
    try {
      const date = req.params.date || new Date().toISOString().split('T')[0];
      
      const query = `
        SELECT 
          e.id,
          e.name as exam_name,
          e.exam_date,
          e.start_time,
          e.end_time,
          COUNT(DISTINCT er.student_id) as total_students,
          COUNT(DISTINCT CASE WHEN a.status = 'present' THEN a.student_id END) as present_count,
          COUNT(DISTINCT CASE WHEN a.status = 'absent' THEN a.student_id END) as absent_count,
          COUNT(DISTINCT CASE WHEN a.status = 'late' THEN a.student_id END) as late_count,
          COUNT(DISTINCT CASE WHEN a.status = 'excused' THEN a.student_id END) as excused_count
        FROM exams e
        LEFT JOIN exam_registrations er ON e.id = er.exam_id
        LEFT JOIN attendance a ON e.id = a.exam_id AND er.student_id = a.student_id
        WHERE e.exam_date = $1
        GROUP BY e.id, e.name, e.exam_date, e.start_time, e.end_time
        ORDER BY e.start_time
      `;
      
      const result = await db.query(query, [date]);
      
      // Calculer les totaux
      const totals = result.rows.reduce((acc, row) => ({
        totalStudents: acc.totalStudents + parseInt(row.total_students),
        present: acc.present + parseInt(row.present_count),
        absent: acc.absent + parseInt(row.absent_count),
        late: acc.late + parseInt(row.late_count),
        excused: acc.excused + parseInt(row.excused_count)
      }), { totalStudents: 0, present: 0, absent: 0, late: 0, excused: 0 });
      
      res.json({
        success: true,
        data: {
          date,
          exams: result.rows,
          totals,
          attendanceRate: totals.totalStudents > 0 
            ? ((totals.present / totals.totalStudents) * 100).toFixed(1)
            : '0.0'
        }
      });
      
    } catch (error) {
      next(error);
    }
  }

  // GET /api/stats/student/:id - Statistiques étudiant
  static async getStudentStats(req, res, next) {
    try {
      const studentId = req.params.id;
      
      const query = `
        SELECT 
          e.name as exam_name,
          e.exam_date,
          c.name as course_name,
          a.status,
          a.validation_time,
          u.first_name as supervisor_first_name,
          u.last_name as supervisor_last_name
        FROM attendance a
        JOIN exams e ON a.exam_id = e.id
        JOIN courses c ON e.course_id = c.id
        LEFT JOIN users u ON a.supervisor_id = u.id
        WHERE a.student_id = $1
        ORDER BY e.exam_date DESC, a.validation_time DESC
      `;
      
      const result = await db.query(query, [studentId]);
      
      // Calculer les statistiques
      const total = result.rows.length;
      const present = result.rows.filter(r => r.status === 'present').length;
      const absent = result.rows.filter(r => r.status === 'absent').length;
      const late = result.rows.filter(r => r.status === 'late').length;
      const excused = result.rows.filter(r => r.status === 'excused').length;
      
      res.json({
        success: true,
        data: {
          history: result.rows,
          statistics: {
            total,
            present,
            absent,
            late,
            excused,
            presentPercentage: total > 0 ? ((present / total) * 100).toFixed(1) : '0.0',
            attendanceRate: total > 0 ? ((present / total) * 100).toFixed(1) : '0.0'
          }
        }
      });
      
    } catch (error) {
      next(error);
    }
  }

  // GET /api/stats/ufr - Statistiques par UFR
  static async getUfrStats(req, res, next) {
    try {
      const query = `
        SELECT 
          s.ufr,
          COUNT(DISTINCT s.id) as total_students,
          COUNT(DISTINCT CASE WHEN a.status = 'present' THEN a.student_id END) as present_count,
          COUNT(DISTINCT e.id) as total_exams
        FROM students s
        LEFT JOIN exam_registrations er ON s.id = er.student_id
        LEFT JOIN exams e ON er.exam_id = e.id
        LEFT JOIN attendance a ON er.exam_id = a.exam_id AND er.student_id = a.student_id
        WHERE s.is_active = true
        GROUP BY s.ufr
        ORDER BY total_students DESC
      `;
      
      const result = await db.query(query);
      
      res.json({
        success: true,
        data: result.rows
      });
      
    } catch (error) {
      next(error);
    }
  }
}

module.exports = StatsController;