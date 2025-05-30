import { gql } from 'apollo-server-express';

export const typeDefs = gql`
  # Scalar types
  scalar DateTime

  # Enums
  enum Category {
    daily
    weekly
    occasional
  }

  enum UserRole {
    user
    coach
  }

  enum CompletionSource {
    checklist
    api
  }

  # Time window for habits
  type TimeWindow {
    startHour: Int!
    endHour: Int!
    description: String
  }

  input TimeWindowInput {
    startHour: Int!
    endHour: Int!
    description: String
  }

  # User type
  type User {
    uid: String!
    displayName: String!
    email: String!
    role: UserRole!
    locale: String!
    createdAt: DateTime!
  }

  # Habit type
  type Habit {
    id: String!
    title: String!
    hadithArabic: String!
    hadithEnglish: String!
    benefits: String!
    tags: [String!]!
    category: Category!
    priority: Int!
    contextTags: [String!]!
    lifeEvent: String
    timeWindow: TimeWindow
    createdAt: DateTime!
  }

  # Bundle type
  type Bundle {
    id: String!
    name: String!
    description: String!
    habitIds: [String!]!
    habits: [Habit!]! # Resolved field
    thumbnailUrl: String
    displayOrder: Int!
    createdAt: DateTime!
  }

  # Completion log type
  type CompletionLog {
    id: String!
    habitId: String!
    habit: Habit # Resolved field
    completedAt: DateTime!
    source: CompletionSource!
    note: String
  }

  # Pagination types
  type PageInfo {
    hasNextPage: Boolean!
    hasPreviousPage: Boolean!
    startCursor: String
    endCursor: String
  }

  type HabitsConnection {
    edges: [HabitEdge!]!
    pageInfo: PageInfo!
    totalCount: Int!
  }

  type HabitEdge {
    node: Habit!
    cursor: String!
  }

  type BundlesConnection {
    edges: [BundleEdge!]!
    pageInfo: PageInfo!
    totalCount: Int!
  }

  type BundleEdge {
    node: Bundle!
    cursor: String!
  }

  type CompletionLogsConnection {
    edges: [CompletionLogEdge!]!
    pageInfo: PageInfo!
    totalCount: Int!
  }

  type CompletionLogEdge {
    node: CompletionLog!
    cursor: String!
  }

  # Statistics type
  type CompletionStats {
    totalCompletions: Int!
    completionsThisWeek: Int!
    completionsThisMonth: Int!
    currentStreak: Int!
    longestStreak: Int!
    completionsByCategory: [CategoryStats!]!
    recentCompletions: [CompletionLog!]!
  }

  type CategoryStats {
    category: Category!
    count: Int!
    percentage: Float!
  }

  # Input types for mutations
  input CreateUserInput {
    displayName: String!
    email: String!
    role: UserRole = user
    locale: String = "en"
  }

  input UpdateUserInput {
    displayName: String
    locale: String
  }

  input CreateCompletionInput {
    habitId: String!
    source: CompletionSource = api
    note: String
  }

  input HabitsFilter {
    category: Category
    tags: [String!]
    search: String
  }

  # Query type
  type Query {
    # Habits
    habits(
      filter: HabitsFilter
      first: Int = 50
      after: String
    ): HabitsConnection!
    
    habit(id: String!): Habit
    
    searchHabits(
      query: String!
      limit: Int = 20
    ): [Habit!]!

    # Bundles
    bundles(
      first: Int = 20
      after: String
    ): BundlesConnection!
    
    bundle(id: String!): Bundle
    
    bundleHabits(bundleId: String!): [Habit!]!

    # Users
    user(userId: String!): User
    
    me: User

    # Completions
    completions(
      userId: String!
      habitId: String
      startDate: DateTime
      endDate: DateTime
      first: Int = 50
      after: String
    ): CompletionLogsConnection!
    
    completionStats(userId: String!): CompletionStats!
  }

  # Mutation type
  type Mutation {
    # Users
    createUser(input: CreateUserInput!): User!
    updateUser(userId: String!, input: UpdateUserInput!): User!
    deleteUser(userId: String!): Boolean!

    # Completions
    createCompletion(input: CreateCompletionInput!): CompletionLog!
    deleteCompletion(id: String!): Boolean!
  }

  # Subscription type (for future real-time features)
  type Subscription {
    completionAdded(userId: String!): CompletionLog!
  }
`;
