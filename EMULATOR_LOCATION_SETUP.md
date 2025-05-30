# Emulator Location Setup Guide

## Problem
Android emulator defaults to Mountain View, CA (Google HQ) regardless of device region settings. This guide shows how to fix this for testing UK/international locations.

## Solution 1: Set Mock Location via Extended Controls

### Step 1: Open Extended Controls
1. Start your Android emulator
2. Click the **"..."** (More) button in the emulator toolbar
3. Select **"Location"** from the left sidebar

### Step 2: Set UK Location
1. In the Location tab, you'll see a map
2. **Option A - Search by Address:**
   - Type "London, UK" in the search box
   - Click "Search" 
   - Click "Set Location"

3. **Option B - Manual Coordinates:**
   - Set Latitude: `51.5074`
   - Set Longitude: `-0.1278`
   - Click "Send"

### Step 3: Verify Location
1. Open your Sunnah Steps app
2. Go to "Nearby Sunnah" page
3. You should now see UK places instead of California

## Solution 2: Command Line Method

### Using ADB Commands
```bash
# Set location to London, UK
adb emu geo fix -0.1278 51.5074

# Set location to Birmingham, UK  
adb emu geo fix -1.8904 52.4862

# Set location to Manchester, UK
adb emu geo fix -2.2426 53.4808
```

## Solution 3: GPX File Method (Advanced)

### Create a GPX file for route simulation
1. Create `uk_locations.gpx`:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<gpx version="1.1">
  <wpt lat="51.5074" lon="-0.1278">
    <name>London</name>
  </wpt>
  <wpt lat="52.4862" lon="-1.8904">
    <name>Birmingham</name>
  </wpt>
</gpx>
```

2. Load in emulator:
   - Extended Controls > Location
   - Click "Load GPX/KML"
   - Select your file
   - Click "Play Route"

## Testing Different Locations

### Major UK Cities
- **London**: 51.5074, -0.1278
- **Birmingham**: 52.4862, -1.8904  
- **Manchester**: 53.4808, -2.2426
- **Edinburgh**: 55.9533, -3.1883
- **Cardiff**: 51.4816, -3.1791

### Islamic Cities for Testing
- **Mecca**: 21.3891, 39.8579
- **Medina**: 24.5247, 39.5692
- **Istanbul**: 41.0082, 28.9784
- **Cairo**: 30.0444, 31.2357

## Troubleshooting

### Location Not Updating
1. **Restart the app** after setting location
2. **Clear app data** if location persists
3. **Check location permissions** in Android settings
4. **Verify GPS is enabled** in emulator settings

### Still Showing Mountain View
1. **Cold boot the emulator**:
   - Close emulator completely
   - In Android Studio: Tools > AVD Manager
   - Click dropdown next to your AVD
   - Select "Cold Boot Now"

2. **Reset location services**:
   - Settings > Apps > Sunnah Steps > Permissions
   - Toggle Location permission off/on

### App Shows "Using Saved Location"
This is normal! The app now intelligently falls back to saved locations when:
- GPS is disabled
- Location permission denied  
- GPS signal unavailable
- User manually selects a saved location

## Battery Optimization Notes

The new smart location system is more battery-friendly because:
- **Reduced API calls**: Uses cached saved locations when GPS fails
- **Shorter timeouts**: GPS requests timeout after 8 seconds
- **Fallback hierarchy**: Avoids repeated GPS attempts
- **User control**: Can disable GPS entirely and use saved locations

## Testing the New Features

### Test Location Settings Page
1. Open app > Nearby Sunnah > Settings icon
2. Add a new location (e.g., "Test Location, London, UK")
3. Set it as active location
4. Disable "Use GPS Location"
5. Refresh Nearby Sunnah page
6. Should show "Using Saved Location" with UK places

### Test Smart Fallback
1. Enable airplane mode (disables GPS)
2. Open Nearby Sunnah page
3. Should automatically use saved location
4. Location banner shows "Using Saved Location"

### Test GPS Priority
1. Disable airplane mode
2. Enable "Use GPS Location" in settings
3. Refresh Nearby Sunnah page
4. Should prefer GPS over saved location
5. Location banner shows "Using GPS"
