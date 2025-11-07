# 🚁 DCS MEDEVAC Script v6.0.0

[![DCS Version](https://img.shields.io/badge/DCS-2.9+-blue.svg)](https://www.digitalcombatsimulator.com/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![MiST Required](https://img.shields.io/badge/MiST-3.2%2B-orange.svg)](https://github.com/mrSkortch/MissionScriptingTools)

> **Immersive combat search and rescue missions for DCS World**  
> Experience the tension of medevac operations with realistic casualty management, weather effects, and night operations.

---

## 📋 Table of Contents

- [Features](#-features)
- [What's New in v6.0.0](#-whats-new-in-v600)
- [Installation](#-installation)
- [Configuration](#-configuration)
- [Usage](#-usage)
- [How It Works](#-how-it-works)
- [Credits](#-credits)
- [Changelog](#-changelog)
- [Support](#-support)
- [License](#-license)

---

## ✨ Features

### Core Functionality
- 🏥 **Automatic Casualty Generation** - Spawns wounded crew when ground vehicles are destroyed
- 🪂 **Search & Rescue (SAR)** - Rescue downed pilots from ejected aircraft
- ⏱️ **Dynamic Bleed Timer** - Wounded personnel have limited time before they succumb to injuries
- 🚁 **Multiple MEDEVAC Units** - Support for multiple rescue helicopters per coalition
- 🏥 **MASH Support** - Multiple Mobile Army Surgical Hospital locations per side

### NEW in v6.0.0 🎉

#### 🗺️ **F10 Map Integration**
- Active MEDEVAC locations automatically marked on F10 map
- Color-coded markers by coalition
- Auto-updating markers that remove when casualties are rescued or KIA

#### 🎆 **Enhanced Visual Signaling**
- **Signal Flares** - Wounded fire periodic flares (every 3 minutes) to mark their position
- **Illumination Bombs** - Automatic area illumination during night operations
- **Colored Smoke** - Coalition-specific smoke markers (Blue/Red)

#### 🌡️ **Environmental Effects**
- **Weather-Based Difficulty** - Temperature affects bleed rates
  - Freezing temps (< 0°C): +30% survival time
  - Cold temps (0-10°C): +15% survival time  
  - Hot temps (25-35°C): -8% survival time
  - Extreme heat (> 35°C): -15% survival time
- **Time of Day Effects** - Night missions provide additional challenges

#### 🎯 **Unit Type Triage System**
- Different bleed rates based on vehicle type:
  - **Tank Crews**: 20% faster bleed (severe injuries from armor penetration)
  - **IFV/APC Crews**: 10% faster bleed (moderate injuries)
  - **Truck/Light Vehicle**: 20% slower bleed (minor injuries)

#### 🚁 **Helicopter Damage Warnings**
- Real-time aircraft health monitoring
- Critical/Warning/Caution alerts based on damage level
- Helps pilots assess mission risk

#### 📊 **Statistics Tracking**
- Lives saved counter
- Missions completed
- Pilots rescued vs crew rescued
- Total casualties
- Medics KIA
- Separate stats per coalition
- Radio menu command to view statistics

#### 🛠️ **Technical Improvements**
- Fixed 40+ "Parameter #self missed" errors
- Enhanced nil safety checks throughout
- Improved error handling with detailed logging
- Fixed all static vs instance method calls per DCS ScriptingLib
- Pre-populated unit→group cache to handle DCS API limitations
- Comprehensive debug logging system with 5 verbosity levels

---

## 🆕 What's New in v6.0.0

**Enhanced by HeavenDCS (2025-11-07)**

This major update brings DCS MEDEVAC into the modern era with enhanced immersion, better visuals, and robust error handling:

### Visual Enhancements
- 🗺️ Map markers show active casualty locations
- 🎆 Signal flares fired every 3 minutes from casualty positions
- 💡 Automatic illumination of pickup zones at night
- 🎨 Coalition-specific smoke colors

### Gameplay Depth
- 🌡️ Weather affects survival time (cold preserves, heat accelerates bleeding)
- 🌙 Night operations are more challenging with extended search times
- 🎯 Injury severity varies by vehicle type (tanks vs trucks)
- 🚁 Helicopter damage warnings keep pilots informed

### Quality of Life
- 📊 Comprehensive statistics tracking
- 🔧 Eliminated all parameter errors
- 📝 Enhanced debug logging system
- ⚡ Improved performance with better caching

### Bug Fixes
- ✅ Fixed incorrect event ID check (was ENGINE_SHUTDOWN, now PLAYER_ENTER_UNIT)
- ✅ Fixed all `string.format` nil argument errors
- ✅ Fixed all static vs instance method calls
- ✅ Added comprehensive nil safety checks
- ✅ Protected all method chaining with proper checks

---

## 📦 Installation

### Prerequisites
- **DCS World** 2.5.6 or newer
- **[MiST 3.2+](https://github.com/mrSkortch/MissionScriptingTools)** (Mission Scripting Tools)

### Installation Steps

1. **Download MiST** (if not already installed)
   ```
   https://github.com/mrSkortch/MissionScriptingTools
   ```

2. **Add to Mission Editor**
   - Open your mission in DCS Mission Editor
   - Go to **Triggers** → **New Trigger**
   - Set trigger to: `MISSION START` / `TIME MORE (1)` / `DO SCRIPT FILE`
   - First, load **MiST** script file
   - Then, load **medevac.lua** script file
   - ⚠️ **Important:** MiST MUST be loaded before MEDEVAC

3. **Configure MEDEVAC Units**
   - Place helicopter units you want as MEDEVAC units
   - Place ground units as MASH (Mobile Army Surgical Hospital)
   - Edit the script configuration (see below)

4. **Save and Test**
   - Save your mission
   - Test to ensure script loads without errors

---

## ⚙️ Configuration

Open `medevac.lua` and edit the settings section at the top:

### Essential Settings

```lua
-- Define your MEDEVAC helicopter units (UNIT NAMES)
medevac.medevacunits = {"MEDEVAC #1", "MEDEVAC #2"}

-- Define your MASH units (UNIT NAMES)
medevac.bluemash = {"BlueMASH #1", "BlueMASH #2"}
medevac.redmash = {"RedMASH #1", "RedMASH #2"}

-- Smoke colors for each coalition
medevac.bluesmokecolor = trigger.smokeColor.Blue
medevac.redsmokecolor = trigger.smokeColor.Red
```

### New Features Configuration (v6.0.0)

```lua
-- Enable/Disable new features
medevac.useMapMarkers = true          -- Show MEDEVAC on F10 map
medevac.useSignalFlares = true        -- Fire signal flares from wounded
medevac.useIllumination = true        -- Illuminate pickup zones at night
medevac.weatherEffects = true         -- Weather affects bleed rates
medevac.timeOfDayEffects = true       -- Night missions more challenging
medevac.unitTypeTriage = true         -- Different bleed rates by vehicle
medevac.heliDamageWarnings = true     -- Warn pilot of helicopter damage
medevac.trackStatistics = true        -- Track missions/lives saved

-- Fine-tune feature behavior
medevac.flareInterval = 180           -- Seconds between flares (3 min)
medevac.illuminationPower = 1000000   -- Illumination bomb intensity
medevac.nightTimeStart = 19           -- Night begins at 19:00 (7 PM)
medevac.nightTimeEnd = 6              -- Night ends at 06:00 (6 AM)
medevac.mapMarkersReadOnly = true     -- Can players edit markers?
```

### Gameplay Settings

```lua
-- Casualty mechanics
medevac.requestdelay = 15             -- Seconds before casualty calls for help
medevac.bluecrewsurvivepercent = 100  -- % of blue crews that survive (0-100)
medevac.redcrewsurvivepercent = 100   -- % of red crews that survive (0-100)
medevac.showbleedtimer = false        -- Show countdown timer?
medevac.sar_pilots = true             -- Rescue downed pilots?
medevac.immortalcrew = true           -- Wounded can't be killed?
medevac.invisiblecrew = true          -- Wounded invisible to AI?

-- Time calculations
medevac.cruisespeed = 40              -- Cruise speed for time calc (m/s)
medevac.minbleedtime = 30             -- Minimum possible bleed time (sec)
medevac.maxbleedtimemultiplier = 1.2  -- Max bleed time multiplier
```

### Coordinate System

```lua
-- Choose coordinate display format
medevac.coordtype = 3  -- Options:
                       -- 0 = Lat/Long DDM
                       -- 1 = Lat/Long DMS
                       -- 2 = MGRS
                       -- 3 = Bullseye Imperial (default)
                       -- 4 = Bullseye Metric
```

### Debug Settings

```lua
-- Debug verbosity levels
medevac.debug_verbose = 0  -- 0=off, 1=errors, 2=warnings, 
                           -- 3=info, 4=debug, 5=trace
```

---

## 🎮 Usage

### For Mission Designers

1. **Setup MEDEVAC Units**
   - Create helicopter groups for rescue missions
   - Add unit names to `medevac.medevacunits` table

2. **Setup MASH Units**  
   - Place ground units to serve as field hospitals
   - Add unit names to `medevac.bluemash` and `medevac.redmash` tables

3. **Configure Options**
   - Set survival percentages
   - Enable/disable new features
   - Adjust timing parameters

### For Players

1. **Start Mission**
   - Enter a MEDEVAC helicopter unit
   - Check F10 Radio Menu for "MEDEVAC" submenu

2. **Receive Casualties**
   - When ground units are destroyed, crew may survive
   - After ~15 seconds, you'll receive a radio call with coordinates
   - Location appears on F10 map (if enabled)

3. **Locate Casualties**
   - Navigate to coordinates
   - Look for:
     - 🎆 Signal flares (every 3 minutes)
     - 💨 Colored smoke (Blue/Red)
     - 💡 Illumination (at night)
     - 🗺️ Map marker on F10

4. **Pickup**
   - Land within 200m of casualties
   - When speed < 1 m/s, casualties automatically board
   - You'll see "Wounded picked up!" message
   - Status updates on casualty condition during flight

5. **Transport to MASH**
   - Fly to nearest friendly MASH
   - Land within 200m with speed < 1 m/s
   - Mission complete!

### Radio Menu Commands

Press **F10** in a MEDEVAC helicopter:

```
MEDEVAC
├── Active MEDEVAC/SAR - Shows all active casualty locations
└── View Statistics    - Shows your rescue statistics
```

---

## 🔧 How It Works

### Casualty Generation
1. Script monitors all unit destruction events
2. When a ground vehicle is destroyed:
   - Checks crew survival percentage
   - Spawns infantry group at destruction location
   - Applies immortal/invisible settings if configured
   - Adds to wounded groups list

### Rescue Process
1. **Request Phase** (15s delay)
   - Casualty group transmits coordinates
   - Map marker created (if enabled)
   - First signal flare fired (if enabled)

2. **Search Phase** (< 3km from casualties)
   - Smoke deployed at casualty location
   - Signal flares fire every 3 minutes
   - Area illuminated if nighttime

3. **Pickup Phase** (< 600m)
   - Casualties move toward helicopter
   - Must land within 200m and reduce speed < 1 m/s
   - Casualties automatically board

4. **Transport Phase**
   - Bleed timer active
   - Status messages based on severity
   - Helicopter damage warnings (if enabled)
   - Weather affects time available

5. **Delivery Phase** (at MASH)
   - Must land within 200m and reduce speed < 1 m/s
   - Mission complete
   - Statistics updated
   - Map marker removed

### Bleed Time Calculation

Base time calculated from:
```
Distance to MASH ÷ Cruise Speed = Base Time
```

Then modified by:
- **Weather multiplier** (0.85x to 1.3x)
- **Unit type multiplier** (0.8x to 1.2x)
- **Random variation** (1.0x to 1.2x)
- **Minimum time constraint** (30s minimum)

Example: Tank destroyed 40km from MASH in -5°C weather
- Base: 40000m ÷ 40 m/s = 1000s
- Weather: 1000s × 1.15 (cold) = 1150s
- Unit type: 1150s × 0.8 (tank) = 920s
- Random: 920s to 1104s (×1.0 to ×1.2)
- **Result: 15-18 minute time window**

---

## 👏 Credits

### Original Authors
**RagnarDa, DragonShadow & Shagrat** (2013-2014)
- Original MEDEVAC script concept and implementation
- Core rescue mechanics and gameplay systems

### Major Contributors
**DragonShadow** (v5 Beta)
- Injection of existing units as MEDEVAC groups
- Distance-based minimum bleed time calculations
- Direct flight distance calculations
- Closest MASH finding algorithm
- Rescue trigger function system

**Shagrat** (v5 Beta)
- Additional gameplay refinements
- Balancing improvements

**alexej21** (v4.1)
- Immortal wounded crew option
- RPG soldier spawning option

### v6.0.0 Enhancement
**HeavenDCS** (2025-11-07)
- Complete code modernization and bug fixes
- F10 map marker integration
- Signal flares and illumination system
- Weather-based difficulty system
- Time of day effects
- Unit type triage system
- Helicopter damage warning system
- Statistics tracking system
- Enhanced error handling and logging
- Fixed 40+ parameter errors
- DCS ScriptingLib API compliance
- Comprehensive nil safety checks

---

## 📜 Changelog

### v6.0.0 (2025-11-07) - Enhanced by HeavenDCS

**New Features:**
- ✨ F10 Map Markers for active MEDEVAC locations
- ✨ Signal Flares fired periodically from wounded positions
- ✨ Illumination Bombs for night pickup zones
- ✨ Weather-Based Difficulty (temperature affects bleed rate)
- ✨ Time of Day Effects (night missions more challenging)
- ✨ Unit Type Triage (different bleed rates by vehicle type)
- ✨ Helicopter Damage Warnings for pilots
- ✨ Statistics Tracking (lives saved, missions completed, etc.)
- ✨ Enhanced messaging with context-aware information
- ✨ Auto-refresh markers as situations change
- ✨ Coalition-specific statistics
- ✨ Critical wound alerts

**Bug Fixes:**
- 🐛 Fixed all "Parameter #self missed" errors (40+ instances)
- 🐛 Fixed `string.format` nil argument errors with `tostring()` wrappers
- 🐛 Added comprehensive nil safety checks throughout
- 🐛 Fixed all static vs instance method calls per DCS ScriptingLib
- 🐛 Protected all method chaining with proper nil checks
- 🐛 Fixed incorrect event ID 19 check (ENGINE_SHUTDOWN → PLAYER_ENTER_UNIT)
- 🐛 Pre-populated unit→group cache to handle DCS API limitations

**Code Quality:**
- 🔧 Replaced hardcoded coalition numbers with enumerations
- 🔧 Replaced hardcoded smoke colors with enumerations
- 🔧 Namespaced global utility functions
- 🔧 Enhanced error handling with detailed messages and stack traces
- 🔧 Added input validation for all critical functions
- 🔧 Improved code documentation and comments
- 🔧 Added debug logging system with 5 verbosity levels
- 🔧 Modernized code to use current DCS API best practices

### v5.1.0 (2025-11-06)
- Enhanced error handling
- Improved code documentation
- MiST 3.2+ compatibility verification

### v5.0 (Beta)
- Merged changes by DragonShadow and Shagrat
- Distance-based bleed time calculations
- Closest MASH finding
- Rescue trigger functions

### v4.2
- MiST 3.2+ compatibility verified

### v4.1
- Re-smoke on medevac crash
- Bug fixes

### v4.0
- Immortal wounded option (alexej21)
- RPG soldier spawn option (alexej21)

### v3.2
- Multiple MASH support
- Hideable bleed timer option

### v3.1
- MASH coalition validation
- Coalition-specific smoke colors
- Removed non-functional MiST messaging option

---

## 🆘 Support

### Troubleshooting

**Script doesn't load:**
- Ensure MiST is loaded BEFORE MEDEVAC script
- Check DCS.log for error messages
- Verify unit names match exactly (case-sensitive)

**No casualties spawning:**
- Check crew survival percentages (set to 100 for testing)
- Ensure ground vehicles are being destroyed
- Check `medevac.debug_verbose` setting (set to 3 for info logs)

**Helicopter can't pick up casualties:**
- Ensure you're within 200m
- Reduce speed to < 1 m/s
- Must be on the ground (not in air)
- Check coalition matches

**Map markers not showing:**
- Ensure `medevac.useMapMarkers = true`
- Check F10 map (not F11)
- Verify casualties are same coalition

**Statistics not tracking:**
- Ensure `medevac.trackStatistics = true`
- Use F10 Radio Menu → MEDEVAC → View Statistics

### Debug Mode

Enable detailed logging:
```lua
medevac.debug_verbose = 5  -- Maximum verbosity
```

Check `DCS.log` file in:
```
C:\Users\[YourName]\Saved Games\DCS\Logs\
```

### Reporting Issues

When reporting issues, please provide:
1. DCS version
2. MiST version  
3. Relevant section of DCS.log
4. Mission file (if possible)
5. Steps to reproduce

---

## 📄 License

This script is provided as-is for the DCS World community.

**Original Authors:** RagnarDa, DragonShadow, Shagrat  
**v6.0.0 Enhancement:** HeavenDCS

Feel free to modify and redistribute with proper attribution.

---

## 🌟 Show Your Support

If you find this script useful:
- ⭐ Star this repository
- 🐛 Report bugs and issues
- 💡 Suggest new features
- 🤝 Contribute improvements
- 📢 Share with the DCS community

---

## 🔗 Related Projects

- [MiST](https://github.com/mrSkortch/MissionScriptingTools) - Mission Scripting Tools
- [MOOSE](https://github.com/FlightControl-Master/MOOSE) - Mission Object Oriented Scripting Environment
- [DCS Lua Documentation](https://wiki.hoggitworld.com/view/Simulator_Scripting_Engine_Documentation)

---

<div align="center">

**🚁 Fly Safe, Save Lives 🚁**

*For realistic combat search and rescue in DCS World*

[Report Bug](../../issues) · [Request Feature](../../issues) · [Documentation](../../wiki)

</div>
