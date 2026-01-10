// backend/test-attendance-fix.js
const axios = require('axios');

async function test() {
  console.log('🔧 Test réparation attendance...');
  
  try {
    // Login
    const login = await axios.post('http://localhost:5000/api/auth/login', {
      email: 'surveillant@univ.fr',
      password: 'password123'
    });
    
    const token = login.data.data.tokens.accessToken;
    console.log('✅ Token obtenu');
    
    // Test 1: Vérifier la route existe
    console.log('\n🔍 Test 1: Vérification route...');
    try {
      const testRes = await axios.get('http://localhost:5000/api/attendance/exam/2', {
        headers: { Authorization: `Bearer ${token}` }
      });
      console.log('✅ Route GET /attendance/exam/:id fonctionne');
    } catch (error) {
      console.log('❌ Route non disponible:', error.response?.status);
      console.log('💡 Vérifie que la route est bien dans app.js');
    }
    
    // Test 2: Valider présence
    console.log('\n🔍 Test 2: Validation présence...');
    try {
      const validateRes = await axios.post('http://localhost:5000/api/attendance/validate', {
        exam_id: 2,
        student_code: 'ETU20240001',
        status: 'present'
      }, {
        headers: { Authorization: `Bearer ${token}` }
      });
      
      console.log('✅ Présence validée!', validateRes.data.message);
      console.log('Data:', validateRes.data.data);
      
    } catch (error) {
      console.log('❌ Erreur validation:', error.response?.data?.message || error.message);
      console.log('Status:', error.response?.status);
      console.log('Data:', error.response?.data);
      
      if (error.response?.status === 500) {
        console.log('\n💡 Problème probable:');
        console.log('1. Vérifie que la table "attendance" existe');
        console.log('2. Vérifie les logs du serveur');
        console.log('3. Vérifie la connexion DB');
      }
    }
    
  } catch (error) {
    console.error('💥 Erreur générale:', error.message);
  }
}

test();