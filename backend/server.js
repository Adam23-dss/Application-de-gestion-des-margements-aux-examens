// server.js
const app = require('./src/app');
const http = require('http');
const socketIo = require('socket.io');
const { testConnection } = require('./src/config/database');

require('dotenv').config();

const PORT = process.env.PORT || 5000;

async function startServer() {
  try {
    console.log('='.repeat(50));
    console.log('🚀 DÉMARRAGE SERVEUR ATTENDANCE - JOUR 2');
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
    
    // 2. Créer le serveur HTTP avec l'app Express
    const server = http.createServer(app);
    
    // 3. Configurer WebSocket
    const io = socketIo(server, {
      cors: {
        origin: "*",
        methods: ["GET", "POST"]
      }
    });
    
    // Gestion WebSocket
    io.on('connection', (socket) => {
      console.log('🔌 Nouveau client connecté:', socket.id);
      
      // Rejoindre une salle d'examen
      socket.on('join-exam', (examId) => {
        socket.join(`exam-${examId}`);
        console.log(`📚 Socket ${socket.id} a rejoint la salle exam-${examId}`);
      });
      
      socket.on('disconnect', () => {
        console.log('🔌 Client déconnecté:', socket.id);
      });
    });
    
    // Stocker io dans l'app pour y accéder depuis les contrôleurs
    app.set('io', io);
    
    // 4. Démarrer le serveur
    server.listen(PORT, () => {
      console.log(`📡 Serveur démarré sur: http://localhost:${PORT}`);
      console.log(`🌐 Environnement: ${process.env.NODE_ENV || 'development'}`);
      console.log(`🗄️  Base de données: PostgreSQL (Neon.tech)`);
      console.log(`🔐 Authentification: JWT activée`);
      console.log('='.repeat(50));
      console.log('✅ PRÊT À RECEVOIR DES REQUÊTES');
      console.log('='.repeat(50));
      console.log('📋 Routes AUTH disponibles:');
      console.log('   POST /api/auth/login       - Connexion');
      console.log('   POST /api/auth/register    - Inscription');
      console.log('   POST /api/auth/refresh     - Rafraîchir token');
      console.log('   GET  /api/auth/profile     - Profil (protégé)');
      console.log('   POST /api/auth/logout      - Déconnexion');
      console.log('   GET  /api/auth/test-auth   - Test auth (protégé)');
      console.log('='.repeat(50));
      console.log('👤 Comptes de test:');
      console.log('   Email: admin@univ.fr / Mot de passe: password123');
      console.log('   Email: surveillant@univ.fr / Mot de passe: password123');
      console.log('='.repeat(50));
    });
    
  } catch (error) {
    console.error('💥 ERREUR LORS DU DÉMARRAGE:', error);
    process.exit(1);
  }
}

// Gestion des arrêts propres
process.on('SIGTERM', () => {
  console.log('🛑 Signal SIGTERM reçu, arrêt...');
  process.exit(0);
});

process.on('SIGINT', () => {
  console.log('🛑 Signal SIGINT reçu (Ctrl+C), arrêt...');
  process.exit(0);
});

// Démarrer le serveur
startServer();