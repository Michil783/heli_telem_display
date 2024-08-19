--[[------------------------------------------------------------------------------------------
	
	Heli Telem. Display - Full Screen Telemetry Display for Helicopters
	
    By Nick Pedersen (username "nickthenorse" on RCGroups.com and HeliFreak.com).
	
	v1.00 - 2021-08-14 - Initial release
	v1.01 - 2021-08-15 - Bug fix
	v1.02 - 2021-08-15 - Bug fix

	Starting from here by Michael Leopoldseder

	V1.03 - 2022-08-13 - changes some colors and telemetry sensors 
	V1.04 - 2022-08-17 - adding flight counter 
	V1.05 - 2022-08-18 - changing Telemetry window name and adding language support
	V1.06 - 2022-08-19 - removed Cell valotage as logging telemetry due to calculated value and not a real value
	V2.00 - 2022-08-25 - split into more apps to keep it smal
	V2.01 - 2022-08-26 - removed low voltage chirp and introduced count down timer
	V2.02 - 2022-08-28 - pLoad/pSave optimizatiuons
	V2.03 - 2022-08-29 - moved functions from Screen to HeliTelm
	V2.04 - 2022-08-30 - moved a function back to Screen due to higher memory usage in HeliTelm
	V2.05 - 2022-09-03 - fault corrections
	V2.06 - 2022-09-06 - get back some PlayVoiceAlarms from Screen and move it to new function PlayTimerAlarms
	V2.07 - 2022-09-07 - use TimerV.jsn file for countdown alert
	V2.08 - 2022-10-02 - small optimizations and reintegration of screen.lua
	V2.09 - 2022-10-16 - error correction for used battery announcement not stored
	V2.10 - 2022-10-17 - use 100% Lipo capacity instead of 80%
	V2.11 - 2022-10-18 - add log value for power and display it in right panel
	V2.20 - 2024-08-18 - add RPM smoothing
		
		It is a full screen telemetry window, and is hardcoded to display:
	
		- A flight timer (counts upwards only).

		- Rx telemetry: Instantaneous and mininum values for Q, A1, A2, and Rx voltage 
		  (max/min recorded for voltage). Signal levels also shown graphically.
		  
		- Maximum recorded FBL rotation rates for the elevator, aileron and rudder channels 
		  for the flight.
		  
		- Headspeed (instantaneous and maximum).

		- Lipo capacity used, in both percentage and in mAh. Capacity used also shown graphically
		  with a battery symbol. Total flight capacity of the lipo is assumed to be 80% of the 
		  nominal lipo capacity (ie, 80% of a 3700 mAh lipo = 2960 mAh).
		  
		- Custom selectable voice file/alarm levels for battery capacity used during the flight.

		- Custom selectable estimation of used battery capacity based on voltage, if the Rx is
		  powered up with a lipo that is not fully charged. Can also warn via audible voice file.
		  
		- The instantaneous and maximum values for ESC current, ESC temperature, ESC 
		  throttle/power, and FBL vibration level.
		  
		- Main flight pack voltage per cell (just the total lipo voltage divided by the
		  number of cells), as well as the min and max values recorded during the flight.
		  Min and max voltages shown graphically.
		  
		- Custom defineable voltage correction factor/multiplier - most ESCs do not allow you to tweak 
		  the voltage reading in case it is a few percent inaccurate.
		  
		- This main flight pack voltage per cell is also recorded as a custom variable in the
		  Jeti flight logs.
		  
		- Allows user to define a time delay to allow for FBL initialisation. Typically need ca. 10 seconds.

		- Allows user to specify number of samples to average voltage readings.

		- The app will detect when a new lipo is plugged in and automatically reset the flight timer and telemetry values,
		  though this can also be done manually by defining the appropriate switches in the menu.

		- Added a flight counter and reorganized some values

		- added language support
		  
	This is purely for my own hobbyist and non-commercial use.	No liability or responsibility 
	is assumed for your own use! Feel free to use this code in any way you see fit to modify 
	and/or personalise the telemetry that is being displayed, or as a way to learn lua for yourself.
	
	Also: this is my first attempt at a lua app for Jeti. I can't claim it is particularly
	efficiently coded, and is in no way optimised for optimal memory usage. But it works :)
	
	Code heavily inspired by JETI model s.r.o.'s own lua application samples, as well as:

		- Nick Pedersen Heli Telem. Display from https://github.com/nickthenorse/heli_telem_display
		- Tero excellent collection of lua "Jeti Tools" https://www.rc-thoughts.com/
		- Thorn's "Display" app from https://www.jetiforum.de/ and https://www.thorn-klaus-jeti.de
		- Dit71's "dbdis" app from https://www.jetiforum.de/ and https://github.com/ribid1/dbdis

--------------------------------------------------------------------------------------------]]


--------------------------------------------------------------------------------------------
-- Variable declarations
--------------------------------------------------------------------------------------------

collectgarbage()

local _version = "2.20"
local _form_version = "1"
local _appName = ""

--local debugOn = true
local debugVoltage = 6 * 4.2
local debugCapacity = true

local setupvars = {}
local Form

local batteryCapacityUsedAtStartup = 0
local voltagePerCell = 0.0
local batteryPercentage=55
local batteryCapacityUsed = 0
local batteryCapacityPercentAtStartup = 0

local value_list_cell_voltages={}
local value_list_rx_1_voltages={}

local isRxPoweredOn = false
local timeAtPowerOn = 0
local resetRx = false
local isAlarmUsedLipoDetectedActive = false
local hasVoltageStartupBeenRead = false
local lastTime = 0
local avgTime = 0
local flightTimerActive = 0
local resetTimer = 0

local goregisterTelemetry = nil
local countSet = 0

local timerVTable = {}
local isAlarmActive = {}

local averagingWindowCellVoltage = 5

-- screen variables
local base_r,base_g,base_b = 0,0,0
local green_r,green_g,green_b = 0,141,0
local green_light_r,green_light_g,green_light_b = 103,161,103
local red_r,red_g,red_b = 255,0,0
local blue_r,blue_g,blue_b = 0,0,255
local orange_r,orange_g,orange_b = 255,179,0

local voltage_r,voltage_g,voltage_b = 0,204,255
local antenna_r,antenna_g,antenna_b = 0,204,0
local quality_r,quality_g,quality_b = 0,0,255

local max_r,max_g,max_b = 255,0,255
local min_r,min_g,min_b = 88,0,212

local screenMinX = 0
local screenMinY = 0
local screenMaxX = 318
local screenMaxY = 159

local batterySymbolWidth = 53
local batterySymbolHeight = 120

local batterySymbolX = screenMaxX*0.5 - batterySymbolWidth*0.5
local batterySymbolY = screenMaxY - batterySymbolHeight

local batteryTopWidth = batterySymbolWidth*0.5
local batteryTopHeight = 7

local flightTimeMinutesSecondsString = ""
local flightTimeTenthsString = ""

--------------------------------------------------------------------------------------------

local function setLanguage()
    local lng=system.getLocale()
    --print( lng )
    local file = io.readall("Apps/Lang/HeliTelm.jsn")
    if( file == nil ) then
    	file = io.readall("Apps/Lang/HeliT_de.jsn")
    end
    local obj = json.decode(file)
    if(obj) then
        setupvars.trans = obj[lng] or obj[obj.default]
    end
end

--------------------------------------------------------------------------------------------
-- Function that converts dB to Jeti antenna fractions in format of X/9.
--------------------------------------------------------------------------------------------
local function getRSSI(value)
	local result
	if     (value > 999) then result = 999
	elseif (value > 34)  then result = 9
	elseif (value > 27)  then result = 8
	elseif (value > 22)  then result = 7
	elseif (value > 18)  then result = 6
	elseif (value > 14)  then result = 5
	elseif (value > 10)  then result = 4
	elseif (value >  6)  then result = 3
	elseif (value >  3)  then result = 2
	elseif (value >  0)  then result = 1
	else                      result = 0
	end
	return result
end
------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------
-- Function that return the color for text/filling depending on Battery level
--------------------------------------------------------------------------------------------
local function getBatteryLevel()
	if( setupvars.telemetryActive == true and setupvars.hasRxBeenPoweredOn == true and setupvars.batteryPercentageRounded < setupvars.alarmCapacityLevelTwo and setupvars.batteryPercentageRounded >= setupvars.alarmCapacityLevelFour) then -- and setupvars.batteryCapacityUsedTotal > 0) then
		return orange_r,orange_g,orange_b
	elseif (setupvars.telemetryActive == true and setupvars.hasRxBeenPoweredOn == true and setupvars.batteryPercentageRounded < setupvars.alarmCapacityLevelFour) then 
		return red_r,red_g,red_b
	elseif (setupvars.telemetryActive == true and setupvars.hasRxBeenPoweredOn == true and setupvars.batteryPercentageRounded >= setupvars.alarmCapacityLevelTwo) then
		return green_r,green_g,green_b
	end
	return base_r,base_g,base_b
end	
------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------
-- Function that creates main telemetry window.
--------------------------------------------------------------------------------------------
local function printTelemetryWindow()
	lcd.setColor(base_r,base_g,base_b)
	lcd.drawRectangle(batterySymbolX,batterySymbolY,batterySymbolWidth,batterySymbolHeight)
	lcd.drawRectangle(batterySymbolX+1,batterySymbolY+1,batterySymbolWidth-2,batterySymbolHeight-2)
	lcd.drawFilledRectangle(batterySymbolX+((batterySymbolWidth-batteryTopWidth)*0.5),batterySymbolY-batteryTopHeight,batteryTopWidth,batteryTopHeight)

	local batterySymbolDeltaY = (setupvars.batteryPercentageRounded*(batterySymbolHeight-4))//100

	lcd.setColor( getBatteryLevel() )
	if( setupvars.telemetryActive == true ) then		
		lcd.drawFilledRectangle(batterySymbolX+2,batterySymbolY+(batterySymbolHeight-2-batterySymbolDeltaY),batterySymbolWidth-4,batterySymbolDeltaY)
	end
	lcd.setColor(base_r,base_g,base_b)

----------------------------------------------------	

	local panel_01_L_Width = batterySymbolX - 12
	local panel_01_L_Height = 29
	local panel_01_L_X = 0
	local panel_01_L_Y = 0

	local flightCounter = string.format("%04i", setupvars.flightCounter[2])
	lcd.drawText(panel_01_L_X + 1,1,setupvars.trans.flight,FONT_MINI)
	lcd.drawText(panel_01_L_Width - lcd.getTextWidth(FONT_MINI,flightCounter)+6,1,flightCounter,FONT_MINI)

	local timeCounter = setupvars.timeCounter
	local flightTimeOver = ""
	if( timeCounter < 0  ) then
		timeCounter = (timeCounter * -1) + setupvars.timer[2]
		flightTimeOver = "+"
	end
	local mm = (timeCounter // (60)) % 60
	local ss = (timeCounter // 1) % 60
	local t = (timeCounter // 0.1) % 10

	flightTimeMinutesSecondsString = string.format("%s%02d:%02d", flightTimeOver, mm, ss)
	flightTimeTenthsString = string.format(".%01d", t)
		
	--print( string.format("%s %s", flightTimeMinutesSecondsString, flightTimeTenthsString) )
	lcd.drawText(panel_01_L_X + 1,(panel_01_L_Height - lcd.getTextHeight(FONT_MINI,setupvars.trans.time))-1,setupvars.trans.time,FONT_MINI)
	lcd.drawText(panel_01_L_Width - lcd.getTextWidth(FONT_BIG,flightTimeMinutesSecondsString)-6,(panel_01_L_Height - lcd.getTextHeight(FONT_BIG,flightTimeMinutesSecondsString)) + 2,flightTimeMinutesSecondsString,FONT_BIG)
	lcd.drawText(panel_01_L_Width - lcd.getTextWidth(FONT_MINI,flightTimeTenthsString)+6,(panel_01_L_Height - lcd.getTextHeight(FONT_MINI,flightTimeTenthsString)),flightTimeTenthsString,FONT_MINI)

----------------------------------------------------


	local panel_02_L_Width = batterySymbolX
	local panel_02_L_Height = 59
	local panel_02_L_X = 0
	local panel_02_L_Y = panel_01_L_Height
	
	lcd.setColor(base_r,base_g,base_b)
	lcd.drawFilledRectangle(panel_02_L_X,panel_02_L_Y,panel_02_L_Width-3,2)

	local rx_1_RSSI_A1_fraction = getRSSI(setupvars.rx_1_RSSI_A1)
	local rx_1_RSSI_A2_fraction = getRSSI(setupvars.rx_1_RSSI_A2)
	local rx_1_RSSI_A1_fraction_min = getRSSI(setupvars.rx_1_RSSI_A1_min)
	local rx_1_RSSI_A2_fraction_min = getRSSI(setupvars.rx_1_RSSI_A2_min)
	
	
	local rxQBarWidth = 65
	local rxQBarHeight = 5
	
	local rxQBarX = panel_02_L_X + 18
	local rxQBarY = panel_02_L_Y + 6
	
	lcd.drawText(rxQBarX - 14,rxQBarY-4,"Q",FONT_MINI)		
	lcd.drawRectangle(rxQBarX,rxQBarY,rxQBarWidth,rxQBarHeight)
	
	local rxQBarDeltaX = (setupvars.rx_1_Q*rxQBarWidth)//100 - 2
	lcd.setColor(quality_r,quality_g,quality_b)
	lcd.drawFilledRectangle(rxQBarX+1,rxQBarY+1,rxQBarDeltaX,rxQBarHeight-2)
		
	local rx_1_Q_min_X = (((setupvars.rx_1_Q_min)/(100))*100) * (rxQBarWidth-2)//100
	if (setupvars.rx_1_Q_min < 99) then
		lcd.drawFilledRectangle(rxQBarX+1+rx_1_Q_min_X,rxQBarY+1,2,rxQBarHeight-2)
	elseif (rx_1_Q_min == 99) then
		lcd.drawFilledRectangle(rxQBarX+1+rx_1_Q_min_X,rxQBarY+1,1,rxQBarHeight-2)
	end
	lcd.setColor(base_r,base_g,base_b)
		
	local rx_1_Q_String = string.format("%1.0f",setupvars.rx_1_Q)
	lcd.drawText((rxQBarX+rxQBarWidth) + (panel_02_L_Width - (rxQBarX+rxQBarWidth) - lcd.getTextWidth(FONT_MINI,rx_1_Q_String))*0.5-12,rxQBarY-4,rx_1_Q_String,FONT_MINI)
	--lcd.setColor(red_r,red_g,red_b)
	local rx_1_Q_min_String = string.format("%i",setupvars.rx_1_Q_min)
	if (rx_1_Q_min == 101) then
		lcd.drawText((rxQBarX+rxQBarWidth) + (panel_02_L_Width - (rxQBarX+rxQBarWidth) - lcd.getTextWidth(FONT_MINI,"-"))*0.5+10,rxQBarY-5,"-",FONT_MINI)
	else
		lcd.drawText((rxQBarX+rxQBarWidth) + (panel_02_L_Width - (rxQBarX+rxQBarWidth) - lcd.getTextWidth(FONT_MINI,rx_1_Q_min_String))*0.5+10,rxQBarY-4,rx_1_Q_min_String,FONT_MINI)
	end
	lcd.setColor(base_r,base_g,base_b)
	
	
	local rx1RSSIA1BarWidth = rxQBarWidth
	local rx1RSSIA1BarHeight = rxQBarHeight

	local rx1RSSIA1BarX = rxQBarX 
	local rx1RSSIA1BarY = rxQBarY + 11
	
	lcd.drawText(rx1RSSIA1BarX - 16,rx1RSSIA1BarY-4,"A1",FONT_MINI)
	lcd.drawRectangle(rx1RSSIA1BarX,rx1RSSIA1BarY,rx1RSSIA1BarWidth,rx1RSSIA1BarHeight)
	
	local rx1RSSIA1BarDeltaX = (100*(rx_1_RSSI_A1_fraction/9)*rx1RSSIA1BarWidth)//100 - 2
	lcd.setColor(antenna_r,antenna_g,antenna_b)
	lcd.drawFilledRectangle(rx1RSSIA1BarX+1,rx1RSSIA1BarY+1,rx1RSSIA1BarDeltaX,rx1RSSIA1BarHeight-2)
	lcd.setColor(base_r,base_g,base_b)
	
	local rx_1_RSSI_A1_fraction_min_X = (((rx_1_RSSI_A1_fraction_min)/(9))*100) * (rx1RSSIA1BarWidth-2)//100
	--lcd.setColor(red_r,red_g,red_b)
	if (rx_1_RSSI_A1_fraction_min < 9) then
		lcd.drawFilledRectangle(rx1RSSIA1BarX+1+rx_1_RSSI_A1_fraction_min_X,rx1RSSIA1BarY+1,2,rx1RSSIA1BarHeight-2)
	end
	lcd.setColor(base_r,base_g,base_b)
	
	local rx_1_RSSI_A1_fraction_String = string.format("%i",rx_1_RSSI_A1_fraction)
	lcd.drawText((rx1RSSIA1BarX+rx1RSSIA1BarWidth) + (panel_02_L_Width - (rx1RSSIA1BarX+rx1RSSIA1BarWidth) - lcd.getTextWidth(FONT_MINI,rx_1_RSSI_A1_fraction_String))*0.5-12,rx1RSSIA1BarY-4,rx_1_RSSI_A1_fraction_String,FONT_MINI)
	--lcd.setColor(red_r,red_g,red_b)
	local rx_1_RSSI_A1_fraction_min_String = string.format("%i",rx_1_RSSI_A1_fraction_min)
	if (rx_1_RSSI_A1_fraction_min == 999) then
		lcd.drawText((rx1RSSIA1BarX+rx1RSSIA1BarWidth) + (panel_02_L_Width - (rx1RSSIA1BarX+rx1RSSIA1BarWidth) - lcd.getTextWidth(FONT_MINI,"-"))*0.5+10,rx1RSSIA1BarY-5,"-",FONT_MINI)
	else
		lcd.drawText((rx1RSSIA1BarX+rx1RSSIA1BarWidth) + (panel_02_L_Width - (rx1RSSIA1BarX+rx1RSSIA1BarWidth) - lcd.getTextWidth(FONT_MINI,rx_1_RSSI_A1_fraction_min_String))*0.5+10,rx1RSSIA1BarY-4,rx_1_RSSI_A1_fraction_min_String,FONT_MINI)
	end
	lcd.setColor(base_r,base_g,base_b)


	local rx1RSSIA2BarWidth = rxQBarWidth
	local rx1RSSIA2BarHeight = rxQBarHeight

	local rx1RSSIA2BarX = rxQBarX
	local rx1RSSIA2BarY = rx1RSSIA1BarY + 11
	
	lcd.drawText(rx1RSSIA2BarX - 16,rx1RSSIA2BarY-4,"A2",FONT_MINI)
	lcd.drawRectangle(rx1RSSIA2BarX,rx1RSSIA2BarY,rx1RSSIA2BarWidth,rx1RSSIA2BarHeight)

	local rx1RSSIA2BarDeltaX = (100*(rx_1_RSSI_A2_fraction/9)*rx1RSSIA2BarWidth)//100 - 2
	lcd.setColor(antenna_r,antenna_g,antenna_b)
	lcd.drawFilledRectangle(rx1RSSIA2BarX+1,rx1RSSIA2BarY+1,rx1RSSIA2BarDeltaX,rx1RSSIA2BarHeight-2)
	lcd.setColor(base_r,base_g,base_b)
	
	local rx_1_RSSI_A2_fraction_min_X = (((rx_1_RSSI_A2_fraction_min)/(9))*100) * (rx1RSSIA2BarWidth-2)//100
	if (rx_1_RSSI_A2_fraction_min < 9) then
		lcd.drawFilledRectangle(rx1RSSIA2BarX+1+rx_1_RSSI_A2_fraction_min_X,rx1RSSIA2BarY+1,2,rx1RSSIA2BarHeight-2)
	end
	lcd.setColor(base_r,base_g,base_b)
	
	local rx_1_RSSI_A2_fraction_String = string.format("%i",rx_1_RSSI_A2_fraction)
	lcd.drawText((rx1RSSIA2BarX+rx1RSSIA2BarWidth) + (panel_02_L_Width - (rx1RSSIA2BarX+rx1RSSIA2BarWidth) - lcd.getTextWidth(FONT_MINI,rx_1_RSSI_A2_fraction_String))*0.5-12,rx1RSSIA2BarY-4,rx_1_RSSI_A2_fraction_String,FONT_MINI)
	local rx_1_RSSI_A2_fraction_min_String = string.format("%i",rx_1_RSSI_A2_fraction_min)
	if (rx_1_RSSI_A2_fraction_min == 999) then
		lcd.drawText((rx1RSSIA2BarX+rx1RSSIA2BarWidth) + (panel_02_L_Width - (rx1RSSIA2BarX+rx1RSSIA2BarWidth) - lcd.getTextWidth(FONT_MINI,"-"))*0.5+10,rx1RSSIA2BarY-5,"-",FONT_MINI)
	else
		lcd.drawText((rx1RSSIA2BarX+rx1RSSIA2BarWidth) + (panel_02_L_Width - (rx1RSSIA2BarX+rx1RSSIA2BarWidth) - lcd.getTextWidth(FONT_MINI,rx_1_RSSI_A2_fraction_String))*0.5+10,rx1RSSIA2BarY-4,rx_1_RSSI_A2_fraction_min_String,FONT_MINI)
	end
	lcd.setColor(base_r,base_g,base_b)
	
	local rx_1_Voltage_String = string.format("%4.2f",setupvars.rx_1_Voltage_Averaged)
	lcd.drawText(panel_02_L_X + 23,(panel_02_L_Y + panel_02_L_Height - lcd.getTextHeight(FONT_BIG,rx_1_Voltage_String))-0,rx_1_Voltage_String,FONT_BIG)
	lcd.drawText(panel_02_L_X + 60,(panel_02_L_Y + panel_02_L_Height - lcd.getTextHeight(FONT_MINI,"v"))-6,"v",FONT_MINI)
	
	lcd.drawText(panel_02_L_X + 71,(panel_02_L_Y + panel_02_L_Height - lcd.getTextHeight(FONT_MINI,"min"))-10,"min",FONT_MINI)
	lcd.drawText(panel_02_L_X + 71,(panel_02_L_Y + panel_02_L_Height - lcd.getTextHeight(FONT_MINI,"max"))-2,"max",FONT_MINI)
	local rx_1_Voltage_min_String = string.format("%4.2f",setupvars.rx_1_Voltage_min)
	lcd.setColor(red_r,red_g,red_b)
	if (setupvars.rx_1_Voltage_min == 99.9) then
		lcd.drawText(panel_02_L_X + 95,(panel_02_L_Y + panel_02_L_Height - lcd.getTextHeight(FONT_NORMAL,"---"))-9," ---",FONT_NORMAL)
	else
		lcd.drawText(panel_02_L_X + 97,(panel_02_L_Y + panel_02_L_Height - lcd.getTextHeight(FONT_MINI,rx_1_Voltage_min_String))-10,rx_1_Voltage_min_String,FONT_MINI)
	end
	lcd.drawText(panel_02_L_X + 121,(panel_02_L_Y + panel_02_L_Height - lcd.getTextHeight(FONT_MINI,"v"))-11,"v",FONT_MINI)
	local rx_1_Voltage_max_String = string.format("%4.2f",setupvars.rx_1_Voltage_max)
	lcd.setColor(green_r,green_g,green_b)
	if (setupvars.rx_1_Voltage_max == -1.0) then
		lcd.drawText(panel_02_L_X + 95,(panel_02_L_Y + panel_02_L_Height - lcd.getTextHeight(FONT_NORMAL,"---"))-0," ---",FONT_NORMAL)
	else
		lcd.drawText(panel_02_L_X + 97,(panel_02_L_Y + panel_02_L_Height - lcd.getTextHeight(FONT_MINI,rx_1_Voltage_max_String))-1,rx_1_Voltage_max_String,FONT_MINI)
	end
	lcd.drawText(panel_02_L_X + 121,(panel_02_L_Y + panel_02_L_Height - lcd.getTextHeight(FONT_MINI,"v"))-2,"v",FONT_MINI)
	lcd.setColor(base_r,base_g,base_b)
	
	lcd.drawText(panel_02_L_X + 1,(panel_02_L_Y + panel_02_L_Height - lcd.getTextHeight(FONT_MINI,"Rx"))-1,"Rx",FONT_MINI)

----------------------------------------------------

	local panel_03_L_Width = batterySymbolX
	local panel_03_L_Height = 43
	local panel_03_L_X = 0
	local panel_03_L_Y = panel_01_L_Height + panel_02_L_Height

	lcd.setColor(base_r,base_g,base_b)
	lcd.drawFilledRectangle(panel_03_L_X,panel_03_L_Y,panel_03_L_Width-3,2)
	
	if( setupvars.elevatorSensor[1] ~= 0 or setupvars.aileronSensor[1] ~= 0 or setupvars.rudderSensor[1] ~= 0 or setupvars.vibrationsSensor[1] ~= 0 ) then
		lcd.drawText(panel_03_L_X + 1,(panel_03_L_Y + panel_03_L_Height - lcd.getTextHeight(FONT_MINI,setupvars.trans.fbl))-1,setupvars.trans.fbl,FONT_MINI)
	end

	local fontHeight = lcd.getTextHeight(FONT_MINI, setupvars.trans.actElevator) - 2
	local elevatorRateMinString = ""
	local elevatorRateMaxString = ""
	if( setupvars.elevatorSensor[1] ~= 0 ) then
		lcd.drawText(panel_03_L_X + 27,panel_03_L_Y+1,setupvars.trans.actElevator,FONT_MINI)
		elevatorRateMinString = string.format("%3i",setupvars.elevatorRateMin)
		if (setupvars.elevatorRateMin == 1e6) then
			lcd.drawText(panel_03_L_X + panel_03_L_Width - lcd.getTextWidth(FONT_MINI,"---")-42,panel_03_L_Y+1,"---",FONT_MINI)
		else
			lcd.drawText(panel_03_L_X + panel_03_L_Width - lcd.getTextWidth(FONT_MINI,elevatorRateMinString)-38,panel_03_L_Y+1,elevatorRateMinString,FONT_MINI)
		end
		
		lcd.setColor(base_r,base_g,base_b)
		lcd.drawText(panel_03_L_X + panel_03_L_Width - lcd.getTextWidth(FONT_MINI,"/")-31,panel_03_L_Y+1,"/",FONT_MINI)
		elevatorRateMaxString = string.format("+%3i",setupvars.elevatorRateMax)
		if (setupvars.elevatorRateMax == -1e6) then
			lcd.drawText(panel_03_L_X + panel_03_L_Width - lcd.getTextWidth(FONT_MINI,"---")-15,panel_03_L_Y+1,"---",FONT_MINI)
		else
			lcd.drawText(panel_03_L_X + panel_03_L_Width - lcd.getTextWidth(FONT_MINI,elevatorRateMaxString)-5,panel_03_L_Y+1,elevatorRateMaxString,FONT_MINI)
		end
	end
	lcd.setColor(base_r,base_g,base_b)
	
	local aileronRateMinString = ""
	local aileronRateMaxString = ""
	if( setupvars.aileronSensor[1] ~= 0 ) then
		lcd.drawText(panel_03_L_X + 27,panel_03_L_Y+1+fontHeight,setupvars.trans.actAileron,FONT_MINI)
		aileronRateMinString = string.format("%3i",setupvars.aileronRateMin)
		if (setupvars.aileronRateMin == 1e6) then
			lcd.drawText(panel_03_L_X + panel_03_L_Width - lcd.getTextWidth(FONT_MINI,"---")-42,panel_03_L_Y+1+fontHeight,"---",FONT_MINI)
		else
			lcd.drawText(panel_03_L_X + panel_03_L_Width - lcd.getTextWidth(FONT_MINI,aileronRateMinString)-38,panel_03_L_Y+ 1+fontHeight,aileronRateMinString,FONT_MINI)
		end
		
		lcd.setColor(base_r,base_g,base_b)
		lcd.drawText(panel_03_L_X + panel_03_L_Width - lcd.getTextWidth(FONT_MINI,"/")-31,panel_03_L_Y+1+fontHeight,"/",FONT_MINI)
		aileronRateMaxString = string.format("+%3i",setupvars.aileronRateMax)
		if (setupvars.aileronRateMax == -1e6) then
			lcd.drawText(panel_03_L_X + panel_03_L_Width - lcd.getTextWidth(FONT_MINI,"---")-15,panel_03_L_Y+1+fontHeight,"---",FONT_MINI)
		else
			lcd.drawText(panel_03_L_X + panel_03_L_Width - lcd.getTextWidth(FONT_MINI,aileronRateMaxString)-5,panel_03_L_Y+1+fontHeight,aileronRateMaxString,FONT_MINI)
		end
	end
	lcd.setColor(base_r,base_g,base_b)

	local rudderRateMinString = ""
	local rudderRateMaxString = ""
	if( setupvars.rudderSensor[1] ~= 0 ) then
		lcd.drawText(panel_03_L_X + 27,panel_03_L_Y+1+fontHeight+fontHeight,setupvars.trans.actRudder,FONT_MINI)
		rudderRateMinString = string.format("%3i",setupvars.rudderRateMin)
		if (setupvars.rudderRateMin == 1e6) then
			lcd.drawText(panel_03_L_X + panel_03_L_Width - lcd.getTextWidth(FONT_MINI,"---")-42,panel_03_L_Y+1+fontHeight+fontHeight,"---",FONT_MINI)
		else
			lcd.drawText(panel_03_L_X + panel_03_L_Width - lcd.getTextWidth(FONT_MINI,rudderRateMinString)-38,panel_03_L_Y+1+fontHeight+fontHeight,rudderRateMinString,FONT_MINI)
		end

		lcd.setColor(base_r,base_g,base_b)
		lcd.drawText(panel_03_L_X + panel_03_L_Width - lcd.getTextWidth(FONT_MINI,"/")-31,panel_03_L_Y+1+fontHeight+fontHeight,"/",FONT_MINI)
		rudderRateMaxString = string.format("+%3i",setupvars.rudderRateMax)
		if (setupvars.rudderRateMax == -1e6) then
			lcd.drawText(panel_03_L_X + panel_03_L_Width - lcd.getTextWidth(FONT_MINI,"---")-15,panel_03_L_Y+1+fontHeight+fontHeight,"---",FONT_MINI)
		else
			lcd.drawText(panel_03_L_X + panel_03_L_Width - lcd.getTextWidth(FONT_MINI,rudderRateMaxString)-5,panel_03_L_Y+1+fontHeight+fontHeight,rudderRateMaxString,FONT_MINI)
		end
	end	
	lcd.setColor(base_r,base_g,base_b)

	local vibrationsString = ""
	local vibrationsMaxString = ""
	if( setupvars.vibrationsSensor[1] ~= 0 ) then	
		lcd.drawText(panel_03_L_X + 27,panel_03_L_Y+1+fontHeight+fontHeight+fontHeight,setupvars.trans.actVibration,FONT_MINI)

		vibrationsString = string.format("%3i",setupvars.vibrations)
		lcd.drawText(panel_03_L_X + panel_03_L_Width - lcd.getTextWidth(FONT_MINI,vibrationsString) - 38, panel_03_L_Y+1+fontHeight+fontHeight+fontHeight, vibrationsString,FONT_MINI)

		lcd.drawText(panel_03_L_X + panel_03_L_Width - lcd.getTextWidth(FONT_MINI,"/")-31,panel_03_L_Y+1+fontHeight+fontHeight+fontHeight,"/",FONT_MINI)
		vibrationsMaxString = string.format("%3i",setupvars.vibrationsMax)
		if (setupvars.vibrationsMax == -1.0) then
			lcd.drawText(panel_03_L_X + panel_03_L_Width - lcd.getTextWidth(FONT_MINI,"---")-15, panel_03_L_Y+1+fontHeight+fontHeight+fontHeight, "---",FONT_MINI)
		else
			lcd.drawText(panel_03_L_X + panel_03_L_Width - lcd.getTextWidth(FONT_MINI,vibrationsMaxString)-5, panel_03_L_Y+1+fontHeight+fontHeight+fontHeight, vibrationsMaxString,FONT_MINI)
		end
	end
	lcd.setColor(base_r,base_g,base_b)

----------------------------------------------------
	
	local panel_04_L_Width = batterySymbolX
	local panel_04_L_Height = 28
	local panel_04_L_X = 0
	local panel_04_L_Y = panel_01_L_Height + panel_02_L_Height + panel_03_L_Height

	lcd.setColor(base_r,base_g,base_b)
	lcd.drawFilledRectangle(panel_04_L_X,panel_04_L_Y,panel_04_L_Width-3,2)
	
	local rpmString = 0
	local rpmMaxString = 0
	if( setupvars.rpmSensor[1] ~= 0 ) then
		lcd.drawText(panel_04_L_X + panel_04_L_Width - lcd.getTextWidth(FONT_MINI,"RPM")-2,panel_04_L_Y + (panel_04_L_Height - lcd.getTextHeight(FONT_MINI,"RPM"))*0.5+3,"RPM",FONT_MINI)
		rpmString = string.format("%4i",setupvars.rpm)
		lcd.drawText((panel_04_L_Width - lcd.getTextWidth(FONT_MAXI,rpmString))-25,panel_04_L_Y+panel_04_L_Height - lcd.getTextHeight(FONT_MAXI,rpmString)+8,rpmString,FONT_MAXI)
		
		lcd.drawText(panel_04_L_X+5,panel_04_L_Y + panel_04_L_Height - lcd.getTextHeight(FONT_MINI,"max")-12,"max",FONT_MINI)
		rpmMaxString = string.format("%4i",setupvars.rpmMax)
		--lcd.setColor(max_r,max_g,max_b)

		if (setupvars.rpmMax == -1.0) then
			lcd.drawText(panel_04_L_X + (panel_04_L_Width - lcd.getTextWidth(FONT_MINI,"------"))*0.5 - 50,panel_04_L_Y + panel_04_L_Height -lcd.getTextHeight(FONT_MINI,"------"),"------",FONT_MINI)
		else
			lcd.drawText(panel_04_L_X + (panel_04_L_Width - lcd.getTextWidth(FONT_MINI,rpmMaxString))*0.5 - 50,panel_04_L_Y + panel_04_L_Height -lcd.getTextHeight(FONT_MINI,rpmMaxString),rpmMaxString,FONT_MINI)
		end
	end

----------------------------------------------------
	
	local panel_01_R_Width = screenMaxX - batterySymbolX - batterySymbolWidth - 12
	local panel_01_R_Height = 29
	local panel_01_R_X = screenMaxX - panel_01_R_Width
	local panel_01_R_Y = 0

	lcd.setColor(base_r,base_g,base_b)

	if( setupvars.capacitySensor[1] ~= 0 ) then		
		lcd.drawText(panel_01_R_X + -5,panel_01_R_Y + panel_01_R_Height - lcd.getTextHeight(FONT_MINI,setupvars.trans.lipo)-1,setupvars.trans.lipo,FONT_MINI)
		lcd.drawText((panel_01_R_X + panel_01_R_Width - lcd.getTextWidth(FONT_MINI,"mAh"))-2,panel_01_R_Y + (panel_01_R_Height - lcd.getTextHeight(FONT_MINI,"mAh"))-1,"mAh",FONT_MINI)
		batteryCapacityUsedString = string.format("%i",setupvars.batteryCapacityUsedTotal)
		
		if (hasRxBeenPoweredOn == true and batteryPercentageRounded <= setupvars.alarmCapacityLevelFive and batteryPercentageRounded > setupvars.alarmCapacityLevelSix and batteryCapacityUsedTotal > 0) then
			lcd.setColor(orange_r,orange_g,orange_b)
		elseif (hasRxBeenPoweredOn == true and batteryPercentageRounded <= setupvars.alarmCapacityLevelSix and batteryCapacityUsedTotal > 0) then
			lcd.setColor(red_r,red_g,red_b)
		else
			lcd.setColor(base_r,base_g,base_b)
		end
			
		lcd.drawText((panel_01_R_X + panel_01_R_Width - lcd.getTextWidth(FONT_MAXI,batteryCapacityUsedString))-28,(panel_01_R_Height - lcd.getTextHeight(FONT_MAXI,batteryCapacityUsedString))*0.5,batteryCapacityUsedString,FONT_MAXI)
	end

	lcd.setColor(base_r,base_g,base_b)
	
	if( setupvars.telemetryActive == true and setupvars.alarmUsedLipo[1] == 1 and setupvars.voltagePerCellAtStartup < (setupvars.alarmUsedLipo[2]/100) ) then
		lcd.setColor(red_r,red_g,red_b)
		lcd.drawText(panel_01_R_X + -5,panel_01_R_Y+5,setupvars.trans.estimate,FONT_MINI)
		lcd.setColor(base_r,base_g,base_b)
	end

----------------------------------------------------

	local panel_02_R_Width = screenMaxX - batterySymbolX - batterySymbolWidth
	local panel_02_R_Height = 75
	local panel_02_R_X = panel_02_L_Width + batterySymbolWidth
	local panel_02_R_Y = panel_01_R_Height

	local displacement = 2
	local fontBigHeight = lcd.getTextHeight(FONT_BIG,"0")-displacement
	local fontNormalHeight = lcd.getTextHeight(FONT_NORMAL,"0")-displacement
	local fontMiniHeight = lcd.getTextHeight(FONT_MINI,"0")-displacement
	local font = FONT_NORMAL
	fontHeight	= lcd.getTextHeight(font,"0") - 1 
	local xOffset = 50
	local xOffset1 = 39

	lcd.setColor(base_r,base_g,base_b)
	lcd.drawFilledRectangle(panel_02_R_X+3,panel_02_R_Y,panel_02_R_Width-3,2)
	
	local escCurrentString = ""
	local escCurrentMaxString = ""
	local currentSensor_Y = panel_02_R_Y-displacement
	if( setupvars.currentSensor[1] ~= 0 ) then
		lcd.drawText(panel_02_R_X+4,currentSensor_Y+fontHeight-fontMiniHeight-displacement,setupvars.trans.actCurrent,FONT_MINI)
		escCurrentString = string.format("%3.1f",setupvars.escCurrent)
		lcd.drawText(panel_02_R_X+panel_02_R_Width-lcd.getTextWidth(font,escCurrentString)-xOffset,currentSensor_Y,escCurrentString,font)
		lcd.drawText(panel_02_R_X+panel_02_R_Width-lcd.getTextWidth(FONT_MINI,"A")-xOffset1,currentSensor_Y+fontHeight-fontMiniHeight-displacement,"A",FONT_MINI)
		escCurrentMaxString = string.format("%3i A",setupvars.escCurrentMax)
		if (setupvars.escCurrentMax == -1.0) then
			lcd.drawText(panel_02_R_X+panel_02_R_Width-lcd.getTextWidth(FONT_MINI,"--- A")-5,currentSensor_Y+fontHeight-fontMiniHeight-displacement,"--- A",FONT_MINI)
		else
			lcd.drawText(panel_02_R_X+panel_02_R_Width-lcd.getTextWidth(FONT_MINI,escCurrentMaxString)-5,currentSensor_Y+fontHeight-fontMiniHeight-displacement,escCurrentMaxString,FONT_MINI)
		end
	end
	lcd.setColor(base_r,base_g,base_b)
	
	local powerString = ""
	local powerMaxString = ""
	local powerSensor_Y = currentSensor_Y + fontHeight-displacement 
	if( setupvars.currentSensor[1] ~= 0 and setupvars.voltageSensor[1] ~= 0 ) then
		lcd.drawText(panel_02_R_X+4,powerSensor_Y+fontHeight-fontMiniHeight-displacement, "Watt",FONT_MINI)
		powerString = string.format("%i",setupvars.powerValue)
		lcd.drawText(panel_02_R_X+panel_02_R_Width-lcd.getTextWidth(font,powerString)-xOffset,powerSensor_Y,powerString,font)
		lcd.drawText(panel_02_R_X+panel_02_R_Width-lcd.getTextWidth(FONT_MINI,"W")-xOffset1,powerSensor_Y+fontHeight-fontMiniHeight-displacement,"W",FONT_MINI)
		if( setupvars.powerMax >= 1000 ) then 
			powerMaxString = string.format("%1.2f kW", setupvars.powerMax / 1000.0 )
		else
			powerMaxString = string.format("%i W",setupvars.powerMax)
		end
		if (setupvars.powerMax == -1.0) then
			lcd.drawText(panel_02_R_X+panel_02_R_Width-lcd.getTextWidth(FONT_MINI,"--- W")-5,powerSensor_Y+fontHeight-fontMiniHeight-displacement,"--- W",FONT_MINI)
		else
			lcd.drawText(panel_02_R_X+panel_02_R_Width-lcd.getTextWidth(FONT_MINI,powerMaxString)-5,powerSensor_Y+fontHeight-fontMiniHeight-displacement,powerMaxString,FONT_MINI)
		end
	end
	lcd.setColor(base_r,base_g,base_b)

	local escTempString = ""
	local escTempMaxString = ""
	local escTempSensor_Y = powerSensor_Y + fontHeight-displacement
	if( setupvars.temperatureSensor[1] ~= 0 ) then
		lcd.drawText(panel_02_R_X+4,escTempSensor_Y+fontHeight-fontMiniHeight-displacement,setupvars.trans.actTemp,FONT_MINI)
		escTempString = string.format("%i",setupvars.escTemp)
		lcd.drawText(panel_02_R_X+panel_02_R_Width-lcd.getTextWidth(font,escTempString)-xOffset,escTempSensor_Y,escTempString,font)
		lcd.drawText(panel_02_R_X+panel_02_R_Width-lcd.getTextWidth(FONT_MINI,"°C")-xOffset1,escTempSensor_Y+fontHeight-fontMiniHeight-displacement,"°C",FONT_MINI)
		escTempMaxString = string.format("%i °C",setupvars.escTempMax)
		if (setupvars.escTempMax == -1.0) then
			lcd.drawText(panel_02_R_X+panel_02_R_Width-lcd.getTextWidth(FONT_MINI,"--- °C")-5,escTempSensor_Y+fontHeight-fontMiniHeight-displacement,"--- °C",FONT_MINI)
		else
			lcd.drawText(panel_02_R_X+panel_02_R_Width-lcd.getTextWidth(FONT_MINI,escTempMaxString)-5,escTempSensor_Y+fontHeight-fontMiniHeight-displacement,escTempMaxString,FONT_MINI)
		end
	end
	lcd.setColor(base_r,base_g,base_b)
	
	local escThrottleString = ""
	local escThrottleMaxString = ""
	local escThrottleSensor_Y = escTempSensor_Y + fontHeight-displacement
	if( setupvars.throttleSensor[1] ~= 0 ) then
		lcd.drawText(panel_02_R_X+4,escThrottleSensor_Y+fontHeight-fontMiniHeight-displacement,setupvars.trans.actThrottle,FONT_MINI)
		escThrottleString = string.format("%i",setupvars.escThrottle)
		lcd.drawText(panel_02_R_X+panel_02_R_Width-lcd.getTextWidth(font,escThrottleString)-xOffset,escThrottleSensor_Y,escThrottleString,font)
		lcd.drawText(panel_02_R_X+panel_02_R_Width-lcd.getTextWidth(FONT_MINI,"%")-xOffset1,escThrottleSensor_Y+fontHeight-fontMiniHeight-displacement,"%",FONT_MINI)
		escThrottleMaxString = string.format("%i %%",setupvars.escThrottleMax)
		if (setupvars.escThrottleMax == -1.0) then
			lcd.drawText(panel_02_R_X+panel_02_R_Width-lcd.getTextWidth(FONT_MINI,"--- %")-3,escThrottleSensor_Y+fontHeight-fontMiniHeight-displacement,"--- %",FONT_MINI)
		else
			lcd.drawText(panel_02_R_X+panel_02_R_Width-lcd.getTextWidth(FONT_MINI,escThrottleMaxString)-3,escThrottleSensor_Y+fontHeight-fontMiniHeight-displacement,escThrottleMaxString,FONT_MINI)
		end
	end
	lcd.setColor(base_r,base_g,base_b)

	local hightString = ""
	local hightMaxString = ""
	local hightSensor_Y = escThrottleSensor_Y + fontHeight-displacement
	if( setupvars.maltiSensor[1] ~= 0 ) then
		lcd.drawText(panel_02_R_X+4,hightSensor_Y+fontHeight-fontMiniHeight-displacement,setupvars.trans.actHeight,FONT_MINI)
		hightString = string.format("%i",setupvars.hight)
		lcd.drawText(panel_02_R_X+(panel_02_R_Width-lcd.getTextWidth(font,hightString))-xOffset,hightSensor_Y,hightString,font)
		lcd.drawText(panel_02_R_X+panel_02_R_Width-lcd.getTextWidth(FONT_MINI,"m")-xOffset1,hightSensor_Y+fontHeight-fontMiniHeight-displacement,"m",FONT_MINI)

		hightMaxString = string.format("%i m",setupvars.hightMax)
		if (setupvars.hightMax == -1.0) then
			lcd.drawText(panel_02_R_X+panel_02_R_Width-lcd.getTextWidth(FONT_MINI,"--- m")-3,hightSensor_Y+fontHeight-fontMiniHeight-displacement,"--- m",FONT_MINI)
		else
			lcd.drawText(panel_02_R_X+panel_02_R_Width-lcd.getTextWidth(FONT_MINI,hightMaxString)-3,hightSensor_Y+fontHeight-fontMiniHeight-displacement,hightMaxString,FONT_MINI)
		end
	end
	lcd.setColor(base_r,base_g,base_b)

----------------------------------------------------
	
	local panel_03_R_Width = screenMaxX - batterySymbolX - batterySymbolWidth
	local panel_03_R_Height = 55
	local panel_03_R_X = panel_04_L_Width + batterySymbolWidth
	local panel_03_R_Y = panel_01_R_Height + panel_02_R_Height

	lcd.setColor(base_r,base_g,base_b)
	lcd.drawFilledRectangle(panel_03_R_X+3,panel_03_R_Y,panel_03_R_Width-3,2)
	
	local voltageSensorValueString = ""
	local voltageBarWidth = 76
	local voltageBarHeight = 7
	
	local voltageBarX = panel_03_R_X + (panel_03_R_Width - voltageBarWidth)*0.5 
	local voltageBarY = panel_03_R_Y+5
	
	local minVoltageValueBar = 3.20
	local maxVoltageValueBar = 4.20
	local restingVoltageTick = 3.75

	local voltageBarFillRatio = ((setupvars.voltagePerCellAveraged - minVoltageValueBar) / (maxVoltageValueBar-minVoltageValueBar))*100
	local voltageBarDeltaX = (voltageBarFillRatio*(voltageBarWidth-2))//100
	local restingVoltageTickX = (((restingVoltageTick - minVoltageValueBar) / (maxVoltageValueBar-minVoltageValueBar))*100) * (voltageBarWidth-2)//100
	local minVoltageValueX = (((setupvars.minVoltagePerCell - minVoltageValueBar) / (maxVoltageValueBar-minVoltageValueBar))*100) * (voltageBarWidth-2)//100
	local maxVoltageValueX = (((setupvars.maxVoltagePerCell - minVoltageValueBar) / (maxVoltageValueBar-minVoltageValueBar))*100) * (voltageBarWidth-2)//100

	if( setupvars.voltageSensor[1] ~= 0 ) then
		voltageSensorValueString = string.format("%02.1f",setupvars.voltageSensorValue)

		lcd.drawText(panel_03_R_X + (panel_03_R_Width - lcd.getTextWidth(FONT_MAXI,voltageSensorValueString))*0.5,panel_03_R_Y + panel_03_R_Height - lcd.getTextHeight(FONT_MAXI,voltageSensorValueString)-8,voltageSensorValueString,FONT_MAXI)
		lcd.drawText(panel_03_R_X + (panel_03_R_Width - lcd.getTextWidth(FONT_MAXI,voltageSensorValueString))*0.5 + 68,panel_03_R_Y + panel_03_R_Height - lcd.getTextHeight(FONT_BIG,"V")-17,"V",FONT_BIG)
		
		lcd.drawText(panel_03_R_X+4,panel_03_R_Y + panel_03_R_Height - lcd.getTextHeight(FONT_MINI,setupvars.trans.cell)-9,setupvars.trans.cell,FONT_MINI)
		lcd.drawText(panel_03_R_X+4,panel_03_R_Y + panel_03_R_Height - lcd.getTextHeight(FONT_MINI,setupvars.trans.cellVolt)+2,setupvars.trans.cellVolt,FONT_MINI)
		
		lcd.drawText(panel_03_R_X + panel_03_R_Width - lcd.getTextWidth(FONT_MINI,"min")-7,panel_03_R_Y+panel_03_R_Height-18,"min",FONT_MINI)
		lcd.drawText(panel_03_R_X + panel_03_R_Width - lcd.getTextWidth(FONT_MINI,"max")-5,panel_03_R_Y+panel_03_R_Height-10,"max",FONT_MINI)

		lcd.drawText(panel_03_R_X+64,panel_03_R_Y+panel_03_R_Height-16,"/",FONT_NORMAL)
		lcd.setColor(green_r,green_g,green_b)
		if (setupvars.maxVoltagePerCell == -1.0) then
			lcd.drawText(panel_03_R_X+75,panel_03_R_Y+panel_03_R_Height-16,"----",FONT_BOLD)
		else
			lcd.drawText(panel_03_R_X+71,panel_03_R_Y+panel_03_R_Height-16,string.format("%02.2f",setupvars.maxVoltagePerCell),FONT_BOLD)
		end
		lcd.setColor(red_r,red_g,red_b)
		if (setupvars.minVoltagePerCell == 99.9) then
			lcd.drawText(panel_03_R_X+41,panel_03_R_Y+panel_03_R_Height-16,"----",FONT_BOLD)
		else
			lcd.drawText(panel_03_R_X+34,panel_03_R_Y+panel_03_R_Height-16,string.format("%02.2f",setupvars.minVoltagePerCell),FONT_BOLD)
		end
		lcd.setColor(base_r,base_g,base_b)
		
		
		lcd.drawRectangle(voltageBarX,voltageBarY,voltageBarWidth,voltageBarHeight)
		lcd.drawText(voltageBarX-23,voltageBarY-3,string.format("%02.2f",minVoltageValueBar),FONT_MINI)
		lcd.drawText(voltageBarX+voltageBarWidth+2,voltageBarY-3,string.format("%02.2f",maxVoltageValueBar),FONT_MINI)
		
		if (voltageBarFillRatio >= 0 and voltageBarFillRatio <= 100) then
			voltageBarFillRatio = voltageBarFillRatio
		else
			voltageBarFillRatio = 0
		end
		
		lcd.setColor(voltage_r,voltage_g,voltage_b)
			
		lcd.drawFilledRectangle(voltageBarX+1,voltageBarY+1,voltageBarDeltaX,voltageBarHeight-2)
		lcd.setColor(base_r,base_g,base_b)
		
		lcd.setColor(base_r,base_g,base_b)
		lcd.drawLine(voltageBarX+1+restingVoltageTickX,voltageBarY+1,voltageBarX+1+restingVoltageTickX,voltageBarY+voltageBarHeight-2)
		lcd.setColor(base_r,base_g,base_b)
		
		lcd.setColor(red_r,red_g,red_b)
		lcd.drawFilledRectangle(voltageBarX+1+minVoltageValueX,voltageBarY+1,3,voltageBarHeight-2)
		lcd.setColor(base_r,base_g,base_b)
		
		lcd.setColor(green_r,green_g,green_b)
		lcd.drawFilledRectangle(voltageBarX+1+maxVoltageValueX,voltageBarY+1,3,voltageBarHeight-2)
		lcd.setColor(base_r,base_g,base_b)
	end	

----------------------------------------------------
		
	local panel_central_Width = screenMaxX - panel_01_L_Width - panel_01_R_Width
	local panel_central_Height = screenMaxY - batterySymbolHeight - batteryTopHeight - 0
	local panel_central_X = panel_01_L_Width
	local panel_central_Y = 0
	
	local batteryPercentageString = string.format("%i",setupvars.batteryPercentageRounded)
	lcd.setColor( getBatteryLevel() )
	if( setupvars.telemetryActive == true and setupvars.capacitySensor[1] ~= 0 ) then
		lcd.drawText(panel_central_X + (panel_central_Width - lcd.getTextWidth(FONT_MAXI,batteryPercentageString))*0.5+lcd.getTextWidth(FONT_MAXI,batteryPercentageString)-1,panel_central_Y + (panel_central_Height - lcd.getTextHeight(FONT_NORMAL,"%"))*0.5-8,"%",FONT_NORMAL)
		lcd.drawText(panel_central_X + (panel_central_Width - lcd.getTextWidth(FONT_MAXI,batteryPercentageString))*0.5-2,panel_central_Y-5,batteryPercentageString,FONT_MAXI)
	end
	lcd.setColor(base_r,base_g,base_b)
	
	if( setupvars.telemetryActive == true and setupvars.alarmUsedLipo[1] == 1 and setupvars.voltagePerCellAtStartup < (setupvars.alarmUsedLipo[2]/100)) then
		lcd.setColor(red_r,red_g,red_b)
		lcd.drawText(panel_central_X + (panel_central_Width - lcd.getTextWidth(FONT_MINI,setupvars.trans.usedBattery1))*0.5,panel_central_Y+batterySymbolY+10,setupvars.trans.usedBattery1,FONT_MINI)
		lcd.drawText(panel_central_X + (panel_central_Width - lcd.getTextWidth(FONT_MINI,setupvars.trans.usedBattery2))*0.5,panel_central_Y+batterySymbolY+22,setupvars.trans.usedBattery2,FONT_MINI)
		lcd.drawText(panel_central_X + (panel_central_Width - lcd.getTextWidth(FONT_MINI,setupvars.trans.usedBattery3))*0.5,panel_central_Y+batterySymbolY+34,setupvars.trans.usedBattery3,FONT_MINI)
		lcd.drawText(panel_central_X + (panel_central_Width - lcd.getTextWidth(FONT_MINI,setupvars.trans.usedBattery4))*0.5,panel_central_Y+batterySymbolY+46,setupvars.trans.usedBattery4,FONT_MINI)
		lcd.setColor(base_r,base_g,base_b)
	end

	local lipoCapacityString = string.format("%i",setupvars.lipo[2])
    local lipoCellCountString = string.format("%iS",setupvars.lipo[1])
	
	lcd.drawText(panel_central_X + (panel_central_Width - lcd.getTextWidth(FONT_NORMAL,lipoCapacityString))*0.5,panel_central_Y+batterySymbolHeight-15,lipoCapacityString,FONT_NORMAL)
	lcd.drawText(panel_central_X + (panel_central_Width - lcd.getTextWidth(FONT_MINI,"mAh"))*0.5,panel_central_Y+batterySymbolHeight+2,"mAh",FONT_MINI)
	lcd.drawText(panel_central_X + (panel_central_Width - lcd.getTextWidth(FONT_NORMAL,lipoCellCountString))*0.5,panel_central_Y+batterySymbolHeight+17,lipoCellCountString,FONT_NORMAL)

	collectgarbage()

end
--------------------------------------------------------------------------------------------

local isAlarmCapacityOneActive = false
local isAlarmCapacityTwoActive = false
local isAlarmCapacityThreeActive = false
local isAlarmCapacityFourActive = false
local isAlarmCapacityFiveActive = false
local isAlarmCapacitySixActive = false

local function resetActiveCapacityAlarms()
	print( "resetActiveCapacityAlarms" )
	isAlarmCapacityOneActive = false
	isAlarmCapacityTwoActive = false
	isAlarmCapacityThreeActive = false
	isAlarmCapacityFourActive = false
	isAlarmCapacityFiveActive = false
	isAlarmCapacitySixActive = false
end

--------------------------------------------------------------------------------------------
-- Audible alarm function
--------------------------------------------------------------------------------------------
local function playVoiceAlarms()

	if (setupvars.telemetryActive == true and isAlarmCapacityOneActive == false and setupvars.batteryPercentageRounded <= setupvars.alarmCapacityLevel[1] and setupvars.batteryPercentageRounded > setupvars.alarmCapacityLevel[2] and setupvars.effectivePercentageAtStartUp > setupvars.alarmCapacityLevel[1]) then
		system.playNumber(setupvars.batteryPercentageRounded, 0, "%", setupvars.trans.capacityUnit)
		system.vibration(true,4)
		isAlarmCapacityOneActive=true
		print( setupvars.batteryPercentageRounded, " isAlarmCapacityOneActive", isAlarmCapacityOneActive )   
	elseif (setupvars.telemetryActive == true and isAlarmCapacityTwoActive == false and setupvars.batteryPercentageRounded <= setupvars.alarmCapacityLevel[2] and setupvars.batteryPercentageRounded > setupvars.alarmCapacityLevel[3] and setupvars.effectivePercentageAtStartUp > setupvars.alarmCapacityLevel[2]) then
		system.playNumber(setupvars.batteryPercentageRounded, 0, "%", setupvars.trans.capacityUnit)
		system.vibration(true,4)
		isAlarmCapacityTwoActive=true   
		print( setupvars.batteryPercentageRounded, " isAlarmCapacityTwoActive", isAlarmCapacityTwoActive )   
	elseif (setupvars.telemetryActive == true and isAlarmCapacityThreeActive == false and setupvars.batteryPercentageRounded <= setupvars.alarmCapacityLevel[3] and setupvars.batteryPercentageRounded > setupvars.alarmCapacityLevel[4] and setupvars.effectivePercentageAtStartUp > setupvars.alarmCapacityLevel[3]) then
		system.playNumber(setupvars.batteryPercentageRounded, 0, "%", setupvars.trans.capacityUnit)
		system.vibration(true,4)
		isAlarmCapacityThreeActive=true   
		print( setupvars.batteryPercentageRounded, " isAlarmCapacityThreeActive", isAlarmCapacityThreeActive )   
	elseif (setupvars.telemetryActive == true and isAlarmCapacityFourActive == false and setupvars.batteryPercentageRounded <= setupvars.alarmCapacityLevel[4] and setupvars.batteryPercentageRounded > setupvars.alarmCapacityLevel[5] and setupvars.effectivePercentageAtStartUp > setupvars.alarmCapacityLevel[4]) then
		system.playNumber(setupvars.batteryPercentageRounded, 0, "%", setupvars.trans.capacityUnit)
		system.vibration(true,4)
		isAlarmCapacityFourActive=true   
		print( setupvars.batteryPercentageRounded, " isAlarmCapacityFourActive", isAlarmCapacityFourActive )   
	elseif (setupvars.telemetryActive == true and isAlarmCapacityFiveActive == false and setupvars.batteryPercentageRounded <= setupvars.alarmCapacityLevel[5] and setupvars.batteryPercentageRounded > setupvars.alarmCapacityLevel[6] and setupvars.effectivePercentageAtStartUp > setupvars.alarmCapacityLevel[5]) then
		system.playNumber(setupvars.batteryPercentageRounded, 0, "%", setupvars.trans.capacityUnit)
		system.vibration(true,4)
		isAlarmCapacityFiveActive=true   
		print( setupvars.batteryPercentageRounded, " isAlarmCapacityFiveActive", isAlarmCapacityFiveActive )   
	elseif (setupvars.telemetryActive == true and isAlarmCapacitySixActive == false and isAlarmCapacityFiveActive == true and setupvars.batteryPercentageRounded <= setupvars.alarmCapacityLevel[6]) then
		system.playNumber(setupvars.batteryPercentageRounded, 0, "%", setupvars.trans.capacityUnit)
		system.vibration(true,4)
		isAlarmCapacitySixActive=true   
		print( setupvars.batteryPercentageRounded, " isAlarmCapacitySixActive", isAlarmCapacitySixActive )  
	end

	collectgarbage()
	
end
--------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------
-- Function resets telemetry min/max values
--------------------------------------------------------------------------------------------
local function resetTelemetryValues()
	setupvars.minVoltagePerCell = 99.9
	setupvars.maxVoltagePerCell = -1.0
	setupvars.rx_1_Q_min = 0
	setupvars.rx_1_RSSI_A1_min = 1000
	setupvars.rx_1_RSSI_A2_min = 1000
	setupvars.rx_1_Voltage_min = 99.9
	setupvars.rx_1_Voltage_max = -1.0
	setupvars.escCurrentMax = -1.0
	setupvars.powerMax = -1
	setupvars.escTempMax = -1
	setupvars.escThrottleMax = -1
	setupvars.vibrationsMax = -1
	setupvars.hightMax = -1
	setupvars.rpm = 0
	setupvars.rpmMax = -1
	setupvars.elevatorRateMin = 1e6
	setupvars.elevatorRateMax = -1e6
	setupvars.aileronRateMin = 1e6
	setupvars.aileronRateMax = -1e6
	setupvars.rudderRateMin = 1e6
	setupvars.rudderRateMax = -1e6
	setupvars.hasRxBeenPoweredOn = false
	setupvars.batteryPercentageRounded = 0
end
--------------------------------------------------------------------------------------------

local function initSetupVars()
	print("initSetupVars()")
	setupvars.telemetryActive = false

	setupvars.alarmCapacityLevelOne = 80
	setupvars.alarmCapacityLevelTwo = 60
	setupvars.alarmCapacityLevelThree = 40
	setupvars.alarmCapacityLevelFour = 20
	setupvars.alarmCapacityLevelFive = 5
	setupvars.alarmCapacityLevelSix = 0

	setupvars.escCurrent = 0.0
	setupvars.escTemp = 0.0
	setupvars.escThrottle = 0
	setupvars.vibrations = 0
	setupvars.hight = 0
	setupvars.rpm = 0
	setupvars.elevatorRate = 0
	setupvars.aileronRate = 0
	setupvars.rudderRate = 0

	resetTelemetryValues()

	setupvars.voltagePerCellAtStartup = 0.0
	setupvars.batteryCapacityUsedTotal = 0
	setupvars.voltageSensorValue = 0.0
	setupvars.rx_1_RSSI_A1 = 0
	setupvars.rx_1_RSSI_A1_min = 0
	if( debugOn ) then
		setupvars.rx_1_RSSI_A2 = 35
	else
		setupvars.rx_1_RSSI_A2 = 0
	end
	setupvars.rx_1_RSSI_A2_min = 0
	setupvars.rx_1_Q = 0
	setupvars.rx_1_Q_min = 0
	setupvars.rx_1_Voltage_Averaged = 0.0
	setupvars.voltagePerCellAveraged = 0.0
	setupvars.effectivePercentageAtStartUp = 0
	if( setupvars.timer[1] == 2) then
		setupvars.timeCounter = setupvars.timer[2]
	else
		setupvars.timeCounter = 0
	end
	setupvars.powerValue = 0
end

local function resetActiveTimerAlarms()
	print( "resetActiveTimerAlarms", #isAlarmActive )
    for i = 1, #timerVTable do 
    	isAlarmActive[i] = false
    end
end

--------------------------------------------------------------------------------------------
-- Converts voltage reading to a percentage (code from Tero @ RC-Thoughts.com)
--------------------------------------------------------------------------------------------
local percentList={{3,0},{3.093,1},{3.196,2},{3.301,3},{3.401,4},{3.477,5},{3.544,6},{3.601,7},{3.637,8},{3.664,9},{3.679,10},{3.683,11},{3.689,12},{3.692,13},{3.705,14},{3.71,15},{3.713,16},{3.715,17},{3.72,18},{3.731,19},{3.735,20},{3.744,21},{3.753,22},{3.756,23},{3.758,24},{3.762,25},{3.767,26},{3.774,27},{3.78,28},{3.783,29},{3.786,30},{3.789,31},{3.794,32},{3.797,33},{3.8,34},{3.802,35},{3.805,36},{3.808,37},{3.811,38},{3.815,39},{3.818,40},{3.822,41},{3.825,42},{3.829,43},{3.833,44},{3.836,45},{3.84,46},{3.843,47},{3.847,48},{3.85,49},{3.854,50},{3.857,51},{3.86,52},{3.863,53},{3.866,54},{3.87,55},{3.874,56},{3.879,57},{3.888,58},{3.893,59},{3.897,60},{3.902,61},{3.906,62},{3.911,63},{3.918,64},{3.923,65},{3.928,66},{3.939,67},{3.943,68},{3.949,69},{3.955,70},{3.961,71},{3.968,72},{3.974,73},{3.981,74},{3.987,75},{3.994,76},{4.001,77},{4.007,78},{4.014,79},{4.021,80},{4.029,81},{4.036,82},{4.044,83},{4.052,84},{4.062,85},{4.074,86},{4.085,87},{4.095,88},{4.105,89},{4.111,90},{4.116,91},{4.12,92},{4.125,93},{4.129,94},{4.135,95},{4.145,96},{4.176,97},{4.179,98},{4.193,99},{4.2,100}}
local function voltageAsAPercentage(value)
	
    local result=0
    if(value > 4.2 or value < 3.00)then
        if(value > 4.2)then
            result=100
        end
        if(value < 3.00)then
            result=0
        end
    else
        for index,entry in ipairs(percentList) do
            if(entry[1] >= value)then
                result=entry[2]
                break
            end
        end
    end
	
    collectgarbage()
	
    return result

end
--------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------
-- Function that tracks Tx time counter, and saves the time at which the Rx is detected.
-- This allows the app to apply the user defined time delay, as well reset the min/max
-- values when a new lipo is plugged in. (Called by the Jeti loop function).
--------------------------------------------------------------------------------------------
local function trackTimeAndResetValues()
	local currentTime = 0
	local voltageSensorTable
	local sensorsRx

	currentTime = system.getTimeCounter() * 1E-3
	sensorsRx = system.getTxTelemetry()
	if( debugOn ) then
		sensorsRx.rx1Percent = 80
	end

	if(sensorsRx.rx1Percent > 1) then
		isRxPoweredOn = true
    else
		isRxPoweredOn = false
    end

	if (setupvars.hasRxBeenPoweredOn == false and isRxPoweredOn == true) then
		timeAtPowerOn = currentTime
		if( setupvars.timer[1] == 2) then
			setupvars.timeCounter = setupvars.timer[2]
		else
			setupvars.timeCounter = 0
		end
	end
	
	
	if(isRxPoweredOn == true) then
		setupvars.hasRxBeenPoweredOn = true
    end
			
	if (setupvars.hasRxBeenPoweredOn == true and isRxPoweredOn == false) then
		resetRx = true
	end
		
	if (resetRx == true)  then
		if (isRxPoweredOn == true) then
			resetRx = false
			hasVoltageStartupBeenRead = false
			timeAtPowerOn = currentTime
			if( setupvars.timer[1] == 2) then
				setupvars.timeCounter = setupvars.timer[2]
			else
				setupvars.timeCounter = 0
			end
			resetTelemetryValues()
			isAlarmUsedLipoDetectedActive = false
			--if( Screen ) then
			--	Screen.resetActiveAlarms()
			--end
			resetActiveCapacityAlarms()
			resetActiveTimerAlarms()
		end
	end
	
	if (isRxPoweredOn == false) then
		voltagePerCell = 0.0
		setupvars.voltagePerCellAtStartup = 0.0
		batteryCapacityPercentAtStartup = 0
		batteryCapacityUsedAtStartup = 0

		setupvars.voltagePerCellAveraged = 0.0
		setupvars.rx_1_Voltage_Averaged = 0.0
		setupvars.escCurrent = 0.0
		setupvars.escTemp = 0
		setupvars.escThrottle = 0
		setupvars.vibrations = 0
		setupvars.hight = 0
		setupvars.rpm = 0.0
	end

	if (isRxPoweredOn == true) and (currentTime > (timeAtPowerOn + setupvars.timeDelay)) and (setupvars.telemetryActive == false) then
		setupvars.telemetryActive = true
		print("telemetryActive")
	elseif (isRxPoweredOn == false) then --or (currentTime < (timeAtPowerOn + setupvars.timeDelay)) then
		setupvars.telemetryActive = false
    end

	--local effectiveLipoCapacity = 0.8 * setupvars.lipo[2]
	local effectiveLipoCapacity = setupvars.lipo[2]

	if (setupvars.telemetryActive == true) and (hasVoltageStartupBeenRead == false) then
		if(setupvars.voltageSensor[1] == 999) then
			if (setupvars.voltageSensor[2] == 1) then
				voltageSensorValue = sensorsRx.rx1Voltage
			elseif (setupvars.voltageSensor[2] == 2) then
				voltageSensorValue = sensorsRx.rx2Voltage
			elseif (setupvars.voltageSensor[2] == 3) then
				voltageSensorValue = sensorsRx.rxBVoltage
			end
		else
			if( debugOn ) then
				setupvars.voltageSensorValue = debugVoltage
				print( "set debug Voltage")
			else
				voltageSensorTable = system.getSensorByID(setupvars.voltageSensor[1],setupvars.voltageSensor[2])
				if (voltageSensorTable) then
					setupvars.voltageSensorValue = voltageSensorTable.value
				end
			end
		end
		
		if (setupvars.voltageSensor[1] ~= 0) then
			setupvars.voltagePerCellAtStartup = setupvars.voltageSensorValue / setupvars.lipo[1]
			batteryCapacityPercentAtStartup = voltageAsAPercentage(setupvars.voltagePerCellAtStartup)
			batteryCapacityUsedAtStartup = setupvars.lipo[2] - (setupvars.lipo[2] * (batteryCapacityPercentAtStartup/100))
			setupvars.effectivePercentageAtStartUp = (1-(batteryCapacityUsedAtStartup / effectiveLipoCapacity))*100
			print( setupvars.voltagePerCellAtStartup, batteryCapacityPercentAtStartup, batteryCapacityUsedAtStartup, setupvars.effectivePercentageAtStartUp)
		end
		hasVoltageStartupBeenRead = true
	end

	local effectivePercentageAtStartUpRounded = math.floor(setupvars.effectivePercentageAtStartUp + 0.5)

	if (setupvars.telemetryActive == true and isAlarmUsedLipoDetectedActive == false and setupvars.alarmUsedLipo[3]~="" and setupvars.alarmUsedLipo[1] == 1 and setupvars.voltagePerCellAtStartup < (setupvars.alarmUsedLipo[2]/100)) then
		system.playFile(setupvars.alarmUsedLipo[3],AUDIO_QUEUE)
		system.playNumber(effectivePercentageAtStartUpRounded,0,"%")
		system.vibration(true,4)
		print("used Battery Alarm")
		isAlarmUsedLipoDetectedActive=true   
	end
	if (setupvars.alarmUsedLipo[1] == 0) then
		setupvars.effectivePercentageAtStartUp = 100
	end
	
	flightTimerActive = system.getInputsVal(setupvars.switchStartTimer)
	resetTimer = system.getInputsVal(setupvars.switchResetTimer)

	local delta = currentTime - lastTime
	lastTime = currentTime

	if (avgTime == 0) then 
		avgTime = delta
	else 
		avgTime = avgTime * 0.95 + delta * 0.05
	end
	
	if (flightTimerActive == 1) then
		if( setupvars.timer[1] == 2) then
			setupvars.timeCounter = setupvars.timeCounter - delta
		else
			setupvars.timeCounter = setupvars.timeCounter + delta
		end
		--print( setupvars.timeCounter )
	else
		setupvars.timeCounter = setupvars.timeCounter
	end

	local timeDiff = setupvars.timeCounter
	if( setupvars.timer[1] == 2) then
		timeDiff = setupvars.timer[2] - setupvars.timeCounter
	end
    if (timeDiff >= setupvars.flightCounter[1]) and countSet == 0 and flightTimerActive == 1 then
        setupvars.flightCounter[2] = setupvars.flightCounter[2] + 1
    	print( string.format("Flightcounter: %d", setupvars.flightCounter[2]) )
        system.pSave("flightCounter", setupvars.flightCounter)
        countSet = 1
    end

	if (resetTimer == 1 and flightTimerActive ~= 1) then
		if( setupvars.timer[1] == 2) then
			setupvars.timeCounter = setupvars.timer[2]
		else
			setupvars.timeCounter = 0
		end
	    countSet = 0
		--if( Screen ) then
		--	Screen.resetActiveAlarms()
		--end
		resetActiveCapacityAlarms()
		resetActiveTimerAlarms()
	end	

	collectgarbage()
end
------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------
-- Function that averages the voltage reading (if desired by the user).
--------------------------------------------------------------------------------------------
local function averagingFunctionVoltage(value)
    local sum_values = 0.0
	local result = 0.0
	result = value
	if (#value_list_cell_voltages == (averagingWindowCellVoltage)) then
		table.remove(value_list_cell_voltages,1)
		collectgarbage()
	end    
	value_list_cell_voltages[#value_list_cell_voltages + 1] = value
	for i,entry in pairs(value_list_cell_voltages) do
		sum_values = sum_values + entry
	end
	result = sum_values / #value_list_cell_voltages
	collectgarbage()
	return result
end    
--------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------
-- Function that averages the Rx voltage reading (if desired by the user).
--------------------------------------------------------------------------------------------
local function averagingFunctionRxVoltage(value)
	local sum_values = 0.0
	local result = 0.0
	result = value
	if (#value_list_rx_1_voltages == (averagingWindowCellVoltage)) then
		table.remove(value_list_rx_1_voltages,1)
		collectgarbage()
	end    
	value_list_rx_1_voltages[#value_list_rx_1_voltages + 1] = value
	for i,entry in pairs(value_list_rx_1_voltages) do
		sum_values = sum_values + entry
	end
	result = sum_values / #value_list_rx_1_voltages
	collectgarbage()
	return result
end    
--------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------
-- Main function that reads the voltage reading (called by the Jeti loop function).
--------------------------------------------------------------------------------------------
local voltageSensorTable = {}
local currentSensorTable = {}
local capacitySensorTable = {}
local temperatureSensorTable = {}
local throttleSensorTable = {}
local vibrationsSensorTable = {}
local maltiSensorTable = {}
local rpmSensorTable = {}
local elevatorSensorTable = {}
local aileronSensorTable = {}
local rudderSensorTable = {}

local sensorsRx = {}
local rx_1_Voltage = 0.0
local rpmArray = {}

local function updateTelemetrySensors()

	--print( string.format("updateTelemetrySensors Memory used: %i KB", (collectgarbage("count") * 1024)) )
	
	if(setupvars.voltageSensor[1] == 999) then
		--print("getTxTelemetry")
		sensorsRx = system.getTxTelemetry()
		
		if (setupvars.voltageSensor[2] == 1) then
			setupvars.voltageSensorValue = sensorsRx.rx1Voltage
		elseif (setupvars.voltageSensor[2] == 2) then
			setupvars.voltageSensorValue = sensorsRx.rx2Voltage
		elseif (setupvars.voltageSensor[2] == 3) then
			setupvars.voltageSensorValue = sensorsRx.rxBVoltage
		end
	else
		voltageSensorTable = system.getSensorByID(setupvars.voltageSensor[1],setupvars.voltageSensor[2])
		if (voltageSensorTable) then
			if( debugOn ) then
				setupvars.voltageSensorValue = debugVoltage
			else
				setupvars.voltageSensorValue = voltageSensorTable.value
			end
		end
	end

	currentSensorTable = system.getSensorByID(setupvars.currentSensor[1],setupvars.currentSensor[2])
	if (currentSensorTable) then
		if( debugOn ) then
			setupvars.escCurrent = 22.0
		else
			setupvars.escCurrent = currentSensorTable.value
		end
	end
	
	if (currentSensorTable and voltageSensorTable) then
		setupvars.powerValue = math.floor(setupvars.voltageSensorValue * setupvars.escCurrent)
		--print( string.format("Power: %i (%fV*%fA)", setupvars.powerValue, setupvars.voltageSensorValue, setupvars.escCurrent) )
	end

	capacitySensorTable = system.getSensorByID(setupvars.capacitySensor[1],setupvars.capacitySensor[2])
	if (capacitySensorTable) then
		if( debugOn and debugCapacity and setupvars.telemetryActive and flightTimerActive == 1 ) then
			if( batteryCapacityUsed < setupvars.lipo[2] ) then
				batteryCapacityUsed = batteryCapacityUsed + 1
				--print( string.format("batteryCapacityUsed: %d (%d)", batteryCapacityUsed, setupvars.lipo[2]) )
			end
		else
			batteryCapacityUsed = capacitySensorTable.value
		end
	end
	
	temperatureSensorTable = system.getSensorByID(setupvars.temperatureSensor[1],setupvars.temperatureSensor[2])
	if (temperatureSensorTable) then
		if( debugOn ) then
			setupvars.escTemp = 22.0
		else
			setupvars.escTemp = temperatureSensorTable.value
		end
	end
	
	throttleSensorTable = system.getSensorByID(setupvars.throttleSensor[1],setupvars.throttleSensor[2])
	if (throttleSensorTable) then
		if( debugOn ) then
			setupvars.escThrottle = 22
		else
			setupvars.escThrottle = throttleSensorTable.value
		end
	end
	
	vibrationsSensorTable = system.getSensorByID(setupvars.vibrationsSensor[1],setupvars.vibrationsSensor[2])
	if (vibrationsSensorTable) then
		if( debugOn ) then
			setupvars.vibrations = 22
		else
			setupvars.vibrations = vibrationsSensorTable.value
		end
	end
	
	maltiSensorTable = system.getSensorByID(setupvars.maltiSensor[1],setupvars.maltiSensor[2])
	if (maltiSensorTable) then
		if( debugOn ) then
			setupvars.hight = 22
		else
			setupvars.hight = maltiSensorTable.value
		end
	end
	
	rpmSensorTable = system.getSensorByID(setupvars.rpmSensor[1],setupvars.rpmSensor[2])
	if (rpmSensorTable) then
		if( setupvars.rpmSmoothing > 1 ) then
			if( #rpmArray == setupvars.rpmSmoothing ) then
				print("array full: ", #rpmArray)
				for i=1, #rpmArray-1, 1 do
					print("array index: ", i)
					rpmArray[i] = rpmArray[i+1]
				end
				table.remove(rpmArray, setupvars.rpmSmoothing)
			end
			if( debugOn ) then
				table.insert(rpmArray, math.random(2000,3000))
			else
				table.insert(rpmArray, rpmSensorTable.value)
			end
			local rpmMean = 0
			for i=1, #rpmArray, 1 do
				rpmMean = rpmMean + rpmArray[i]
			end
			rpmMean = rpmMean / #rpmArray
			setupvars.rpm = rpmMean
		else
			if( debugOn ) then
				setupvars.rpm = math.random(2000,3000)
			else
				setupvars.rpm = rpmSensorTable.value
			end
		end
		if( setupvars.rpmDivisor > 10 ) then
			setupvars.rpm = setupvars.rpm / (setupvars.rpmDivisor / 10)
		end
	end
	
	elevatorSensorTable = system.getSensorByID(setupvars.elevatorSensor[1],setupvars.elevatorSensor[2])
	if (elevatorSensorTable) then
		if( debugOn ) then
			setupvars.elevatorRate = 22
		else
			setupvars.elevatorRate = elevatorSensorTable.value
		end
	end
	
	aileronSensorTable = system.getSensorByID(setupvars.aileronSensor[1],setupvars.aileronSensor[2])
	if (aileronSensorTable) then
		if( debugOn ) then
			setupvars.aileronRate = 22
		else
			setupvars.aileronRate = aileronSensorTable.value
		end
	end
	
	rudderSensorTable = system.getSensorByID(setupvars.rudderSensor[1],setupvars.rudderSensor[2])
	if (rudderSensorTable) then
		if( debugOn ) then
			setupvars.rudderRate = 22
		else
			setupvars.rudderRate = rudderSensorTable.value
		end
	end
	
	if (setupvars.voltageSensorValue) then
		voltagePerCell = setupvars.voltageSensorValue / setupvars.lipo[1]
		setupvars.voltagePerCellAveraged = averagingFunctionVoltage(voltagePerCell)
	end
	
	if (setupvars.telemetryActive and setupvars.voltagePerCellAveraged < setupvars.minVoltagePerCell and voltagePerCell > 0.1) then
		setupvars.minVoltagePerCell = setupvars.voltagePerCellAveraged
	end
	
	if (setupvars.telemetryActive and setupvars.voltagePerCellAveraged > setupvars.maxVoltagePerCell and voltagePerCell > 0.1) then
		setupvars.maxVoltagePerCell = setupvars.voltagePerCellAveraged
	end
	
	
	if (setupvars.alarmUsedLipo[1] == 1 and setupvars.voltagePerCellAtStartup < (setupvars.alarmUsedLipo[2]/100) and setupvars.voltagePerCellAtStartup > 0) then
		setupvars.batteryCapacityUsedTotal = batteryCapacityUsedAtStartup + batteryCapacityUsed
	else
		setupvars.batteryCapacityUsedTotal = batteryCapacityUsed
	end

	--local effectiveLipoCapacity = 0.8 * setupvars.lipo[2]
	local effectiveLipoCapacity = setupvars.lipo[2]

	if (capacitySensorTable) then
		if (batteryCapacityUsed and effectiveLipoCapacity) then
			if (setupvars.batteryCapacityUsedTotal > effectiveLipoCapacity) then
				batteryPercentage = 0
			else
				batteryPercentage = (1 - (setupvars.batteryCapacityUsedTotal / effectiveLipoCapacity))*100
			end
		end

		setupvars.batteryPercentageRounded = math.floor(batteryPercentage + 0.5)
		if (setupvars.batteryPercentageRounded >= 0 and setupvars.batteryPercentageRounded <= 100) then
			setupvars.batteryPercentageRounded = setupvars.batteryPercentageRounded
		else
			setupvars.batteryPercentageRounded = 0
		end
	end	

	if (setupvars.telemetryActive and setupvars.escCurrent > setupvars.escCurrentMax) then
		setupvars.escCurrentMax = setupvars.escCurrent
	end
		
	if (setupvars.telemetryActive and setupvars.escTemp > setupvars.escTempMax) then
		setupvars.escTempMax = setupvars.escTemp
	end
	
	if (setupvars.telemetryActive and setupvars.escThrottle > setupvars.escThrottleMax) then
		setupvars.escThrottleMax = setupvars.escThrottle
	end
	
	if (setupvars.telemetryActive and setupvars.vibrations > setupvars.vibrationsMax) then
		setupvars.vibrationsMax = setupvars.vibrations
	end
	
	if (setupvars.telemetryActive and setupvars.hight > setupvars.hightMax) then
		setupvars.hightMax = setupvars.hight
	end
	
	if (setupvars.telemetryActive and setupvars.rpm > setupvars.rpmMax) then
		setupvars.rpmMax = setupvars.rpm
	end
	
	if (setupvars.telemetryActive and setupvars.powerValue > setupvars.powerMax) then
		setupvars.powerMax = setupvars.powerValue
	end

	if (setupvars.telemetryActive and setupvars.elevatorRate < setupvars.elevatorRateMin) then
		setupvars.elevatorRateMin = setupvars.elevatorRate
	elseif (setupvars.telemetryActive and setupvars.elevatorRate > setupvars.elevatorRateMax) then
		setupvars.elevatorRateMax = setupvars.elevatorRate
	end
	
	if (setupvars.telemetryActive and setupvars.aileronRate < setupvars.aileronRateMin) then
		setupvars.aileronRateMin = setupvars.aileronRate
	elseif (setupvars.telemetryActive and setupvars.aileronRate > setupvars.aileronRateMax) then
		setupvars.aileronRateMax = setupvars.aileronRate
	end

	if (setupvars.telemetryActive and setupvars.rudderRate < setupvars.rudderRateMin) then
		setupvars.rudderRateMin = setupvars.rudderRate
	elseif (setupvars.telemetryActive and setupvars.rudderRate > setupvars.rudderRateMax) then
		setupvars.rudderRateMax = setupvars.rudderRate
	end

	collectgarbage()
end
--------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------
-- Function to update Rx telemetry values
--------------------------------------------------------------------------------------------
local rx_1_RSSI_A1_delta = 1
local rx_1_RSSI_A2_delta = -1
local rx_1_Q_delta = 1
local sensorsRx = {}

local function updateRxValues()

	sensorsRx = system.getTxTelemetry()

	if( debugOn ) then
		if( setupvars.rx_1_Q == 0) then
			rx_1_Q_delta = 1
			setupvars.rx_1_Q = 1
		elseif( setupvars.rx_1_Q == 100 ) then
			rx_1_Q_delta = -1
			setupvars.rx_1_Q = 99
		else
			setupvars.rx_1_Q = setupvars.rx_1_Q + rx_1_Q_delta
		end
		rx_1_Voltage = 8.0
		if( setupvars.rx_1_RSSI_A1 == 0 ) then
			rx_1_RSSI_A1_delta = 1
			setupvars.rx_1_RSSI_A1 = 1
		elseif( setupvars.rx_1_RSSI_A1 == 35 ) then
			rx_1_RSSI_A1_delta = -1
			setupvars.rx_1_RSSI_A1 = 34
		else
			setupvars.rx_1_RSSI_A1 = setupvars.rx_1_RSSI_A1 + rx_1_RSSI_A1_delta
		end
		if( setupvars.rx_1_RSSI_A2 == 0 ) then
			rx_1_RSSI_A2_delta = 1
			setupvars.rx_1_RSSI_A2 = 1
		elseif( setupvars.rx_1_RSSI_A2 == 35 ) then
			rx_1_RSSI_A2_delta = -1
			setupvars.rx_1_RSSI_A2 = 34
		else
			setupvars.rx_1_RSSI_A2 = setupvars.rx_1_RSSI_A2 + rx_1_RSSI_A2_delta
		end
	elseif (sensorsRx) then
		rx_1_Voltage = sensorsRx.rx1Voltage
		setupvars.rx_1_Q = sensorsRx.rx1Percent
		setupvars.rx_1_RSSI_A1 = sensorsRx.RSSI[1]
		setupvars.rx_1_RSSI_A2 = sensorsRx.RSSI[2]
	end

	if (setupvars.telemetryActive == false and isRxPoweredOn == true) then
		setupvars.rx_1_Voltage_Averaged = rx_1_Voltage
	elseif (setupvars.telemetryActive == true) then
		setupvars.rx_1_Voltage_Averaged = averagingFunctionRxVoltage(rx_1_Voltage)
	end

	if (setupvars.telemetryActive and setupvars.rx_1_Q < setupvars.rx_1_Q_min) then
		setupvars.rx_1_Q_min = setupvars.rx_1_Q
	end
	
	if (setupvars.telemetryActive and setupvars.rx_1_Voltage_Averaged < setupvars.rx_1_Voltage_min) then
		setupvars.rx_1_Voltage_min = setupvars.rx_1_Voltage_Averaged
	end
	
	if (setupvars.telemetryActive and setupvars.rx_1_Voltage_Averaged > setupvars.rx_1_Voltage_max) then
		setupvars.rx_1_Voltage_max = setupvars.rx_1_Voltage_Averaged
	end
	
	if (setupvars.telemetryActive and setupvars.rx_1_RSSI_A1 < setupvars.rx_1_RSSI_A1_min) then
		setupvars.rx_1_RSSI_A1_min = setupvars.rx_1_RSSI_A1
	end
	
	if (setupvars.telemetryActive and setupvars.rx_1_RSSI_A2 < setupvars.rx_1_RSSI_A2_min) then
		setupvars.rx_1_RSSI_A2_min = setupvars.rx_1_RSSI_A2
	end	

	collectgarbage()
end
--------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------
-- Audible alarm function
--------------------------------------------------------------------------------------------
local function playTimerAlarms()

	if( flightTimerActive == 1 and setupvars.timer[1] == 2 ) then
		--print( "flightTimerActive: ", flightTimerActive )
		for k, v in ipairs(timerVTable) do
			--print( k, isAlarmActive[k], math.abs(v["Time"]), setupvars.timeCounter )
			if( isAlarmActive[k] == false and setupvars.timeCounter <= math.abs(v["Time"]) ) then
				if v["Type"] == 1 then
					print( v["Time"], "play beep", v["Freq"], v["Cnt"] - 1, v["Length"] )
					system.playBeep(v["Cnt"] - 1, v["Freq"], v["Length"])
					system.vibration(true,4)
				elseif v["Type"] == 2 then
					print( v["Time"], "play sound", v["File"] )
					system.playFile(v["File"], AUDIO_QUEUE)
				end
				isAlarmActive[k] = true
			end
		end
	end

	collectgarbage()
	
end

--------------------------------------------------------------------------------------------

-- remove unused module
local function unrequire(module)
	package.loaded[module] = nil
	_G[module] = nil
end

-- switch to setup context
local function setupForm(formID)

	collectgarbage()

	Form = require "HeliTelm/Form"

	-- return modified data from user
	setupvars = Form.initForm(setupvars)

	collectgarbage()
end

-- switch to telemetry context
local function closeForm()
	print ("-Lua Form uninitialized-")

	Form = nil
	unrequire("HeliTelm/Form")
	
	collectgarbage()
	
	if( setupvars.timer[1] == 2) then
		setupvars.timeCounter = setupvars.timer[2]
	else
		setupvars.timeCounter = 0
	end

	collectgarbage()
end


-- caclulate power 
local function calculatePower(index)
	return setupvars.powerValue, 0
end

-- Telemetry Window
local function Window()

	printTelemetryWindow()

	collectgarbage()	
end

-- main loop
--local debugLocalTime = 0
local function loop()

	trackTimeAndResetValues()
	updateRxValues()
	playVoiceAlarms()
	playTimerAlarms()
	--if (setupvars.telemetryActive == true) then
	updateTelemetrySensors()
	--end
	
	--print( string.format("loop Memory used: %i KB", (collectgarbage("count") * 1024)) )
	collectgarbage()
end

function dump(o)
	local s = ""
	if type(o) == 'table' then
		s = '{ '
		for k,v in pairs(o) do
			if type(k) ~= 'number' then k = '"'..k..'"' end
				s = s .. '['..k..'] = ' .. dump(v) .. ','
		end
		return s .. '} '
	else
		return tostring(o)
	end
end

function initTimerV()
	print( "initTimerV" )
    local file = io.readall("Config/TimerV.jsn")
    if( file ~= nil ) then
	    timerVTable = json.decode(file)
	    for i = 1, #timerVTable do 
	    	isAlarmActive[#isAlarmActive + 1] = false
	    end
	    print( #timerVTable .. " entries added to timerVTable" )
	    --print( #isAlarmActive .. " entries added to isAlarmActive" )
	else
		print( "no TimerV.jsn found" )
    end
end

--------------------------------------------------------------------------------------------
-- Jeti lua initialization
--------------------------------------------------------------------------------------------
local function init(code)
	print ("-Lua application Heli Telem. Display initialized-")

	setupvars.voltageSensor     = system.pLoad("voltageSensor",{0,0})
	setupvars.currentSensor     = system.pLoad("currentSensor",{0,0})
	setupvars.capacitySensor    = system.pLoad("capacitySensor",{0,0})
	setupvars.temperatureSensor = system.pLoad("temperatureSensor",{0,0})
	setupvars.throttleSensor    = system.pLoad("throttleSensor",{0,0})
	setupvars.rpmSensor         = system.pLoad("rpmSensor",{0,0})
	setupvars.vibrationsSensor  = system.pLoad("vibrationsSensor",{0,0})
	setupvars.maltiSensor       = system.pLoad("maltiSensor",{0,0})
	setupvars.elevatorSensor    = system.pLoad("elevatorSensor",{0,0})
	setupvars.aileronSensor     = system.pLoad("aileronSensor",{0,0})
	setupvars.rudderSensor      = system.pLoad("rudderSensor",{0,0})

	setupvars.rpmSmoothing      = system.pLoad("rpmSmoothing",0)
	setupvars.rpmDivisor        = system.pLoad("rpmDivisor",10)

	setupvars.lipo              = system.pLoad("lipo",{1,0})

	setupvars.timeDelay = system.pLoad("timeDelay",10)

	setupvars.alarmCapacityLevel = system.pLoad("alarmCapacityLevel",{80,60,40,20,5,0})
	
	setupvars.alarmUsedLipo = system.pLoad("alarmUsedLipo",{1,410,""})

	setupvars.switchStartTimer = system.pLoad("switchStartTimer")
	setupvars.switchResetTimer = system.pLoad("switchResetTimer")
	setupvars.timer = system.pLoad("timer",{2,450})

    setupvars.flightCounter = system.pLoad("flightCounter", {0,5})

    if( debugOn ) then
    	setupvars.lipo[1] = 6
    	setupvars.lipo[2] = 1800
    	setupvars.timeDelay = 4
		setupvars.voltageSensor     = {34186242,1} 
		setupvars.currentSensor     = {34186242,2} 
		setupvars.capacitySensor    = {34186242,4} 
		setupvars.temperatureSensor = {34186242,9} 
		setupvars.throttleSensor    = {34186242,8} 
		setupvars.rpmSensor         = {34186242,3}
		setupvars.rpmSmoothing      = 0
		setupvars.vibrationsSensor  = {34186242,8}
		setupvars.maltiSensor       = {34186242,8}
		setupvars.elevatorSensor    = {34186242,8}
		setupvars.aileronSensor     = {34186242,8}
		setupvars.rudderSensor      = {34186242,8}
	end

	initTimerV()

    initSetupVars()

	resetTelemetryValues()

	system.registerLogVariable("Power", "W", calculatePower )

	system.registerForm(1, MENU_APPS, _appName, setupForm, nil, nil, closeForm)

	local modelName = system.getProperty("Model")
	local windowTitle = _appName.." ".._version..".".._form_version.." - "..modelName
	system.registerTelemetry(1, windowTitle, 4, Window)
	
	print( string.format("init Memory used: %i KB", (collectgarbage("count") * 1024)) )

	collectgarbage()
end
--------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------
-- Application interface
--------------------------------------------------------------------------------------------
setLanguage()
_appName = "Telemetry Display"
Form = require "HeliTelm/Form"
_form_version = Form.version
unrequire( "HeliTelm/Form" )
return {init = init, loop = loop, author = "Michael Leopoldseder", version = _version, name = _appName}
--------------------------------------------------------------------------------------------