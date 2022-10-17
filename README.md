# heli_telem_display

Heli Telem. Display - Full Screen Telemetry Display for Electric Helicopters - JETI

Compatible with DS-12, DS-24, DS-14 II, DS-16 II and corresponding DC models. No chance to get it running on older models without color display (e.g. DS-16), it is too big in memory consumption.

By Michael Leopoldseder forked from the excellent work of Nick Pedersen (https://github.com/nickthenorse/heli_telem_display)

	v1.05 - 2022-08-18 - Initial release
	v1.06 - 2022-08-19 - removed Cell valotage as logging telemetry due to calculated value and not a real value
	v2.00 - 2022-08-25 - split into more apps to keep it small
	v2.01 - 2022-08-26 - removed low voltage chirp and introduced count down timer
	v2.02 - 2022-08-28 - pLoad/pSave optimizations
	v2.03 - 2022-08-29 - moved functions from Screen to HeliTelm
	v2.04 - 2022-08-30 - moved a function back to Screen due to higher memory usage in HeliTelm
	v2.05 - 2022-09-03 - fault corrections
	v2.06 - 2022-09-06 - get back some PlayVoiceAlarms from Screen and move it to new function PlayTimerAlarms
	v2.07 - 2022-09-07 - use TimerV.jsn file for countdown alert
	v2.08 - 2022-10-02 - small optimizations and reintegration of screen.lua (introduced v2.0)
	v2.09 - 2022-10-16 - error correction for used battery announcement not stored
	v2.10 - 2022-10-17 - use 100% Lipo capacity instead of 80%
	
Instructions: download the file HeliTelm.lua as well as the folder Lang and HeliTelm and copy it to the /Apps folder on your Jeti transmitter. Then install via "User Applications" submenu.

There is a branch (splitApp) were the app is split up into three parts (HeliTelm, Screen and Form app). Goal is to balance memory usage to achieve DS-16 compatibility.

It is a full screen telemetry window, and is changed in some points from Nick Pedersen's original

	- It shows the flight hight if a hight sensor is configured
	  (shown in the space of the vibrations instead)
	
	- it does not show values for sensor not configured
	  
	- includes a flight counter and is show above the flight time
	  (flight time character set size is reduced)
	  
	- most of the min/max values are shown in standard color for better readability
	
	- it supports languages (currently available in english and german)
	  (please feel free to add additional languages)

	- seperated setup form into an own lua script (HeliTelm/form.lua)

![Screenshot Main Window](Screen001.png?raw=true "Screenshot Main Window")

![Screenshot Main Window](Screen004.png?raw=true "Screenshot Main Window")

This is purely for my own hobbyist and non-commercial use.
No liability or responsibility is assumed for your own use! Feel free to use this code in any way you see fit to modify 
and/or personalise the telemetry that is being displayed, or as a way to learn lua for yourself.

Also: this is my first attempt at a lua app for Jeti. I can't claim it is particularly
efficiently coded, and is in no way optimised for optimal memory usage. But it works :)

Code was forked from Nick Pedersen's Heli Telm. Display (see above) and all references are still valid.
Please inform me if I made a mistake with the credentials, it's my first github code.
