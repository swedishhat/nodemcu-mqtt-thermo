-- config.lua for thermometer
-- by Patrick Lloyd

-- Global variable configuration file for better portability
-- Change for your particular setup. This assumes default Mosquitto config

-- Pin Declarations
PIN_SCK = 1
PIN_MISO = 2
PIN_CS = 3

-- WiFi
WIFI_SSID = ""
WIFI_PASS = ""

-- MQTT
MQTT_CLIENTID   = "esp-therm"
MQTT_HOST       = ""
MQTT_PORT       = 1883
MQTT_CMDTIME_MS = 500

print("\nConfig complete")