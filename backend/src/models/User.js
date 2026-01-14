// src/models/User.js
const db = require('../config/database');
const bcrypt = require('bcrypt');

class User {
  // Créer un nouvel utilisateur
  static async create(userData) {
    const { email, password, first_name, last_name, role, ufr, department } = userData;
    
    try {
      // Hash du mot de passe
      const saltRounds = 10;
      const hashedPassword = await bcrypt.hash(password, saltRounds);
      
      const query = `
        INSERT INTO users (email, password, first_name, last_name, role, ufr, department)
        VALUES ($1, $2, $3, $4, $5, $6, $7)
        RETURNING id, email, first_name, last_name, role, ufr, department, is_active, created_at
      `;
      
      const values = [email, hashedPassword, first_name, last_name, role || 'supervisor', ufr, department];
      const result = await db.query(query, values);
      
      return result.rows[0];
      
    } catch (error) {
      if (error.code === '23505') { // Violation de contrainte unique
        throw new Error('Un utilisateur avec cet email existe déjà');
      }
      throw error;
    }
  }

  // Trouver un utilisateur par email
  static async findByEmail(email) {
    try {
      const query = `
        SELECT id, email, password, first_name, last_name, role, ufr, department, 
               is_active, last_login, created_at, updated_at
        FROM users 
        WHERE email = $1
      `;
      
      const result = await db.query(query, [email]);
      return result.rows[0];
      
    } catch (error) {
      throw error;
    }
  }

  // Trouver un utilisateur par ID
  static async findById(id) {
    try {
      const query = `
        SELECT id, email, first_name, last_name, role, ufr, department, 
               is_active, last_login, created_at, updated_at
        FROM users 
        WHERE id = $1 AND is_active = true
      `;
      
      const result = await db.query(query, [id]);
      return result.rows[0];
      
    } catch (error) {
      throw error;
    }
  }

  // Trouver des utilisateurs par rôle
  static async findByRole(role) {
    try {
      const query = `
        SELECT id, email, first_name, last_name, role, ufr, department, 
               is_active, last_login, created_at, updated_at
        FROM users 
        WHERE role = $1 AND is_active = true
      `;
      
      const result = await db.query(query, [role]);
      return result.rows;
      
    } catch (error) {
      throw error;
    }
  }

  // Supprimer un utilisateur (désactivation)
  static async delete(id) {
    try {
      const query = `
        UPDATE users 
        SET is_active = false, updated_at = CURRENT_TIMESTAMP 
        WHERE id = $1
      `;
      await db.query(query, [id]);
      return true;
    } catch (error) {
      throw error;
    }
  }
  // Lister tous les utilisateurs actifs
  static async findAll() {
    try {
      const query = `
        SELECT id, email, first_name, last_name, role, ufr, department, 
               is_active, last_login, created_at, updated_at
        FROM users 
        WHERE is_active = true
      `;
      
      const result = await db.query(query);
      return result.rows;
      
    } catch (error) {
      throw error;
    }
  }

  // Mise à jour du profil utilisateur
  static async updateProfile(id, updateData) {
    const { first_name, last_name, ufr, department } = updateData;
    try {
      const query = `
        UPDATE users
        SET first_name = $1, last_name = $2, ufr = $3, department = $4, updated_at = CURRENT_TIMESTAMP
        WHERE id = $5
        RETURNING id, email, first_name, last_name, role, ufr, department, is_active, last_login, created_at, updated_at
      `;
      
      const values = [first_name || null, last_name || null, ufr || null, department || null, id];
      const result = await db.query(query, values);
      
      return result.rows[0];
      
    } catch (error) {
      throw error;
    }
  }

  // Mettre à jour la dernière connexion
  static async updateLastLogin(userId) {
    try {
      const query = `
        UPDATE users 
        SET last_login = CURRENT_TIMESTAMP 
        WHERE id = $1
      `;
      
      await db.query(query, [userId]);
      return true;
      
    } catch (error) {
      throw error;
    }
  }

  // Comparer un mot de passe avec le hash
  static async comparePassword(plainPassword, hashedPassword) {
    try {
      return await bcrypt.compare(plainPassword, hashedPassword);
    } catch (error) {
      throw error;
    }
  }

  // Vérifier si l'utilisateur existe
  static async exists(email) {
    try {
      const query = 'SELECT EXISTS(SELECT 1 FROM users WHERE email = $1)';
      const result = await db.query(query, [email]);
      return result.rows[0].exists;
    } catch (error) {
      throw error;
    }
  }

  // Formater les données utilisateur pour la réponse
  static formatUserResponse(user) {
    if (!user) return null;
    
    return {
      id: user.id,
      email: user.email,
      firstName: user.first_name,
      lastName: user.last_name,
      fullName: `${user.first_name} ${user.last_name}`,
      role: user.role,
      ufr: user.ufr,
      department: user.department,
      isActive: user.is_active,
      lastLogin: user.last_login,
      createdAt: user.created_at,
      updatedAt: user.updated_at
    };
  }
}

module.exports = User;