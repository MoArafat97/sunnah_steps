import type { Habit, UserProfile, HabitCategory } from '@/types';
// Import Lucide icons explicitly if they are used by name in mockUserProfile badges
// For this example, Moon and BookOpen are used. Add others if needed.
import { Moon, BookOpen } from 'lucide-react'; 


export const mockHabits: Habit[] = [
  {
    id: '1',
    name: 'Miswak (Siwak)',
    description: 'Cleaning teeth with a natural twig.',
    category: 'daily',
    hadith: 'The Prophet (ﷺ) said, "Siwak cleanses the mouth and pleases the Lord."',
    benefit: 'Promotes oral hygiene and earns divine pleasure.',
    icon: 'TreePalm',
  },
  {
    id: '2',
    name: 'Tahajjud Prayer',
    description: 'Voluntary night prayer.',
    category: 'daily',
    hadith: 'The Prophet (ﷺ) said, "The best prayer after the obligatory prayers is the night prayer."',
    benefit: 'Brings one closer to Allah, grants peace and tranquility.',
    icon: 'Moon',
  },
  {
    id: '3',
    name: 'Recite Quran',
    description: 'Reading a portion of the Quran daily.',
    category: 'daily',
    hadith: 'The Prophet (ﷺ) said, "Read the Quran, for it will come as an intercessor for its reciters on the Day of Resurrection."',
    benefit: 'Guidance, spiritual enlightenment, and reward.',
    icon: 'BookOpen',
  },
  {
    id: '4',
    name: 'Dhikr (Remembrance of Allah)',
    description: 'Engaging in remembrance of Allah (e.g., SubhanAllah, Alhamdulillah, Allahu Akbar).',
    category: 'daily',
    hadith: 'The Prophet (ﷺ) said, "Shall I not tell you of the best of your deeds...?" (mentioning Dhikr)',
    benefit: 'Peace of heart, increases faith, and forgiveness of sins.',
    icon: 'Droplets', 
  },
  {
    id: '5',
    name: 'Smile / Good Character',
    description: 'Being cheerful and kind to others.',
    category: 'daily',
    hadith: 'The Prophet (ﷺ) said, "Smiling in the face of your brother is an act of charity."',
    benefit: 'Spreads positivity, strengthens bonds, and is a form of charity.',
    icon: 'Smile',
  },
  {
    id: '6',
    name: 'Fasting on Mondays and Thursdays',
    description: 'Voluntary fasting on these two days.',
    category: 'weekly',
    hadith: 'The Prophet (ﷺ) used to fast on Mondays and Thursdays.',
    benefit: 'Spiritual purification, health benefits, and increased reward.',
    icon: 'Sunrise', 
  },
  {
    id: '7',
    name: 'Visit the Sick',
    description: 'Visiting and comforting those who are ill.',
    category: 'occasional',
    hadith: 'The Prophet (ﷺ) said, "A Muslim who visits his sick Muslim brother... will remain in Khurfat al-Jannah until he returns."',
    benefit: 'Earns great reward, strengthens community bonds, and offers comfort.',
    icon: 'HelpingHand',
  },
  {
    id: '8',
    name: 'Give Charity (Sadaqah)',
    description: 'Giving in charity, even a small amount.',
    category: 'occasional',
    hadith: 'The Prophet (ﷺ) said, "Charity does not decrease wealth."',
    benefit: 'Purifies wealth, helps the needy, and earns immense reward.',
    icon: 'Gift',
  },
  {
    id: '9',
    name: 'Sunnah Prayers before/after Fardh',
    description: 'Performing voluntary prayers before or after obligatory ones.',
    category: 'daily',
    hadith: 'The Prophet (ﷺ) said, "Whoever prays twelve rak’ahs in a day and night, a house will be built for him in Paradise."',
    benefit: 'Compensates for deficiencies in obligatory prayers, increases reward.',
    icon: 'Sunset',
  },
  {
    id: '10',
    name: 'Maintain Family Ties (Silat ar-Rahim)',
    description: 'Keeping good relations with relatives.',
    category: 'weekly', // Or occasional, depending on context
    hadith: 'The Prophet (ﷺ) said, "Whoever believes in Allah and the Last Day, let him maintain the ties of kinship."',
    benefit: 'Increases sustenance, prolongs life, and brings blessings.',
    icon: 'Users',
  },
];

export const mockUserProfile: UserProfile = {
  id: 'user123',
  name: 'Aisha Zaman',
  email: 'aisha@example.com',
  goal: 'I want to grow spiritually and be consistent in my Sunnah practices.',
  selectedHabitIds: ['1', '2', '3', '5', '6'], // Miswak, Tahajjud, Quran, Smile, Fasting Mon/Thu
  dailyLogs: [
    { habitId: '1', date: new Date(Date.now() - 86400000 * 2).toISOString().split('T')[0] }, // 2 days ago
    { habitId: '3', date: new Date(Date.now() - 86400000 * 2).toISOString().split('T')[0] },
    { habitId: '1', date: new Date(Date.now() - 86400000).toISOString().split('T')[0] }, // Yesterday
    { habitId: '2', date: new Date(Date.now() - 86400000).toISOString().split('T')[0] },
    { habitId: '3', date: new Date(Date.now() - 86400000).toISOString().split('T')[0] },
    { habitId: '5', date: new Date(Date.now() - 86400000).toISOString().split('T')[0] },
  ],
  streak: 2, // Example streak
  preferences: {
    darkMode: false,
  },
  badges: [
    {
      id: 'badge1',
      name: 'Early Riser',
      description: 'Completed Tahajjud for 7 consecutive days.',
      icon: 'Moon', // Stored as string name
      dateEarned: '2023-10-20',
    },
    {
      id: 'badge2',
      name: 'Consistent Reciter',
      description: 'Recited Quran daily for 30 days.',
      icon: 'BookOpen', // Stored as string name
      dateEarned: '2023-11-15',
    }
  ],
};

// Helper functions to get data
export const getHabitById = (id: string): Habit | undefined => mockHabits.find(h => h.id === id);

export const getSelectedUserHabits = (user: UserProfile): Habit[] => {
  return user.selectedHabitIds.map(id => getHabitById(id)).filter(Boolean) as Habit[];
};

export const getHabitsByCategory = (category: HabitCategory): Habit[] => {
  return mockHabits.filter(h => h.category === category);
};

// Function to check if a habit was completed on a specific date
export const isHabitCompletedOnDate = (userId: string, habitId: string, date: string, logs: UserProfile['dailyLogs']): boolean => {
  // In a real app, userId would be used to fetch user-specific logs
  return logs.some(log => log.habitId === habitId && log.date === date);
};
