"use client"

import { Bar, BarChart, ResponsiveContainer, XAxis, YAxis, CartesianGrid, Tooltip } from "recharts"
import { useTheme } from "next-themes" // If you install next-themes for dark mode
import { themes } from "tailwind.config"; // Assuming you export your HSL values

interface WeeklyCompletionChartClientProps {
  data: Array<{ date: string; shortDate: string; completed: number }>;
}

export function WeeklyCompletionChartClient({ data }: WeeklyCompletionChartClientProps) {
  // const { resolvedTheme } = useTheme(); // For dynamic theme colors, install next-themes
  // For now, hardcode colors or use CSS variables if Recharts supports them well.
  // Recharts typically takes direct color strings.

  const primaryColor = "hsl(var(--primary))"; // Use CSS var directly
  const mutedForegroundColor = "hsl(var(--muted-foreground))";

  return (
    <ResponsiveContainer width="100%" height="100%">
      <BarChart data={data} margin={{ top: 5, right: 0, left: -30, bottom: 0 }}>
        <CartesianGrid strokeDasharray="3 3" stroke="hsl(var(--border))" vertical={false}/>
        <XAxis 
          dataKey="shortDate" 
          stroke={mutedForegroundColor}
          fontSize={12} 
          tickLine={false} 
          axisLine={false}
        />
        <YAxis 
          stroke={mutedForegroundColor}
          fontSize={12} 
          tickLine={false} 
          axisLine={false}
          allowDecimals={false}
        />
        <Tooltip
          contentStyle={{ 
            backgroundColor: "hsl(var(--popover))", 
            borderColor: "hsl(var(--border))",
            borderRadius: "var(--radius)",
            color: "hsl(var(--popover-foreground))",
            fontFamily: "var(--font-cairo)",
          }}
          cursor={{ fill: "hsl(var(--primary)/0.1)" }}
          formatter={(value: number, name: string, props: any) => [`${value} habits`, props.payload.date]}
        />
        <Bar dataKey="completed" fill={primaryColor} radius={[4, 4, 0, 0]} barSize={20} />
      </BarChart>
    </ResponsiveContainer>
  )
}
