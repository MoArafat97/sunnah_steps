import { Timestamp } from 'firebase-admin/firestore';

// Time window interface matching the Flutter model
export interface TimeWindow {
  startHour: number; // 0-23
  endHour: number;   // 0-23
  description?: string;
}

// User document interface
export interface User {
  uid: string;
  displayName: string;
  email: string;
  role: 'user' | 'coach';
  locale: string;
  createdAt: Timestamp;
}

// Habit document interface
export interface Habit {
  id: string;
  title: string;
  hadithArabic: string;
  hadithEnglish: string;
  benefits: string;
  tags: string[];
  category: 'daily' | 'weekly' | 'occasional';
  priority: number; // 1-10, higher = more important
  contextTags: string[];
  lifeEvent?: string;
  timeWindow?: TimeWindow;
  createdAt: Timestamp;
}

// Bundle document interface
export interface Bundle {
  id: string;
  name: string;
  description: string;
  habitIds: string[];
  thumbnailUrl?: string;
  displayOrder: number;
  createdAt: Timestamp;
}

// Completion log document interface (subcollection under users)
export interface CompletionLog {
  id: string;
  habitId: string;
  completedAt: Timestamp;
  source: 'checklist' | 'api';
  note?: string;
}

// Request/Response DTOs for API
export interface CreateUserRequest {
  displayName: string;
  email: string;
  role?: 'user' | 'coach';
  locale?: string;
}

export interface CreateCompletionRequest {
  habitId: string;
  source: 'checklist' | 'api';
  note?: string;
}

export interface HabitsQueryParams {
  category?: string;
  tags?: string[];
  limit?: number;
  offset?: number;
}

export interface BundlesQueryParams {
  limit?: number;
  offset?: number;
}

export interface CompletionLogQueryParams {
  habitId?: string;
  startDate?: string; // ISO date string
  endDate?: string;   // ISO date string
  limit?: number;
  offset?: number;
}

// API Response wrappers
export interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
  message?: string;
}

export interface PaginatedResponse<T> {
  items: T[];
  total: number;
  limit: number;
  offset: number;
  hasMore: boolean;
}
