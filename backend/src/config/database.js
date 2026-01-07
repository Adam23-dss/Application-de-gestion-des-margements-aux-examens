// src/config/database.js
const { Pool } = require('pg');
require('dotenv').config();

// Configuration du pool de connexions PostgreSQL
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
  // Augmente les timeouts
  connectionTimeoutMillis: 10000, // 10 secondes au lieu de 5
  idleTimeoutMillis: 60000, // 1 minute
  max: 10 // Réduit le nombre max de connexions
});
// Test de connexion au démarrage
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

// Événements du pool
pool.on('connect', () => {
  if (process.env.NODE_ENV === 'development') {
    console.log('🔗 Nouvelle connexion DB établie');
  }
});

pool.on('error', (err) => {
  console.error('💥 Erreur inattendue du pool PostgreSQL:', err.message);
});

// Fonctions exportées
module.exports = {
  query: (text, params) => pool.query(text, params),
  getClient: async () => {
    const client = await pool.connect();
    return client;
  },
  testConnection,
  pool
};