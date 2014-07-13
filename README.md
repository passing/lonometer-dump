lonometer-dump
==============

This project describes, how get data out of the 'lonometer' aka 'VENTUS W030'.

The lonometer is a bluetooth thermometer/hygrometer and it is intended to us an Android/IOS App to read and visualize its measurements.
This README contains the basic knowledge that you need to get the data from the device using a linux PC (tested with a raspberry-pi).
The perl script I wrote reads the data from the device and writes a shell script containing commands to feed the data to an rrd file.

capabilities
------------

- resolution is 1 degree celsius / 1 percent rH.
- temperature and humidity are measured every 5 minutes, independent from when data is being read.
- the device keeps a history of the last 24 hours (so 288 measured values).
- when reading data, the device always returns the whole set of data.

prerequisites
-------------

- linux machine with BTLE-adapter
- bluez with BTLE support
(for a raspberry-pi with raspbian, see http://www.ioncannon.net/linux/1570/bluetooth-4-0-le-on-raspberry-pi-with-bluez-5-x/
packages needed to compile bluez: libglib2.0-dev libdbus-1-dev libusb-dev libudev-dev libical-dev libreadline-dev systemd)

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

do a characteristics scan
```
gatttool -b AA:BB:CC:DD:EE:FF --characteristics
handle = 0x0002, char properties = 0x02, char value handle = 0x0003, uuid = 00002a00-0000-1000-8000-00805f9b34fb
handle = 0x0004, char properties = 0x02, char value handle = 0x0005, uuid = 00002a01-0000-1000-8000-00805f9b34fb
handle = 0x0006, char properties = 0x0a, char value handle = 0x0007, uuid = 00002a02-0000-1000-8000-00805f9b34fb
handle = 0x0008, char properties = 0x08, char value handle = 0x0009, uuid = 00002a03-0000-1000-8000-00805f9b34fb
handle = 0x000a, char properties = 0x02, char value handle = 0x000b, uuid = 00002a04-0000-1000-8000-00805f9b34fb
handle = 0x000d, char properties = 0x20, char value handle = 0x000e, uuid = 00002a05-0000-1000-8000-00805f9b34fb
handle = 0x0011, char properties = 0x02, char value handle = 0x0012, uuid = 00002a23-0000-1000-8000-00805f9b34fb
handle = 0x0013, char properties = 0x02, char value handle = 0x0014, uuid = 00002a24-0000-1000-8000-00805f9b34fb
handle = 0x0015, char properties = 0x02, char value handle = 0x0016, uuid = 00002a25-0000-1000-8000-00805f9b34fb
handle = 0x0017, char properties = 0x02, char value handle = 0x0018, uuid = 00002a26-0000-1000-8000-00805f9b34fb
handle = 0x0019, char properties = 0x02, char value handle = 0x001a, uuid = 00002a27-0000-1000-8000-00805f9b34fb
handle = 0x001b, char properties = 0x02, char value handle = 0x001c, uuid = 00002a28-0000-1000-8000-00805f9b34fb
handle = 0x001d, char properties = 0x02, char value handle = 0x001e, uuid = 00002a29-0000-1000-8000-00805f9b34fb
handle = 0x001f, char properties = 0x02, char value handle = 0x0020, uuid = 00002a2a-0000-1000-8000-00805f9b34fb
handle = 0x0021, char properties = 0x02, char value handle = 0x0022, uuid = 00002a50-0000-1000-8000-00805f9b34fb
handle = 0x0024, char properties = 0x10, char value handle = 0x0025, uuid = 00002a1c-0000-1000-8000-00805f9b34fb
handle = 0x0027, char properties = 0x08, char value handle = 0x0028, uuid = 0000fff1-0000-1000-8000-00805f9b34fb
handle = 0x002a, char properties = 0x12, char value handle = 0x002b, uuid = 00002a19-0000-1000-8000-00805f9b34fb
```

so according to https://developer.bluetooth.org/gatt/characteristics/Pages/CharacteristicsHome.aspx
- handle 0x0024 is for temperature measurement (uuid = 00002a1c matches 0x2A1C in the documentation)
- handle 0x002a is for battery level (uuid = 00002a19 matches 0x2A19 in the documentation)

so reading the battery level is done by
```
gatttool -b AA:BB:CC:DD:EE:FF --char-read --handle=0x002b
Characteristic value/descriptor: 64
```

the result is 0x62 - I assume it means the battery level is 100%

reading temprature is done in a different way by
```
gatttool -b AA:BB:CC:DD:EE:FF --char-write-req --handle=0x0026 --value=0100 --listen
```

the output can be found in the file dump.txt

- The first 2 bytes count from 288 down to 1 and indicate the age of the measurement (multiply by 5 and subtract 1 to get minutes)
- The 3rd byte corresponds to the channel selected with the sliding switch in the battery compartment (can be 1, 2 or 3)
- The 4th byte corresponds to the temperature (I assume that subtracting 40 gets you to the correct value in celsius)
- The 5th byte corresponds to the humidity (doesn't need to be converted)

usage
-----

use shell script to create rrd files (set the variable 'name' inside the script to the BT device address)
```
./rrdcreate.sh
```

use perl script to read data from the BT device 
```
./lonometer-dump.pl -b AA:BB:CC:DD:EE:FF -r /tmp/
```
the script expects the rrd files in the given directory and puts a file 'update.sh' there which you can execute thereafter
