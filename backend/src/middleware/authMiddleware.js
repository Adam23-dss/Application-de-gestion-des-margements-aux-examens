// src/middleware/authMiddleware.js
const JWTUtils = require('../utils/jwt');
const User = require('../models/User');

class AuthMiddleware {
  // Authentifier un utilisateur via JWT
  static async authenticate(req, res, next) {
    try {
      const authHeader = req.headers.authorization;
      
      if (!authHeader) {
        return res.status(401).json({
          success: false,
          error: 'MISSING_TOKEN',
          message: 'Token d\'authentification requis'
        });
      }

      const token = JWTUtils.extractTokenFromHeader(authHeader);
      
      if (!token) {
        return res.status(401).json({
          success: false,
          error: 'INVALID_TOKEN_FORMAT',
          message: 'Format du token invalide. Utilisez: Bearer <token>'
        });
      }

      // Vérifier le token
      const decoded = JWTUtils.verifyAccessToken(token);
      
      if (!decoded) {
        return res.status(401).json({
          success: false,
          error: 'INVALID_TOKEN',
          message: 'Token invalide ou expiré'
        });
      }

      // Vérifier que l'utilisateur existe toujours
      const user = await User.findById(decoded.id);
      
      if (!user) {
        return res.status(401).json({
          success: false,
          error: 'USER_NOT_FOUND',
          message: 'Utilisateur non trouvé'
        });
      }

      if (!user.is_active) {
        return res.status(403).json({
          success: false,
          error: 'USER_INACTIVE',
          message: 'Compte désactivé'
        });
      }

      // Attacher l'utilisateur à la requête
      req.user = {
        id: user.id,
        email: user.email,
        role: user.role,
        ufr: user.ufr,
        department: user.department
      };

      next();
      
    } catch (error) {
      console.error('Authentication middleware error:', error);
      return res.status(500).json({
        success: false,
        error: 'SERVER_ERROR',
        message: 'Erreur interne du serveur'
      });
    }
  }

  // Autoriser seulement certains rôles
  static authorize(...allowedRoles) {
    return (req, res, next) => {
      if (!req.user) {
        return res.status(401).json({
          success: false,
          error: 'UNAUTHORIZED',
          message: 'Authentification requise'
        });
      }

      if (!allowedRoles.includes(req.user.role)) {
        return res.status(403).json({
          success: false,
          error: 'FORBIDDEN',
          message: 'Permissions insuffisantes'
        });
      }

      next();
    };
  }

  // Middleware pour rafraîchir le token
  static async refreshToken(req, res, next) {
    try {
      const { refreshToken } = req.body;

      if (!refreshToken) {
        return res.status(400).json({
          success: false,
          error: 'MISSING_REFRESH_TOKEN',
          message: 'Refresh token requis'
        });
      }

      // Vérifier le refresh token
      const decoded = JWTUtils.verifyRefreshToken(refreshToken);
      
      if (!decoded) {
        return res.status(401).json({
          success: false,
          error: 'INVALID_REFRESH_TOKEN',
          message: 'Refresh token invalide ou expiré'
        });
      }

      // Vérifier que l'utilisateur existe toujours
      const user = await User.findById(decoded.id);
      
      if (!user) {
        return res.status(401).json({
          success: false,
          error: 'USER_NOT_FOUND',
          message: 'Utilisateur non trouvé'
        });
      }

      if (!user.is_active) {
        return res.status(403).json({
          success: false,
          error: 'USER_INACTIVE',
          message: 'Compte désactivé'
        });
      }

      // Générer de nouveaux tokens
      const tokens = JWTUtils.generateTokens(user);
      
      // Mettre à jour la dernière connexion
      await User.updateLastLogin(user.id);

      res.json({
        success: true,
        message: 'Token rafraîchi avec succès',
        data: JWTUtils.formatTokenResponse(tokens)
      });
      
    } catch (error) {
      console.error('Refresh token error:', error);
      next(error);
    }
  }

  // Valider les données de login
  static validateLogin(req, res, next) {
    const { email, password } = req.body;
    
    if (!email || !password) {
      return res.status(400).json({
        success: false,
        error: 'VALIDATION_ERROR',
        message: 'Email et mot de passe sont requis'
      });
    }

    // Validation basique de l'email
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return res.status(400).json({
        success: false,
        error: 'VALIDATION_ERROR',
        message: 'Format d\'email invalide'
      });
    }

    next();
  }

  // Valider les données d'inscription
  static validateRegister(req, res, next) {
    const { email, password, confirmPassword, first_name, last_name } = req.body;
    
    if (!email || !password || !confirmPassword || !first_name || !last_name) {
      return res.status(400).json({
        success: false,
        error: 'VALIDATION_ERROR',
        message: 'Tous les champs sont requis'
      });
    }
    
    // Validation email
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return res.status(400).json({
        success: false,
        error: 'VALIDATION_ERROR',
        message: 'Format d\'email invalide'
      });
    }
    
    // Validation mot de passe
    if (password.length < 6) {
      return res.status(400).json({
        success: false,
        error: 'VALIDATION_ERROR',
        message: 'Le mot de passe doit contenir au moins 6 caractères'
      });
    }
    
    // Confirmation mot de passe
    if (password !== confirmPassword) {
      return res.status(400).json({
        success: false,
        error: 'VALIDATION_ERROR',
        message: 'Les mots de passe ne correspondent pas'
      });
    }
    
    next();
  }
}

module.exports = AuthMiddleware;