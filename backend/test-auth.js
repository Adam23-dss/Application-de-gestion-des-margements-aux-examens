// test-auth.js
const axios = require('axios');

const API_URL = 'http://localhost:5000/api';

async function testAuth() {
  console.log('🧪 Test du système d\'authentification\n');
  
  try {
    // Test 1: Vérifier que le serveur répond
    console.log('1. Test de base du serveur...');
    const baseResponse = await axios.get(`${API_URL}/test`);
    console.log('✅ Serveur actif:', baseResponse.data.message);

    // Test 2: Login avec compte supervisor
    console.log('\n2. Test de connexion supervisor...');
    const loginResponse = await axios.post(`${API_URL}/auth/login`, {
      email: 'surveillant@univ.fr',
      password: 'password123'
    });
    
    console.log('✅ Connexion supervisor réussie!');
    console.log(`   Utilisateur: ${loginResponse.data.data.user.fullName}`);
    console.log(`   Rôle: ${loginResponse.data.data.user.role}`);
    
    const supervisorToken = loginResponse.data.data.tokens.accessToken;
    
    // Test 3: Récupérer le profil avec token
    console.log('\n3. Test récupération profil...');
    const profileResponse = await axios.get(`${API_URL}/auth/profile`, {
      headers: {
        Authorization: `Bearer ${supervisorToken}`
      }
    });
    
    console.log('✅ Profil récupéré!');
    console.log(`   Email: ${profileResponse.data.data.email}`);
    
    // Test 4: Tester la route protégée test-auth
    console.log('\n4. Test route protégée /test-auth...');
    const testAuthResponse = await axios.get(`${API_URL}/auth/test-auth`, {
      headers: {
        Authorization: `Bearer ${supervisorToken}`
      }
    });
    
    console.log('✅ Route protégée accessible!');
    console.log(`   Message: ${testAuthResponse.data.message}`);
    
    // Test 5: Tester la route admin (devrait échouer)
    console.log('\n5. Test accès admin (devrait échouer pour supervisor)...');
    try {
      await axios.get(`${API_URL}/auth/test-admin`, {
        headers: {
          Authorization: `Bearer ${supervisorToken}`
        }
      });
      console.log('❌ Test admin a réussi (inattendu)');
    } catch (error) {
      if (error.response?.status === 403) {
        console.log('✅ Accès admin correctement refusé (403 Forbidden)');
      } else {
        console.log('❌ Erreur inattendue:', error.message);
      }
    }
    
    // Test 6: Rafraîchir le token
    console.log('\n6. Test rafraîchissement token...');
    const refreshToken = loginResponse.data.data.tokens.refreshToken;
    const refreshResponse = await axios.post(`${API_URL}/auth/refresh`, {
      refreshToken
    });
    
    console.log('✅ Token rafraîchi!');
    console.log(`   Nouveau token obtenu`);
    
    // Test 7: Login admin
    console.log('\n7. Test de connexion admin...');
    const adminLoginResponse = await axios.post(`${API_URL}/auth/login`, {
      email: 'admin@univ.fr',
      password: 'password123'
    });
    
    console.log('✅ Connexion admin réussie!');
    console.log(`   Rôle: ${adminLoginResponse.data.data.user.role}`);
    
    const adminToken = adminLoginResponse.data.data.tokens.accessToken;
    
    // Test 8: Tester la route admin (devrait réussir)
    console.log('\n8. Test accès admin avec compte admin...');
    const adminTestResponse = await axios.get(`${API_URL}/auth/test-admin`, {
      headers: {
        Authorization: `Bearer ${adminToken}`
      }
    });
    
    console.log('✅ Accès admin autorisé!');
    console.log(`   Message: ${adminTestResponse.data.message}`);
    
    // Test 9: Login avec mauvais mot de passe
    console.log('\n9. Test connexion échouée (mauvais mot de passe)...');
    try {
      await axios.post(`${API_URL}/auth/login`, {
        email: 'surveillant@univ.fr',
        password: 'mauvaispassword'
      });
      console.log('❌ Connexion a réussi avec mauvais mot de passe (inattendu)');
    } catch (error) {
      if (error.response?.status === 401) {
        console.log('✅ Connexion correctement refusée (401 Unauthorized)');
        console.log(`   Message: ${error.response.data.message}`);
      } else {
        console.log('❌ Erreur inattendue:', error.message);
      }
    }
    
    // Test 10: Inscription nouvel utilisateur
    console.log('\n10. Test inscription nouvel utilisateur...');
    try {
      const randomEmail = `test${Date.now()}@test.com`;
      const registerResponse = await axios.post(`${API_URL}/auth/register`, {
        email: randomEmail,
        password: 'password123',
        confirmPassword: 'password123',
        first_name: 'Test',
        last_name: 'User',
        ufr: 'Sciences',
        department: 'Informatique'
      });
      
      console.log('✅ Inscription réussie!');
      console.log(`   Nouvel utilisateur: ${registerResponse.data.data.user.email}`);
    } catch (error) {
      console.log('⚠️  Inscription échouée:', error.response?.data?.message || error.message);
    }
    
    console.log('\n🎉 ' + '='.repeat(50));
    console.log('✅ TOUS LES TESTS D\'AUTHENTIFICATION SONT TERMINÉS AVEC SUCCÈS!');
    console.log('='.repeat(50));
    
  } catch (error) {
    console.error('\n❌ Erreur pendant les tests:');
    console.error('   Message:', error.message);
    if (error.response) {
      console.error('   Status:', error.response.status);
      console.error('   URL:', error.response.config.url);
      console.error('   Error:', error.response.data.error);
      console.error('   Message:', error.response.data.message);
    }
    console.error('\n💡 Conseil: Vérifie que le serveur tourne (npm run dev)');
  }
}

// Exécuter les tests
testAuth();
/*
  const axios = require('axios');

const API_URL = 'http://localhost:5000/api/auth';

async function testAuth() {
    console.log('🧪 Test des endpoints d\'authentification\n');

    try {
        // Test d'inscription
        console.log('1. Test d\'inscription...');
        const registerData = {
            email: 'test.surveillant@univ.fr',
            password: 'password123',
            name: 'Jean Dupont',
            role: 'supervisor'
        };

        const registerResponse = await axios.post(`${API_URL}/register`, registerData);
        console.log('✅ Inscription réussie:', registerResponse.data.message);
        console.log('   User ID:', registerResponse.data.user.id);
        console.log('   Tokens reçus:', !!registerResponse.data.accessToken);

        // Test de connexion
        console.log('\n2. Test de connexion...');
        const loginData = {
            email: 'test.surveillant@univ.fr',
            password: 'password123'
        };

        const loginResponse = await axios.post(`${API_URL}/login`, loginData);
        console.log('✅ Connexion réussie:', loginResponse.data.message);
        const { accessToken, refreshToken } = loginResponse.data;

        // Test profile avec token
        console.log('\n3. Test récupération profil...');
        const profileResponse = await axios.get(`${API_URL}/profile`, {
            headers: { 'Authorization': `Bearer ${accessToken}` }
        });
        console.log('✅ Profil récupéré:', profileResponse.data.user.email);

        // Test refresh token
        console.log('\n4. Test refresh token...');
        const refreshResponse = await axios.post(`${API_URL}/refresh-token`, {
            refreshToken
        });
        console.log('✅ Token rafraîchi:', !!refreshResponse.data.accessToken);

        // Test avec token invalide
        console.log('\n5. Test token invalide...');
        try {
            await axios.get(`${API_URL}/profile`, {
                headers: { 'Authorization': 'Bearer invalid-token' }
            });
        } catch (error) {
            console.log('✅ Accès refusé (token invalide):', error.response?.data?.error);
        }

        console.log('\n🎉 Tous les tests d\'authentification sont passés avec succès!');

    } catch (error) {
        console.error('❌ Erreur lors des tests:', error.response?.data || error.message);
    }
}

// Exécuter les tests si ce fichier est exécuté directement
if (require.main === module) {
    testAuth();
}

module.exports = testAuth;
*/