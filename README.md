lonometer-dump
==============

This project describes, how get data out of the 'lonometer' aka 'VENTUS W030'.

The lonometer is a bluetooth thermometer/hygrometer and it is intended to us an Android/IOS App to read and visualize its measurements.
This README contains the basic knowledge that you need to get the data from the device using a linux PC (tested with a raspberry-pi).
The perl script I wrote reads the data from the device and writes a shell script containing commands to feed the data to an rrd file.

capabilities
------------

- resolution is 1 degree celsius / 1 percent rH.
- temperature and humidity are measured every 5 minutes, independent from the data being read.
- the device keeps a history of the last 24 hours (so 288 measured values).
- when reading data, the device always returns the whole set of data.

prerequisites
-------------

- linux machine with BTLE-adapter
- packages: libglib2.0-dev libdbus-1-dev libusb-dev libudev-dev libical-dev systemd libreadline-dev

steps to read data
------------------

activate the BTLE interface
```
sudo hciconfig hci0 up
```

scan for BTLE devices
```
sudo hcitool lescan
```
after some seconds, the output should show the address of the device
```
LE Scan ...
AA:BB:CC:DD:EE:FF (unknown)
AA:BB:CC:DD:EE:FF NGE76
AA:BB:CC:DD:EE:FF (unknown)
AA:BB:CC:DD:EE:FF NGE76
AA:BB:CC:DD:EE:FF (unknown)
AA:BB:CC:DD:EE:FF NGE76
```
