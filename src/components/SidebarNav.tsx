'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { SidebarMenu, SidebarMenuItem, SidebarMenuButton } from '@/components/ui/sidebar';
import { LayoutDashboard, ListChecks, BarChart3, SettingsIcon, Leaf } from 'lucide-react';

const navItems = [
  { href: '/', label: 'Dashboard', icon: LayoutDashboard, tooltip: 'Dashboard' },
  { href: '/habits', label: 'Habit Library', icon: ListChecks, tooltip: 'Habit Library' },
  { href: '/progress', label: 'Progress', icon: BarChart3, tooltip: 'Progress' },
  { href: '/settings', label: 'Settings', icon: SettingsIcon, tooltip: 'Settings' },
];

export function SidebarNav() {
  const pathname = usePathname();

  return (
    <SidebarMenu>
      {navItems.map((item) => (
        <SidebarMenuItem key={item.href}>
          <SidebarMenuButton
            asChild
            isActive={pathname === item.href || (item.href !== "/" && pathname.startsWith(item.href))}
            tooltip={{ children: item.tooltip, className: "font-cairo" }}
            className="font-cairo"
          >
            <Link href={item.href}>
              <item.icon />
              <span>{item.label}</span>
            </Link>
          </SidebarMenuButton>
        </SidebarMenuItem>
      ))}
    </SidebarMenu>
  );
}
