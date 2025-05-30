'use client';

import type { UserProfile } from '@/types';
import { useState, useTransition } from 'react';
import { Card, CardHeader, CardTitle, CardContent, CardDescription, CardFooter } from '@/components/ui/card';
import { Label } from '@/components/ui/label';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { Switch } from '@/components/ui/switch';
import { Textarea } from '@/components/ui/textarea';
import { useToast } from '@/hooks/use-toast';
import { updateUserName, updateUserGoal, toggleDarkMode } from '@/lib/actions';
import { Loader2 } from 'lucide-react';

interface SettingsClientProps {
  user: UserProfile;
}

export function SettingsClient({ user: initialUser }: SettingsClientProps) {
  const [name, setName] = useState(initialUser.name);
  const [goal, setGoal] = useState(initialUser.goal || '');
  const [darkMode, setDarkMode] = useState(initialUser.preferences.darkMode);
  const [isPending, startTransition] = useTransition();
  const { toast } = useToast();

  const handleProfileSave = () => {
    startTransition(async () => {
      const nameResult = await updateUserName(name);
      const goalResult = await updateUserGoal(goal);
      if (nameResult.success && goalResult.success) {
        toast({ title: "Profile Updated", description: "Your name and goal have been saved." });
      } else {
        toast({ title: "Error", description: "Failed to update profile.", variant: "destructive" });
      }
    });
  };

  const handleThemeToggle = (checked: boolean) => {
    startTransition(async () => {
      setDarkMode(checked);
      document.documentElement.classList.toggle('dark', checked); // Basic theme toggle
      const result = await toggleDarkMode(checked);
      if (result.success) {
        toast({ title: "Theme Updated", description: `Dark mode ${checked ? 'enabled' : 'disabled'}.` });
      } else {
        // Revert UI if server update fails
        setDarkMode(!checked);
        document.documentElement.classList.toggle('dark', !checked);
        toast({ title: "Error", description: "Failed to update theme preference.", variant: "destructive" });
      }
    });
  };

  return (
    <div className="space-y-8">
      <Card className="shadow-lg">
        <CardHeader>
          <CardTitle className="font-cairo">Profile Information</CardTitle>
          <CardDescription className="font-cairo">Update your personal details.</CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="space-y-1">
            <Label htmlFor="name" className="font-cairo">Name</Label>
            <Input id="name" value={name} onChange={(e) => setName(e.target.value)} className="font-cairo" />
          </div>
          <div className="space-y-1">
            <Label htmlFor="email" className="font-cairo">Email</Label>
            <Input id="email" value={initialUser.email} disabled className="font-cairo bg-muted/50" />
          </div>
          <div className="space-y-1">
            <Label htmlFor="goal" className="font-cairo">Your Spiritual Goal</Label>
            <Textarea
              id="goal"
              value={goal}
              onChange={(e) => setGoal(e.target.value)}
              placeholder="e.g., I want to grow spiritually and be consistent..."
              className="font-cairo min-h-[80px]"
            />
          </div>
        </CardContent>
        <CardFooter>
          <Button onClick={handleProfileSave} disabled={isPending} className="font-cairo">
            {isPending && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
            Save Profile
          </Button>
        </CardFooter>
      </Card>

      <Card className="shadow-lg">
        <CardHeader>
          <CardTitle className="font-cairo">Preferences</CardTitle>
          <CardDescription className="font-cairo">Customize your app experience.</CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="flex items-center justify-between rounded-lg border p-4">
            <div>
              <Label htmlFor="dark-mode" className="font-cairo font-medium">Dark Mode</Label>
              <p className="text-sm text-muted-foreground font-cairo">
                Enable a darker color scheme for the app.
              </p>
            </div>
            <Switch
              id="dark-mode"
              checked={darkMode}
              onCheckedChange={handleThemeToggle}
              disabled={isPending}
              aria-label="Toggle dark mode"
            />
          </div>
          {/* Future: Notification preferences */}
        </CardContent>
      </Card>

      <Card className="shadow-lg border-destructive">
        <CardHeader>
          <CardTitle className="font-cairo text-destructive">Account Management</CardTitle>
          <CardDescription className="font-cairo">Manage your account data.</CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
           <Button variant="destructive" className="w-full font-cairo" disabled>
            Delete Account (Not Implemented)
          </Button>
           <Button variant="outline" className="w-full font-cairo" disabled>
            Clear Data (Not Implemented)
          </Button>
        </CardContent>
      </Card>
    </div>
  );
}
