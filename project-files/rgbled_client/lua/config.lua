-- config.lua for light strip
-- by Patrick Lloyd

-- Global variable configuration file for better portability
-- Change for your particular setup. This assumes default Mosquitto config


-- Pin Declarations
PIN_WS2812 = 4  -- This is GPIO2 on ESP8266. No idea why NodeMCU does this...

-- WiFi
WIFI_SSID = ""
WIFI_PASS = ""

-- MQTT
MQTT_CLIENTID   = "esp-led"
MQTT_HOST       = ""
MQTT_PORT       = 1883
MQTT_CMDTIME_MS = 50

-- Upper and lower temperature bounds for comfort (deg C)
TEMP_MAX = 44.0     -- Too hot!
TEMP_MIN = -7.0     -- Brrr!

-- HSV Temperature Color Table in form of Inverse HSV Gradient based off of this tool: http://www.perbang.dk/rgbgradient/
TEMP_COLOR_LUT = string.char(
    0, 0, 255, 0, 17, 255, 0, 34, 255, 0, 51, 255, 0, 69, 255, 0, 86, 255, 0, 103, 255, 0, 121, 255, 0, 138, 255, 0, 155, 255, 0, 172, 255, 0, 190, 255,
    0, 207, 255, 0, 224, 255, 0, 242, 255, 0, 255, 250, 0, 255, 233, 0, 255, 216, 0, 255, 198, 0, 255, 181, 0, 255, 164, 0, 255, 146, 0, 255, 129, 0,
    255, 112, 0, 255, 95, 0, 255, 77, 0, 255, 60, 0, 255, 43, 0, 255, 25, 0, 255, 8, 8, 255, 0, 25, 255, 0, 43, 255, 0, 60, 255, 0, 77, 255, 0, 95,
    255, 0, 112, 255, 0, 129, 255, 0, 146, 255, 0, 164, 255, 0, 181, 255, 0, 198, 255, 0, 216, 255, 0, 233, 255, 0, 250, 255, 0, 255, 242, 0, 255, 224,
    0, 255, 207, 0, 255, 190, 0, 255, 172, 0, 255, 155, 0, 255, 138, 0, 255, 121, 0, 255, 103, 0, 255, 86, 0, 255, 69, 0, 255, 51, 0, 255, 34, 0, 255,
    17, 0, 255, 0, 0)

print("\nConfig complete")