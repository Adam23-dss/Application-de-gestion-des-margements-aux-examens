// seed.js
require('dotenv').config();
const User = require('./src/models/User');

async function seedUsers() {
  try {
    const users = [
      {
        email: 'admin@univ.fr',
        password: 'password123',
        first_name: 'Admin',
        last_name: 'System',
        role: 'admin',
        ufr: 'Sciences',
        department: 'Informatique'
      },
      {
        email: 'surveillant@univ.fr',
        password: 'password123',
        first_name: 'Jean',
        last_name: 'Dupont',
        role: 'supervisor',
        ufr: 'Sciences',
        department: 'Mathématiques'
      }
    ];

    for (const userData of users) {
      const exists = await User.exists(userData.email);
      if (!exists) {
        await User.create(userData);
        console.log(`Utilisateur ${userData.email} créé`);
      } else {
        console.log(`Utilisateur ${userData.email} existe déjà`);
      }
    }

    console.log('Seed terminé avec succès!');
    process.exit(0);
  } catch (error) {
    console.error('Erreur lors du seed:', error);
    process.exit(1);
  }
}

seedUsers();