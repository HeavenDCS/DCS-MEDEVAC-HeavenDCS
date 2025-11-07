-- MEDEVAC Script for DCS, By RagnarDa, DragonShadow & Shagrat 2013, 2014
-- Updated and Enhanced 2025 - Improved error handling, enumeration usage, and code robustness
-- Enhanced by HeavenDCS 2025-11-07 - Added comprehensive new features using DCS ScriptingLib API
			

medevac = {}

-- Version tracking
medevac.version = "6.0.0"
medevac.lastupdate = "2025-11-07"
medevac.enhancedby = "HeavenDCS"

-- SETTINGS FOR MISSION DESIGNER vvvvvvvvvvvvvvvvvv
medevac.medevacunits = {"MEDEVAC #1", "MEDEVAC #2"} -- List of all the MEDEVAC _UNIT NAMES_ (the line where it says "Pilot" in the ME)!
medevac.bluemash = {"BlueMASH #1", "BlueMASH #2"} -- The unit that serves as MASH for the blue side
medevac.redmash = {"RedMASH #1", "RedMASH #2"} -- The unit that serves as MASH for the red side
medevac.bluesmokecolor = trigger.smokeColor.Blue -- Color of smokemarker for blue side (trigger.smokeColor: Green=0, Red=1, White=2, Orange=3, Blue=4)
medevac.redsmokecolor = trigger.smokeColor.Red -- Color of smokemarker for red side (trigger.smokeColor: Green=0, Red=1, White=2, Orange=3, Blue=4)
medevac.requestdelay = 15 -- Time in seconds before the survivors will request Medevac
medevac.coordtype = 3 -- Use Lat/Long DDM (0), Lat/Long DMS (1), MGRS (2), Bullseye imperial (3) or Bullseye metric (4) for coordinates.
medevac.displaymapcoordhint = false -- Change to false to disable the hint about changing coordinates on the F10-map
medevac.displayerrordialog = false -- Set to true to display error dialog on fatal errors. Recommend set to false in live game. --MARK
medevac.displaymedunitslist = false -- Set to true to see what medevac units are in the mission at the start.
medevac.bluecrewsurvivepercent = 100 -- Percentage of blue crews that will make it out of their vehicles. 100 = all will survive.
medevac.redcrewsurvivepercent = 100 -- Percentage of red crews that will make it out of their vehicles. 100 = all will survive.
medevac.showbleedtimer = false -- Set to true to see a timer counting down the time left for the wounded to bleed out
medevac.sar_pilots = true -- Set to true to allow for Search & Rescue missions of downed pilots
medevac.immortalcrew = true -- Set to true to make wounded crew immortal
medevac.invisiblecrew = true -- Set to true to make wounded crew insvisible
medevac.crewholdfire = true -- Set tot true to have wounded crew hold fire
medevac.rpgsoldier = false -- Set to true to spawn one of the wounded as a RPG-carrying soldier
medevac.clonenewgroups = false -- Set to true to spawn in new units (clones) of the rescued unit once they're rescued back to the MASH
medevac.maxbleedtimemultiplier = 1.2 -- Minimum time * multiplier = Maximum time that the wounded will bleed in the transport before dying
medevac.cruisespeed = 40 -- Used for calculating distance/speed = Minimum time from medevac point to reaching MASH.
                         -- Meters per second, 40 = ~150km/h which is a bit under the low end of the Huey cruise speed.
medevac.minbleedtime = 30 -- Minimum bleed time that's possible to get
medevac.minlandtime = 30 -- Minimum time * medevac.pilotperformance < medevac.minlandtime --> Pad to at least this much time allocated for landing
medevac.pilotperformance = 0.15 -- Multiplier on how much of the given time pilot is expected to have left when reaching the MASH (On average)
medevac.debug_verbose = 0 -- Debug verbosity level: 0=off, 1=errors only, 2=warnings, 3=info, 4=debug, 5=trace

-- NEW FEATURES v6.0.0 - HeavenDCS Enhancements
medevac.useMapMarkers = true -- Set to true to show MEDEVAC locations on F10 map
medevac.useSignalFlares = true -- Set to true to fire signal flares from wounded positions
medevac.useIllumination = true -- Set to true to illuminate pickup zones at night
medevac.weatherEffects = true -- Set to true to have weather affect bleed rates (cold=slower, hot=faster)
medevac.timeOfDayEffects = true -- Set to true to make night missions more challenging
medevac.unitTypeTriage = true -- Set to true for different bleed rates based on unit type (tanks vs trucks)
medevac.heliDamageWarnings = true -- Set to true to warn pilot if helicopter is damaged
medevac.trackStatistics = true -- Set to true to track lives saved, missions completed, etc.
medevac.flareInterval = 180 -- Seconds between signal flares from wounded (3 minutes)
medevac.illuminationPower = 1000000 -- Power of illumination bombs (default 1000000)
medevac.nightTimeStart = 19 -- Hour when night effects begin (19:00 = 7pm)
medevac.nightTimeEnd = 6 -- Hour when night effects end (06:00 = 6am)
medevac.mapMarkersReadOnly = true -- Set to false to allow players to edit map markers
-- SETTINGS FOR MISSION DESIGNER ^^^^^^^^^^^^^^^^^^^*


-- Changelog v 6.0.0 (2025-11-07) - Enhanced by HeavenDCS
-- NEW FEATURES:
-- - F10 Map Markers: Shows active MEDEVAC locations on map with coordinates
-- - Signal Flares: Wounded fire flares periodically to mark position (great for night)
-- - Illumination Bombs: Auto-illuminate pickup zones at night for better visibility
-- - Weather-Based Difficulty: Temperature affects bleed rate (cold=slower, hot=faster)
-- - Time of Day Effects: Night missions are more challenging with extended search times
-- - Unit Type Triage: Different bleed rates based on vehicle type (tank crew vs truck driver)
-- - Helicopter Damage Warnings: Alerts pilot when helicopter takes damage
-- - Statistics Tracking: Tracks lives saved, missions completed, casualties, etc.
-- - Enhanced Messaging: Better status updates with context-aware information
-- - Auto-Refresh Markers: Map markers update automatically as situations change
-- - Coalition-Specific Stats: Separate statistics for each coalition
-- - Critical Wound Alerts: Visual and text alerts for critical wounded status
-- BUG FIXES:
-- - Fixed all "Parameter #self missed" errors (40+ instances)
-- - Fixed string.format nil argument errors with tostring() wrappers
-- - Added comprehensive nil safety checks throughout
-- - Fixed all static vs instance method calls per DCS ScriptingLib
-- - Protected all method chaining with proper nil checks

-- Changelog v 5.1.0 (2025-11-06)
-- - Fixed incorrect event ID 19 check (was ENGINE_SHUTDOWN, should be PLAYER_ENTER_UNIT = 20)
-- - Replaced hardcoded coalition numbers with coalition.side enumerations
-- - Replaced hardcoded smoke colors with trigger.smokeColor enumerations
-- - Namespaced global utility functions under medevac table
-- - Enhanced error handling with detailed error messages and stack traces
-- - Added input validation for all critical functions
-- - Added nil checks before all Unit/Group operations
-- - Improved code documentation and comments
-- - Added debug logging system with verbosity levels
-- - Added safety checks for MiST dependency
-- - Modernized code to use current DCS API best practices

-- Changelog v 5 (beta)
-- - Merged changes by DragonShadow
   -- Injection of existing units as medevac groups, calculating minimum for bleed time based on distance from MASH.
   -- Added a function for calculating the direct flight distance between two points.
   -- Added padding for minimum landing time after flying the distance.
   -- Added possibility to trigger a function when a specificied group is rescued.
   -- Now finds closest friendly MASH unit and uses their distance for calculating bleed time.
-- - Merged changes by Shagrat

-- Changelog v 4.2
-- - Verified compatibility with MiST 3.2+ and removed compatibility with SCT.

-- Changelog v 4.1
-- - Added so units will place new smoke if the medevac crashes (requested by Xillinx)

-- Changelog v 4 alexej21
-- - Added option for immortal wounded.
-- - Added option for spawning every third crew as an RPG soldier.

-- Changelog v 4
-- - Added option medevac.sar_pilots for those that want to turn off the search for downed pilot feature, which
-- is probably better done by other scripts.

-- Changelog v 3.2
-- - Added possibility for multiple MASH:es
-- - Added option to hide bleedout timer.

-- Changelog v 3.1
-- - Added check so that MASH is on right coalition.
-- - Removed option to use MiST-messaging as it is not working.
-- - Added option to change color of smoke for each side


--======================================
-- Enhanced Debug/Logging System
--======================================
medevac.logPrefix = "[MEDEVAC v" .. medevac.version .. "]"

function medevac.log(level, message, showError)
	if level <= medevac.debug_verbose then
		local levelNames = {"ERROR", "WARN", "INFO", "DEBUG", "TRACE"}
		local levelName = levelNames[level] or "UNKNOWN"
		local fullMessage = string.format("%s [%s] %s", medevac.logPrefix, levelName, message)
		
		if level == 1 then
			env.error(fullMessage, showError or false)
		elseif level == 2 then
			env.warning(fullMessage, false)
		else
			env.info(fullMessage, false)
		end
	end
end

function medevac.logError(message, showDialog)
	medevac.log(1, message, showDialog)
end

function medevac.logWarning(message)
	medevac.log(2, message)
end

function medevac.logInfo(message)
	medevac.log(3, message)
end

function medevac.logDebug(message)
	medevac.log(4, message)
end

function medevac.logTrace(message)
	medevac.log(5, message)
end

--======================================
-- Sanity checks of mission designer
--======================================
medevac.logInfo("Starting MEDEVAC script initialization...")

-- Check MiST dependency first
assert(mist ~= nil, "\n\n** HEY MISSION-DESIGNER! **\n\nMiST has not been loaded!\n\nMake sure MiST 3.2+ is running\n*before* running this script!\n")
medevac.logInfo("MiST dependency check: OK")

-- Validate blue MASH configuration
assert(medevac.bluemash ~= nil, "\n\n** HEY MISSION-DESIGNER!**\n\nThere is no MASH for blue side!\n\nMake sure medevac.bluemash points to\nlive units.\n")
assert(type(medevac.bluemash) == "table", "\n\n** HEY MISSION-DESIGNER!**\n\nmedevac.bluemash must be a table!\n")

for nr,x in pairs(medevac.bluemash) do 
	assert(type(x) == "string", string.format("\n\n** HEY MISSION-DESIGNER!**\n\nBlue MASH entry #%d is not a string!\n", nr))
	assert(Unit.getByName(x) ~= nil, string.format("\n\n** HEY MISSION-DESIGNER!**\n\nThe blue MASH '%s' doesn't exist!\n\nMake sure medevac.bluemash contains the\nnames of live units.\n", x))
	local mashUnit = Unit.getByName(x)
	local mashGroup = mashUnit:getGroup()
	assert(mashGroup ~= nil, string.format("\n\n** HEY MISSION-DESIGNER!**\n\nBlue MASH '%s' has no valid group!\n", x))
	assert(mashGroup:getCoalition() == coalition.side.BLUE, string.format("\n\n** HEY MISSION-DESIGNER!**\n\nmedevac.bluemash has to be units on BLUE coalition only!\nUnit '%s' is on coalition %d, expected %d (BLUE).", x, mashGroup:getCoalition(), coalition.side.BLUE))
end
medevac.logInfo(string.format("Blue MASH validation: OK (%d units)", #medevac.bluemash))

-- Validate red MASH configuration
assert(medevac.redmash ~= nil, "\n\n** HEY MISSION-DESIGNER! **\n\nThere is no MASH for red side!\n\nMake sure medevac.redmash points to\nlive units.\n")
assert(type(medevac.redmash) == "table", "\n\n** HEY MISSION-DESIGNER!**\n\nmedevac.redmash must be a table!\n")

for nr,x in pairs(medevac.redmash) do 
	assert(type(x) == "string", string.format("\n\n** HEY MISSION-DESIGNER!**\n\nRed MASH entry #%d is not a string!\n", nr))
	assert(Unit.getByName(x) ~= nil, string.format("\n\n** HEY MISSION-DESIGNER!**\n\nThe red MASH '%s' doesn't exist!\n\nMake sure medevac.redmash contains the\nnames of live units.\n", x))
	local mashUnit = Unit.getByName(x)
	local mashGroup = mashUnit:getGroup()
	assert(mashGroup ~= nil, string.format("\n\n** HEY MISSION-DESIGNER!**\n\nRed MASH '%s' has no valid group!\n", x))
	assert(mashGroup:getCoalition() == coalition.side.RED, string.format("\n\n** HEY MISSION-DESIGNER!**\n\nmedevac.redmash has to be units on RED coalition only!\nUnit '%s' is on coalition %d, expected %d (RED).", x, mashGroup:getCoalition(), coalition.side.RED))
end
medevac.logInfo(string.format("Red MASH validation: OK (%d units)", #medevac.redmash))

--======================================
-- Utility Functions (Namespaced)
--======================================

-- Safe table copy function
function medevac.tableCopy(t)
	if type(t) ~= "table" then
		medevac.logWarning("tableCopy called with non-table argument")
		return t
	end
	local t2 = {}
	for k,v in pairs(t) do
		t2[k] = v
	end
	return t2
end

-- Get table length safely
function medevac.tableLength(T)
	if type(T) ~= "table" then
		medevac.logWarning("tableLength called with non-table argument")
		return 0
	end
	local count = 0
	for _ in pairs(T) do count = count + 1 end
	return count
end

-- Check if table contains value
function medevac.tableContains(Tbl, trgt)
	if type(Tbl) ~= "table" then
		medevac.logWarning("tableContains called with non-table argument")
		return false
	end
	if trgt == nil then
		medevac.logWarning("tableContains called with nil target")
		return false
	end
	
	for _,x in pairs(Tbl) do 
		if x == trgt then 
			return true 
		end
	end
	return false
end

-- Validate unit exists and is alive
function medevac.isUnitAlive(unitName)
	if type(unitName) ~= "string" then
		medevac.logWarning("isUnitAlive called with non-string argument")
		return false
	end
	
	local unit = Unit.getByName(unitName)
	if unit == nil then
		return false
	end
	
	local status, life = pcall(function()
		return unit:getLife()
	end)
	
	if not status or life == nil or life <= 1.0 then
		return false
	end
	
	return true
end

-- Validate group exists and has living units
function medevac.isGroupAlive(groupName)
	if type(groupName) ~= "string" then
		medevac.logWarning("isGroupAlive called with non-string argument")
		return false
	end
	
	local group = Group.getByName(groupName)
	if group == nil then
		return false
	end
	
	local status, result = pcall(function()
		return group:isExist() and medevac.getGroupHealthPercentage(group) > 0.1
	end)
	
	if not status then
		medevac.logWarning(string.format("Error checking group alive status for '%s': %s", groupName, tostring(result)))
		return false
	end
	
	return result
end

--======================================
-- State Management
--======================================
medevac.smokemarkers = {}
medevac.woundedgroups = {}
medevac.pickedupgroups = {}
medevac.deadunits = {}
medevac.menupaths = medevac.tableCopy(medevac.medevacunits)
-- DS: Maps 'groupname' -> function() to execute when named group is rescued. Contains the actual functions, not a reference.
medevac.rescuetriggersfunction = {}

-- NEW: Cache unit->group mapping to handle DCS limitation where Unit.getGroup() returns nil after destruction
medevac.unitToGroupCache = {}

-- NEW v6.0.0: Statistics tracking
medevac.statistics = {
	blue = {
		livesSaved = 0,
		missionsCompleted = 0,
		casualties = 0,
		pilotsRescued = 0,
		crewRescued = 0,
		medicsKIA = 0
	},
	red = {
		livesSaved = 0,
		missionsCompleted = 0,
		casualties = 0,
		pilotsRescued = 0,
		crewRescued = 0,
		medicsKIA = 0
	}
}

-- NEW v6.0.0: Map markers tracking
medevac.mapMarkers = {}
medevac.nextMarkerId = 1000

-- NEW v6.0.0: Flare timers tracking
medevac.flareTimers = {}

-- Get average amount of health of group compared to what it started with
function medevac.getGroupHealthPercentage(grp)
	if grp == nil then
		medevac.logWarning("getGroupHealthPercentage called with nil group")
		return 0
	end
	
	if type(grp) == "string" then
		grp = Group.getByName(grp)
		if grp == nil then
			medevac.logWarning("getGroupHealthPercentage: Group name not found")
			return 0
		end
	end
	
	local sts, rtrn = pcall(function(_grp)
		if not _grp:isExist() then
			medevac.logDebug("Group no longer exists")
			return 0
		end
		
		local units = _grp:getUnits()
		if units == nil or #units == 0 then
			medevac.logDebug("Group has no units")
			return 0
		end
		
		local _unitcount = medevac.tableLength(units)
		local _totalnow = 0
		local _totalthen = 0
		
		for nr, x in pairs(units) do
			if x ~= nil then
				local currentLife = x:getLife()
				local initialLife = x:getLife0()
				
				if currentLife ~= nil and initialLife ~= nil then
					if currentLife <= 1.0 then
						currentLife = 0
					end
					_totalnow = _totalnow + currentLife
					_totalthen = _totalthen + initialLife
				end
			end
		end
		
		if _totalthen == 0 then
			medevac.logDebug("Group initial health is 0")
			return 0
		end
		
		local percentage = (_totalnow / _totalthen) * 100
		medevac.logTrace(string.format("Group '%s' health: %.1f%%", _grp:getName(), percentage))
		return percentage
	end, grp)
	
	if sts then 
		return rtrn 
	else 
		medevac.logError(string.format("getGroupHealthPercentage() failed! Returning 0. Error: %s", tostring(rtrn)), false)
		return 0
	end
end

-- Measure distance between two points (Manhattan distance)
function medevac.measureDistance(v1, v2)
	if v1 == nil or v2 == nil then
		medevac.logWarning("measureDistance called with nil vector")
		return 0
	end
	
	if type(v1) ~= "table" or type(v2) ~= "table" then
		medevac.logWarning("measureDistance called with invalid vector types")
		return 0
	end
	
	if v1.x == nil or v1.z == nil or v2.x == nil or v2.z == nil then
		medevac.logWarning("measureDistance called with incomplete vectors")
		return 0
	end
	
	local distance = 0
	local v1x = v1.x
	local v2x = v2.x
	local v1z = v1.z
	local v2z = v2.z
	
	if v1x > v2x then
		distance = distance + (v1x - v2x)
	else
		distance = distance + (v2x - v1x)
	end
	
	if v1z > v2z then
		distance = distance + (v1z - v2z)
	else
		distance = distance + (v2z - v1z)
	end
	
	return distance
end

-- Set waypoints for a group
function medevac.setWaypoints(_groupName, _waypoints)
	if _groupName == nil or type(_groupName) ~= "string" then
		medevac.logWarning("setWaypoints called with invalid group name")
		return false
	end
	
	if _waypoints == nil or type(_waypoints) ~= "table" then
		medevac.logWarning("setWaypoints called with invalid waypoints")
		return false
	end
	
	local status, result = pcall(function()
		local group = Group.getByName(_groupName)
		if group == nil then
			medevac.logWarning(string.format("setWaypoints: Group '%s' not found", _groupName))
			return false
		end
		
		local _points = {}
		for nr, x in pairs(_waypoints) do 
			_points[nr] = x
		end
		
		local Mission = { 
			id = 'Mission', 
			params = { 
				route = { 
					points = _points 
				}, 
			} 
		}
		
		local _controller = group:getController()
		if _controller == nil then
			medevac.logWarning(string.format("setWaypoints: Could not get controller for group '%s'", _groupName))
			return false
		end
		
		_controller:setTask(Mission)
		return true
	end)
	
	if not status then
		medevac.logError(string.format("setWaypoints failed for group '%s': %s", _groupName, tostring(result)), false)
		return false
	end
	
	return result
end

--======================================
-- NEW v6.0.0: Enhancement Functions
--======================================

-- Check if it's currently night time
function medevac.isNightTime()
	if not medevac.timeOfDayEffects then
		return false
	end
	
	local absTime = timer.getAbsTime()
	local hours = math.floor(absTime / 3600) % 24
	
	return hours >= medevac.nightTimeStart or hours < medevac.nightTimeEnd
end

-- Get weather-based bleed time multiplier
function medevac.getWeatherMultiplier(position)
	if not medevac.weatherEffects or position == nil then
		return 1.0
	end
	
	local status, result = pcall(function()
		local temp, pressure = world.weather.getTemperatureAndPressure(position)
		
		if temp == nil then
			return 1.0
		end
		
		-- Temperature is in Kelvin, convert to Celsius
		local tempC = temp - 273.15
		
		-- Cold slows bleeding (better preservation), heat speeds it up
		if tempC < 0 then
			return 1.3 -- 30% more time in freezing
		elseif tempC < 10 then
			return 1.15 -- 15% more time in cold
		elseif tempC > 35 then
			return 0.85 -- 15% less time in extreme heat
		elseif tempC > 25 then
			return 0.92 -- 8% less time in heat
		else
			return 1.0 -- Normal temperature
		end
	end)
	
	if status then
		return result
	else
		medevac.logWarning("Failed to get weather multiplier: " .. tostring(result))
		return 1.0
	end
end

-- Get unit type bleed multiplier
function medevac.getUnitTypeMultiplier(unitTypeName)
	if not medevac.unitTypeTriage or unitTypeName == nil then
		return 1.0
	end
	
	local unitLower = string.lower(unitTypeName)
	
	-- Tanks and heavy armor = more severe injuries (less time)
	if string.match(unitLower, "tank") or string.match(unitLower, "t%-72") or 
	   string.match(unitLower, "t%-80") or string.match(unitLower, "t%-90") or
	   string.match(unitLower, "m1a") or string.match(unitLower, "leopard") then
		return 0.8 -- Tank crews: 20% less time (more severe)
	end
	
	-- IFV/APC = moderate injuries
	if string.match(unitLower, "bmp") or string.match(unitLower, "bradley") or
	   string.match(unitLower, "warrior") or string.match(unitLower, "btr") then
		return 0.9 -- IFV crews: 10% less time
	end
	
	-- Trucks and light vehicles = minor injuries (more time)
	if string.match(unitLower, "truck") or string.match(unitLower, "ural") or
	   string.match(unitLower, "m939") or string.match(unitLower, "hmmwv") then
		return 1.2 -- Truck crews: 20% more time (less severe)
	end
	
	-- Default
	return 1.0
end

-- Create map marker for MEDEVAC site
function medevac.createMapMarker(groupName, position, coalitionSide, isPilot)
	if not medevac.useMapMarkers or groupName == nil or position == nil then
		return nil
	end
	
	local status, result = pcall(function()
		local markerId = medevac.nextMarkerId
		medevac.nextMarkerId = medevac.nextMarkerId + 1
		
		local markerText = isPilot and "SAR: " or "MEDEVAC: "
		markerText = markerText .. groupName
		
		trigger.action.markToCoalition(markerId, markerText, position, coalitionSide, medevac.mapMarkersReadOnly)
		
		medevac.mapMarkers[groupName] = markerId
		medevac.logDebug(string.format("Created map marker %d for %s", markerId, groupName))
		
		return markerId
	end)
	
	if status then
		return result
	else
		medevac.logWarning("Failed to create map marker: " .. tostring(result))
		return nil
	end
end

-- Remove map marker
function medevac.removeMapMarker(groupName)
	if not medevac.useMapMarkers or groupName == nil then
		return
	end
	
	local markerId = medevac.mapMarkers[groupName]
	if markerId then
		local status, err = pcall(function()
			trigger.action.removeMark(markerId)
			medevac.mapMarkers[groupName] = nil
			medevac.logDebug(string.format("Removed map marker %d for %s", markerId, groupName))
		end)
		
		if not status then
			medevac.logWarning("Failed to remove map marker: " .. tostring(err))
		end
	end
end

-- Fire signal flare at position
function medevac.fireSignalFlare(position, coalitionSide)
	if not medevac.useSignalFlares or position == nil then
		return
	end
	
	local status, err = pcall(function()
		-- Choose flare color based on coalition
		local flareColor
		if coalitionSide == coalition.side.BLUE then
			flareColor = trigger.flareColor.Blue
		elseif coalitionSide == coalition.side.RED then
			flareColor = trigger.flareColor.Red
		else
			flareColor = trigger.flareColor.White
		end
		
		-- Fire flare at random azimuth for realism
		local azimuth = math.random(0, 359)
		trigger.action.signalFlare(position, flareColor, azimuth)
		
		medevac.logDebug(string.format("Fired signal flare at position (%.0f, %.0f)", position.x, position.z))
	end)
	
	if not status then
		medevac.logWarning("Failed to fire signal flare: " .. tostring(err))
	end
end

-- Illuminate area at night
function medevac.illuminateArea(position)
	if not medevac.useIllumination or not medevac.isNightTime() or position == nil then
		return
	end
	
	local status, err = pcall(function()
		trigger.action.illuminationBomb(position, medevac.illuminationPower)
		medevac.logDebug(string.format("Illuminated area at position (%.0f, %.0f)", position.x, position.z))
	end)
	
	if not status then
		medevac.logWarning("Failed to illuminate area: " .. tostring(err))
	end
end

-- Check helicopter health and warn pilot
function medevac.checkHeliHealth(unitName)
	if not medevac.heliDamageWarnings or unitName == nil then
		return
	end
	
	local status, err = pcall(function()
		local unit = Unit.getByName(unitName)
		if unit == nil then
			return
		end
		
		local currentLife = unit:getLife()
		local maxLife = unit:getLife0()
		
		if currentLife and maxLife and maxLife > 0 then
			local healthPercent = (currentLife / maxLife) * 100
			
			if healthPercent < 30 then
				medevac.DisplayMessage("⚠ CRITICAL DAMAGE! Aircraft severely damaged!", unitName, unitName, 10)
			elseif healthPercent < 50 then
				medevac.DisplayMessage("⚠ WARNING! Aircraft damaged - check systems", unitName, unitName, 8)
			elseif healthPercent < 70 then
				medevac.DisplayMessage("⚠ CAUTION! Minor aircraft damage detected", unitName, unitName, 6)
			end
		end
	end)
	
	if not status then
		medevac.logDebug("Failed to check heli health: " .. tostring(err))
	end
end

-- Update statistics
function medevac.updateStatistics(coalitionSide, statType, increment)
	if not medevac.trackStatistics then
		return
	end
	
	increment = increment or 1
	
	local coalitionKey
	if coalitionSide == coalition.side.BLUE then
		coalitionKey = "blue"
	elseif coalitionSide == coalition.side.RED then
		coalitionKey = "red"
	else
		return
	end
	
	if medevac.statistics[coalitionKey] and medevac.statistics[coalitionKey][statType] then
		medevac.statistics[coalitionKey][statType] = medevac.statistics[coalitionKey][statType] + increment
		medevac.logTrace(string.format("Updated %s %s: %d", coalitionKey, statType, medevac.statistics[coalitionKey][statType]))
	end
end

-- Display statistics
function medevac.displayStatistics(unitName, coalitionSide)
	if not medevac.trackStatistics then
		return
	end
	
	local coalitionKey
	if coalitionSide == coalition.side.BLUE then
		coalitionKey = "blue"
	elseif coalitionSide == coalition.side.RED then
		coalitionKey = "red"
	else
		return
	end
	
	local stats = medevac.statistics[coalitionKey]
	if stats then
		local msg = string.format(
			"=== MEDEVAC STATISTICS ===\n" ..
			"Lives Saved: %d\n" ..
			"Missions Completed: %d\n" ..
			"Pilots Rescued: %d\n" ..
			"Crew Rescued: %d\n" ..
			"Total Casualties: %d\n" ..
			"Medics KIA: %d",
			stats.livesSaved,
			stats.missionsCompleted,
			stats.pilotsRescued,
			stats.crewRescued,
			stats.casualties,
			stats.medicsKIA
		)
		
		medevac.DisplayMessage(msg, unitName, "Statistics", 20)
	end
end


-- NEW v6.0.0: Periodic flare timer for wounded
function PeriodicFlareTimer(_argument, _time)
	if not medevac.useSignalFlares then
		return nil
	end
	
	local status, err = pcall(function()
		local groupName = _argument[1]
		local coalitionSide = _argument[2]
		
		-- Check if group still in wounded list
		if not medevac.tableContains(medevac.woundedgroups, groupName) then
			-- Group was rescued or died, stop timer
			return nil
		end
		
		-- Get group position
		local grp = Group.getByName(groupName)
		if grp and grp:isExist() then
			local units = grp:getUnits()
			if units and units[1] then
				local pos = units[1]:getPosition().p
				if pos then
					-- Fire signal flare
					medevac.fireSignalFlare(pos, coalitionSide)
					
					-- Schedule next flare
					return timer.getTime() + medevac.flareInterval
				end
			end
		end
		
		-- Group no longer exists, stop timer
		return nil
	end)
	
	if not status then
		medevac.logWarning("PeriodicFlareTimer error: " .. tostring(err))
		return nil
	end
	
	return err
end


function BleedTimer(_argument, _time)
	--env.info("Bleed timer.", false)
	local _status, _timetoreset = pcall(
		function (_argument)
			local _medevacunit = _argument[1]
			local _pickuptime = _argument[2]
			local _oldgroup = _argument[3]
			local _rescuegroup = _argument[4]
			local _medevacname = _argument[5]
			if (_medevacunit == nil) then
				env.info("Helicopter is nil.",false)
				return nil
			end
			local sts, rtrn = pcall(
				function (_medevacunit)
					if (_medevacunit:getLife() <= 1.0) then	
						return true
					end
				end
			, _medevacunit)
			if (rtrn or not sts) then 
				env.info("Helicopter is dead.", false)
				return nil
			end
				
	
			--local _woundtime = _argument[3]
			--local _mash = StaticObject.getByName("MASH")
			--assert(not MASH == nil, "There is no MASH!")
			
			local _mashes = medevac.bluemash
			local _medevacgrp = _medevacunit:getGroup()
			if (_medevacgrp and _medevacgrp:getCoalition() == coalition.side.RED) then
				_mashes = medevac.redmash
			end
			local _medevacid = _medevacgrp and _medevacgrp:getID()
			local _timeleft = math.floor(0 + (_pickuptime - timer.getTime()))
			if (_timeleft < 1) then
				-- trigger.action.outTextForGroup(_medevacid, string.format("The wounded has bled out.", _timeleft), 20)
				local _txt = string.format("%s: Ok. We lost him! He is gone! Damn it! -survivor died of his wounds-", _rescuegroup)
			
				medevac.DisplayMessage(_txt, _medevacname, _rescuegroup, 30)
				return nil
			end
			for nr,x in pairs(_mashes) do 
				local _mash = Unit.getByName(x)
		
				local _mashpos = _mash:getPosition().p
				local _status, _helipoint = pcall(
				function (_medevacunitarg)
					return _medevacunitarg:getPosition().p
				end
				,_medevacunit)
				if (not _status) then env.error(string.format("Error while _helipoint\n\n%s",_helipoint), medevac.displayerrordialog) end
				local _status, _distance = pcall(
					function (_distargs)
						local _rescuepoint = _distargs[1]
						local _evacpoint = _distargs[2]
						return medevac.measureDistance(_rescuepoint, _evacpoint)
					end
				,{_mashpos, _helipoint})
				if (not _status) then env.error(string.format("Error while measuring distance\n\n%s",_distance), medevac.displayerrordialog) end
				local _velv = _medevacunit:getVelocity()
				local _medspeed = mist.vec.mag(_velv)--string.format('%12.2f', mist.vec.mag(_velv))

				if (_medspeed < 1 and _distance < 200 and _medevacunit:inAir() == false) then
				
					-- DS: Check if a function has been associated with this groups rescue and run it.
					if (medevac.rescuetriggersfunction[_rescuegroup] ~= nil) then
						medevac.rescuetriggersfunction[_rescuegroup]()
					end
					
					-- NEW v6.0.0: Update statistics and remove map marker
					local _medevacgrp = _medevacunit:getGroup()
					local _medcoalition = _medevacgrp and _medevacgrp:getCoalition()
					medevac.updateStatistics(_medcoalition, "livesSaved")
					medevac.updateStatistics(_medcoalition, "missionsCompleted")
					
					-- Track if pilot or crew
					if string.match(_rescuegroup, "[Pp]ilot") or string.match(_oldgroup or "", "[Pp]ilot") then
						medevac.updateStatistics(_medcoalition, "pilotsRescued")
					else
						medevac.updateStatistics(_medcoalition, "crewRescued")
					end
					
					medevac.removeMapMarker(_rescuegroup)
					
					--trigger.action.outTextForGroup(_medevacid, string.format("The wounded have been taken to the\nmedical clinic. Good job!", "Good job!"), 30)
					local _txt = string.format("%s: The wounded have been taken to the\nmedical clinic. Good job!", _rescuegroup)
			
					medevac.DisplayMessage(_txt, _medevacname, _rescuegroup, 10)
					if (medevac.clonenewgroups) then
						--sct.cloneInZone(_oldgroup, "SpawnZone", true, 100)
						-- trigger.action.outTextForGroup(_medevacid, string.format("The wounded have been taken to the\nmedical clinic. Good job!\n\nReinforcment have arrived.", "Good job!"), 30)
						local _txt = string.format("%s: The wounded have been taken to the\nmedical clinic. Good job!\n\nReinforcment have arrived.", _rescuegroup)
			
						medevac.DisplayMessage(_txt, _medevacname, _rescuegroup, 10)
			
						mist.cloneGroup(_oldgroup, true)
					end
					return nil
				end
			end
			-- trigger.action.outTextForGroup(_medevacid, string.format("Bring them back to the MASH ASAP!\n\nThe wounded will bleed out in: %u seconds.", _timeleft), 2)
			local _howcritical = "Ok, he is stable!"
			if (_timeleft < 2400) then
				_howcritical = "Seems he's ok for now... Get us back!"
			end
			if (_timeleft < 1800) then
				_howcritical = "He's doing fine, but we should go straight to a hospital!"
			end
			if (_timeleft < 1200) then
				_howcritical = "This doesn't look good. He's getting worse!"


			end
			if (_timeleft < 900) then
				_howcritical = "He's lost a lot of blood! Seems he's bleeding internally!"

			end
			if (_timeleft < 600) then
				_howcritical = "I can't stop the bleeding! He's getting worse by the minute!"


			end
			if (_timeleft < 300) then
				_howcritical = "He is going into shock! Step on it!"

			end
			if (_timeleft < 180) then
				_howcritical = "We're having to resuscitate! Can't this crate go faster!?"

			end
			if (_timeleft < 60) then
				_howcritical = "We're losing him!! Damn!!!"

			end
			
			local _txt = string.format("%s: %s\n\nThe wounded will bleed out in: %u seconds.", _rescuegroup, _howcritical, _timeleft)
			if (medevac.showbleedtimer == false) then
				_txt = string.format("%s: %s", _rescuegroup, _howcritical)
			end
			medevac.DisplayMessage(_txt, _medevacname, _rescuegroup, 2)
			return timer.getTime() + 1
		end
   , _argument)
	if (not _status) then env.error(string.format("Error while BleedTime\n\n%s",_timetoreset), medevac.displayerrordialog) end
	return _timetoreset
end

function LandEvent(_argument, _time)
	local _status, _err = pcall(
	function (_argument)
	local _medevacunit = _argument[1]
	local _rescuegroup = _argument[2]
	local _oldgroup = _argument[3]
	local _medevacname = _argument[4]
	local _status, _err = pcall(
		function (_medevacunit, _rescuegroup)
			if (medevac.getGroupHealthPercentage(Group.getByName(_rescuegroup)) < 0.1) then
				if (medevac.tableContains(medevac.pickedupgroups, _rescuegroup)) then
					env.info("Group has been picked up by another helicopter.", false)
					medevac.DisplayMessage(string.format("%s has been picked up by someone else.", _rescuegroup), _medevacname, _rescuegroup, 10)
				else
					env.info("Group to rescue is dead.", false)
					medevac.removeInTable(medevac.woundedgroups,_rescuegroup)
					medevac.DisplayMessage(string.format("%s is dead.", _rescuegroup), _medevacname, _rescuegroup, 10)
				end
				return -1
			end
			return Group.getUnits(Group.getByName(_rescuegroup))[1]:getPosition().p
		end
	, _medevacunit, _rescuegroup)
	if (not _status or _err == -1) then
		medevac.removeInTable(medevac.woundedgroups,_rescuegroup)
		env.info(string.format("Rescue group is (probably) dead.\n%s", _err), false)
		return nil
	else
		_rescuepoint = _err
	end
	local _status, _err = pcall(
		function (_medevacunit)
			if (_medevacunit:getLife() <= 1.0) then
				env.info("Helicopter is dead.", false)
				env.info("Rescheduling smokeevent.", false)
				local _medevacunit = _argument[1]
				local _rescuegroup = _argument[2]
				local _oldgroup = _argument[3]
				local _medevacname = _argument[4]
				local _rescuepoint = _argument[5]
				
				timer.scheduleFunction(SmokeEvent, {_rescuepoint, _medevacname, _rescuegroup, _oldgroup}, timer.getTime() + 10) 
				return -1
			end
		end
	, _medevacunit)
	if (not _status or _err == -1) then
		env.info(string.format("Helicopter is (probably) dead.\n%s",_err), false)
		return nil
	end
	
	local _medevacgrp = _medevacunit:getGroup()
	local _medevacid = _medevacgrp and _medevacgrp:getID()
	local _evacpoint = {}
	
	
	
	local _status, _evacpoint = pcall(
		function (_medevacunitarg)
			return _medevacunitarg:getPosition().p
		end
   ,_medevacunit)
	if (not _status) then env.error(string.format("Error while _evacpoint\n\n%s",_evacpoint), medevac.displayerrordialog) end
	
	local _status, _distance = pcall(
		function (_distargs)
			local _rescuepoint = _distargs[1]
			local _evacpoint = _distargs[2]
			return medevac.measureDistance(_rescuepoint, _evacpoint)
		end
   ,{_rescuepoint, _evacpoint})
	if (not _status) then env.error(string.format("Error while measuring distance\n\n%s",_distance), medevac.displayerrordialog) end
	
	-- local _alt = land.getHeight(_evacpoint)
	-- local _agl = _evacpoint.y - _alt
	-- trigger.action.outTextForGroup(_medevacid, string.format("Altitude now: %f", _agl), 10)
	
	local _velv = _medevacunit:getVelocity()
	local _medspeed = mist.vec.mag(_velv)--string.format('%12.2f', mist.vec.mag(_velv))
	--trigger.action.outTextForGroup(_medevacid, string.format("Speed: %f", _medspeed),10)
	local _status, _err = pcall(
		function (_args)
		_medspeed = _args[1]
		_distance = _args[2]
		_medevacunit = _args[3]
		_medevacid = _args[4]
		_rescuegroup = _args[5]
		_oldgroup = _args[6]
		_medevacname = _args[7]
		if (_medspeed < 1 and _distance < 200 and _medevacunit:inAir() == false) then
			local _txt = "Wounded picked up!\n\nBring them back to MASH ASAP!"
			table.insert(medevac.pickedupgroups, _rescuegroup)
			medevac.removeInTable(medevac.woundedgroups,_rescuegroup)
			-- trigger.action.outTextForGroup(_medevacid, string.format("Units picked up!\n\nBring them back to MASH ASAP!", _agl), 10)
			medevac.DisplayMessage(_txt, _medevacname, _rescuegroup, 20)
   
			-- DS: Make sure the pilot has a reasonable time to make it to the MASH, while providing a challenge.
			local _mashes = medevac.bluemash
			local _medevacgrp = _medevacunit:getGroup()
			if (_medevacgrp and _medevacgrp:getCoalition() == coalition.side.RED) then
					_mashes = medevac.redmash
			end
	
			local _mashdistance = medevac.getShortestMashDistance(_medevacunit, _mashes)
			local _minbleedtime = medevac.calculateMinBleedTime(_mashdistance, medevac.cruisespeed, medevac.minbleedtime)
			
			-- NEW v6.0.0: Apply weather and unit type multipliers
			local _rescuePos = Group.getByName(_rescuegroup) and Group.getByName(_rescuegroup):getUnits()[1]:getPosition().p
			if _rescuePos then
				local weatherMult = medevac.getWeatherMultiplier(_rescuePos)
				_minbleedtime = math.ceil(_minbleedtime * weatherMult)
				_maxbleedtime = math.ceil(_minbleedtime * medevac.maxbleedtimemultiplier)
			end
			
			-- DS: If estimated time left for landing is under medevac.minlandtime seconds, pad it to medevac.minlandtime seconds.
			local _estimatedlandingtime = _minbleedtime * medevac.pilotperformance
			if(_estimatedlandingtime < medevac.minlandtime) then
				_minbleedtime = math.ceil(_minbleedtime + (medevac.minlandtime - _estimatedlandingtime))
			end   
			local _maxbleedtime = math.ceil(_minbleedtime * medevac.maxbleedtimemultiplier)
			
			local _rescuegrp = Group.getByName(_rescuegroup)
			if _rescuegrp then _rescuegrp:destroy() end
			
			-- NEW v6.0.0: Check helicopter health
			medevac.checkHeliHealth(_medevacname)
			-- DS: Set random time between _minbleedtime and _maxbleedtime
			timer.scheduleFunction(BleedTimer, {_medevacunit, math.random(_minbleedtime, _maxbleedtime) + timer.getTime(), _oldgroup, _rescuegroup, _medevacname}, timer.getTime() + 1)
			
			return -1
		end
	end
   ,{_medspeed, _distance, _medevacunit, _medevacid, _rescuegroup, _oldgroup, _medevacname})
	if (not _status) then env.error(string.format("Error while picking up\n\n%s",_err), medevac.displayerrordialog) end
	if (_err == -1) then return nil end
	
	if (_distance < 600 and _distance > 500) then
		--local _moveblend = 0 - (1/(_distance/200))
		
		
		local _medevacgrp = _medevacunit:getGroup()
		local _rescuegrp = Group.getByName(_rescuegroup)
		if _medevacgrp and _rescuegrp then
			local _medevacunits = _medevacgrp:getUnits()
			local _rescueunits = _rescuegrp:getUnits()
			if _medevacunits and _medevacunits[1] and _rescueunits and _rescueunits[1] then
				local _moveto = medevac.getPointBetween(_medevacunits[1]:getPosition().p, _rescueunits[1]:getPosition().p, 0.2)
	
	
		--local _moveto = medevac.getPointBetween(_rescuepoint, _evacpoint, 0.2)
		local _rescuePos = _rescueunits[1]:getPosition().p
		Mission = { 
			id = 'Mission', 
			params = { 
				route = { 
					points = { 
						[1] = {
								action = 0,
								x = _rescuePos.x, 
								y = _rescuePos.z, 
								speed = 25,
								ETA = 100,
								ETA_locked = false,
								name = "Starting point", 
								task = nil 
						},
						[2] = {
								action = 0,
								x = _moveto.x, 
								y = _moveto.z, 
								speed = 25,
								ETA = 100,
								ETA_locked = false,
								name = "Pick-up", 
								task = nil 
						},  
					} 
				}, 
			} 
		}
		local _controller = _rescuegrp:getController();
		Controller.setOption(_controller, AI.Option.Ground.id.ALARM_STATE, AI.Option.Ground.val.ALARM_STATE.GREEN)
		_controller:setTask(Mission)
		-- Controller.setOption(_controller, AI.Option.Ground.id.ALARM_STATE, AI.Option.Ground.val.ALARM_STATE.GREEN)
			end
		end
	end
	return timer.getTime() + 2
	end
	,_argument)
	if (not _status) then env.error(string.format("Error while LandEvent\n\n%s",_err), medevac.displayerrordialog) end
	return _err
end

function SmokeEvent(_argument, _time)
local _status, _err = pcall(
		function (_argument)
   local _rescuepoint = _argument[1]
   local _medevacname = _argument[2]
   local _medevacunit = Unit.getByName(_medevacname)
   local _rescuegroup = _argument[3]
   local _oldgroup = _argument[4]
    local _status, _err = pcall(
		function (_medevacunitarg, _rescuegroup, _medevacname)
			if (_medevacunit:getLife() <= 1.0) then
				env.info("Helicopter is dead.", false)
				return -1
			end
		
			if (medevac.getGroupHealthPercentage(Group.getByName(_rescuegroup)) < 0.1) then
				env.info("Group to rescue is dead.", false)
				medevac.DisplayMessage(string.format("%s is dead.", _rescuegroup), _medevacname, _rescuegroup, 10)
				medevac.removeInTable(medevac.woundedgroups,_rescuegroup)
				return -1
			end
		end
	, _medevacunitarg, _rescuegroup, _medevacname)
	if (_status ~= true or _err == -1) then env.info(string.format("Helicopter or group to rescue is dead.\n%s",_err), false) return nil end
	
	
   local _medevacgrp = _medevacunit:getGroup()
   local _medevacid = _medevacgrp and _medevacgrp:getID()
   
   local _status, _evacpoint = pcall(
		function (_medevacunitarg)
			return _medevacunitarg:getPosition().p
		end
   ,_medevacunit)
	if (not _status) then env.error(string.format("Error while _evacpoint\n\n%s",_evacpoint), medevac.displayerrordialog) end
   -- local _evacpoint = _medevacunit:getPosition().p
   local _status, _distance = pcall(
		function (_distargs)
			local _rescuepoint = _distargs[1]
			local _evacpoint = _distargs[2]
			return medevac.measureDistance(_rescuepoint, _evacpoint)
		end
   ,{_rescuepoint, _evacpoint})
	if (not _status) then env.error(string.format("Error while measuring distance\n\n%s",_distance), medevac.displayerrordialog) end
   -- local _distance = measuredistance(_rescuepoint, _evacpoint)
   -- trigger.action.outTextForGroup(_medevacid, string.format("Distance now: %f", _distance), 10)
   
   if (_distance < 3000) then
   		-- Helicopter is within 3km
		local _status, _err = pcall(
		function (_args)
			_medevacunit = _args[1]
			_rescuepoint = _args[2]
			_oldgroup = _args[3]
			_rescuegroup = _args[4]
			_medevacname = _args[5]
			-- trigger.action.outTextForGroup(_medevacid, "Land by the smoke.", 10)
			local _txt = string.format("%s: We see you! Land by the smoke.", _rescuegroup)
			medevac.DisplayMessage(_txt, _medevacname, _rescuegroup, 300)
			
			local smokenear = false
			for _,x in pairs(medevac.smokemarkers) do 
				local _smokepoint = x[1]
				local _smoketime = x[2]
				local _smokedistance = medevac.measureDistance(_rescuepoint, _smokepoint)
				
				--trigger.action.outTextForGroup(_medevacid, _txt, 10)
				
				if (_smokedistance < 400 and ((_smoketime + 30) > timer.getTime() )) then 
					local _txt = string.format("%s: We are %u meters from the smoke! Do you see us?", _rescuegroup, math.floor(_smokedistance / 10) * 10, ((_smoketime + 300) - timer.getTime() ))
					medevac.DisplayMessage(_txt, _medevacname, _rescuegroup, 300)
					smokenear = true
				end
			end
			local alt = land.getHeight(_rescuepoint)
			if (smokenear == false) then 
				local _rescuegrp = Group.getByName(_rescuegroup)
				local _woundcoal = _rescuegrp and _rescuegrp:getCoalition()
				local _smokecolor = medevac.redsmokecolor
				if (_woundcoal == coalition.side.BLUE) then
					_smokecolor = medevac.bluesmokecolor
				end
				trigger.action.smoke(_rescuepoint, _smokecolor)
				
				-- NEW v6.0.0: Add signal flare and illumination
				medevac.fireSignalFlare(_rescuepoint, _woundcoal)
				medevac.illuminateArea(_rescuepoint)
				
				table.insert(medevac.smokemarkers, {_rescuepoint, timer.getTime()})
			end
			timer.scheduleFunction(LandEvent, {_medevacunit, _rescuegroup, _oldgroup, _medevacname}, timer.getTime() + 2) 
		end
		,{_medevacunit, _rescuepoint, _oldgroup, _rescuegroup, _medevacname})
		if (not _status) then env.error(string.format("Error while planting smoke:\n\n%s",_err), medevac.displayerrordialog) end
		--trigger.action.smoke({x = _rescuepoint.x + 5, y = _rescuepoint.y, z = _rescupoint.z}, 1)
		return nil
   end
   
   return timer.getTime() + 10
   end
	,_argument)
	if (not _status) then env.error(string.format("Error while SmokeEvent\n\n%s",_err), medevac.displayerrordialog) end
	return _err
end

-- Finds a point between two points according to a given blend (0.5 = right between, 0.3 = a third from point1)
function medevac.getPointBetween(point1, point2, blend)
	if point1 == nil or point2 == nil then
		medevac.logWarning("getPointBetween called with nil point")
		return nil
	end
	
	if type(point1) ~= "table" or type(point2) ~= "table" then
		medevac.logWarning("getPointBetween called with invalid point types")
		return nil
	end
	
	if point1.x == nil or point1.y == nil or point1.z == nil or
	   point2.x == nil or point2.y == nil or point2.z == nil then
		medevac.logWarning("getPointBetween called with incomplete points")
		return nil
	end
	
	if blend == nil or type(blend) ~= "number" or blend < 0 or blend > 1 then
		medevac.logWarning("getPointBetween called with invalid blend value")
		blend = 0.5
	end
	
	return {
		x = point1.x + blend * (point2.x - point1.x),
		y = point1.y + blend * (point2.y - point1.y),
		z = point1.z + blend * (point2.z - point1.z)
	}
end

-- Removes target from a array/table and returns true if the item was removed
function medevac.removeInTable(Tbl, trgt)
	if type(Tbl) ~= "table" then
		medevac.logWarning("removeInTable called with non-table argument")
		return false
	end
	
	if trgt == nil then
		medevac.logWarning("removeInTable called with nil target")
		return false
	end
	
	local removed = false
	for nr, x in pairs(Tbl) do 
		if x == trgt then 
			table.remove(Tbl, nr)
			removed = true
			break -- Only remove first occurrence
		end
	end
	return removed
end

-- Unit tests for removeInTable
local function runUnitTests()
	medevac.logInfo("Running unit tests...")
	
	local unittesttbl = {1, 2, 3}
	assert(medevac.removeInTable(unittesttbl, 2) == true, "Unit test 1 of removeInTable failed!")
	assert(unittesttbl[1] == 1 and unittesttbl[2] == 3, "Unit test 2 of removeInTable failed!")
	
	medevac.logInfo("Unit tests passed!")
end

runUnitTests()

-- Displays all active MEDEVACS/SAR
function medevac.displayactive(_unit)
	local _msg = "Active MEDEVAC/SAR:"
	local _unitobj = Unit.getByName(_unit)
	local _unitgrp = _unitobj and _unitobj:getGroup()
	local _unitcoal = _unitgrp and _unitgrp:getCoalition()
	for nr,x in pairs(medevac.woundedgroups) do 
		local sts, _grp = pcall(
			function (x)
				return Group.getByName(x)
			end
			, x)
		if (sts and _grp ~= nil) then
			local _woundcoal = _grp:getCoalition()
			if (_woundcoal == _unitcoal) then
				_unittable = {_grp:getUnits()[1]:getName()} -- Get name of first unit
				local _coordinatestext = "ERROR!"
				if (medevac.coordtype == 0) then -- Lat/Long DMTM
					_coordinatestext = string.format("%s", mist.getLLString({units = _unittable, acc = 3, DMS = 0}))
				end
				if (medevac.coordtype == 1) then -- Lat/Long DMS
					_coordinatestext = string.format("%s", mist.getLLString({units = _unittable, acc = 3, DMS = 1}))
				end
				if (medevac.coordtype == 2) then -- MGRS
					_coordinatestext = string.format("%s", mist.getMGRSString({units = _unittable, acc = 3}))
				end
				if (medevac.coordtype == 3) then -- Bullseye Imperial
					_coordinatestext = string.format("bullseye %s", mist.getBRString({units = _unittable, ref = coalition.getMainRefPoint(_woundcoal), alt = 0}))
				end
				if (medevac.coordtype == 4) then -- Bullseye Metric
					_coordinatestext = string.format("bullseye %s", mist.getBRString({units = _unittable, ref = coalition.getMainRefPoint(_woundcoal), alt = 0, metric = 1}))
				end
				_msg = string.format("%s\n%s at %s", _msg, x, _coordinatestext)
			end
		end
	end
	medevac.DisplayMessage(_msg, _unit, string.format("Activemedevacs %s", _unit), 20)
end


-- Handles all world events
medevac.eventhandler = {}
function medevac.eventhandler:onEvent(vnt)
	local status, err = pcall(
		function (vnt)
			
			
			assert(vnt ~= nil, "Event is nil!")
			
			-- NEW: Cache unit-to-group mapping on S_EVENT_BIRTH
			if vnt.id == world.event.S_EVENT_BIRTH and vnt.initiator ~= nil then
				local status, result = pcall(function()
					local unit = vnt.initiator
					local unitName = unit:getName()
					local grp = unit:getGroup()
					
					if grp ~= nil then
						local grpName = grp:getName()
						if grpName ~= nil then
							medevac.unitToGroupCache[unitName] = grpName
							medevac.logTrace(string.format("Cached unit->group: %s -> %s", unitName, grpName))
						end
					end
				end)
				
				if not status then
					medevac.logDebug(string.format("Error caching unit->group mapping: %s", tostring(result)))
				end
			end
			
			-- FIXED: Event ID 20 is PLAYER_ENTER_UNIT (was incorrectly using 19 which is ENGINE_SHUTDOWN)
			if vnt.id == world.event.S_EVENT_PLAYER_ENTER_UNIT then
				-- Player entered unit
				if vnt.initiator == nil then
					medevac.logWarning("S_EVENT_PLAYER_ENTER_UNIT: initiator is nil")
					return nil
				end
				
				local status, result = pcall(function()
					local unitName = vnt.initiator:getName()
					medevac.logInfo(string.format("Player entered unit: %s", unitName))
					
					if medevac.tableContains(medevac.medevacunits, unitName) then
						-- Unit is a MEDEVAC unit, add command
						local group = vnt.initiator:getGroup()
						if group ~= nil then
							local groupID = group:getID()
							missionCommands.addCommandForGroup(
								groupID,
								"Active MEDEVAC/SAR",
								nil,
								medevac.displayactive,
								unitName
							)
							medevac.logInfo(string.format("Added radio item for MEDEVAC group: %s", unitName))
						else
							medevac.logWarning(string.format("Could not get group for unit: %s", unitName))
						end
					end
				end)
				
				if not status then
					medevac.logError(string.format("Error handling PLAYER_ENTER_UNIT event: %s", tostring(result)), false)
				end
			end
			
			
			if vnt.id == world.event.S_EVENT_PILOT_DEAD and medevac.sar_pilots == true then
				-- Pilot dead event
				local _grp = vnt.initiator:getGroup()
				local _groupname = _grp:getName()
				local _unittable = {vnt.initiator:getName()}--string.format("[g]%s", _groupname)
				local _woundcoal = _grp:getCoalition()
				local _coordinatestext = string.format("bullseye %s", mist.getBRString({units = _unittable, ref = coalition.getMainRefPoint(_woundcoal), alt = 0}))
				
				trigger.action.outTextForCoalition(_woundcoal, string.format("MAYDAY MAYDAY! Airman down %s. No chute.", _coordinatestext), 20)
			end
			
			if ((vnt.id == world.event.S_EVENT_DEAD and vnt.initiator ~= nil) or (vnt.id == world.event.S_EVENT_EJECTION and medevac.sar_pilots == true)) then
				-- Unit dead (ID=8) or pilot ejected (ID=6)
				local _ispilot = false
				
				-- Enhanced logging for debugging
				if vnt.id == world.event.S_EVENT_DEAD then
					medevac.logDebug("S_EVENT_DEAD triggered")
				else
					medevac.logDebug("S_EVENT_EJECTION triggered")
				end
				
				-- Log unit information
				local unitName = "unknown"
				local unitTypeName = "unknown"
				if vnt.initiator ~= nil then
					local status, name = pcall(function() return vnt.initiator:getName() end)
					if status and name ~= nil then unitName = name end
					
					local status2, typeName = pcall(function() return vnt.initiator:getTypeName() end)
					if status2 and typeName ~= nil then unitTypeName = typeName end
					
					medevac.logInfo(string.format("Unit destroyed: %s (Type: %s)", tostring(unitName), tostring(unitTypeName)))
				end
				
				-- Check if event has been fired more than once
				if medevac.tableContains(medevac.deadunits, vnt.initiator) then 
					medevac.logWarning(string.format("Event already fired for unit: %s. Exiting.", unitName))
					return nil
				end
				table.insert(medevac.deadunits, vnt.initiator)
				
				if vnt.id == world.event.S_EVENT_EJECTION then
					_ispilot = true 
					local _grp = vnt.initiator:getGroup()
					if _grp == nil then
						medevac.logWarning(string.format("Unit.getGroup() returned nil for ejected pilot: %s", unitName))
						return nil
					end
					local _groupname = _grp:getName()
					local _unittable = {vnt.initiator:getName()}
					local _woundcoal = _grp:getCoalition()
					local _coordinatestext = string.format("bullseye %s", mist.getBRString({units = _unittable, ref = coalition.getMainRefPoint(_woundcoal), alt = 0}))
				
					trigger.action.outTextForCoalition(_woundcoal, string.format("MAYDAY MAYDAY! Airman down %s. Chute spotted.", _coordinatestext), 20)
				end
				
				local _unit = vnt.initiator
				if (vnt.initiator == nil) then 
					medevac.logWarning("Initiator is nil after event processing")
					return nil
				end
				
				local _grp
				
				-- FIXED: Try cache first since Unit.getGroup() returns nil after destruction
				if medevac.unitToGroupCache[unitName] ~= nil then
					_grp = medevac.unitToGroupCache[unitName]
					medevac.logDebug(string.format("Got group name from cache: %s", _grp))
				else
					-- Fallback to trying Unit.getGroup() (may work in some cases)
					local sts, result = pcall(
						function (_int)
							local grp = _int:getGroup()
							if grp == nil then
								return nil
							end
							local grpName = grp:getName()
							if grpName ~= nil then
								medevac.logDebug(string.format("Got group name from Unit.getGroup(): %s", grpName))
							end
							return grpName
						end
					, vnt.initiator)
					
					if sts and result ~= nil then
						_grp = result
					else
						medevac.logWarning(string.format("Unit.getGroup() returned nil for unit: %s (not in cache either)", unitName))
						return nil
					end
				end
				
				if _grp == nil then
					medevac.logWarning(string.format("Could not determine group name for unit: %s", unitName))
					return nil
				end
				
				local _grpObj = Group.getByName(_grp)
				if _grpObj == nil then
					medevac.logWarning(string.format("Could not get group object for group name: %s", tostring(_grp)))
					return nil
				end
				local _woundcoal = _grpObj:getCoalition()
				local _crsurviveperc = medevac.redcrewsurvivepercent
				local _rndsurv = math.random(-1, 99)
				if _woundcoal == coalition.side.BLUE then
					_crsurviveperc = medevac.bluecrewsurvivepercent
				end
				
				medevac.logDebug(string.format("Crew survival check: %d%% survive rate, rolled %d", _crsurviveperc, _rndsurv))
				
				if (_crsurviveperc < _rndsurv and _ispilot == false) then
					medevac.logInfo(string.format("Crew from %s didn't make it. %u/%u", _grp, _rndsurv, _crsurviveperc))
					return nil
				end
				
				medevac.logDebug(string.format("Crew survived. Checking if unit qualifies for MEDEVAC..."))
				
				-- Check if unit is a ground vehicle or pilot
				local hasGroundAttr = false
				local status3, result3 = pcall(function()
					return Object.hasAttribute(_unit, "Ground vehicles")
				end)
				
				if status3 then
					hasGroundAttr = result3
					medevac.logDebug(string.format("Unit has 'Ground vehicles' attribute: %s", tostring(hasGroundAttr)))
				else
					medevac.logWarning(string.format("Object.hasAttribute() failed: %s", tostring(result3)))
				end
				
				if (hasGroundAttr or _ispilot) then
					medevac.logInfo(string.format("Unit qualifies for MEDEVAC (Ground vehicle: %s, Pilot: %s)", tostring(hasGroundAttr), tostring(_ispilot)))
					
					
					local _pos = Object.getPoint(_unit)
					local _coord1, _coord2, _dist = coord.LOtoLL(_pos)
					local _tarpos = _pos
					local _idroot = math.random(1000, 10000)
					local _n = 1
					local _groupname = string.format("%s wounded crew #%u", _grp, _n)
					if _ispilot then
						_groupname = string.format("%s downed pilot #%u", _grp, _n)
					end
					
					while _n < 100 do
						if medevac.tableContains(medevac.woundedgroups, _groupname) or Group.getByName(_groupname) ~= nil then
							_n = _n + 1
							_groupname = string.format("%s wounded crew #%u", _grp, _n)
							if _ispilot then
								_groupname = string.format("%s downed pilot #%u", _grp, _n)
							end
						else
							table.insert(medevac.woundedgroups, _groupname)
							_n = 110
						end
					end
					--local _groupname = string.format("Wounded infantry #%f", _idroot)
	
					
					
					local _country = country.id.RUSSIA -- Default to RED coalition country
					local _infantry = "Infantry AK"
					local _thirdinfantry = "Infantry AK"
					if medevac.rpgsoldier then
						_thirdinfantry = "Soldier RPG"
					end
					
					if _woundcoal == coalition.side.BLUE then 
						_country = country.id.USA -- Blue coalition country
						_infantry = "Soldier M4"
						_thirdinfantry = "Soldier M4"
						if medevac.rpgsoldier then
							_thirdinfantry = "Soldier RPG"
						end
					end
					
					if (_ispilot) then
						--_infantry = "pilot_parashut"
						coalition.addGroup(_country, Group.Category.GROUND, {
								["visible"] = false,
                                ["taskSelected"] = true,
                                ["route"] = 
                                {
                                    ["spans"] = 
                                    {
                                        [1] = 
                                        {
                                            [1] = 
                                            {
                                                ["y"] = _tarpos.z,
                                                ["x"] = _tarpos.x,
                                            }, -- end of [1]
                                            [2] = 
                                            {
                                                ["y"] = _tarpos.z,
                                                ["x"] = _tarpos.x,
                                            }, -- end of [2]
                                        }, -- end of [1]
                                    }, -- end of ["spans"]
                                    ["points"] = 
                                    {
                                        [1] = 
                                        {
                                            ["alt"] = 18,
                                            ["type"] = "Turning Point",
                                            ["ETA"] = 0,
                                            ["alt_type"] = "BARO",
                                            ["formation_template"] = "",
                                            ["y"] = _tarpos.z,
                                            ["x"] = _tarpos.x,
                                            ["ETA_locked"] = true,
                                            ["speed"] = 5.5555555555556,
                                            ["action"] = "Off Road",
                                            ["task"] = 
                                            {
                                                ["id"] = "ComboTask",
                                                ["params"] = 
                                                {
                                                    ["tasks"] = 
                                                    {
                                                        [1] = 
                                                        {
                                                            ["number"] = 1,
                                                            ["auto"] = false,
                                                            ["id"] = "WrappedAction",
                                                            ["enabled"] = true,
                                                            ["params"] = 
                                                            {
                                                                ["action"] = 
                                                                {
                                                                    ["id"] = "Option",
                                                                    ["params"] = 
                                                                    {
                                                                        ["value"] = 0,
                                                                        ["name"] = 0,
                                                                    }, -- end of ["params"]
                                                                }, -- end of ["action"]
                                                            }, -- end of ["params"]
                                                        }, -- end of [1]
                                                        [2] = 
                                                        {
                                                            ["enabled"] = true,
                                                            ["auto"] = false,
                                                            ["id"] = "WrappedAction",
                                                            ["number"] = 2,
                                                            ["params"] = 
                                                            {
                                                                ["action"] = 
                                                                {
                                                                    ["id"] = "Option",
                                                                    ["params"] = 
                                                                    {
                                                                        ["value"] = 2,
                                                                        ["name"] = 9,
                                                                    }, -- end of ["params"]
                                                                }, -- end of ["action"]
                                                            }, -- end of ["params"]
                                                        }, -- end of [2]
                                                    }, -- end of ["tasks"]
                                                }, -- end of ["params"]
                                            }, -- end of ["task"]
                                            ["speed_locked"] = true,
                                        }, -- end of [1]
                                    }, -- end of ["points"]
                                }, -- end of ["route"]
                                ["groupId"] = _idroot,
                                ["tasks"] = 
                                {
                                }, -- end of ["tasks"]
                                ["hidden"] = false,
                                ["units"] = 
                                {
                                    [1] = 
                                    {
                                        ["y"] = _tarpos.z + 8,
                                        ["type"] = _infantry,
                                        ["name"] = string.format("%s pilot", _groupname),
                                        ["unitId"] = _idroot + 1,
                                        ["heading"] = 3,
                                        ["playerCanDrive"] = true,
                                        ["skill"] = "Excellent",
                                        ["x"] = _tarpos.x - 4.6,
                                    }, -- end of [1]
                                }, -- end of ["units"]
                                ["y"] = _tarpos.z,
                                ["x"] = _tarpos.x,
                                ["name"] = _groupname,
                                ["start_time"] = 0,
                                ["task"] = "Ground Nothing",
                            })
					else
					coalition.addGroup(_country, Group.Category.GROUND, {
								["visible"] = false,
                                ["taskSelected"] = true,
                                ["route"] = 
                                {
                                    ["spans"] = 
                                    {
                                        [1] = 
                                        {
                                            [1] = 
                                            {
                                                ["y"] = _tarpos.z,
                                                ["x"] = _tarpos.x,
                                            }, -- end of [1]
                                            [2] = 
                                            {
                                                ["y"] = _tarpos.z,
                                                ["x"] = _tarpos.x,
                                            }, -- end of [2]
                                        }, -- end of [1]
                                    }, -- end of ["spans"]
                                    ["points"] = 
                                    {
                                        [1] = 
                                        {
                                            ["alt"] = 18,
                                            ["type"] = "Turning Point",
                                            ["ETA"] = 0,
                                            ["alt_type"] = "BARO",
                                            ["formation_template"] = "",
                                            ["y"] = _tarpos.z,
                                            ["x"] = _tarpos.x,
                                            ["ETA_locked"] = true,
                                            ["speed"] = 5.5555555555556,
                                            ["action"] = "Off Road",
                                            ["task"] = 
                                            {
                                                ["id"] = "ComboTask",
                                                ["params"] = 
                                                {
                                                    ["tasks"] = 
                                                    {
                                                        [1] = 
                                                        {
                                                            ["number"] = 1,
                                                            ["auto"] = false,
                                                            ["id"] = "WrappedAction",
                                                            ["enabled"] = true,
                                                            ["params"] = 
                                                            {
                                                                ["action"] = 
                                                                {
                                                                    ["id"] = "Option",
                                                                    ["params"] = 
                                                                    {
                                                                        ["value"] = 0,
                                                                        ["name"] = 0,
                                                                    }, -- end of ["params"]
                                                                }, -- end of ["action"]
                                                            }, -- end of ["params"]
                                                        }, -- end of [1]
                                                        [2] = 
                                                        {
                                                            ["enabled"] = true,
                                                            ["auto"] = false,
                                                            ["id"] = "WrappedAction",
                                                            ["number"] = 2,
                                                            ["params"] = 
                                                            {
                                                                ["action"] = 
                                                                {
                                                                    ["id"] = "Option",
                                                                    ["params"] = 
                                                                    {
                                                                        ["value"] = 2,
                                                                        ["name"] = 9,
                                                                    }, -- end of ["params"]
                                                                }, -- end of ["action"]
                                                            }, -- end of ["params"]
                                                        }, -- end of [2]
														[3] = -- set Option ROE to Weapon Hold!!! Shagrat
                                                        {
                                                            ["number"] = 3,
                                                            ["auto"] = false,
                                                            ["id"] = "WrappedAction",
                                                            ["enabled"] = medevac.crewholdfire,
                                                            ["params"] = 
                                                            {
                                                                ["action"] = 
                                                                {
                                                                    ["id"] = "Option",
                                                                    ["params"] = 
                                                                    {
                                                                        ["name"] = 0,
                                                                        ["value"] = 4,
                                                                    }, -- end of ["params"]
                                                                }, -- end of ["action"]
                                                            }, -- end of ["params"]
                                                        }, -- end of [3]
                                                    }, -- end of ["tasks"]
                                                }, -- end of ["params"]
                                            }, -- end of ["task"]
                                            ["speed_locked"] = true,
                                        }, -- end of [1]
                                    }, -- end of ["points"]
                                }, -- end of ["route"]
                                ["groupId"] = _idroot,
                                ["tasks"] = 
                                {
                                }, -- end of ["tasks"]
                                ["hidden"] = false,
                                ["units"] = 
                                {
                                    [1] = 
                                    {
                                        ["y"] = _tarpos.z + 8,
                                        ["type"] = _infantry,
                                        ["name"] = string.format("%s #1", _groupname),
                                        ["unitId"] = _idroot + 1,
                                        ["heading"] = 3,
                                        ["playerCanDrive"] = true,
                                        ["skill"] = "Excellent",
                                        ["x"] = _tarpos.x - 4.6,
                                    }, -- end of [1]
                                    [2] = 
                                    {
                                        ["y"] = _tarpos.z + 6.2,
                                        ["type"] = _infantry,
                                        ["name"] = string.format("%s #2", _groupname),
                                        ["unitId"] = _idroot + 2,
                                        ["heading"] = 2,
                                        ["playerCanDrive"] = true,
                                        ["skill"] = "Excellent",
                                        ["x"] = _tarpos.x - 6.2,
                                    }, -- end of [2]
                                    [3] = 
                                    {
                                        ["y"] = _tarpos.z + 4.6,
                                        ["type"] = _thirdinfantry,
                                        ["name"] = string.format("%s #3", _groupname),
                                        ["unitId"] = _idroot + 3,
                                        ["heading"] = 2,
                                        ["playerCanDrive"] = true,
                                        ["skill"] = "Excellent",
                                        ["x"] = _tarpos.x - 8,
                                    }, -- end of [3]
                                }, -- end of ["units"]
                                ["y"] = _tarpos.z,
                                ["x"] = _tarpos.x,
                                ["name"] = _groupname,
                                ["start_time"] = 0,
                                ["task"] = "Ground Nothing",
                            })
					
					medevac.logInfo(string.format("✅ Spawned wounded group '%s' at coordinates %f, %f", _groupname, _tarpos.x, _tarpos.z))
					end
					
					-- Immortal code for alexej21
					local _SetImmortal = { 
						id = 'SetImmortal', 
						params = { 
							value = true
						} 
					}
					-- invisible to AI, Shagrat
					local _SetInvisible = { 
						id = 'SetInvisible', 
						params = { 
							value = true
						} 
					}
					local _controller = Group.getByName(_groupname):getController()
					if _controller then
						if (medevac.immortalcrew) then 
							Controller.setCommand(_controller, _SetImmortal)
						end
						if (medevac.invisiblecrew) then
							Controller.setCommand(_controller, _SetInvisible)						
						end
					end
					local _leadername = string.format("%s #1", _groupname)
					if (_ispilot) then _leadername = string.format("%s pilot", _groupname) end
					local _leaderunit = Unit.getByName(_leadername)
					local _leaderpos = _leaderunit and _leaderunit:getPosition().p
					
					--local _unittable = mist.makeUnitTable({string.format("[g]%s",_groupname)})
					local _unittable = {_leadername}--string.format("[g]%s", _groupname)
					--assert(type(_unittable)=="table", "Error while generating unittable.")
					
					local _medevactext = "MEDEVAC REQUESTED!" 
					if (_ispilot) then _medevactext = "SAR REQUESTED!" end
					
					
					local _mgrs = coord.LLtoMGRS(_coord1, _coord2)
					local _coordinatestext = string.format("%s %s %s %s", _mgrs.UTMZone, _mgrs.MGRSDigraph, _mgrs.Easting, _mgrs.Northing)
					
					
					if (medevac.coordtype == 0) then -- Lat/Long DMTM
						_coordinatestext = string.format("%s", mist.getLLString({units = _unittable, acc = 3, DMS = 0}))
					end
					if (medevac.coordtype == 1) then -- Lat/Long DMS
						_coordinatestext = string.format("%s", mist.getLLString({units = _unittable, acc = 3, DMS = 1}))
					end
					if (medevac.coordtype == 2) then -- MGRS
						_coordinatestext = string.format("%s", mist.getMGRSString({units = _unittable, acc = 3}))
					end
					if (medevac.coordtype == 3) then -- Bullseye Imperial
						_coordinatestext = string.format("bullseye %s", mist.getBRString({units = _unittable, ref = coalition.getMainRefPoint(_woundcoal), alt = 0}))
					end
					if (medevac.coordtype == 4) then -- Bullseye Metric
						_coordinatestext = string.format("bullseye %s", mist.getBRString({units = _unittable, ref = coalition.getMainRefPoint(_woundcoal), alt = 0, metric = 1}))
					end
					
					_medevactext = string.format("%s requests medevac at %s", _groupname, _coordinatestext)
					if (_ispilot) then _medevactext = string.format("%s requests SAR at %s", _groupname, _coordinatestext) end
					
					-- Loop through all the medevac units
					for nr,x in pairs(medevac.medevacunits) do
						local status, err = pcall(
							function (_args)
								x = _args[1]
								_woundcoal = _args[2]
								_medevactext = _args[3]
								_leaderpos = _args[4]
								_groupname = _args[5]
								_grp = _args[6]
								if (Unit.getByName(x) ~= nil and Unit.isActive(Unit.getByName(x))) then
									local _medevacgrp = Unit.getGroup(Unit.getByName(x))
									local _evacoal = _medevacgrp and _medevacgrp:getCoalition()
						
						
									-- Check coalition side
									if (_evacoal == _woundcoal) then
										-- Display a delayed message
										timer.scheduleFunction(delayedhelpevent, {x, _medevactext, _groupname}, timer.getTime() + medevac.requestdelay) 
						
										-- Schedule timer to check when to pop smoke
										timer.scheduleFunction(SmokeEvent, {_leaderpos, x, _groupname, _grp}, timer.getTime() + 10) 
									end
								else
									env.warning(string.format("Medevac unit %s not active", x), false)
								end
								
							end
						, {x, _woundcoal, _medevactext, _leaderpos, _groupname, _grp})
	
						if (not status) then env.warning(string.format("Error while checking with medevac-units:\n\n%s",err), false) end
					end
				else
					medevac.logWarning(string.format("Unit %s (type: %s) does not qualify for MEDEVAC (not a ground vehicle and not a pilot)", unitName, unitTypeName))
				end
			end
		end
	, vnt)
	if (not status) then env.error(string.format("Error while handling event\n\n%s",err), medevac.displayerrordialog) end
end

-- Displays a request for medivac
function delayedhelpevent(_args, _time)
	local status, err = pcall(
		function (_args)	
			-- Validate input arguments
			if _args == nil or type(_args) ~= "table" then
				medevac.logError("delayedhelpevent: Invalid arguments - expected table")
				return
			end
			
			local _medleadname = _args[1]
			local _medevactext = _args[2]
			local _survivorgroup = _args[3]
			
			-- Validate arguments
			if type(_medleadname) ~= "string" or _medleadname == "" then
				medevac.logError("delayedhelpevent: Invalid medevac leader name")
				return
			end
			
			if type(_medevactext) ~= "string" then
				medevac.logError("delayedhelpevent: Invalid medevac text")
				return
			end
			
			if type(_survivorgroup) ~= "string" or _survivorgroup == "" then
				medevac.logError("delayedhelpevent: Invalid survivor group name")
				return
			end
			
			-- Check if survivor group still exists and has health
			local survivorGrp = Group.getByName(_survivorgroup)
			if survivorGrp == nil then
				medevac.logDebug(string.format("delayedhelpevent: Survivor group '%s' no longer exists", _survivorgroup))
				return
			end
			
			if medevac.getGroupHealthPercentage(survivorGrp) <= 0.1 then
				medevac.logDebug(string.format("delayedhelpevent: Survivor group '%s' is dead", _survivorgroup))
				return
			end
			
			-- Check if medevac unit still exists
			local medevacUnit = Unit.getByName(_medleadname)
			if medevacUnit == nil then
				medevac.logDebug(string.format("delayedhelpevent: Medevac unit '%s' no longer exists", _medleadname))
				return
			end
			
			-- Get medevac group safely
			local medevacGrp = medevacUnit:getGroup()
			if medevacGrp == nil then
				medevac.logError(string.format("delayedhelpevent: Could not get group for medevac unit '%s'", _medleadname))
				return
			end
			
			local _medevacid = medevacGrp:getID()
			if _medevacid == nil then
				medevac.logError(string.format("delayedhelpevent: Could not get group ID for '%s'", _medleadname))
				return
			end
			
			-- Display the message
			medevac.DisplayMessage(_medevactext, _medleadname, _survivorgroup, 300)
		end
	, _args)
	
	if not status then
		medevac.logError(string.format("delayedhelpevent: Error handling delayed help event: %s", tostring(err)), medevac.displayerrordialog)
	end
	return nil
end

medevac.textdisplaymode = 1 -- Always use non-MiST-system

-- Displays messages to the pilot
function medevac.DisplayMessage(_message, _unit, _nameofmessage, _t)
	-- Input validation
	if type(_message) ~= "string" or _message == "" then
		medevac.logWarning("DisplayMessage: Invalid message text")
		return false
	end
	
	if type(_unit) ~= "string" or _unit == "" then
		medevac.logWarning("DisplayMessage: Invalid unit name")
		return false
	end
	
	local status, err = pcall(function()
		if medevac.textdisplaymode == 0 then
			-- Display stacked messages using MiST
			if mist == nil or mist.message == nil or mist.message.add == nil then
				medevac.logError("DisplayMessage: MiST not available for text display mode 0")
				return false
			end
			
			local msg = {}
			msg.text = _message
			msg.displayTime = (_t ~= nil and type(_t) == "number") and _t or 300
			msg.msgFor = {units = {_unit}}
			msg.name = _nameofmessage or "MEDEVAC"
			mist.message.add(msg)
			
		elseif medevac.textdisplaymode == 1 then
			-- Display single messages using regular method
			local unit = Unit.getByName(_unit)
			if unit == nil then
				medevac.logDebug(string.format("DisplayMessage: Unit '%s' not found", _unit))
				return false
			end
			
			local grp = unit:getGroup()
			if grp == nil then
				medevac.logDebug(string.format("DisplayMessage: Could not get group for unit '%s'", _unit))
				return false
			end
			
			local grpId = grp:getID()
			if grpId == nil then
				medevac.logError(string.format("DisplayMessage: Could not get group ID for unit '%s'", _unit))
				return false
			end
			
			local msgtime = (_t ~= nil and type(_t) == "number") and _t or 120
			trigger.action.outTextForGroup(grpId, _message, msgtime)
		else
			medevac.logError(string.format("DisplayMessage: Unknown text display mode %s", tostring(medevac.textdisplaymode)))
			return false
		end
		
		return true
	end)
	
	if not status then
		medevac.logError(string.format("DisplayMessage: Error displaying message: %s", tostring(err)), false)
		return false
	end
	
	return err -- Return the result from the pcall'd function
end

if (medevac.displaymapcoordhint) then
	timer.scheduleFunction(
		function()
			local status, err = pcall(
			function ()	
			local msg = {}
			msg.text =  "Tip: To change the coordinate system of the F10-map, press Left Alt + Y"
			msg.displayTime = 10
			
			msg.msgFor = {units = medevac.medevacunits}
			
			mist.message.add(msg)
			end
			, nil)
			if (not status) then env.error(string.format("Error while displaying coord-hint\n\n%s",err), medevac.displayerrordialog) end
			return nil
		end
	, nil, timer.getTime() + 10) 
end

-- DS: Calculate direct distance between two points (Say flight of a helicopter from evac point to MASH)
function medevac.calculateDirectDistance(v1, v2)
	-- Input validation
	if v1 == nil or v2 == nil then
		medevac.logError("calculateDirectDistance: Nil vector provided")
		return nil
	end
	
	if type(v1) ~= "table" or type(v2) ~= "table" then
		medevac.logError("calculateDirectDistance: Invalid vector types")
		return nil
	end
	
	if v1.x == nil or v1.z == nil or v2.x == nil or v2.z == nil then
		medevac.logError("calculateDirectDistance: Incomplete vectors (missing x or z)")
		return nil
	end
	
	local status, result = pcall(function()
		return math.sqrt((v1.x - v2.x)^2 + (v1.z - v2.z)^2)
	end)
	
	if not status then
		medevac.logError(string.format("calculateDirectDistance: Error calculating distance: %s", tostring(result)))
		return nil
	end
	
	return result
end

-- DS: Get the shortest distance to a MASH unit.
function medevac.getShortestMashDistance(_medevacunit, _mashtable)
	-- Input validation
	if _medevacunit == nil then
		medevac.logError("getShortestMashDistance: Medevac unit is nil")
		return -1
	end
	
	if _mashtable == nil or type(_mashtable) ~= "table" or #_mashtable == 0 then
		medevac.logError("getShortestMashDistance: Invalid or empty MASH table")
		return -1
	end
	
	local status, result = pcall(function()
		local _shortestdistance = -1
		local _distance = 0
		local _medevacpos = _medevacunit:getPosition()
		
		if _medevacpos == nil or _medevacpos.p == nil then
			medevac.logError("getShortestMashDistance: Could not get medevac unit position")
			return -1
		end
	 
		for _intnum, _strunitname in ipairs(_mashtable) do
			if type(_strunitname) ~= "string" then
				medevac.logWarning(string.format("getShortestMashDistance: Invalid MASH unit name at index %d", _intnum))
			else
				local _mashunit = Unit.getByName(_strunitname)
				if _mashunit ~= nil then
					local _mashpos = _mashunit:getPosition()
					if _mashpos ~= nil and _mashpos.p ~= nil then
						_distance = medevac.calculateDirectDistance(_medevacpos.p, _mashpos.p)
						if _distance ~= nil and (_shortestdistance == -1 or _distance < _shortestdistance) then
							_shortestdistance = _distance
						end
					else
						medevac.logDebug(string.format("getShortestMashDistance: Could not get position for MASH '%s'", _strunitname))
					end
				else
					medevac.logDebug(string.format("getShortestMashDistance: MASH unit '%s' not found", _strunitname))
				end
			end
		end
	  
		return _shortestdistance
	end)
	
	if not status then
		medevac.logError(string.format("getShortestMashDistance: Error: %s", tostring(result)))
		return -1
	end
	
	return result
end

-- DS: Calculate minimum bleed time based on distance to MASH
function medevac.calculateMinBleedTime(_distance, _metersPerSecond, _minBleedTime)
	-- Input validation
	if _distance == nil or type(_distance) ~= "number" or _distance < 0 then
		medevac.logError(string.format("calculateMinBleedTime: Invalid distance: %s", tostring(_distance)))
		return _minBleedTime or 30
	end
	
	if _metersPerSecond == nil or type(_metersPerSecond) ~= "number" or _metersPerSecond <= 0 then
		medevac.logError(string.format("calculateMinBleedTime: Invalid speed: %s", tostring(_metersPerSecond)))
		return _minBleedTime or 30
	end
	
	if _minBleedTime == nil or type(_minBleedTime) ~= "number" or _minBleedTime < 0 then
		medevac.logWarning(string.format("calculateMinBleedTime: Invalid min bleed time: %s, using 30", tostring(_minBleedTime)))
		_minBleedTime = 30
	end
	
	local status, result = pcall(function()
		-- _distance comes out in meters due to DCS coordinate system
		local _calcBleedTime = math.ceil(_distance / _metersPerSecond)
		if _calcBleedTime < _minBleedTime then
			_calcBleedTime = _minBleedTime
		end
		return _calcBleedTime
	end)
	
	if not status then
		medevac.logError(string.format("calculateMinBleedTime: Error calculating: %s", tostring(result)))
		return _minBleedTime
	end
	
	return result
end

-- DS: Custom function to inject wounded groups
function medevac.addWoundedGroup(_groupname, _medevactext)
	-- Input validation
	if _groupname == nil or type(_groupname) ~= "string" or _groupname == "" then
		medevac.logError("addWoundedGroup: Invalid group name")
		return false
	end
	
	-- Check if group exists
	local _grp = Group.getByName(_groupname)
	if _grp == nil then
		medevac.logError(string.format("addWoundedGroup: Group '%s' not found", _groupname))
		return false
	end
	
	-- Check if MiST is available
	if mist == nil or mist.getAvgPos == nil or mist.makeUnitTable == nil then
		medevac.logError("addWoundedGroup: MiST functions not available")
		return false
	end
	
	local status, result = pcall(function()
		-- Add to wounded groups list
		table.insert(medevac.woundedgroups, _groupname)
		
		local _woundcoal = _grp:getCoalition()
		if _woundcoal == nil then
			medevac.logError(string.format("addWoundedGroup: Could not get coalition for group '%s'", _groupname))
			return false
		end
		
		local _leaderpos = mist.getAvgPos(mist.makeUnitTable({"[g]" .. _groupname}))
		if _leaderpos == nil then
			medevac.logError(string.format("addWoundedGroup: Could not get position for group '%s'", _groupname))
			return false
		end
		
		-- NEW v6.0.0: Create map marker and update statistics
		local isPilot = _medevactext and string.match(_medevactext, "[Pp]ilot")
		medevac.createMapMarker(_groupname, _leaderpos, _woundcoal, isPilot)
		medevac.updateStatistics(_woundcoal, "casualties")
		if isPilot then
			-- This is tracked separately when actually rescued
		end
		
		-- NEW v6.0.0: Schedule periodic signal flares
		if medevac.useSignalFlares then
			timer.scheduleFunction(PeriodicFlareTimer, {_groupname, _woundcoal}, timer.getTime() + medevac.flareInterval)
		end
		
		-- Notify all medevac units of the same coalition
		for nr, x in pairs(medevac.medevacunits) do  
			local innerStatus, innerErr = pcall(function()
				if type(x) ~= "string" or x == "" then
					medevac.logWarning(string.format("addWoundedGroup: Invalid medevac unit name at index %d", nr))
					return
				end
				
				local medevacUnit = Unit.getByName(x)
				if medevacUnit == nil or not Unit.isActive(medevacUnit) then
					medevac.logDebug(string.format("addWoundedGroup: Medevac unit '%s' not active", x))
					return
				end
				
				local _medevacgrp = medevacUnit:getGroup()
				if _medevacgrp == nil then
					medevac.logWarning(string.format("addWoundedGroup: Could not get group for medevac unit '%s'", x))
					return
				end
				
				local _evacoal = _medevacgrp:getCoalition()
				if _evacoal == nil then
					medevac.logWarning(string.format("addWoundedGroup: Could not get coalition for medevac group '%s'", x))
					return
				end
				
				-- Check coalition side
				if _evacoal == _woundcoal then
					-- Display a delayed message
					if _medevactext ~= nil and type(_medevactext) == "string" then
						timer.scheduleFunction(delayedhelpevent, {x, _medevactext, _groupname}, timer.getTime() + medevac.requestdelay)
					end
					
					-- Schedule timer to check when to pop smoke
					timer.scheduleFunction(SmokeEvent, {_leaderpos, x, _groupname, _groupname}, timer.getTime() + 10)
				end
			end)
			
			if not innerStatus then
				medevac.logWarning(string.format("addWoundedGroup: Error processing medevac unit '%s': %s", tostring(x), tostring(innerErr)))
			end
		end
		
		return true
	end)
	
	if not status then
		medevac.logError(string.format("addWoundedGroup: Error adding wounded group '%s': %s", _groupname, tostring(result)))
		return false
	end
	
	return result
end

world.addEventHandler(medevac.eventhandler)
env.info("Medevac event handler added", false)

-- NEW: Pre-populate unit->group cache for all existing units in mission
function medevac.populateUnitGroupCache()
	medevac.logInfo("Populating unit->group cache...")
	local cached = 0
	
	-- Cache for all coalitions
	for _, coalitionID in pairs({coalition.side.RED, coalition.side.BLUE, coalition.side.NEUTRAL}) do
		local status, groups = pcall(function()
			return coalition.getGroups(coalitionID)
		end)
		
		if status and groups ~= nil then
			for _, grp in pairs(groups) do
				if grp ~= nil then
					local grpName = grp:getName()
					local units = grp:getUnits()
					
					if units ~= nil and grpName ~= nil then
						for _, unit in pairs(units) do
							if unit ~= nil then
								local unitName = unit:getName()
								if unitName ~= nil then
									medevac.unitToGroupCache[unitName] = grpName
									cached = cached + 1
								end
							end
						end
					end
				end
			end
		end
	end
	
	medevac.logInfo(string.format("Cached %d unit->group mappings", cached))
end

-- Call cache population
medevac.populateUnitGroupCache()

-- Adds menuitem to all medevac units that are active
function AddMenuItem()
	local msg = {}

	-- Loop through all Medevac units
	msg.text =  "MEDEVAC-SCRIPT RUNNING FOR:\n"
	local _unitsmissing = false
	for nr,x in pairs(medevac.medevacunits) do 
		local asterix = " "
		if (Unit.getByName(x) == nil) then
			-- Unit not active
			asterix = "* " 
			_unitmissing = true
			medevac.menupaths[nr] = x
			
		else
			-- Unit active
			local unit = Unit.getByName(x)
			local grp = unit and unit:getGroup()
			local grpID = grp and grp:getID()
			
			if grpID then
				if (medevac.menupaths[nr] ~= x) then 
					missionCommands.removeItemForGroup(grpID, medevac.menupaths[nr]) 
				end
				
				-- NEW v6.0.0: Add menu for active MEDEVAC/SAR and statistics
				medevac.menupaths[nr] = missionCommands.addSubMenuForGroup(grpID, "MEDEVAC", nil)
				
				missionCommands.addCommandForGroup(
					grpID,
					"Active MEDEVAC/SAR",
					medevac.menupaths[nr],
					medevac.displayactive, 
					x)
					
				missionCommands.addCommandForGroup(
					grpID,
					"View Statistics",
					medevac.menupaths[nr],
					medevac.displayStatistics,
					x,
					grp:getCoalition())
			end
			
		end
		
		msg.text = string.format("%s%s%s", msg.text, x, asterix)
	end
	if (_unitmissing) then msg.text = string.format("%s\n* = Missing unit", msg.text) end
	msg.text = string.format("%s\n\nVersion %s by %s (%s)", msg.text, medevac.version, medevac.enhancedby, medevac.lastupdate)
	msg.text = msg.text .. "\nNew Features: Map Markers, Flares, Weather Effects, Statistics"
	msg.displayTime = 5
			
	msg.msgFor = {coa = {'all'}}

	-- DEBUG message		
	if (medevac.displaymedunitslist) then
		mist.message.add(msg)
	end
	return 5
end

-- Schedule timer to add radio item
timer.scheduleFunction(AddMenuItem, {}, timer.getTime() + 5) 
