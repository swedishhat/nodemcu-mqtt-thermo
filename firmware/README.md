# Firmware Info

## NodeMCU custom build by [Frightanic](http://frightanic.com/nodemcu-custom-build/)
* Branch:     dev
* Commit:     f5ae0ed7c7fe697ee402216269e87b901e08b698
* SSL:        true
* Modules:    node,file,gpio,wifi,tmr,uart,mqtt,ws2812
* Built on:   2015-09-14 23:28
* Lua Ver:    5.1.4

## How to Flash Firmware

### Get the Board into Flash Mode and Connect to USB-Serial Device
Less Fancy ESP8266 Boards like ESP-01 don't automatically go into flash mode
so you have to do it manually. Enable the chip by connecting CH_PD to VCC and
put it into flash mode by grounding GPIO 0.

The less fancy boards also don't have onboard USB-Serial converters like the
CH340G on the NodeMCU-Devkit or the popular FT232RL. Make sure it's 3V3 logic
and connect: 
* TX_serial-> RX_esp
* RX_serial -> TX_esp
* GND_serial -> GND_esp

The NodeMCU-Devkit does this automatically so you don't gotta worry, man.

### Flash! AAAHHAAA! Savior of the Universe!
`../tools/esptool/esptool.py -p PORT -b BAUD write_flash 0x00000 nodemcu-firmware.bin`
If the -p or -b options are omitted, they default to /dev/ttyUSB0 and 9600 respectively