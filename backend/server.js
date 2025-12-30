const express = require('express');
const cors = require('cors');
const { testConnection, checkPoolHealth } = require('./src/config/database');
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
// ROUTES
// ============================================
app.get('/', (req, res) => {
  res.json({ 
    message: '🏫 API Gestion des Émargements', 
    status: 'online',
    version: '1.0.0',
    environment: process.env.NODE_ENV || 'development'
  });
});

app.get('/api/test', (req, res) => {
  res.json({ 
    success: true, 
    message: '✅ Backend opérationnel',
    timestamp: new Date().toISOString(),
    service: 'attendance-api'
  });
});

// Route pour vérifier l'état de la DB
app.get('/api/health/db', async (req, res) => {
  try {
    const dbHealthy = await testConnection();
    const poolStats = await checkPoolHealth();
    
    res.json({
      success: dbHealthy,
      database: dbHealthy ? 'connected' : 'disconnected',
      pool: poolStats,
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
// DÉMARRAGE DU SERVEUR
// ============================================
const PORT = process.env.PORT || 5000;

async function startServer() {
  try {
    console.log('='.repeat(50));
    console.log('🚀 DÉMARRAGE SERVEUR ATTENDANCE');
    console.log('='.repeat(50));
    
    // 1. Tester la connexion DB
    console.log('🔧 Test de connexion à la base de données...');
    const dbConnected = await testConnection();
    
    if (!dbConnected) {
      console.error('❌ IMPOSSIBLE DE DÉMARRER: Base de données non disponible');
      console.log('💡 Vérifie:');
      console.log('   - Ton fichier .env (DATABASE_URL)');
      console.log('   - Que Neon.tech est actif');
      console.log('   - Tes identifiants');
      process.exit(1);
    }
    
    // 2. Démarrer le serveur Express
    app.listen(PORT, () => {
      console.log(`📡 Serveur démarré sur: http://localhost:${PORT}`);
      console.log(`🌐 Environnement: ${process.env.NODE_ENV || 'development'}`);
      console.log(`🗄️  Base de données: PostgreSQL (Neon.tech)`);
      console.log('='.repeat(50));
      console.log('✅ PRÊT À RECEVOIR DES REQUÊTES');
      console.log('='.repeat(50));
    });
    
  } catch (error) {
    console.error('💥 ERREUR LORS DU DÉMARRAGE:', error);
    process.exit(1);
  }
}

// Gestion des arrêts propres
process.on('SIGTERM', async () => {
  console.log('🛑 Signal SIGTERM reçu, arrêt propre...');
  const { close } = require('./src/config/database');
  await close();
  process.exit(0);
});

process.on('SIGINT', async () => {
  console.log('🛑 Signal SIGINT reçu (Ctrl+C), arrêt propre...');
  const { close } = require('./src/config/database');
  await close();
  process.exit(0);
});

// Démarrer le serveur
startServer();