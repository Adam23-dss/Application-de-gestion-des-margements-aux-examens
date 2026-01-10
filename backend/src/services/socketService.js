const socketIO = require('socket.io');

let io;

exports.init = (server) => {
  io = socketIO(server, {
    cors: {
      origin: process.env.FRONTEND_URL || 'http://localhost:3000',
      methods: ['GET', 'POST']
    }
  });

  io.on('connection', (socket) => {
    console.log('🔌 Nouvelle connexion WebSocket:', socket.id);

    // Rejoindre une salle d'examen
    socket.on('join-exam', (examId) => {
      socket.join(`exam-${examId}`);
      console.log(`Socket ${socket.id} a rejoint exam-${examId}`);
    });

    // Quitter une salle d'examen
    socket.on('leave-exam', (examId) => {
      socket.leave(`exam-${examId}`);
      console.log(`Socket ${socket.id} a quitté exam-${examId}`);
    });

    // Déconnexion
    socket.on('disconnect', () => {
      console.log('🔌 Déconnexion WebSocket:', socket.id);
    });
  });

  return io;
};

exports.getIO = () => {
  if (!io) {
    throw new Error('Socket.IO non initialisé');
  }
  return io;
};