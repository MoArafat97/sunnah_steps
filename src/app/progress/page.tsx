import { mockUserProfile, mockHabits } from '@/lib/data';
import { Card, CardHeader, CardTitle, CardContent, CardDescription } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { BarChart, TrendingUp, Award, CalendarDays, Moon, BookOpen, type LucideIcon } from 'lucide-react'; // Added Moon, BookOpen
import { WeeklyCompletionChartClient } from '@/components/progress/WeeklyCompletionChartClient';
import { ActivityHeatmapClient } from '@/components/progress/ActivityHeatmapClient';

// Define an icon map for badge icons
const badgeIconMap: { [key: string]: LucideIcon } = {
  Moon,
  BookOpen,
  // Add other icons used in badges here as string keys
};


export default async function ProgressPage() {
  const user = mockUserProfile;

  // Prepare data for weekly chart (last 7 days)
  const today = new Date();
  const weeklyChartData = Array.from({ length: 7 }).map((_, i) => {
    const date = new Date(today);
    date.setDate(today.getDate() - (6 - i));
    const dateString = date.toISOString().split('T')[0];
    const completedCount = user.dailyLogs.filter(log => log.date === dateString && user.selectedHabitIds.includes(log.habitId)).length;
    return {
      date: date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' }),
      shortDate: date.toLocaleDateString('en-US', { weekday: 'short' }).slice(0,1), // Single letter for day
      completed: completedCount,
    };
  });
  
  // Prepare data for heatmap (example: last 30 days of logs)
  const heatmapData = user.dailyLogs
    .filter(log => user.selectedHabitIds.includes(log.habitId)) // only count selected habits
    .reduce<{[date: string]: number}>((acc, log) => {
      acc[log.date] = (acc[log.date] || 0) + 1;
      return acc;
    }, {});

  return (
    <div className="container mx-auto py-8">
      <div className="mb-8">
        <h1 className="text-3xl font-bold font-cairo text-primary mb-2">Your Progress</h1>
        <p className="text-muted-foreground font-cairo">Track your journey and celebrate your consistency.</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 mb-8">
        <Card className="shadow-lg">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium font-cairo">Current Streak</CardTitle>
            <TrendingUp className="h-5 w-5 text-accent" />
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-bold font-cairo">{user.streak} days</div>
            <p className="text-xs text-muted-foreground mt-1 font-cairo">Masha'Allah! Keep going!</p>
          </CardContent>
        </Card>
        <Card className="shadow-lg col-span-1 lg:col-span-2">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium font-cairo">Habits Completed This Week</CardTitle>
            <BarChart className="h-5 w-5 text-primary" />
          </CardHeader>
          <CardContent className="h-[100px]">
            <WeeklyCompletionChartClient data={weeklyChartData} />
          </CardContent>
        </Card>
      </div>

      <Card className="shadow-xl mb-8">
        <CardHeader>
          <CardTitle className="font-cairo text-xl text-primary flex items-center gap-2">
            <CalendarDays className="h-5 w-5" /> Activity Heatmap
          </CardTitle>
          <CardDescription className="font-cairo">Visualize your daily consistency. Darker green means more habits completed.</CardDescription>
        </CardHeader>
        <CardContent>
          <ActivityHeatmapClient data={heatmapData} />
        </CardContent>
      </Card>

      <Card className="shadow-xl">
        <CardHeader>
          <CardTitle className="font-cairo text-xl text-primary flex items-center gap-2">
            <Award className="h-5 w-5" /> Spiritual Badges
          </CardTitle>
          <CardDescription className="font-cairo">Milestones achieved on your spiritual journey.</CardDescription>
        </CardHeader>
        <CardContent>
          {user.badges.length > 0 ? (
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
              {user.badges.map(badge => {
                const BadgeIcon = badgeIconMap[badge.icon] || Award; // Fallback to Award icon if not found
                return (
                  <Card key={badge.id} className="bg-accent/10 border-accent/50 p-4 flex flex-col items-center text-center">
                    <BadgeIcon className="h-12 w-12 text-accent mb-3" />
                    <h3 className="font-cairo font-semibold text-foreground">{badge.name}</h3>
                    <p className="text-xs text-muted-foreground font-cairo mb-1">{badge.description}</p>
                    <Badge variant="outline" className="font-cairo text-xs border-accent text-accent">
                      Earned: {new Date(badge.dateEarned).toLocaleDateString()}
                    </Badge>
                  </Card>
                );
              })}
            </div>
          ) : (
            <p className="text-muted-foreground text-center py-4 font-cairo">No badges earned yet. Keep up the good work!</p>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
