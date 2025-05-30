import type React from 'react';
import { SidebarProvider, Sidebar, SidebarHeader, SidebarContent, SidebarFooter, SidebarTrigger, SidebarInset } from '@/components/ui/sidebar';
import { SidebarNav } from '@/components/SidebarNav';
import { SiteHeader } from '@/components/SiteHeader';
import { BookHeart } from 'lucide-react';
import Link from 'next/link';
import { Toaster } from "@/components/ui/toaster";

interface AppShellProps {
  children: React.ReactNode;
}

export function AppShell({ children }: AppShellProps) {
  return (
    <SidebarProvider defaultOpen={true}>
      <Sidebar variant="sidebar" collapsible="icon" side="left" className="border-r-0">
        <SidebarHeader className="p-4">
          <Link href="/" className="flex items-center gap-2 text-sidebar-foreground hover:text-sidebar-primary transition-colors">
            <BookHeart className="w-8 h-8 text-sidebar-primary" />
            <span className="font-cairo text-xl font-semibold group-data-[collapsible=icon]:hidden">SunnahSync</span>
          </Link>
        </SidebarHeader>
        <SidebarContent className="p-2">
          <SidebarNav />
        </SidebarContent>
        <SidebarFooter className="p-4 group-data-[collapsible=icon]:hidden">
          <p className="text-xs text-sidebar-foreground/70">&copy; {new Date().getFullYear()} SunnahSync</p>
        </SidebarFooter>
      </Sidebar>
      <SidebarInset className="flex flex-col">
        <SiteHeader />
        <main className="flex-1 overflow-y-auto p-4 md:p-6 lg:p-8">
          {children}
        </main>
        <Toaster />
      </SidebarInset>
    </SidebarProvider>
  );
}
