--[[------------------------------------------------------------------------------------------
	
	Heli Telem. Display - Form - Full Screen Telemetry Display for Helicopters
	
    By Michael Leopoldseder
	
	v2.00 - 2022-08-25 - split into more apps to keep it smal

	1 - 2022-08-25 - initial version
	2 - 2022-08-28 - pLoad/pSave optimizations
	3 - 
	4 - 2022-08-30 - 
	5 - 2022-09-07 - remove time end sound

--------------------------------------------------------------------------------------------]]

local _version = 5

local setupvars = {}
local sensorsAvailable = {}

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

--------------------------------------------------------------------------------------------
-- Functions to save new user input values
--------------------------------------------------------------------------------------------
local function voltageSensorChanged(value)
	setupvars.voltageSensor[1] = sensorsAvailable[value].id
	setupvars.voltageSensor[2] = sensorsAvailable[value].param
	system.pSave("voltageSensor",setupvars.voltageSensor)
end

local function currentSensorChanged(value)
	setupvars.currentSensor[1] = sensorsAvailable[value].id
	setupvars.currentSensor[2] = sensorsAvailable[value].param
	system.pSave("currentSensor",setupvars.currentSensor)
end

local function capacitySensorChanged(value)
	setupvars.capacitySensor[1] = sensorsAvailable[value].id
	setupvars.capacitySensor[2] = sensorsAvailable[value].param
	system.pSave("capacitySensor",setupvars.capacitySensor)
end

local function temperatureSensorChanged(value)
	setupvars.temperatureSensor[1] = sensorsAvailable[value].id
	setupvars.temperatureSensor[2] = sensorsAvailable[value].param
	system.pSave("temperatureSensor",setupvars.temperatureSensor)
end

local function throttleSensorChanged(value)
	setupvars.throttleSensor[1] = sensorsAvailable[value].id
	setupvars.throttleSensor[2] = sensorsAvailable[value].param
	system.pSave("throttleSensor",setupvars.throttleSensor)
end

local function rpmSensorChanged(value)
	setupvars.rpmSensor[1] = sensorsAvailable[value].id
	setupvars.rpmSensor[2] = sensorsAvailable[value].param
	system.pSave("rpmSensor",setupvars.rpmSensor)
end

local function vibrationsSensorChanged(value)
	setupvars.vibrationsSensor[1] = sensorsAvailable[value].id
	setupvars.vibrationsSensor[2] = sensorsAvailable[value].param
	system.pSave("vibrationsSensor",setupvars.vibrationsSensor)
end

local function maltiSensorChanged(value)
	setupvars.maltiSensor[1] = sensorsAvailable[value].id
	setupvars.maltiSensor[2] = sensorsAvailable[value].param
	system.pSave("maltiSensor",setupvars.maltiSensor)
end

local function elevatorSensorChanged(value)
	setupvars.elevatorSensor[1] = sensorsAvailable[value].id
	setupvars.elevatorSensor[2] = sensorsAvailable[value].param
	system.pSave("elevatorSensor",setupvars.elevatorSensor)
end

local function aileronSensorChanged(value)
	setupvars.aileronSensor[1] = sensorsAvailable[value].id
	setupvars.aileronSensor[2] = sensorsAvailable[value].param
	system.pSave("aileronSensor",setupvars.aileronSensor)
end

local function rudderSensorChanged(value)
	setupvars.rudderSensor[1] = sensorsAvailable[value].id
	setupvars.rudderSensor[2] = sensorsAvailable[value].param
	system.pSave("rudderSensor",setupvars.rudderSensor)
end

local function lipoCellCountChanged(value)
	setupvars.lipo[1] = value
	system.pSave("lipo",setupvars.lipo)
end

local function lipoCapacityChanged(value)
	setupvars.lipo[2] = value
	system.pSave("lipo",setupvars.lipo)
end

local function estimateUsedLipoBooleanChanged(value)
	if( not value ) then
		setupvars.alarmUsedLipo[1] = 1
	else
		setupvars.alarmUsedLipo[1] = 0
	end
	form.setValue(checkboxIndex1,not value)
	system.pSave("alarmUsedLipo",setupvars.alarmUsedLipo)
end

local function voltageThresholdUsedLipoChanged(value)
	setupvars.alarmUsedLipo[2] = value
	setupvars.alarmUsedLipo = system.pLoad("alarmUsedLipo",{0,410,""})
end

local function alarmUsedLipoDetectedFileChanged(value)
	setupvars.alarmUsedLipo[3] = value
	setupvars.alarmUsedLipo = system.pLoad("alarmUsedLipo",{0,410,""})
end

local function timeDelayChanged(value)
	setupvars.timeDelay = value
	system.pSave("timeDelay",value)
end

local function switchStartTimerChanged(value)
	setupvars.switchStartTimer = value
	system.pSave("switchStartTimer",value)
end

local function switchUpDownTimerChanged(value)
	setupvars.timer[1] = value
	system.pSave("timer",setupvars.timer)
end

local function timerValueChanged(value)
	setupvars.timer[2] = value
	system.pSave("timer",setupvars.timer)
end

local function switchResetTimerChanged(value)
	setupvars.switchResetTimer = value
	system.pSave("switchResetTimer",value)
end

local function alarmCapacityLevelOneChanged(value)
	setupvars.alarmCapacityLevel[1] = value
	system.pSave("alarmCapacityLevel",setupvars.alarmCapacityLevel)
end

local function alarmCapacityLevelTwoChanged(value)
	setupvars.alarmCapacityLevel[2] = value
	system.pSave("alarmCapacityLevel",setupvars.alarmCapacityLevel)
end

local function alarmCapacityLevelThreeChanged(value)
	setupvars.alarmCapacityLevel[3] = value
	system.pSave("alarmCapacityLevel",setupvars.alarmCapacityLevel)
end

local function alarmCapacityLevelFourChanged(value)
	setupvars.alarmCapacityLevel[4] = value
	system.pSave("alarmCapacityLevel",setupvars.alarmCapacityLevel)
end

local function alarmCapacityLevelFiveChanged(value)
	setupvars.alarmCapacityLevel[5] = value
	system.pSave("alarmCapacityLevel",setupvars.alarmCapacityLevel)
end

local function alarmCapacityLevelSixChanged(value)
	setupvars.alarmCapacityLevel[6] = value
	system.pSave("alarmCapacityLevel",setupvars.alarmCapacityLevel)
end

local function actTimeChanged(value)
	setupvars.flightCounter[1] = value
	system.pSave("flightCounter", setupvars.flightCounter)
end

local function flightCountChanged(value)
	setupvars.flightCounter[2] = value
	system.pSave("flightCount", setupvars.flightCounter)
end

--------------------------------------------------------------------------------------------


--------------------------------------------------------------------------------------------
-- Function that creates user input form
--------------------------------------------------------------------------------------------
local function initForm(vars)
	print ("-Lua Form initialized-")
	
	setupvars = vars

	local available = system.getSensors()

	local selectionList={}

	local voltageCurrentIndex = -1
	local currentCurrentIndex = -1
	local capacityCurrentIndex = -1
	local temperatureCurrentIndex = -1
	local throttleCurrentIndex = -1
	local rpmCurrentIndex = -1
	local vibrationsCurrentIndex = -1
	local maltiCurrentIndex = -1
	local elevatorCurrentIndex = -1
	local aileronCurrentIndex = -1
	local rudderCurrentIndex = -1
		
	selectionList[#selectionList + 1] = string.format("%s","Jeti - Rx1 Voltage")
	sensorsAvailable[#sensorsAvailable + 1] = {["unit"] = "V",["param"] = 1,["id"] = 999,["sensorName"] = "Jeti",["label"] = "Rx1 Voltage"}

	selectionList[#selectionList + 1] = string.format("%s","Jeti - Rx2 Voltage")
	sensorsAvailable[#sensorsAvailable + 1] = {["unit"] = "V",["param"] = 2,["id"] = 999,["sensorName"] = "Jeti",["label"] = "Rx2 Voltage"}
		
	selectionList[#selectionList + 1] = string.format("%s","Jeti - RxB Voltage")
	sensorsAvailable[#sensorsAvailable + 1] = {["unit"] = "V",["param"] = 3,["id"] = 999,["sensorName"] = "Jeti",["label"] = "RxB Voltage"}
	
	if (setupvars.voltageSensor[1] == 999 and setupvars.voltageSensor[2] == 1) then
		voltageCurrentIndex = 1
	elseif (setupvars.voltageSensor[1] == 999 and setupvars.voltageSensor[2] == 2) then
		voltageCurrentIndex = 2
	elseif (setupvars.voltageSensor[1] == 999 and setupvars.voltageSensor[2] == 3) then
		voltageCurrentIndex = 3
	end
	
	for index,sensor in ipairs(available) do 
		if(sensor.param ~= 0) then 
			if(sensor.sensorName and string.len(sensor.sensorName) > 0) then
				selectionList[#selectionList + 1] = string.format("%s - %s [%s]",sensor.sensorName,sensor.label,sensor.unit)
			else
				selectionList[#selectionList + 1] = string.format("%s [%s]",sensor.label,sensor.unit)
			end
			
			sensorsAvailable[#sensorsAvailable + 1] = sensor
						
			if(sensor.id == setupvars.voltageSensor[1] and sensor.param == setupvars.voltageSensor[2]) then
				voltageCurrentIndex = #sensorsAvailable
			end
			if(sensor.id == setupvars.currentSensor[1] and sensor.param == setupvars.currentSensor[2]) then
				currentCurrentIndex = #sensorsAvailable
			end
			if(sensor.id == setupvars.capacitySensor[1] and sensor.param == setupvars.capacitySensor[2]) then
				capacityCurrentIndex = #sensorsAvailable
			end
			if(sensor.id == setupvars.temperatureSensor[1] and sensor.param == setupvars.temperatureSensor[2]) then
				temperatureCurrentIndex = #sensorsAvailable
			end
			if(sensor.id == setupvars.throttleSensor[1] and sensor.param == setupvars.throttleSensor[2]) then
				throttleCurrentIndex = #sensorsAvailable
			end
			if(sensor.id == setupvars.rpmSensor[1] and sensor.param == setupvars.rpmSensor[2]) then
				rpmCurrentIndex = #sensorsAvailable
			end
			if(sensor.id == setupvars.vibrationsSensor[1] and sensor.param == setupvars.vibrationsSensor[2]) then
				vibrationsCurrentIndex = #sensorsAvailable
			end
			if(sensor.id == setupvars.maltiSensor[1] and sensor.param == setupvars.maltiSensor[2]) then
				maltiCurrentIndex = #sensorsAvailable
			end
			if(sensor.id == setupvars.elevatorSensor[1] and sensor.param == setupvars.elevatorSensor[2]) then
				elevatorCurrentIndex = #sensorsAvailable
			end
			if(sensor.id == setupvars.aileronSensor[1] and sensor.param == setupvars.aileronSensor[2]) then
				aileronCurrentIndex = #sensorsAvailable
			end
			if(sensor.id == setupvars.rudderSensor[1] and sensor.param == setupvars.rudderSensor[2]) then
				rudderCurrentIndex = #sensorsAvailable
			end
		end
	end
	
	form.addRow(2)
	form.addLabel({label=setupvars.trans.sensors,font=FONT_BOLD,alignRight=false,enabled=false,visible=true,width=240})
	
	form.addRow(2)
	form.addLabel({label=setupvars.trans.voltage,font=FONT_NORMAL,width=170})
	form.addSelectbox(selectionList,voltageCurrentIndex, true, voltageSensorChanged)
	
	form.addRow(2)
	form.addLabel({label=setupvars.trans.capacity,font=FONT_NORMAL,width=170})
	form.addSelectbox(selectionList,capacityCurrentIndex, true, capacitySensorChanged)
	
	form.addRow(2)
	form.addLabel({label=setupvars.trans.current,font=FONT_NORMAL,width=170})
	form.addSelectbox(selectionList,currentCurrentIndex, true, currentSensorChanged)
	
	form.addRow(2)
	form.addLabel({label=setupvars.trans.temp,font=FONT_NORMAL,width=170})
	form.addSelectbox(selectionList,temperatureCurrentIndex, true, temperatureSensorChanged)
	
	form.addRow(2)
	form.addLabel({label=setupvars.trans.throttle,font=FONT_NORMAL,width=170})
	form.addSelectbox(selectionList,throttleCurrentIndex, true, throttleSensorChanged)
	
	form.addRow(2)
	form.addLabel({label=setupvars.trans.rpm,font=FONT_NORMAL,width=170})
	form.addSelectbox(selectionList,rpmCurrentIndex, true, rpmSensorChanged)
	
	form.addRow(2)
	form.addLabel({label=setupvars.trans.height,font=FONT_NORMAL,width=170})
	form.addSelectbox(selectionList,maltiCurrentIndex, true, maltiSensorChanged)
	
	form.addRow(2)
	form.addLabel({label=setupvars.trans.vibrations,font=FONT_NORMAL,width=170})
	form.addSelectbox(selectionList,vibrationsCurrentIndex, true, vibrationsSensorChanged)
	
	form.addRow(2)
	form.addLabel({label=setupvars.trans.elevator,font=FONT_NORMAL,width=170})
	form.addSelectbox(selectionList,elevatorCurrentIndex, true, elevatorSensorChanged)
	
	form.addRow(2)
	form.addLabel({label=setupvars.trans.aileron,font=FONT_NORMAL,width=170})
	form.addSelectbox(selectionList,aileronCurrentIndex, true, aileronSensorChanged)
	
	form.addRow(2)
	form.addLabel({label=setupvars.trans.rudder,font=FONT_NORMAL,width=170})
	form.addSelectbox(selectionList,rudderCurrentIndex, true, rudderSensorChanged)
	
	form.addRow(2)
	form.addLabel({label=setupvars.trans.options,font=FONT_BOLD,alignRight=false,enabled=false,visible=true,width=200})
	
	form.addRow(2)
	form.addLabel({label=setupvars.trans.cellCount,font=FONT_NORMAL,width=200})
	form.addIntbox(setupvars.lipo[1],1,99,1,0,1,lipoCellCountChanged)
	
	form.addRow(2)
	form.addLabel({label=setupvars.trans.nominalCapacity,font=FONT_NORMAL,width=210})
	form.addIntbox(setupvars.lipo[2],0,10000,0,0,50,lipoCapacityChanged)
	
	form.addRow(2)
	form.addLabel({label=setupvars.trans.usedLipo,font=FONT_NORMAL,width=230})
	local value = false
	if( setupvars.alarmUsedLipo[1] == 1 ) then
		value = true
	end
	checkboxIndex1 = form.addCheckbox(value,estimateUsedLipoBooleanChanged)
	
	form.addRow(2)
	form.addLabel({label=setupvars.trans.voltageThreshold,font=FONT_NORMAL,width=230})
	form.addIntbox(setupvars.alarmUsedLipo[2],0,420,330,2,1,voltageThresholdUsedLipoChanged)
	
	form.addRow(2)
	form.addLabel({label=setupvars.trans.usedLipoAnnouncement,font=FONT_NORMAL,width=160})
	form.addAudioFilebox(setupvars.alarmUsedLipo[3],alarmUsedLipoDetectedFileChanged)
	
	form.addRow(2)
	form.addLabel({label=setupvars.trans.fblInitDelay,font=FONT_NORMAL,width=230})
	form.addIntbox(setupvars.timeDelay,0,100,0,0,1,timeDelayChanged)

	form.addRow(2)
	form.addLabel({label=setupvars.trans.batteryAnnouncements,font=FONT_BOLD,alignRight=false,enabled=false,visible=true,width=250})
	
	form.addRow(2)
	form.addLabel({label=setupvars.trans.batteryLevel1,font=FONT_NORMAL,width=225})
	form.addIntbox(setupvars.alarmCapacityLevel[1],0,100,1,0,1,alarmCapacityLevelOneChanged)
	
	form.addRow(2)
	form.addLabel({label=setupvars.trans.batteryLevel2,font=FONT_NORMAL,width=225})
	form.addIntbox(setupvars.alarmCapacityLevel[2],0,100,1,0,1,alarmCapacityLevelTwoChanged)
	
	form.addRow(2)
	form.addLabel({label=setupvars.trans.batteryLevel3,font=FONT_NORMAL,width=225})
	form.addIntbox(setupvars.alarmCapacityLevel[3],0,100,1,0,1,alarmCapacityLevelThreeChanged)
	
	form.addRow(2)
	form.addLabel({label=setupvars.trans.batteryLevel4,font=FONT_NORMAL,width=225})
	form.addIntbox(setupvars.alarmCapacityLevel[4],0,100,1,0,1,alarmCapacityLevelFourChanged)
	
	form.addRow(2)
	form.addLabel({label=setupvars.trans.batteryLevel5,font=FONT_NORMAL,width=225})
	form.addIntbox(setupvars.alarmCapacityLevel[5],0,100,1,0,1,alarmCapacityLevelFiveChanged)
	
	form.addRow(2)
	form.addLabel({label=setupvars.trans.batteryLevel6,font=FONT_NORMAL,width=225})
	form.addIntbox(setupvars.alarmCapacityLevel[6],0,100,1,0,1,alarmCapacityLevelSixChanged)
	
	form.addRow(2)
	form.addLabel({label=setupvars.trans.switches,font=FONT_BOLD,alignRight=false,enabled=false,visible=true,width=200})
	
	form.addRow(2)
	form.addLabel({label=setupvars.trans.startTimer,font=FONT_NORMAL,width=200})
	form.addInputbox(setupvars.switchStartTimer,true,switchStartTimerChanged)

	local typeOptions = {"Up","Down"}
	form.addRow(2)
	form.addLabel({label="UP/DOWN Timer",font=FONT_NORMAL,width=200})
	form.addSelectbox(typeOptions, setupvars.timer[1], true, switchUpDownTimerChanged)

	form.addRow(2)
	form.addLabel({label=setupvars.trans.TimerValue, font=FONT_NORMAL,width=200})
	form.addIntbox(setupvars.timer[2], 0, 600, 0, 0 , 10, timerValueChanged, {label="s"})
	
	form.addRow(2)
	form.addLabel({label=setupvars.trans.resetTimer,font=FONT_NORMAL,width=200})
	form.addInputbox(setupvars.switchResetTimer,true,switchResetTimerChanged)
	
	form.addRow(2)
	form.addLabel({label=setupvars.trans.flightCounter,font=FONT_BOLD,alignRight=false,enabled=false,visible=true,width=250})
	
    form.addRow(2)
    form.addLabel({label=setupvars.trans.actTime, width=220})
    form.addIntbox(setupvars.flightCounter[1], 1, 600, 0, 0, 1, actTimeChanged)

	form.addRow(2)
	form.addLabel({label=setupvars.trans.flightCount,font=FONT_NORMAL,width=220})
    form.addIntbox(setupvars.flightCounter[2], -0, 10000, 0, 0, 1, flightCountChanged)

	return setupvars	
	--collectgarbage()
end
--------------------------------------------------------------------------------------------

return {

	initForm = initForm,
	version = _version

}
