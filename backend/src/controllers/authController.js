// src/controllers/authController.js
const User = require('../models/User');
const JWTUtils = require('../utils/jwt');

class AuthController {
  // Inscription d'un nouvel utilisateur
  static async register(req, res, next) {
    try {
      const { email, password, confirmPassword, first_name, last_name, role, ufr, department } = req.body;
      
      // Vérifier si l'utilisateur existe déjà
      const userExists = await User.exists(email);
      if (userExists) {
        return res.status(409).json({
          success: false,
          error: 'USER_EXISTS',
          message: 'Un utilisateur avec cet email existe déjà'
        });
      }
      
      // Créer l'utilisateur
      const userData = {
        email,
        password,
        first_name,
        last_name,
        role: role || 'supervisor',
        ufr,
        department
      };
      
      const user = await User.create(userData);
      
      // Générer les tokens
      const tokens = JWTUtils.generateTokens(user);
      
      // Mettre à jour la dernière connexion
      await User.updateLastLogin(user.id);
      
      // Formater la réponse
      const userResponse = User.formatUserResponse(user);
      
      res.status(201).json({
        success: true,
        message: 'Inscription réussie',
        data: {
          user: userResponse,
          tokens: JWTUtils.formatTokenResponse(tokens)
        }
      });
      
    } catch (error) {
      console.error('Registration error:', error);
      next(error);
    }
  }

  // Connexion utilisateur
  static async login(req, res, next) {
    try {
      const { email, password } = req.body;
      
      // Trouver l'utilisateur
      const user = await User.findByEmail(email);
      
      if (!user) {
        return res.status(401).json({
          success: false,
          error: 'INVALID_CREDENTIALS',
          message: 'Email ou mot de passe incorrect'
        });
      }
      
      // Vérifier si le compte est actif
      if (!user.is_active) {
        return res.status(403).json({
          success: false,
          error: 'ACCOUNT_DISABLED',
          message: 'Ce compte est désactivé'
        });
      }
      
      // Vérifier le mot de passe
      const isPasswordValid = await User.comparePassword(password, user.password);
      
      if (!isPasswordValid) {
        return res.status(401).json({
          success: false,
          error: 'INVALID_CREDENTIALS',
          message: 'Email ou mot de passe incorrect'
        });
      }
      
      // Générer les tokens
      const tokens = JWTUtils.generateTokens(user);
      
      // Mettre à jour la dernière connexion
      await User.updateLastLogin(user.id);
      
      // Formater la réponse
      const userResponse = User.formatUserResponse(user);
      
      res.json({
        success: true,
        message: 'Connexion réussie',
        data: {
          user: userResponse,
          tokens: JWTUtils.formatTokenResponse(tokens)
        }
      });
      
    } catch (error) {
      console.error('Login error:', error);
      next(error);
    }
  }

  // Obtenir le profil utilisateur
  static async getProfile(req, res, next) {
    try {
      const user = await User.findById(req.user.id);
      
      if (!user) {
        return res.status(404).json({
          success: false,
          error: 'USER_NOT_FOUND',
          message: 'Utilisateur non trouvé'
        });
      }
      
      const userResponse = User.formatUserResponse(user);
      
      res.json({
        success: true,
        data: userResponse
      });
      
    } catch (error) {
      console.error('Get profile error:', error);
      next(error);
    }
  }

  // Déconnexion
  static async logout(req, res, next) {
    try {
      res.json({
        success: true,
        message: 'Déconnexion réussie'
      });
      
    } catch (error) {
      console.error('Logout error:', error);
      next(error);
    }
  }
  // Lister les utilisateurs par rôle (admin only)
  static async getUsersByRole(req, res, next) {
    try {
      const { role } = req.params;
      const users = await User.findByRole(role);
      const formattedUsers = users.map(user => User.formatUserResponse(user));
      
      res.json({
        success: true,
        data: formattedUsers
      });
    } catch (error) {
      console.error('Get users by role error:', error);
      next(error);
    }
  }

  // Supprimer un utilisateur (admin only)
  static async deleteUser(req, res, next) {
    try {
      const { id } = req.params;
      const user = await User.findById(id);
      if (!user) {
        return res.status(404).json({
          success: false,
          error: 'USER_NOT_FOUND',
          message: 'Utilisateur non trouvé'
        });
      }
      await User.delete(id);
      res.json({
        success: true,
        message: 'Utilisateur supprimé avec succès'
      });
    } catch (error) {
      console.error('Delete user error:', error);
      next(error);
    }
  }
  // Lister tous les utilisateurs (admin only)
  static async listUsers(req, res, next) {
    try {
      const users = await User.findAll();
      const formattedUsers = users.map(user => User.formatUserResponse(user));
      res.json({
        success: true,
        data: formattedUsers
      });
    } catch (error) {
      console.error('List users error:', error);
      next(error);
    }
  }
  // Details utilisateur par ID
  static async getUserById(req, res, next) {
    try {
      const { id } = req.params;
      const user = await User.findById(id);
      if (!user) {
        return res.status(404).json({
          success: false,
          error: 'USER_NOT_FOUND',
          message: 'Utilisateur non trouvé'
        });
      }
      const userResponse = User.formatUserResponse(user);
      res.json({
        success: true,
        data: userResponse
      });
    } catch (error) {
      console.error('Get user by ID error:', error);
      next(error);
    }
  }
  // Mettre à jour le profil utilisateur
  static async updateProfile(req, res, next) {
    try {
      const { id } = req.user;
      const updateData = req.body;
      const user = await User.updateProfile(id, updateData);
      const userResponse = User.formatUserResponse(user);
      res.json({
        success: true,
        message: 'Profil mis à jour avec succès',
        data: userResponse
      });
    } catch (error) {
      console.error('Update profile error:', error);
      next(error);
    }
  }
  // Changer le mot de passe
  static async changePassword(req, res, next) {
    try {
      const { id } = req.user;
      const { currentPassword, newPassword } = req.body;
      const user = await User.findById(id);
      const isPasswordValid = await User.comparePassword(currentPassword, user.password);
      if (!isPasswordValid) {
        return res.status(400).json({
          success: false,
          error: 'INVALID_PASSWORD',
          message: 'Mot de passe actuel incorrect'
        });
      }
      const hashedPassword = await User.hashPassword(newPassword);
      await User.update(id, { password: hashedPassword });
      res.json({
        success: true,
        message: 'Mot de passe mis à jour avec succès'
      });
    } catch (error) {
      console.error('Change password error:', error);
      next(error);
    }
  }
}

module.exports = AuthController;