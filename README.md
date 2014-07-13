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

the output looks like
```
Characteristic value was written successfully
Notification handle = 0x0025 value: 01 20 01 3b 45 
Notification handle = 0x0025 value: 01 1f 01 3b 45 
Notification handle = 0x0025 value: 01 1e 01 3b 45 
Notification handle = 0x0025 value: 01 1d 01 3c 44 
Notification handle = 0x0025 value: 01 1c 01 3c 43 
Notification handle = 0x0025 value: 01 1b 01 3b 43 
Notification handle = 0x0025 value: 01 1a 01 3b 43 
Notification handle = 0x0025 value: 01 19 01 3c 42 
Notification handle = 0x0025 value: 01 18 01 3c 43 
Notification handle = 0x0025 value: 01 17 01 3c 42 
Notification handle = 0x0025 value: 01 16 01 3c 42 
Notification handle = 0x0025 value: 01 15 01 3c 42 
Notification handle = 0x0025 value: 01 14 01 3c 42 
Notification handle = 0x0025 value: 01 13 01 3c 42 
Notification handle = 0x0025 value: 01 12 01 3b 42 
Notification handle = 0x0025 value: 01 11 01 3b 42 
Notification handle = 0x0025 value: 01 10 01 3b 43 
Notification handle = 0x0025 value: 01 0f 01 3b 43 
Notification handle = 0x0025 value: 01 0e 01 3b 43 
Notification handle = 0x0025 value: 01 0d 01 3b 43 
Notification handle = 0x0025 value: 01 0c 01 3b 43 
Notification handle = 0x0025 value: 01 0b 01 3b 43 
Notification handle = 0x0025 value: 01 0a 01 3b 43 
Notification handle = 0x0025 value: 01 09 01 3b 43 
Notification handle = 0x0025 value: 01 08 01 3b 43 
Notification handle = 0x0025 value: 01 07 01 3b 43 
Notification handle = 0x0025 value: 01 06 01 3c 42 
Notification handle = 0x0025 value: 01 05 01 3c 42 
Notification handle = 0x0025 value: 01 04 01 3c 40 
Notification handle = 0x0025 value: 01 03 01 3c 40 
Notification handle = 0x0025 value: 01 02 01 3c 3e 
Notification handle = 0x0025 value: 01 01 01 3d 3b 
Notification handle = 0x0025 value: 01 00 01 3d 3b 
Notification handle = 0x0025 value: 00 ff 01 3d 39 
Notification handle = 0x0025 value: 00 fe 01 3d 3a 
Notification handle = 0x0025 value: 00 fd 01 3d 3a 
Notification handle = 0x0025 value: 00 fc 01 3d 39 
Notification handle = 0x0025 value: 00 fb 01 3d 39 
Notification handle = 0x0025 value: 00 fa 01 3d 3a 
Notification handle = 0x0025 value: 00 f9 01 3c 3d 
Notification handle = 0x0025 value: 00 f8 01 3d 3a 
Notification handle = 0x0025 value: 00 f7 01 3d 3a 
Notification handle = 0x0025 value: 00 f6 01 3d 3a 
Notification handle = 0x0025 value: 00 f5 01 3e 3a 
Notification handle = 0x0025 value: 00 f4 01 3e 3a 
Notification handle = 0x0025 value: 00 f3 01 3e 3a 
Notification handle = 0x0025 value: 00 f2 01 3d 3a 
Notification handle = 0x0025 value: 00 f1 01 3d 3b 
Notification handle = 0x0025 value: 00 f0 01 3d 3b 
Notification handle = 0x0025 value: 00 ef 01 3d 3b 
Notification handle = 0x0025 value: 00 ee 01 3d 3b 
Notification handle = 0x0025 value: 00 ed 01 3d 3c 
Notification handle = 0x0025 value: 00 ec 01 3d 3b 
Notification handle = 0x0025 value: 00 eb 01 3d 3b 
Notification handle = 0x0025 value: 00 ea 01 3d 3b 
Notification handle = 0x0025 value: 00 e9 01 3d 3c 
Notification handle = 0x0025 value: 00 e8 01 3d 3b 
Notification handle = 0x0025 value: 00 e7 01 3d 3b 
Notification handle = 0x0025 value: 00 e6 01 3d 3b 
Notification handle = 0x0025 value: 00 e5 01 3d 3c 
Notification handle = 0x0025 value: 00 e4 01 3d 3b 
Notification handle = 0x0025 value: 00 e3 01 3d 3c 
Notification handle = 0x0025 value: 00 e2 01 3c 3f 
Notification handle = 0x0025 value: 00 e1 01 3c 40 
Notification handle = 0x0025 value: 00 e0 01 3c 40 
Notification handle = 0x0025 value: 00 df 01 3c 40 
Notification handle = 0x0025 value: 00 de 01 3c 40 
Notification handle = 0x0025 value: 00 dd 01 3c 40 
Notification handle = 0x0025 value: 00 dc 01 3c 40 
Notification handle = 0x0025 value: 00 db 01 3c 41 
Notification handle = 0x0025 value: 00 da 01 3c 41 
Notification handle = 0x0025 value: 00 d9 01 3c 41 
Notification handle = 0x0025 value: 00 d8 01 3c 41 
Notification handle = 0x0025 value: 00 d7 01 3b 42 
Notification handle = 0x0025 value: 00 d6 01 3b 42 
Notification handle = 0x0025 value: 00 d5 01 3b 42 
Notification handle = 0x0025 value: 00 d4 01 3b 42 
Notification handle = 0x0025 value: 00 d3 01 3b 42 
Notification handle = 0x0025 value: 00 d2 01 3b 42 
Notification handle = 0x0025 value: 00 d1 01 3b 42 
Notification handle = 0x0025 value: 00 d0 01 3b 42 
Notification handle = 0x0025 value: 00 cf 01 3b 42 
Notification handle = 0x0025 value: 00 ce 01 3b 43 
Notification handle = 0x0025 value: 00 cd 01 3b 43 
Notification handle = 0x0025 value: 00 cc 01 3b 43 
Notification handle = 0x0025 value: 00 cb 01 3b 43 
Notification handle = 0x0025 value: 00 ca 01 3b 43 
Notification handle = 0x0025 value: 00 c9 01 3a 43 
Notification handle = 0x0025 value: 00 c8 01 3a 43 
Notification handle = 0x0025 value: 00 c7 01 3a 43 
Notification handle = 0x0025 value: 00 c6 01 3a 44 
Notification handle = 0x0025 value: 00 c5 01 3a 44 
Notification handle = 0x0025 value: 00 c4 01 3a 44 
Notification handle = 0x0025 value: 00 c3 01 3a 44 
Notification handle = 0x0025 value: 00 c2 01 3a 44 
Notification handle = 0x0025 value: 00 c1 01 3a 44 
Notification handle = 0x0025 value: 00 c0 01 3a 44 
Notification handle = 0x0025 value: 00 bf 01 3a 44 
Notification handle = 0x0025 value: 00 be 01 3a 44 
Notification handle = 0x0025 value: 00 bd 01 3a 44 
Notification handle = 0x0025 value: 00 bc 01 3a 44 
Notification handle = 0x0025 value: 00 bb 01 3a 44 
Notification handle = 0x0025 value: 00 ba 01 3a 45 
Notification handle = 0x0025 value: 00 b9 01 3a 45 
Notification handle = 0x0025 value: 00 b8 01 3a 45 
Notification handle = 0x0025 value: 00 b7 01 39 45 
Notification handle = 0x0025 value: 00 b6 01 39 45 
Notification handle = 0x0025 value: 00 b5 01 39 45 
Notification handle = 0x0025 value: 00 b4 01 39 45 
Notification handle = 0x0025 value: 00 b3 01 39 45 
Notification handle = 0x0025 value: 00 b2 01 39 45 
Notification handle = 0x0025 value: 00 b1 01 39 45 
Notification handle = 0x0025 value: 00 b0 01 39 45 
Notification handle = 0x0025 value: 00 af 01 39 45 
Notification handle = 0x0025 value: 00 ae 01 39 45 
Notification handle = 0x0025 value: 00 ad 01 39 45 
Notification handle = 0x0025 value: 00 ac 01 39 45 
Notification handle = 0x0025 value: 00 ab 01 39 45 
Notification handle = 0x0025 value: 00 aa 01 39 45 
Notification handle = 0x0025 value: 00 a9 01 39 45 
Notification handle = 0x0025 value: 00 a8 01 38 45 
Notification handle = 0x0025 value: 00 a7 01 38 45 
Notification handle = 0x0025 value: 00 a6 01 39 45 
Notification handle = 0x0025 value: 00 a5 01 38 45 
Notification handle = 0x0025 value: 00 a4 01 38 45 
Notification handle = 0x0025 value: 00 a3 01 38 45 
Notification handle = 0x0025 value: 00 a2 01 38 45 
Notification handle = 0x0025 value: 00 a1 01 38 45 
Notification handle = 0x0025 value: 00 a0 01 38 45 
Notification handle = 0x0025 value: 00 9f 01 38 45 
Notification handle = 0x0025 value: 00 9e 01 38 45 
Notification handle = 0x0025 value: 00 9d 01 38 45 
Notification handle = 0x0025 value: 00 9c 01 38 45 
Notification handle = 0x0025 value: 00 9b 01 38 45 
Notification handle = 0x0025 value: 00 9a 01 38 45 
Notification handle = 0x0025 value: 00 99 01 38 45 
Notification handle = 0x0025 value: 00 98 01 38 45 
Notification handle = 0x0025 value: 00 97 01 38 45 
Notification handle = 0x0025 value: 00 96 01 38 45 
Notification handle = 0x0025 value: 00 95 01 38 45 
Notification handle = 0x0025 value: 00 94 01 38 45 
Notification handle = 0x0025 value: 00 93 01 38 45 
Notification handle = 0x0025 value: 00 92 01 38 45 
Notification handle = 0x0025 value: 00 91 01 38 45 
Notification handle = 0x0025 value: 00 90 01 38 45 
Notification handle = 0x0025 value: 00 8f 01 38 45 
Notification handle = 0x0025 value: 00 8e 01 38 45 
Notification handle = 0x0025 value: 00 8d 01 38 45 
Notification handle = 0x0025 value: 00 8c 01 38 45 
Notification handle = 0x0025 value: 00 8b 01 38 45 
Notification handle = 0x0025 value: 00 8a 01 38 45 
Notification handle = 0x0025 value: 00 89 01 38 45 
Notification handle = 0x0025 value: 00 88 01 38 45 
Notification handle = 0x0025 value: 00 87 01 38 45 
Notification handle = 0x0025 value: 00 86 01 38 45 
Notification handle = 0x0025 value: 00 85 01 38 45 
Notification handle = 0x0025 value: 00 84 01 38 45 
Notification handle = 0x0025 value: 00 83 01 38 45 
Notification handle = 0x0025 value: 00 82 01 38 45 
Notification handle = 0x0025 value: 00 81 01 38 45 
Notification handle = 0x0025 value: 00 80 01 38 46 
Notification handle = 0x0025 value: 00 7f 01 38 46 
Notification handle = 0x0025 value: 00 7e 01 38 46 
Notification handle = 0x0025 value: 00 7d 01 38 46 
Notification handle = 0x0025 value: 00 7c 01 38 46 
Notification handle = 0x0025 value: 00 7b 01 38 46 
Notification handle = 0x0025 value: 00 7a 01 38 46 
Notification handle = 0x0025 value: 00 79 01 38 46 
Notification handle = 0x0025 value: 00 78 01 38 46 
Notification handle = 0x0025 value: 00 77 01 38 46 
Notification handle = 0x0025 value: 00 76 01 38 46 
Notification handle = 0x0025 value: 00 75 01 38 46 
Notification handle = 0x0025 value: 00 74 01 38 46 
Notification handle = 0x0025 value: 00 73 01 38 46 
Notification handle = 0x0025 value: 00 72 01 38 46 
Notification handle = 0x0025 value: 00 71 01 38 46 
Notification handle = 0x0025 value: 00 70 01 38 46 
Notification handle = 0x0025 value: 00 6f 01 38 46 
Notification handle = 0x0025 value: 00 6e 01 38 46 
Notification handle = 0x0025 value: 00 6d 01 38 46 
Notification handle = 0x0025 value: 00 6c 01 38 46 
Notification handle = 0x0025 value: 00 6b 01 38 46 
Notification handle = 0x0025 value: 00 6a 01 38 46 
Notification handle = 0x0025 value: 00 69 01 38 46 
Notification handle = 0x0025 value: 00 68 01 38 46 
Notification handle = 0x0025 value: 00 67 01 37 49 
Notification handle = 0x0025 value: 00 66 01 37 49 
Notification handle = 0x0025 value: 00 65 01 37 49 
Notification handle = 0x0025 value: 00 64 01 37 49 
Notification handle = 0x0025 value: 00 63 01 37 49 
Notification handle = 0x0025 value: 00 62 01 37 49 
Notification handle = 0x0025 value: 00 61 01 37 49 
Notification handle = 0x0025 value: 00 60 01 37 49 
Notification handle = 0x0025 value: 00 5f 01 37 49 
Notification handle = 0x0025 value: 00 5e 01 37 4a 
Notification handle = 0x0025 value: 00 5d 01 37 4a 
Notification handle = 0x0025 value: 00 5c 01 37 4a 
Notification handle = 0x0025 value: 00 5b 01 37 4a 
Notification handle = 0x0025 value: 00 5a 01 37 4a 
Notification handle = 0x0025 value: 00 59 01 37 4a 
Notification handle = 0x0025 value: 00 58 01 37 4a 
Notification handle = 0x0025 value: 00 57 01 37 4a 
Notification handle = 0x0025 value: 00 56 01 37 4a 
Notification handle = 0x0025 value: 00 55 01 37 4a 
Notification handle = 0x0025 value: 00 54 01 37 4a 
Notification handle = 0x0025 value: 00 53 01 37 4a 
Notification handle = 0x0025 value: 00 52 01 37 4a 
Notification handle = 0x0025 value: 00 51 01 37 4a 
Notification handle = 0x0025 value: 00 50 01 37 4a 
Notification handle = 0x0025 value: 00 4f 01 37 4a 
Notification handle = 0x0025 value: 00 4e 01 37 4a 
Notification handle = 0x0025 value: 00 4d 01 37 4a 
Notification handle = 0x0025 value: 00 4c 01 37 4a 
Notification handle = 0x0025 value: 00 4b 01 37 4a 
Notification handle = 0x0025 value: 00 4a 01 37 4a 
Notification handle = 0x0025 value: 00 49 01 37 4a 
Notification handle = 0x0025 value: 00 48 01 37 4a 
Notification handle = 0x0025 value: 00 47 01 37 4a 
Notification handle = 0x0025 value: 00 46 01 37 4a 
Notification handle = 0x0025 value: 00 45 01 37 4a 
Notification handle = 0x0025 value: 00 44 01 37 4a 
Notification handle = 0x0025 value: 00 43 01 37 4a 
Notification handle = 0x0025 value: 00 42 01 37 4a 
Notification handle = 0x0025 value: 00 41 01 37 4a 
Notification handle = 0x0025 value: 00 40 01 38 48 
Notification handle = 0x0025 value: 00 3f 01 38 48 
Notification handle = 0x0025 value: 00 3e 01 38 48 
Notification handle = 0x0025 value: 00 3d 01 38 48 
Notification handle = 0x0025 value: 00 3c 01 38 48 
Notification handle = 0x0025 value: 00 3b 01 38 48 
Notification handle = 0x0025 value: 00 3a 01 38 48 
Notification handle = 0x0025 value: 00 39 01 38 48 
Notification handle = 0x0025 value: 00 38 01 38 48 
Notification handle = 0x0025 value: 00 37 01 38 48 
Notification handle = 0x0025 value: 00 36 01 39 48 
Notification handle = 0x0025 value: 00 35 01 39 48 
Notification handle = 0x0025 value: 00 34 01 39 47 
Notification handle = 0x0025 value: 00 33 01 3a 47 
Notification handle = 0x0025 value: 00 32 01 3a 47 
Notification handle = 0x0025 value: 00 31 01 3a 46 
Notification handle = 0x0025 value: 00 30 01 3a 46 
Notification handle = 0x0025 value: 00 2f 01 3a 46 
Notification handle = 0x0025 value: 00 2e 01 3a 46 
Notification handle = 0x0025 value: 00 2d 01 3a 46 
Notification handle = 0x0025 value: 00 2c 01 3a 46 
Notification handle = 0x0025 value: 00 2b 01 3a 45 
Notification handle = 0x0025 value: 00 2a 01 3b 45 
Notification handle = 0x0025 value: 00 29 01 3b 44 
Notification handle = 0x0025 value: 00 28 01 3b 43 
Notification handle = 0x0025 value: 00 27 01 3b 44 
Notification handle = 0x0025 value: 00 26 01 3c 43 
Notification handle = 0x0025 value: 00 25 01 3c 43 
Notification handle = 0x0025 value: 00 24 01 3c 42 
Notification handle = 0x0025 value: 00 23 01 3d 3e 
Notification handle = 0x0025 value: 00 22 01 3d 3d 
Notification handle = 0x0025 value: 00 21 01 3d 3c 
Notification handle = 0x0025 value: 00 20 01 3d 3c 
Notification handle = 0x0025 value: 00 1f 01 3c 40 
Notification handle = 0x0025 value: 00 1e 01 3c 3e 
Notification handle = 0x0025 value: 00 1d 01 3d 3b 
Notification handle = 0x0025 value: 00 1c 01 3c 3f 
Notification handle = 0x0025 value: 00 1b 01 3d 3b 
Notification handle = 0x0025 value: 00 1a 01 3d 39 
Notification handle = 0x0025 value: 00 19 01 3c 3e 
Notification handle = 0x0025 value: 00 18 01 3c 3e 
Notification handle = 0x0025 value: 00 17 01 3c 3d 
Notification handle = 0x0025 value: 00 16 01 3d 39 
Notification handle = 0x0025 value: 00 15 01 3d 3a 
Notification handle = 0x0025 value: 00 14 01 3d 3a 
Notification handle = 0x0025 value: 00 13 01 3e 39 
Notification handle = 0x0025 value: 00 12 01 3e 37 
Notification handle = 0x0025 value: 00 11 01 3e 37 
Notification handle = 0x0025 value: 00 10 01 3d 37 
Notification handle = 0x0025 value: 00 0f 01 3d 38 
Notification handle = 0x0025 value: 00 0e 01 3e 36 
Notification handle = 0x0025 value: 00 0d 01 3e 36 
Notification handle = 0x0025 value: 00 0c 01 3e 34 
Notification handle = 0x0025 value: 00 0b 01 3e 37 
Notification handle = 0x0025 value: 00 0a 01 3e 36 
Notification handle = 0x0025 value: 00 09 01 3e 35 
Notification handle = 0x0025 value: 00 08 01 3f 35 
Notification handle = 0x0025 value: 00 07 01 3f 34 
Notification handle = 0x0025 value: 00 06 01 40 34 
Notification handle = 0x0025 value: 00 05 01 3f 33 
Notification handle = 0x0025 value: 00 04 01 3f 34 
Notification handle = 0x0025 value: 00 03 01 3f 33 
Notification handle = 0x0025 value: 00 02 01 3f 33 
Notification handle = 0x0025 value: 00 01 01 3e 32 
```

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
