# heli_telem_display

Heli Telem. Display - Full Screen Telemetry Display for Electric Helicopters - JETI

Compatible with DS-12, DS-24, DS-14 II, DS-16 II and corresponding DC models.

By Michael Leopoldseder forked from the excellent work of Nick Pedersen (https://github.com/nickthenorse/heli_telem_display)

	v1.05 - 2022-08-18 - Initial release
	
Instructions: download the file HeliTelm.lua as well as the folder Lang and copy it to the /Apps folder on your Jeti transmitter. Then install via "User Applications" submenu.

It is a full screen telemetry window, and is changed in some points from Nick Pedersen's original

	- It shows the flight hight if a hight sensor is configured
	  (shown in the space of the vibrations instead)
	
	- it does not show values for sensor not configured
	  
	- includes a flight counter and is show above the flight time
	  (flight time character set size is reduced)
	  
	- most of the min/max values are shown in standard color for better readability
	
	- it has alanguage file which is currently available in english and german
	  (please feel free to add additional languages)

![Screenshot Main Window](HeliTelem1.png?raw=true "Screenshot Main Window")

This is purely for my own hobbyist and non-commercial use.
No liability or responsibility is assumed for your own use! Feel free to use this code in any way you see fit to modify 
and/or personalise the telemetry that is being displayed, or as a way to learn lua for yourself.

Also: this is my first attempt at a lua app for Jeti. I can't claim it is particularly
efficiently coded, and is in no way optimised for optimal memory usage. But it works :)

Code was forked from Nick Pedersen's Heli Telm. Display (see above) and all references are still valid.
Please inform me if I made a mistake with the credentials, it's my first github code.
