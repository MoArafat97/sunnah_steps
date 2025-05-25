"use client";

import type { Habit } from '@/types';
import { useState, useTransition } from 'react';
import { Checkbox } from '@/components/ui/checkbox';
import { Button } from '@/components/ui/button';
import { toggleHabitCompletion } from '@/lib/actions';
import { cn } from '@/lib/utils';
import { Info, Check, type LucideIcon, TreePalm, Moon, BookOpen, Droplets, Smile, Sunrise, HelpingHand, Gift, Sunset, Users } from 'lucide-react';
import { useToast } from '@/hooks/use-toast';
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
  DialogFooter,
  DialogClose,
} from "@/components/ui/dialog";

interface HabitChecklistItemClientProps {
  habit: Habit;
  userId: string;
  initialCompleted: boolean;
  currentDate: string; // YYYY-MM-DD
}

const iconMap: { [key: string]: LucideIcon } = {
  TreePalm,
  Moon,
  BookOpen,
  Droplets,
  Smile,
  Sunrise,
  HelpingHand,
  Gift,
  Sunset,
  Users,
};

export function HabitChecklistItemClient({ habit, userId, initialCompleted, currentDate }: HabitChecklistItemClientProps) {
  const [completed, setCompleted] = useState(initialCompleted);
  const [isPending, startTransition] = useTransition();
  const { toast } = useToast();
  const [isDetailsModalOpen, setIsDetailsModalOpen] = useState(false);

  const handleToggleCompletion = () => {
    startTransition(async () => {
      const newCompletedStatus = !completed;
      const result = await toggleHabitCompletion(habit.id, currentDate);
      if (result.success) {
        setCompleted(newCompletedStatus); // Use the server's response if available: result.completed
        toast({
          title: newCompletedStatus ? "Habit Completed!" : "Habit Marked Incomplete",
          description: `${habit.name} status updated.`,
          variant: newCompletedStatus ? "default" : "default", 
          className: newCompletedStatus ? "bg-primary/10 border-primary/50" : "bg-muted/50",
        });
      } else {
        toast({
          title: "Error",
          description: result.message || "Failed to update habit status.",
          variant: "destructive",
        });
      }
    });
  };

  const HabitIconComponent = habit.icon ? iconMap[habit.icon] : null;

  return (
    <>
      <li
        className={cn(
          "flex items-center justify-between p-3 rounded-lg border transition-all duration-200 ease-in-out",
          completed ? "bg-primary/10 border-primary/50" : "bg-card hover:bg-muted/50",
          isPending && "opacity-70 pointer-events-none"
        )}
      >
        <div className="flex items-center gap-3 flex-1 min-w-0">
          <Checkbox
            id={`habit-${habit.id}`}
            checked={completed}
            onCheckedChange={handleToggleCompletion}
            aria-label={`Mark ${habit.name} as ${completed ? 'incomplete' : 'complete'}`}
            className={cn("shrink-0", completed && "border-primary data-[state=checked]:bg-primary data-[state=checked]:text-primary-foreground")}
          />
          <label
            htmlFor={`habit-${habit.id}`}
            className={cn(
              "font-cairo text-sm font-medium cursor-pointer truncate",
              completed ? "line-through text-muted-foreground" : "text-foreground"
            )}
            title={habit.name}
          >
            {habit.name}
          </label>
          {completed && <Check className="h-4 w-4 text-primary shrink-0" />}
        </div>
        <div className="flex items-center gap-2 shrink-0 ml-2">
          {HabitIconComponent && <HabitIconComponent className={cn("h-5 w-5", completed ? "text-primary/70" : "text-muted-foreground")} />}
          <Button
            variant="ghost"
            size="icon"
            className="h-7 w-7 rounded-full"
            onClick={() => setIsDetailsModalOpen(true)}
            aria-label={`View details for ${habit.name}`}
          >
            <Info className="h-4 w-4 text-muted-foreground hover:text-primary" />
          </Button>
        </div>
      </li>

      <Dialog open={isDetailsModalOpen} onOpenChange={setIsDetailsModalOpen}>
        <DialogContent className="sm:max-w-[425px] bg-background font-cairo">
          <DialogHeader>
            <DialogTitle className="text-primary flex items-center gap-2">
              {HabitIconComponent && <HabitIconComponent className="h-5 w-5" />}
              {habit.name}
            </DialogTitle>
            <DialogDescription className="text-muted-foreground pt-1">
              {habit.description}
            </DialogDescription>
          </DialogHeader>
          <div className="py-4 space-y-3 text-sm">
            <div>
              <h4 className="font-semibold text-foreground/90 mb-1">Category:</h4>
              <p className="text-muted-foreground capitalize">{habit.category}</p>
            </div>
            <div>
              <h4 className="font-semibold text-foreground/90 mb-1">Hadith Reference:</h4>
              <p className="text-muted-foreground italic">"{habit.hadith}"</p>
            </div>
            <div>
              <h4 className="font-semibold text-foreground/90 mb-1">Spiritual Benefit:</h4>
              <p className="text-muted-foreground">{habit.benefit}</p>
            </div>
          </div>
          <DialogFooter>
            <DialogClose asChild>
              <Button type="button" variant="outline">Close</Button>
            </DialogClose>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </>
  );
}
