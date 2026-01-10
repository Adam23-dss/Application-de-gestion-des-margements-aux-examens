// server.js
const app = require('./src/app');
const http = require('http');
const socketIo = require('socket.io');
const { testConnection } = require('./src/config/database');

require('dotenv').config();

const PORT = process.env.PORT || 5000;

async function startServer() {
  try {
    console.log('='.repeat(60));
    console.log('🚀 DÉMARRAGE SERVEUR ATTENDANCE MANAGEMENT - JOUR 4');
    console.log('='.repeat(60));
    
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
        origin: process.env.FRONTEND_URL || "http://localhost:3000",
        methods: ["GET", "POST"],
        credentials: true
      }
    });
    
    // Gestion WebSocket
    io.on('connection', (socket) => {
      console.log(`🔌 Nouveau client connecté: ${socket.id} (${socket.handshake.address})`);
      
      // Rejoindre une salle d'examen
      socket.on('join-exam', (examId) => {
        socket.join(`exam-${examId}`);
        console.log(`📚 ${socket.id} a rejoint la salle exam-${examId}`);
        
        // Accuser réception
        socket.emit('exam-joined', {
          examId,
          message: `Vous surveillez maintenant l'examen ${examId}`
        });
      });
      
      // Quitter une salle d'examen
      socket.on('leave-exam', (examId) => {
        socket.leave(`exam-${examId}`);
        console.log(`📚 ${socket.id} a quitté la salle exam-${examId}`);
      });
      
      // Authentification WebSocket (optionnel)
      socket.on('authenticate', (token) => {
        // Ici, tu pourrais vérifier le JWT token
        console.log(`🔐 ${socket.id} s'est authentifié`);
        socket.emit('authenticated', { success: true });
      });
      
      // Déconnexion
      socket.on('disconnect', (reason) => {
        console.log(`🔌 Client déconnecté: ${socket.id} (Raison: ${reason})`);
      });
    });
    
    // Stocker io dans l'app pour y accéder depuis les contrôleurs
    app.set('io', io);
    
    // Fonctions utilitaires pour émettre des événements
    app.locals.emitAttendanceUpdate = (examId, data) => {
      io.to(`exam-${examId}`).emit('attendance-updated', {
        ...data,
        timestamp: new Date().toISOString()
      });
    };
    
    app.locals.emitExamStarted = (examId) => {
      io.to(`exam-${examId}`).emit('exam-started', {
        examId,
        startTime: new Date().toISOString()
      });
    };
    
    app.locals.emitExamEnded = (examId) => {
      io.to(`exam-${examId}`).emit('exam-ended', {
        examId,
        endTime: new Date().toISOString()
      });
    };
    
    // 4. Démarrer le serveur
    server.listen(PORT, () => {
      console.log(`📡 Serveur démarré sur: http://localhost:${PORT}`);
      console.log(`🔌 WebSocket actif sur: ws://localhost:${PORT}`);
      console.log(`🌐 Environnement: ${process.env.NODE_ENV || 'development'}`);
      console.log(`🗄️  Base de données: PostgreSQL (Neon.tech)`);
      console.log(`🔐 Authentification: JWT activée`);
      console.log('='.repeat(60));
      console.log('✅ PRÊT À RECEVOIR DES REQUÊTES');
      console.log('='.repeat(60));
      
      console.log('👥 AUTHENTIFICATION:');
      console.log('   POST   /api/auth/register          - Inscription (admin)');
      console.log('   POST   /api/auth/login             - Connexion');
      console.log('   POST   /api/auth/refresh-token     - Rafraîchir token');
      console.log('   GET    /api/auth/profile           - Profil utilisateur');
      console.log('   POST   /api/auth/logout            - Déconnexion');
      console.log('='.repeat(60));
      
      console.log('🎓 GESTION ÉTUDIANTS:');
      console.log('   GET    /api/students               - Liste (paginée)');
      console.log('   GET    /api/students/search        - Recherche');
      console.log('   GET    /api/students/filters/options - Options filtres');
      console.log('   GET    /api/students/code/:code    - Par code étudiant');
      console.log('   GET    /api/students/:id           - Détails');
      console.log('   POST   /api/students               - Créer (admin)');
      console.log('   PUT    /api/students/:id           - Modifier (admin)');
      console.log('   DELETE /api/students/:id           - Désactiver (admin)');
      console.log('   GET    /api/students/stats/ufr     - Stats par UFR (admin)');
      console.log('='.repeat(60));
      
      console.log('📝 GESTION EXAMENS:');
      console.log('   GET    /api/exams                  - Liste (paginée)');
      console.log('   GET    /api/exams/:id              - Détails examen');
      console.log('   POST   /api/exams                  - Créer (admin)');
      console.log('   PUT    /api/exams/:id              - Modifier (admin)');
      console.log('   DELETE /api/exams/:id              - Annuler (admin)');
      console.log('   POST   /api/exams/:id/start        - Démarrer examen');
      console.log('   POST   /api/exams/:id/end          - Terminer examen');
      console.log('   GET    /api/exams/:id/students     - Étudiants inscrits');
      console.log('   POST   /api/exams/:id/students     - Ajouter étudiant (admin)');
      console.log('   DELETE /api/exams/:id/students/:studentId - Retirer étudiant');
      console.log('   GET    /api/exams/:id/statistics   - Statistiques examen');
      console.log('='.repeat(60));
      
      console.log('✅ SYSTÈME DE PRÉSENCE (JOUR 4):');
      console.log('   POST   /api/attendance/validate    - Valider présence');
      console.log('   GET    /api/attendance/exam/:id    - Présences par examen');
      console.log('   GET    /api/attendance/student/:id - Historique étudiant');
      console.log('   PUT    /api/attendance/:id         - Modifier statut présence');
      console.log('   POST   /api/attendance/bulk        - Validation groupée (admin)');
      console.log('   GET    /api/attendance/stats/:id   - Statistiques présence');
      console.log('='.repeat(60));
      
      console.log('🔌 ÉVÉNEMENTS WEBSOCKET:');
      console.log('   attendance-updated  - Présence validée/modifiée');
      console.log('   exam-started        - Examen démarré');
      console.log('   exam-ended          - Examen terminé');
      console.log('   bulk-attendance     - Validation groupée terminée');
      console.log('   join-exam           - Rejoindre une salle');
      console.log('   leave-exam          - Quitter une salle');
      console.log('='.repeat(60));
      
      console.log('📚 GESTION COURS:');

      console.log('='.repeat(60));
      
      console.log('📊 ENDPOINTS UTILITAIRES:');
      console.log('   GET    /health                     - Santé de l\'API');
      console.log('   GET    /api/seed                   - Remplissage DB (dev)');
      console.log('='.repeat(60));
      
      console.log('👤 COMPTES DE TEST:');
      console.log('   🔷 Administrateur:');
      console.log('        Email: admin@univ.fr');
      console.log('        Mot de passe: password123');
      console.log('   🔶 Surveillant:');
      console.log('        Email: surveillant@univ.fr');
      console.log('        Mot de passe: password123');
      console.log('='.repeat(60));
      console.log('💡 CONSEILS:');
      console.log('   1. Toujours inclure: Authorization: Bearer {token}');
      console.log('   2. Pour WebSocket: socket.emit(\'join-exam\', examId)');
      console.log('   3. Tests: node test-attendance.js');
      console.log('='.repeat(60));
    });
    
  } catch (error) {
    console.error('💥 ERREUR LORS DU DÉMARRAGE:', error);
    process.exit(1);
  }
}

// Gestion des arrêts propres
process.on('SIGTERM', () => {
  console.log('🛑 Signal SIGTERM reçu, arrêt propre en cours...');
  console.log('👋 Au revoir !');
  process.exit(0);
});

process.on('SIGINT', () => {
  console.log('🛑 Signal SIGINT reçu (Ctrl+C), arrêt...');
  console.log('👋 À bientôt !');
  process.exit(0);
});

process.on('uncaughtException', (error) => {
  console.error('💥 ERREUR NON GÉRÉE:', error);
  console.log('🔄 Redémarrage recommandé');
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('💥 PROMESSE NON GÉRÉE:', reason);
  console.log('⚠️  Vérifie tes async/await');
});

// Démarrer le serveur
startServer();

module.exports = { startServer }; // Pour les tests