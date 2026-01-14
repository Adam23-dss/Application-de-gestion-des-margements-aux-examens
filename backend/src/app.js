// src/app.js
const express = require('express');
const cors = require('cors');
require('dotenv').config();

const app = express();

// ============================================
// MIDDLEWARE
// ============================================
app.use(cors({
  origin: process.env.CLIENT_URL || 'http://localhost:3000',
  credentials: true
}));

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// ============================================
// ROUTES DE BASE
// ============================================
app.get('/', (req, res) => {
  res.json({
    success: true,
    message: '🏫 API Gestion des Émargements',
    version: '1.0.0',
    endpoints: {
      auth: '/api/auth',
      students: '/api/students',
      exams: '/api/exams',
      attendance: '/api/attendance'
    }
  });
});

app.get('/api/test', (req, res) => {
  res.json({
    success: true,
    message: '✅ Backend opérationnel',
    timestamp: new Date().toISOString()
  });
});

// ============================================
// IMPORT ET UTILISATION DES ROUTES
// ============================================
const authRoutes = require('./routes/authRoutes');
const studentRoutes = require('./routes/studentRoutes');
const examRoutes = require('./routes/examRoutes');
const attendanceRoutes = require('./routes/attendanceRoutes');
const courseRoutes = require('./routes/courseRoutes');
const roomRoutes = require('./routes/roomRoutes');
const exportRoutes = require('./routes/exportRoutes');
const statsRoutes = require('./routes/statsRoutes');

  
app.use('/api/attendance', attendanceRoutes);
app.use('/api/exams', examRoutes);
app.use('/api/students', studentRoutes);
app.use('/api/auth', authRoutes);
app.use('/api/courses', courseRoutes);
app.use('/api/rooms', roomRoutes);
app.use('/api/exports', exportRoutes);
app.use('/api/stats', statsRoutes);

// ============================================
// ROUTE DE SANTÉ DE LA BASE DE DONNÉES
// ============================================
// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'OK',
    timestamp: new Date().toISOString(),
    service: 'Attendance Management API',
    version: process.env.APP_VERSION || '1.0.0',
    environment: process.env.NODE_ENV || 'development',
    database: 'Connected' // Tu peux vérifier la connexion DB ici
  });
});
app.get('/api/health/db', async (req, res) => {
  try {
    const { testConnection } = require('./config/database');
    const dbHealthy = await testConnection();
    
    res.json({
      success: dbHealthy,
      database: dbHealthy ? 'connected' : 'disconnected',
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// ============================================
// 404 HANDLER (doit être APRÈS toutes les routes)
// ============================================
app.use((req, res) => {
  res.status(404).json({
    success: false,
    error: 'ROUTE_NOT_FOUND',
    message: `Route ${req.method} ${req.originalUrl} non trouvée`,
    availableRoutes: [
      'GET  /',
      'GET  /api/test',
      'GET  /api/health/db',
      'POST /api/auth/login',
      'POST /api/auth/register',
      'POST /api/auth/refresh',
      'GET  /api/auth/profile (protected)',
      'GET  /api/auth/test-auth (protected)',
      'GET  /api/auth/test-admin (admin only)',
      'POST /api/auth/change-password (protected)',
      
      'GET  /api/students (protected)',
      'GET  /api/students/:id (protected)',
      'GET  /api/exams (protected)',
      'GET  /api/exams/:id (protected)',
      'PUT  /api/exams/:id (protected)',
      'POST /api/exams/:id/start (protected)',
      'POST /api/exams/:id/end (protected)',
      'GET  /api/exams/:id/students (protected)',
      'POST /api/attendance/validate (protected)',
      'GET  /api/courses (protected)',
      'GET  /api/courses/:id (protected)',
      'GET  /api/courses/code/:code (protected)',
      'POST /api/courses (protected)',
      'GET  /api/rooms (protected)',
      'GET  /api/rooms/:id (protected)',
      'GET  /api/rooms/code/:code (protected)',
      'POST /api/rooms (protected)',
      'GET  /api/exports/attendance/:id/pdf (protected)',
      'GET  /api/exports/attendance/:id/excel (protected)',
      'GET  /api/stats/dashboard (protected)',
      'GET  /api/stats/daily/:date (protected)'
    ]
  });
});

// ============================================
// ERROR HANDLER GLOBAL
// ============================================
app.use((err, req, res, next) => {
  console.error('🔥 Server Error:', err);
  
  const statusCode = err.statusCode || 500;
  const message = err.message || 'Internal server error';
  
  res.status(statusCode).json({
    success: false,
    error: process.env.NODE_ENV === 'development' ? message : 'Internal server error',
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
  });
});

module.exports = app;