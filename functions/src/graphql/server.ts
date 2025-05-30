import { graphql } from 'graphql';
import { Request, Response } from 'express';
import * as admin from 'firebase-admin';
import { typeDefs } from './typeDefs';
import { resolvers } from './resolvers';
import { makeExecutableSchema } from 'graphql-tools';

// Create executable schema
const schema = makeExecutableSchema({
  typeDefs,
  resolvers
});

// Helper function to extract user from request
const getUserFromRequest = async (req: Request): Promise<admin.auth.DecodedIdToken | null> => {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return null;
  }

  const token = authHeader.split('Bearer ')[1];
  try {
    return await admin.auth().verifyIdToken(token);
  } catch (error) {
    console.error('Token verification failed:', error);
    return null;
  }
};

// Export GraphQL handler
export const graphqlHandler = async (req: Request, res: Response) => {
  try {
    // Only allow POST requests for GraphQL
    if (req.method !== 'POST') {
      // For GET requests, return GraphQL Playground in development
      if (req.method === 'GET' && process.env.NODE_ENV !== 'production') {
        res.setHeader('Content-Type', 'text/html');
        res.send(`
          <!DOCTYPE html>
          <html>
          <head>
            <title>GraphQL Playground</title>
            <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/graphql-playground-react/build/static/css/index.css" />
          </head>
          <body>
            <div id="root">
              <style>
                body { margin: 0; font-family: 'Open Sans', sans-serif; }
                #root { height: 100vh; }
              </style>
              <div style="display: flex; align-items: center; justify-content: center; height: 100vh; flex-direction: column;">
                <h1>GraphQL Playground</h1>
                <p>Send POST requests to this endpoint with GraphQL queries</p>
                <p>Example query:</p>
                <pre style="background: #f5f5f5; padding: 10px; border-radius: 4px;">
{
  habits(first: 5) {
    edges {
      node {
        id
        title
        category
        priority
      }
    }
    pageInfo {
      hasNextPage
    }
  }
}
                </pre>
              </div>
            </div>
          </body>
          </html>
        `);
        return;
      }

      res.status(405).json({ error: 'Method not allowed. Use POST for GraphQL queries.' });
      return;
    }

    // Extract GraphQL query from request body
    const { query, variables, operationName } = req.body;

    if (!query) {
      res.status(400).json({ error: 'GraphQL query is required' });
      return;
    }

    // Get user from request
    const user = await getUserFromRequest(req);

    // Execute GraphQL query
    const result = await graphql({
      schema,
      source: query,
      variableValues: variables,
      operationName,
      contextValue: {
        user,
        req
      }
    });

    // Set appropriate status code
    if (result.errors && result.errors.length > 0) {
      res.status(400);
    }

    res.json(result);
  } catch (error) {
    console.error('GraphQL handler error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: process.env.NODE_ENV === 'development' ? (error as Error).message : 'Something went wrong'
    });
  }
};
