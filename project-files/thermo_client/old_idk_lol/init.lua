--[[
init_man.lua
by Patrick Lloyd

Actual init file, but named something other than init.lua in order to 
manually test and debug initialization code.
--]]

-- Load all the global user-defined variables
dofile("config.lua")
dofile("max31855_swspi.lua")

function get_sys_info()
  -- WiFi Info
  local ip, nm, gw = wifi.sta.getip()
  local mac = wifi.sta.getmac()
  local wifi_mode = {[1] = "STATION", [2] = "SOFTAP", [3] = "STATIONAP"}
  
  -- Hardware Info
  local ver_maj, ver_min, ver_dev, chip_id, flash_id, flash_size, flash_mode,
    flash_speed = node.info()
  local heap_size = node.heap()
  
  local info = {
    ["wifi"] = {
      ["WiFi Mode"]   = wifi_mode[wifi.getmode()],
      ["MAC Address"] = mac,
      ["IP Address"]  = ip,
      ["Netmask"]     = nm,
      ["Gateway"]     = gw
    },
    ["sys"] = {
      ["Version"]     = ver_maj.."."..ver_min.."."..ver_dev,
      ["Heap Size"]   = heap_size,
      ["Chip ID"]     = chip_id,
      ["Flash ID"]    = flash_id,
      ["Flash Size"]  = flash_size,
      ["Flash Mode"]  = flash_mode,
      ["Flash Speed"] = flash_speed
    },
    ["mqtt"] = {
      ["Client ID"]   = MQTT_CLIENTID,
      ["MQTT Host"]  = MQTT_HOST..":"..MQTT_PORT
    }
  }
    
    return info
end

-- 
max31855_swspi_setup(PIN_CS, PIN_MISO, PIN_SCK)


-- Put radio into station mode to connect to network
wifi.setmode(wifi.STATION)

-- Undescriptive name for a table that holds all the system info
-- "t" is for "too many nested tables with string indecies for system info"
local t = get_sys_info()

-- Print all the system info
print("\n"..
  "-----------------\n"..
  "-- System Info --\n"..
  "-----------------")
for key, val in pairs(t.sys) do
  print(key..":\t"..val)
end
print("")

-- Start the connection attempt
wifi.sta.config(WIFI_SSID, WIFI_PASS)

-- Create an alarm to poll the wifi.sta.getip() function once a second
-- If the device hasn't connected yet, blink through the LED colors. If it 
-- has, turn the LED white
tmr.alarm(0, 1000, 1, function()
	if wifi.sta.getip() == nil then
		print("Connecting to AP...")	
	else
  	-- Refresh the system info table
    t = get_sys_info()
      	
  	-- Print all the WiFi info
    print("\n"..
      "-----------------\n"..
      "--- WiFi Info ---\n"..
      "-----------------")
    for key, val in pairs(t.wifi) do
      print(key..":\t"..val)
    end      	
    print("")
    tmr.stop(0)		      -- Stop the WiFi connect alarm
    --print(#TEMP_COLOR_LUT)
    dofile("main.lua")  -- Run the main function
   	end
end)