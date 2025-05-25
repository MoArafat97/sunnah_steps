import type { LucideIcon } from 'lucide-react';

export interface Habit {
  id: string;
  name: string;
  description: string;
  category: "daily" | "weekly" | "occasional";
  hadith: string;
  benefit: string;
  icon: string; // Name of the Lucide icon
}

export interface UserHabitLog {
  habitId: string;
  date: string; // YYYY-MM-DD format
}

export interface UserProfile {
  id: string;
  name: string;
  email: string;
  goal?: string;
  selectedHabitIds: string[]; // Array of habit IDs
  dailyLogs: UserHabitLog[]; // Log of completed habits
  streak: number; // Current streak in days
  preferences: {
    darkMode: boolean;
    // notifications: boolean; // Future feature
  };
  badges: Array<{
    id: string;
    name: string;
    description: string;
    icon: string; // Name of the Lucide icon
    dateEarned: string; // YYYY-MM-DD
  }>;
}

export type HabitCategory = Habit['category'];
