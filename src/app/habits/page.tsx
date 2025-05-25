import { mockHabits, mockUserProfile, getHabitsByCategory } from '@/lib/data';
import { Card, CardHeader, CardTitle, CardContent, CardDescription } from '@/components/ui/card';
import { HabitCardClient } from '@/components/habits/HabitCardClient';
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import type { HabitCategory } from '@/types';
import { ScrollArea } from '@/components/ui/scroll-area';

const categories: HabitCategory[] = ['daily', 'weekly', 'occasional'];

export default async function HabitLibraryPage() {
  const userSelectedHabitIds = new Set(mockUserProfile.selectedHabitIds);

  return (
    <div className="container mx-auto py-8">
      <div className="mb-8">
        <h1 className="text-3xl font-bold font-cairo text-primary mb-2">Habit Library</h1>
        <p className="text-muted-foreground font-cairo">Browse and select Sunnah habits to add to your daily tracker.</p>
      </div>

      <Tabs defaultValue="daily" className="w-full">
        <TabsList className="grid w-full grid-cols-3 mb-6 bg-primary/10">
          {categories.map(category => (
            <TabsTrigger key={category} value={category} className="capitalize font-cairo data-[state=active]:bg-primary data-[state=active]:text-primary-foreground">
              {category}
            </TabsTrigger>
          ))}
        </TabsList>
        
        {categories.map(category => {
          const habitsInCategory = getHabitsByCategory(category);
          return (
            <TabsContent key={category} value={category}>
              <Card className="shadow-xl">
                <CardHeader>
                  <CardTitle className="capitalize font-cairo text-xl text-primary">{category} Sunnahs</CardTitle>
                  <CardDescription className="font-cairo">
                    Explore {category} practices to enrich your routine.
                  </CardDescription>
                </CardHeader>
                <CardContent>
                  {habitsInCategory.length > 0 ? (
                    <ScrollArea className="h-[500px] pr-2">
                      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
                        {habitsInCategory.map(habit => (
                          <HabitCardClient 
                            key={habit.id} 
                            habit={habit} 
                            initialIsSelected={userSelectedHabitIds.has(habit.id)} 
                          />
                        ))}
                      </div>
                    </ScrollArea>
                  ) : (
                    <p className="text-muted-foreground text-center py-4 font-cairo">No {category} habits found in the library.</p>
                  )}
                </CardContent>
              </Card>
            </TabsContent>
          );
        })}
      </Tabs>
    </div>
  );
}
