import * as admin from 'firebase-admin';
import * as readline from 'readline';
import fetch from 'node-fetch';

// Initialize Firebase Admin if not already initialized
if (!admin.apps.length) {
  admin.initializeApp();
}

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

function askQuestion(question: string): Promise<string> {
  return new Promise((resolve) => {
    rl.question(question, (answer) => {
      resolve(answer);
    });
  });
}

async function createTestUser(): Promise<{ email: string; password: string; uid: string }> {
  const email = `test-${Date.now()}@example.com`;
  const password = 'testpassword123';

  try {
    const userRecord = await admin.auth().createUser({
      email: email,
      password: password,
      emailVerified: true
    });

    console.log(`✅ Created test user: ${email}`);
    return { email, password, uid: userRecord.uid };
  } catch (error) {
    console.error('❌ Error creating test user:', error);
    throw error;
  }
}

async function createCustomToken(uid: string): Promise<string> {
  try {
    const customToken = await admin.auth().createCustomToken(uid);
    console.log('✅ Created custom token');
    return customToken;
  } catch (error) {
    console.error('❌ Error creating custom token:', error);
    throw error;
  }
}

async function exchangeCustomTokenForIdToken(customToken: string): Promise<string> {
  const apiKey = 'AIzaSyCKyhU_vhIGOHO2jeVF0VUzK1ZYGVFvz9Q'; // From your firebase_options.dart

  try {
    const response = await fetch(`https://identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key=${apiKey}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        token: customToken,
        returnSecureToken: true
      })
    });

    const data = await response.json() as any;

    if (!response.ok) {
      throw new Error(`Failed to exchange token: ${JSON.stringify(data)}`);
    }

    console.log('✅ Exchanged custom token for ID token');
    return data.idToken;
  } catch (error) {
    console.error('❌ Error exchanging token:', error);
    throw error;
  }
}

async function callSeedFunction(idToken: string): Promise<void> {
  const functionUrl = 'https://us-central1-sunnah-steps-82d64.cloudfunctions.net/seedDatabase';

  try {
    const response = await fetch(functionUrl, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${idToken}`,
        'Content-Type': 'application/json'
      },
      body: '{}'
    });

    const data = await response.json();

    if (!response.ok) {
      throw new Error(`Seed function failed: ${JSON.stringify(data)}`);
    }

    console.log('✅ Database seeded successfully!');
    console.log('Response:', JSON.stringify(data, null, 2));
  } catch (error) {
    console.error('❌ Error calling seed function:', error);
    throw error;
  }
}

async function cleanupTestUser(uid: string): Promise<void> {
  try {
    await admin.auth().deleteUser(uid);
    console.log('✅ Cleaned up test user');
  } catch (error) {
    console.error('❌ Error cleaning up test user:', error);
  }
}

async function main() {
  console.log('🌱 Firebase Database Seeding Tool');
  console.log('==================================\n');

  const choice = await askQuestion('Choose an option:\n1. Use existing user credentials\n2. Create temporary test user\nEnter choice (1 or 2): ');

  let idToken: string;
  let testUserUid: string | null = null;

  try {
    if (choice === '1') {
      // Option 1: Use existing user
      const email = await askQuestion('Enter your email: ');
      const password = await askQuestion('Enter your password: ');

      // Sign in with email/password to get ID token
      const apiKey = 'AIzaSyCKyhU_vhIGOHO2jeVF0VUzK1ZYGVFvz9Q';

      const response = await fetch(`https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${apiKey}`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          email: email,
          password: password,
          returnSecureToken: true
        })
      });

      const data = await response.json() as any;

      if (!response.ok) {
        throw new Error(`Authentication failed: ${JSON.stringify(data)}`);
      }

      idToken = data.idToken;
      console.log('✅ Authenticated successfully');

    } else if (choice === '2') {
      // Option 2: Create temporary test user
      const testUser = await createTestUser();
      testUserUid = testUser.uid;

      const customToken = await createCustomToken(testUser.uid);
      idToken = await exchangeCustomTokenForIdToken(customToken);

    } else {
      throw new Error('Invalid choice');
    }

    // Call the seed function
    await callSeedFunction(idToken);

  } catch (error) {
    console.error('❌ Process failed:', error);
  } finally {
    // Cleanup test user if created
    if (testUserUid) {
      await cleanupTestUser(testUserUid);
    }

    rl.close();
  }
}

// Run the script
if (require.main === module) {
  main().catch(console.error);
}
