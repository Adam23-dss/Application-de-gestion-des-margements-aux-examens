// src/config/database.js
const { Pool } = require('pg');
require('dotenv').config();

// ============================================
// CONFIGURATION DU POOL DE CONNEXIONS
// ============================================
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  // Configuration SSL obligatoire pour Neon.tech
  ssl: process.env.NODE_ENV === 'production' 
    ? { rejectUnauthorized: true } 
    : { rejectUnauthorized: false },
  
  // Optimisations de performance
  max: 20,                    // Nombre maximum de connexions
  idleTimeoutMillis: 30000,   // Fermer les connexions inactives après 30s
  connectionTimeoutMillis: 5000, // Timeout de connexion après 5s
});

// ============================================
// TEST DE CONNEXION
// ============================================
const testConnection = async () => {
  let client;
  try {
    console.log('🔧 Test de connexion à la base de données...');
    
    // Acquérir un client du pool
    client = await pool.connect();
    
    // Test 1 : Connexion basique
    const pingResult = await client.query('SELECT 1 as test');
    if (pingResult.rows[0].test !== 1) {
      throw new Error('Le test de ping a échoué');
    }
    
    // Test 2 : Récupérer l'heure de la base
    const timeResult = await client.query('SELECT NOW() as server_time');
    const dbTime = timeResult.rows[0].server_time;
    
    // Test 3 : Vérifier la version de PostgreSQL
    const versionResult = await client.query('SELECT version()');
    
    console.log('✅ Connexion PostgreSQL réussie !');
    console.log(`📊 Version: ${versionResult.rows[0].version.split(' ')[1]}`);
    console.log(`🕐 Heure DB: ${dbTime.toLocaleString()}`);
    console.log(`📍 Host: ${pool.options.host || 'Neon.tech'}`);
    
    return true;
    
  } catch (error) {
    console.error('❌ ERREUR DE CONNEXION POSTGRESQL:');
    console.error(`   Message: ${error.message}`);
    console.error(`   Code: ${error.code || 'N/A'}`);
    
    console.log('\n🔧 DÉPANNAGE:');
    console.log('   1. Vérifie ta connection string dans .env');
    console.log('   2. Vérifie que Neon.tech est actif (https://console.neon.tech)');
    console.log('   3. Vérifie tes identifiants');
    console.log('   4. Vérifie ta connexion internet');
    
    return false;
    
  } finally {
    // TOUJOURS libérer le client
    if (client) {
      client.release();
    }
  }
};

// ============================================
// ÉVÉNEMENTS DU POOL (logging)
// ============================================
pool.on('connect', () => {
  if (process.env.NODE_ENV === 'development') {
    console.log('🔗 Nouvelle connexion DB établie');
  }
});

pool.on('error', (err) => {
  console.error('💥 Erreur inattendue du pool PostgreSQL:', err.message);
  
  // Ne pas crasher l'app en production
  if (process.env.NODE_ENV === 'production') {
    console.error('Erreur du pool, mais on continue...');
  }
});

pool.on('remove', () => {
  if (process.env.NODE_ENV === 'development') {
    console.log('🔌 Connexion DB fermée');
  }
});

// ============================================
// FONCTION POUR VÉRIFIER L'ÉTAT DU POOL
// ============================================
const checkPoolHealth = async () => {
  try {
    const stats = {
      total: pool.totalCount,
      idle: pool.idleCount,
      waiting: pool.waitingCount
    };
    
    console.log('📊 Statistiques du pool DB:');
    console.log(`   Connexions totales: ${stats.total}`);
    console.log(`   Connexions inactives: ${stats.idle}`);
    console.log(`   Requêtes en attente: ${stats.waiting}`);
    
    return stats;
  } catch (error) {
    console.error('Erreur lors de la vérification du pool:', error);
    return null;
  }
};

// ============================================
// EXPORT DES FONCTIONS
// ============================================
module.exports = {
  // Fonction de base pour exécuter des requêtes
  query: (text, params) => {
    const start = Date.now();
    
    return pool.query(text, params)
      .then((result) => {
        const duration = Date.now() - start;
        if (process.env.NODE_ENV === 'development') {
          console.log(`📝 Requête exécutée en ${duration}ms:`, text.substring(0, 50) + '...');
        }
        return result;
      })
      .catch((error) => {
        console.error('❌ Erreur requête SQL:', {
          query: text.substring(0, 100),
          params,
          error: error.message
        });
        throw error;
      });
  },
  
  // Pour les transactions
  getClient: async () => {
    const client = await pool.connect();
    
    // Ajouter du logging pour le client
    const originalQuery = client.query;
    const originalRelease = client.release;
    
    client.query = (...args) => {
      console.log('🔍 Client query:', args[0].substring(0, 80) + '...');
      return originalQuery.apply(client, args);
    };
    
    client.release = () => {
      console.log('🔄 Client released');
      return originalRelease.apply(client);
    };
    
    return client;
  },
  
  // Pour tester la connexion
  testConnection,
  
  // Pour vérifier l'état du pool
  checkPoolHealth,
  
  // Le pool pour accès direct (rarement nécessaire)
  pool,
  
  // Fermer proprement toutes les connexions
  close: async () => {
    console.log('🛑 Fermeture du pool de connexions...');
    await pool.end();
    console.log('✅ Pool fermé');
  }
};