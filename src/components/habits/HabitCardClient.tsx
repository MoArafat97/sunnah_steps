"use client";

import type { Habit } from '@/types';
import { useState, useTransition } from 'react';
import { Button } from '@/components/ui/button';
import { Card, CardHeader, CardTitle, CardDescription, CardContent, CardFooter } from '@/components/ui/card';
import { updateUserSelectedHabits } from '@/lib/actions';
import { PlusCircle, CheckCircle, Info, Loader2, type LucideIcon, TreePalm, Moon, BookOpen, Droplets, Smile, Sunrise, HelpingHand, Gift, Sunset, Users } from 'lucide-react';
import { useToast } from '@/hooks/use-toast';
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription as DialogDescModal, 
  DialogFooter,
  DialogClose,
} from "@/components/ui/dialog";
import { cn } from '@/lib/utils';

interface HabitCardClientProps {
  habit: Habit;
  initialIsSelected: boolean;
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

export function HabitCardClient({ habit, initialIsSelected }: HabitCardClientProps) {
  const [isSelected, setIsSelected] = useState(initialIsSelected);
  const [isPending, startTransition] = useTransition();
  const { toast } = useToast();
  const [isDetailsModalOpen, setIsDetailsModalOpen] = useState(false);

  const handleToggleSelection = () => {
    startTransition(async () => {
      const newSelectedStatus = !isSelected;
      const result = await updateUserSelectedHabits(habit.id, newSelectedStatus);
      if (result.success) {
        setIsSelected(newSelectedStatus);
        toast({
          title: newSelectedStatus ? "Habit Added" : "Habit Removed",
          description: `${habit.name} ${newSelectedStatus ? 'added to' : 'removed from'} your tracker.`,
          className: newSelectedStatus ? "bg-primary/10 border-primary/50" : "bg-muted/50",
        });
      } else {
        toast({
          title: "Error",
          description: result.message || "Failed to update habit selection.",
          variant: "destructive",
        });
      }
    });
  };
  
  const HabitIconComponent = habit.icon ? iconMap[habit.icon] : null;

  return (
    <>
      <Card className={cn("flex flex-col justify-between h-full shadow-md hover:shadow-lg transition-shadow duration-200", isSelected && "border-primary bg-primary/5")}>
        <CardHeader>
          <div className="flex items-center justify-between mb-2">
            <CardTitle className="font-cairo text-base font-semibold text-foreground flex items-center gap-2">
              {HabitIconComponent && <HabitIconComponent className={cn("h-5 w-5", isSelected ? "text-primary" : "text-muted-foreground")} />}
              {habit.name}
            </CardTitle>
            <Button variant="ghost" size="icon" className="h-7 w-7" onClick={() => setIsDetailsModalOpen(true)}>
              <Info className="h-4 w-4 text-muted-foreground hover:text-primary" />
            </Button>
          </div>
          <CardDescription className="text-xs font-cairo text-muted-foreground line-clamp-2">{habit.description}</CardDescription>
        </CardHeader>
        <CardFooter>
          <Button
            variant={isSelected ? "outline" : "default"}
            size="sm"
            className="w-full font-cairo"
            onClick={handleToggleSelection}
            disabled={isPending}
          >
            {isPending ? (
              <Loader2 className="mr-2 h-4 w-4 animate-spin" />
            ) : isSelected ? (
              <CheckCircle className="mr-2 h-4 w-4" />
            ) : (
              <PlusCircle className="mr-2 h-4 w-4" />
            )}
            {isPending ? "Updating..." : isSelected ? "Added to Tracker" : "Add to Tracker"}
          </Button>
        </CardFooter>
      </Card>

      <Dialog open={isDetailsModalOpen} onOpenChange={setIsDetailsModalOpen}>
        <DialogContent className="sm:max-w-[425px] bg-background font-cairo">
          <DialogHeader>
            <DialogTitle className="text-primary flex items-center gap-2">
              {HabitIconComponent && <HabitIconComponent className="h-5 w-5" />}
              {habit.name}
            </DialogTitle>
            <DialogDescModal className="text-muted-foreground pt-1">
              {habit.description}
            </DialogDescModal>
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
