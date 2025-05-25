import type { Metadata } from 'next';
import { Cairo, Geist, Geist_Mono } from 'next/font/google';
import './globals.css';
import { AppShell } from '@/components/AppShell'; // Import AppShell
import { cn } from '@/lib/utils';

const geistSans = Geist({
  variable: '--font-geist-sans',
  subsets: ['latin'],
});

const geistMono = Geist_Mono({
  variable: '--font-geist-mono',
  subsets: ['latin'],
});

const cairo = Cairo({
  variable: '--font-cairo',
  subsets: ['latin', 'arabic'],
  weight: ['400', '600', '700'], // Include needed weights
});

export const metadata: Metadata = {
  title: 'SunnahSync - Track Your Sunnah Habits',
  description: 'A calm, reflective, and minimalistic Sunnah habit tracker.',
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body 
        className={cn(
          "min-h-screen bg-background font-cairo antialiased",
          geistSans.variable, 
          geistMono.variable, 
          cairo.variable
        )}
      >
        <AppShell>
          {children}
        </AppShell>
      </body>
    </html>
  );
}
