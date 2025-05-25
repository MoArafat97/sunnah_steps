import { mockUserProfile, getSelectedUserHabits, getHabitById, isHabitCompletedOnDate } from '@/lib/data';
import { Card, CardHeader, CardTitle, CardContent, CardDescription } from '@/components/ui/card';
import { HabitChecklistItemClient } from '@/components/dashboard/HabitChecklistItemClient';
import { ScrollArea } from '@/components/ui/scroll-area';
import { CheckCircle2, TrendingUp, Award } from 'lucide-react';
import { Progress } from '@/components/ui/progress';
import { Separator } from '@/components/ui/separator';

export default async function DashboardPage() {
  const user = mockUserProfile;
  const habitsToDisplay = getSelectedUserHabits(user);
  const today = new Date().toISOString().split('T')[0];

  const dailyHabits = habitsToDisplay.filter(h => h.category === 'daily' || h.category === 'occasional'); // Show occasional for now too
  const weeklyHabits = habitsToDisplay.filter(h => h.category === 'weekly');

  const completedTodayCount = dailyHabits.filter(h => isHabitCompletedOnDate(user.id, h.id, today, user.dailyLogs)).length;
  const totalDailyHabits = dailyHabits.length;
  const progressPercentage = totalDailyHabits > 0 ? (completedTodayCount / totalDailyHabits) * 100 : 0;

  return (
    <div className="container mx-auto py-8">
      <div className="mb-8">
        <h1 className="text-3xl font-bold font-cairo text-primary mb-2">Assalamu 'Alaikum, {user.name}!</h1>
        <p className="text-muted-foreground font-cairo">{user.goal || "Let's make progress on our Sunnahs today."}</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
        <Card className="shadow-lg">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium font-cairo">Habits Completed Today</CardTitle>
            <CheckCircle2 className="h-5 w-5 text-primary" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold font-cairo">{completedTodayCount}/{totalDailyHabits}</div>
            <Progress value={progressPercentage} className="w-full mt-2 h-2" />
          </CardContent>
        </Card>
        <Card className="shadow-lg">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium font-cairo">Current Streak</CardTitle>
            <TrendingUp className="h-5 w-5 text-accent" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold font-cairo">{user.streak} days</div>
            <p className="text-xs text-muted-foreground mt-1 font-cairo">Keep it up!</p>
          </CardContent>
        </Card>
        <Card className="shadow-lg">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium font-cairo">Badges Earned</CardTitle>
            <Award className="h-5 w-5 text-yellow-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold font-cairo">{user.badges.length}</div>
            <p className="text-xs text-muted-foreground mt-1 font-cairo">View in Progress tab.</p>
          </CardContent>
        </Card>
      </div>
      
      <Card className="shadow-xl">
        <CardHeader>
          <CardTitle className="font-cairo text-xl text-primary">Today's Sunnah Checklist</CardTitle>
          <CardDescription className="font-cairo">Mark habits as completed for {new Date(today).toLocaleDateString('en-US', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' })}.</CardDescription>
        </CardHeader>
        <CardContent>
          {dailyHabits.length > 0 ? (
            <ScrollArea className="h-[300px] pr-4">
              <ul className="space-y-3">
                {dailyHabits.map((habit) => (
                  <HabitChecklistItemClient
                    key={habit.id}
                    habit={habit}
                    userId={user.id}
                    initialCompleted={isHabitCompletedOnDate(user.id, habit.id, today, user.dailyLogs)}
                    currentDate={today}
                  />
                ))}
              </ul>
            </ScrollArea>
          ) : (
            <p className="text-muted-foreground font-cairo text-center py-4">No daily habits selected. Visit the Habit Library to add some!</p>
          )}

          {weeklyHabits.length > 0 && (
            <>
              <Separator className="my-6" />
              <h3 className="font-cairo text-lg font-semibold mb-3 text-primary/80">Weekly Sunnahs</h3>
              <ScrollArea className="h-[150px] pr-4">
                <ul className="space-y-3">
                  {weeklyHabits.map((habit) => (
                    <HabitChecklistItemClient
                      key={habit.id}
                      habit={habit}
                      userId={user.id}
                      initialCompleted={isHabitCompletedOnDate(user.id, habit.id, today, user.dailyLogs)} // Note: Weekly completion logic might differ
                      currentDate={today} // For weekly, this date context needs care
                    />
                  ))}
                </ul>
              </ScrollArea>
            </>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
