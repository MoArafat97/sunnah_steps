"use server";

import { revalidatePath } from 'next/cache';
import { mockUserProfile, mockHabits } from './data'; // Assuming data is mutable for demo
import type { UserHabitLog } from '@/types';

// This is a mock implementation. In a real app, you'd interact with a database.

export async function toggleHabitCompletion(habitId: string, date: string): Promise<{ success: boolean; completed?: boolean, message?: string }> {
  // Simulate finding the user's logs
  const userLogs = mockUserProfile.dailyLogs;
  
  const logIndex = userLogs.findIndex(log => log.habitId === habitId && log.date === date);

  let completed;
  if (logIndex > -1) {
    // Habit was completed, so un-complete it
    userLogs.splice(logIndex, 1);
    completed = false;
  } else {
    // Habit was not completed, so complete it
    userLogs.push({ habitId, date });
    completed = true;
  }

  // Simulate updating streak (very basic)
  // A real streak calculation would be more complex
  const todayStr = new Date().toISOString().split('T')[0];
  const habitsCompletedToday = userLogs.filter(log => log.date === todayStr).length;
  const yesterdayStr = new Date(Date.now() - 86400000).toISOString().split('T')[0];
  const habitsCompletedYesterday = userLogs.filter(log => log.date === yesterdayStr).length;

  if (habitsCompletedToday > 0 && habitsCompletedYesterday > 0) {
    // Potentially increment streak, this logic needs to be robust
  } else if (habitsCompletedToday === 0 && date === todayStr) {
    // Potentially reset streak if today's habits are un-checked
  }
  // For simplicity, we won't update mockUserProfile.streak here.

  revalidatePath('/'); // Revalidate the dashboard page
  revalidatePath('/progress'); // Revalidate progress page
  return { success: true, completed, message: `Habit ${completed ? 'marked as complete' : 'marked as incomplete'}.` };
}

export async function updateUserSelectedHabits(habitId: string, selected: boolean): Promise<{ success: boolean, message?: string }> {
  const index = mockUserProfile.selectedHabitIds.indexOf(habitId);
  if (selected && index === -1) {
    mockUserProfile.selectedHabitIds.push(habitId);
  } else if (!selected && index > -1) {
    mockUserProfile.selectedHabitIds.splice(index, 1);
    // Also remove any logs for this habit if unselected (optional behavior)
    // mockUserProfile.dailyLogs = mockUserProfile.dailyLogs.filter(log => log.habitId !== habitId);
  }
  
  revalidatePath('/habits');
  revalidatePath('/'); // Dashboard might change
  return { success: true, message: `Habit selection updated.` };
}

export async function updateUserName(name: string): Promise<{ success: boolean }> {
  mockUserProfile.name = name;
  revalidatePath('/settings');
  return { success: true };
}

export async function updateUserGoal(goal: string): Promise<{ success: boolean }> {
  mockUserProfile.goal = goal;
  revalidatePath('/settings');
  return { success: true };
}

export async function toggleDarkMode(darkMode: boolean): Promise<{ success: boolean }> {
  mockUserProfile.preferences.darkMode = darkMode;
  // This would typically trigger a client-side theme change as well
  revalidatePath('/settings');
  return { success: true };
}
