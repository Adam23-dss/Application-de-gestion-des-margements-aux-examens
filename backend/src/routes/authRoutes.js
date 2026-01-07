// src/routes/authRoutes.js
const express = require('express');
const router = express.Router();
const AuthController = require('../controllers/authController');
const AuthMiddleware = require('../middleware/authMiddleware');

// ============================================
// ROUTES PUBLIQUES (pas d'authentification requise)
// ============================================

// Inscription
router.post(
  '/register',
  AuthMiddleware.validateRegister,
  AuthController.register
);

// Connexion
router.post(
  '/login',
  AuthMiddleware.validateLogin,
  AuthController.login
);

// Rafraîchir le token
router.post(
  '/refresh',
  AuthMiddleware.refreshToken
);

// ============================================
// ROUTES PROTÉGÉES (authentification requise)
// ============================================

// Profil utilisateur
router.get(
  '/profile',
  AuthMiddleware.authenticate,
  AuthController.getProfile
);

// Déconnexion
router.post(
  '/logout',
  AuthMiddleware.authenticate,
  AuthController.logout
);

// ============================================
// ROUTES DE TEST POUR LE DÉVELOPPEMENT
// ============================================

// Route pour tester l'authentification
router.get(
  '/test-auth',
  AuthMiddleware.authenticate,
  (req, res) => {
    res.json({
      success: true,
      message: '✅ Authentification réussie!',
      user: req.user
    });
  }
);

// Route pour tester les rôles admin
router.get(
  '/test-admin',
  AuthMiddleware.authenticate,
  AuthMiddleware.authorize('admin'),
  (req, res) => {
    res.json({
      success: true,
      message: '✅ Accès admin autorisé!',
      user: req.user
    });
  }
);

// Route pour tester les rôles supervisor
router.get(
  '/test-supervisor',
  AuthMiddleware.authenticate,
  AuthMiddleware.authorize('supervisor'),
  (req, res) => {
    res.json({
      success: true,
      message: '✅ Accès supervisor autorisé!',
      user: req.user
    });
  }
);

module.exports = router;