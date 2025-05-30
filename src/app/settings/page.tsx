import { mockUserProfile } from '@/lib/data';
import { Card, CardHeader, CardTitle, CardContent, CardDescription, CardFooter } from '@/components/ui/card';
import { Label } from '@/components/ui/label';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { Switch } from '@/components/ui/switch';
import { Textarea } from '@/components/ui/textarea';
import { SettingsClient } from '@/components/settings/SettingsClient';

export default async function SettingsPage() {
  const user = mockUserProfile;

  return (
    <div className="container mx-auto py-8">
      <div className="mb-8">
        <h1 className="text-3xl font-bold font-cairo text-primary mb-2">Settings</h1>
        <p className="text-muted-foreground font-cairo">Manage your profile and application preferences.</p>
      </div>
      <SettingsClient user={user} />
    </div>
  );
}
