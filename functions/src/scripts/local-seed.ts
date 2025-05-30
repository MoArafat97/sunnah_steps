import * as admin from 'firebase-admin';
import { seedDatabase } from './seed';

// Initialize Firebase Admin if not already initialized
if (!admin.apps.length) {
  admin.initializeApp({
    projectId: 'sunnah-steps-82d64'
  });
}

async function main() {
  console.log('🌱 Starting local database seeding...');
  console.log('=====================================\n');

  try {
    await seedDatabase();
    console.log('\n✅ Database seeding completed successfully!');
  } catch (error) {
    console.error('\n❌ Database seeding failed:', error);
    process.exit(1);
  }
}

// Run the script
if (require.main === module) {
  main().catch(console.error);
}
