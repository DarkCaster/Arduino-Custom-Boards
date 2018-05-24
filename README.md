# Arduino IDE board-manager's packages for my custom AVR boards

This project contains Arduino IDE board-manager's packages (and build-scrpt with source files to create it),
for use with various AVR boards and arduino-clones that I have.
I've created this project because I need some customizations missing in default Arduino IDE setup.

I've only tested it with my own arduino\avr boards, so if you want to use provided packages in your projects - ** USE AT YOUR OWN RISK **.
I cannot guarantee that all settings will work as intended in your setup.
Some configuration options ("Clock" menu, for example) perform fuse-bits modifications,
that may totally brick your AVR board if you do not fully understand option meaning and select wrong one.

Supported boards:
 - ATmega328/P/PB based boards. You can select compiler defines to mimic various official Arduino boards.
 - ATmega1284P based boards. Added mainly for Anet v1.0 board support (used in Anet A6\A8\E10 and other 3D-printers).

Third-party code used in this project:
 - pins_arduino.h from https://github.com/Lauszus/Sanguino project for ATmega1284P support;
 - programmers.txt from https://github.com/arduino/ArduinoCore-avr project to implement some ISP programmer tweaks;
 - optiboot bootloader sources (and some build scripts) from https://github.com/sleemanj/optiboot project;
 - using some ideas and code examples from https://github.com/SkyNet3D/anet-board projects;
 - make and bc binaries for windows from GnuWin32 project: http://gnuwin32.sourceforge.net;

Tested with Arduino IDE v1.8.5.
Older versions is not tested and may not be supported.
