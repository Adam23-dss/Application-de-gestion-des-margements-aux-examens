// src/utils/jwt.js
const jwt = require('jsonwebtoken');
require('dotenv').config();

class JWTUtils {
  // Générer les tokens (access + refresh)
  static generateTokens(user) {
    const userPayload = {
      id: user.id,
      email: user.email,
      role: user.role,
      ufr: user.ufr,
      department: user.department
    };

    const accessToken = jwt.sign(
      userPayload,
      process.env.JWT_SECRET,
      { 
        expiresIn: process.env.JWT_EXPIRES_IN || '24h'
      }
    );

    const refreshToken = jwt.sign(
      { id: user.id },
      process.env.JWT_REFRESH_SECRET,
      { 
        expiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '7d'
      }
    );

    return { accessToken, refreshToken };
  }

  // Vérifier un access token
  static verifyAccessToken(token) {
    try {
      return jwt.verify(token, process.env.JWT_SECRET);
    } catch (error) {
      return null;
    }
  }

  // Vérifier un refresh token
  static verifyRefreshToken(token) {
    try {
      return jwt.verify(token, process.env.JWT_REFRESH_SECRET);
    } catch (error) {
      return null;
    }
  }

  // Extraire le token du header Authorization
  static extractTokenFromHeader(authHeader) {
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return null;
    }
    return authHeader.split(' ')[1];
  }

  // Formater la réponse des tokens
  static formatTokenResponse(tokens) {
    return {
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
      tokenType: 'Bearer',
      expiresIn: process.env.JWT_EXPIRES_IN || '24h'
    };
  }
}

module.exports = JWTUtils;