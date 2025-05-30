const fetch = (...args) => import('node-fetch').then(({default: fetch}) => fetch(...args));

async function testGraphQL() {
  const url = 'https://us-central1-sunnah-steps-82d64.cloudfunctions.net/api/graphql';

  // Test 1: Simple introspection query (should work without auth for schema info)
  const introspectionQuery = {
    query: `
      query IntrospectionQuery {
        __schema {
          types {
            name
            kind
          }
        }
      }
    `
  };

  try {
    console.log('🧪 Testing GraphQL Introspection...');
    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(introspectionQuery)
    });

    const result = await response.json();
    console.log('✅ GraphQL endpoint is working!');
    console.log('Status:', response.status);
    console.log('Response:', JSON.stringify(result, null, 2));

    if (result.data && result.data.__schema) {
      console.log('\n📋 Available Types:');
      result.data.__schema.types
        .filter(type => !type.name.startsWith('__'))
        .slice(0, 10)
        .forEach(type => {
          console.log(`  - ${type.name} (${type.kind})`);
        });
    }

  } catch (error) {
    console.error('❌ Error testing GraphQL:', error.message);
  }

  // Test 2: Try a query that requires authentication (should fail gracefully)
  const habitsQuery = {
    query: `
      query GetHabits {
        habits(first: 3) {
          edges {
            node {
              id
              title
              category
            }
          }
        }
      }
    `
  };

  try {
    console.log('\n🔒 Testing authenticated query (should fail)...');
    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(habitsQuery)
    });

    const result = await response.json();
    console.log('Status:', response.status);
    console.log('Response:', JSON.stringify(result, null, 2));

    if (result.errors) {
      console.log('✅ Authentication is working (query properly rejected)');
    }

  } catch (error) {
    console.error('❌ Error testing authenticated query:', error.message);
  }
}

testGraphQL().catch(console.error);
