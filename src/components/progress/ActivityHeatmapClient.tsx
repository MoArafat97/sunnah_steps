"use client";

import { addDays, format, startOfMonth, endOfMonth, eachDayOfInterval, getDay, isSameMonth, isToday, parseISO } from 'date-fns';
import { cn } from '@/lib/utils';
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from "@/components/ui/tooltip";

interface ActivityHeatmapClientProps {
  data: { [date: string]: number }; // Date string (YYYY-MM-DD) -> count
}

// A very basic heatmap implementation. Libraries like react-calendar-heatmap are more robust.
export function ActivityHeatmapClient({ data }: ActivityHeatmapClientProps) {
  const today = new Date();
  const firstDayCurrentMonth = startOfMonth(today);
  // Display current month
  const daysInMonth = eachDayOfInterval({
    start: firstDayCurrentMonth,
    end: endOfMonth(firstDayCurrentMonth),
  });

  // For alignment, find out which day of the week the month starts on
  // Sunday is 0, Monday is 1, etc.
  const startingDayOffset = getDay(firstDayCurrentMonth);

  const getIntensityClass = (count: number | undefined) => {
    if (!count || count === 0) return "bg-muted/30 hover:bg-muted/50";
    if (count <= 2) return "bg-primary/20 hover:bg-primary/30";
    if (count <= 4) return "bg-primary/50 hover:bg-primary/60";
    return "bg-primary/80 hover:bg-primary/90";
  };

  return (
    <TooltipProvider>
      <div className="p-2 rounded-lg border bg-card">
        <div className="flex justify-between items-center mb-3 px-1">
            <h3 className="font-cairo text-md font-semibold text-foreground">
              {format(firstDayCurrentMonth, 'MMMM yyyy')}
            </h3>
        </div>
        <div className="grid grid-cols-7 gap-1.5">
          {['S', 'M', 'T', 'W', 'T', 'F', 'S'].map(day => (
            <div key={day} className="text-center text-xs font-cairo text-muted-foreground">{day}</div>
          ))}
          {Array.from({ length: startingDayOffset }).map((_, i) => (
            <div key={`empty-${i}`} /> // Empty cells for offset
          ))}
          {daysInMonth.map((day) => {
            const dateString = format(day, 'yyyy-MM-dd');
            const count = data[dateString] || 0;
            return (
              <Tooltip key={dateString} delayDuration={100}>
                <TooltipTrigger asChild>
                  <div
                    className={cn(
                      "w-full aspect-square rounded border transition-colors duration-150",
                      getIntensityClass(count),
                      isToday(day) && "ring-2 ring-accent ring-offset-1 ring-offset-background"
                    )}
                  />
                </TooltipTrigger>
                <TooltipContent className="font-cairo bg-popover text-popover-foreground">
                  <p>{format(day, 'MMM d, yyyy')}: {count} habits</p>
                </TooltipContent>
              </Tooltip>
            );
          })}
        </div>
      </div>
    </TooltipProvider>
  );
}
