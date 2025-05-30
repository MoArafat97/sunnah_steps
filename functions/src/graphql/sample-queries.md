# GraphQL Sample Queries for Sunnah Steps API

## Authentication
All queries require a Firebase ID token in the Authorization header:
```
Authorization: Bearer <firebase-id-token>
```

## Sample Queries

### 1. Get Habits with Pagination
```graphql
query GetHabits($first: Int, $category: Category) {
  habits(first: $first, filter: { category: $category }) {
    edges {
      node {
        id
        title
        category
        priority
        tags
        hadithEnglish
        benefits
      }
      cursor
    }
    pageInfo {
      hasNextPage
      hasPreviousPage
      startCursor
      endCursor
    }
    totalCount
  }
}
```

Variables:
```json
{
  "first": 10,
  "category": "daily"
}
```

### 2. Get Single Habit
```graphql
query GetHabit($id: String!) {
  habit(id: $id) {
    id
    title
    hadithArabic
    hadithEnglish
    benefits
    tags
    category
    priority
    contextTags
    timeWindow {
      startHour
      endHour
      description
    }
    createdAt
  }
}
```

Variables:
```json
{
  "id": "h21"
}
```

### 3. Search Habits
```graphql
query SearchHabits($query: String!, $limit: Int) {
  searchHabits(query: $query, limit: $limit) {
    id
    title
    category
    priority
    tags
    benefits
  }
}
```

Variables:
```json
{
  "query": "prayer",
  "limit": 5
}
```

### 4. Get Bundles with Habits
```graphql
query GetBundles($first: Int) {
  bundles(first: $first) {
    edges {
      node {
        id
        name
        description
        displayOrder
        habits {
          id
          title
          category
          priority
        }
      }
    }
    pageInfo {
      hasNextPage
    }
    totalCount
  }
}
```

Variables:
```json
{
  "first": 5
}
```

### 5. Get Bundle with Habits
```graphql
query GetBundle($id: String!) {
  bundle(id: $id) {
    id
    name
    description
    displayOrder
    habits {
      id
      title
      hadithEnglish
      benefits
      category
      priority
    }
  }
}
```

Variables:
```json
{
  "id": "bundle_morning"
}
```

### 6. Get User Profile
```graphql
query GetMe {
  me {
    uid
    displayName
    email
    role
    locale
    createdAt
  }
}
```

### 7. Get User Completions
```graphql
query GetCompletions($userId: String!, $first: Int, $habitId: String) {
  completions(userId: $userId, first: $first, habitId: $habitId) {
    edges {
      node {
        id
        habitId
        habit {
          title
          category
        }
        completedAt
        source
        note
      }
    }
    pageInfo {
      hasNextPage
    }
    totalCount
  }
}
```

Variables:
```json
{
  "userId": "your-user-id",
  "first": 10
}
```

### 8. Get Completion Statistics
```graphql
query GetCompletionStats($userId: String!) {
  completionStats(userId: $userId) {
    totalCompletions
    completionsThisWeek
    completionsThisMonth
    currentStreak
    longestStreak
    completionsByCategory {
      category
      count
      percentage
    }
    recentCompletions {
      id
      habitId
      habit {
        title
      }
      completedAt
      source
    }
  }
}
```

Variables:
```json
{
  "userId": "your-user-id"
}
```

## Sample Mutations

### 1. Create User
```graphql
mutation CreateUser($input: CreateUserInput!) {
  createUser(input: $input) {
    uid
    displayName
    email
    role
    locale
    createdAt
  }
}
```

Variables:
```json
{
  "input": {
    "displayName": "John Doe",
    "email": "john@example.com",
    "role": "user",
    "locale": "en"
  }
}
```

### 2. Update User
```graphql
mutation UpdateUser($userId: String!, $input: UpdateUserInput!) {
  updateUser(userId: $userId, input: $input) {
    uid
    displayName
    email
    role
    locale
    createdAt
  }
}
```

Variables:
```json
{
  "userId": "your-user-id",
  "input": {
    "displayName": "John Smith",
    "locale": "ar"
  }
}
```

### 3. Create Completion
```graphql
mutation CreateCompletion($input: CreateCompletionInput!) {
  createCompletion(input: $input) {
    id
    habitId
    habit {
      title
      category
    }
    completedAt
    source
    note
  }
}
```

Variables:
```json
{
  "input": {
    "habitId": "h21",
    "source": "api",
    "note": "Completed after Fajr prayer"
  }
}
```

### 4. Delete Completion
```graphql
mutation DeleteCompletion($id: String!) {
  deleteCompletion(id: $id)
}
```

Variables:
```json
{
  "id": "completion-id"
}
```

## Error Handling

GraphQL errors will be returned in the `errors` array:

```json
{
  "data": null,
  "errors": [
    {
      "message": "Authentication required",
      "code": "UNAUTHENTICATED",
      "path": ["habits"]
    }
  ]
}
```

Common error codes:
- `UNAUTHENTICATED`: Missing or invalid authentication token
- `FORBIDDEN`: User doesn't have permission for this operation
- `BAD_USER_INPUT`: Invalid input data
- `INTERNAL_ERROR`: Server error
