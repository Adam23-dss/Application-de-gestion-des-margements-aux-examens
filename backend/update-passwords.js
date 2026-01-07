// update-passwords.js
require('dotenv').config();
const bcrypt = require('bcrypt');
const db = require('./src/config/database');

async function updatePasswords() {
  try {
    const users = [
      {
        email: 'admin@univ.fr',
        password: 'password123'
      },
      {
        email: 'surveillant@univ.fr',
        password: 'password123'
      }
    ];

    for (const user of users) {
      // Générer un nouveau hash
      const saltRounds = 10;
      const hashedPassword = await bcrypt.hash(user.password, saltRounds);
      
      // Mettre à jour dans la base
      const query = 'UPDATE users SET password = $1 WHERE email = $2';
      await db.query(query, [hashedPassword, user.email]);
      
      console.log(`Mot de passe mis à jour pour ${user.email}`);
      console.log(`Nouveau hash: ${hashedPassword}`);
    }

    console.log('Mise à jour terminée!');
    process.exit(0);
  } catch (error) {
    console.error('Erreur:', error);
    process.exit(1);
  }
}

updatePasswords();