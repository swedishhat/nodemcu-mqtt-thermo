-- main.lua for thermometer
-- by Patrick Lloyd

--------------------------------
-- HARDWARE CONTROL FUNCTIONS --
--------------------------------

-- Bit-bang SPI bus to update 'raw' table
reading_bus = false

function _read32()
  local raw = {}

  -- Setting this flag allows functions to wait for data in a blocking loop
  reading_bus = true
  
  -- Select chip and give it a microsecond to become active
  gpio.write(PIN_CS, gpio.LOW)
  tmr.delay(1)

  -- Cycle clock and read bus data into 'raw' 32 times
  for i = 1, 32 do
    gpio.write(PIN_SCK, gpio.HIGH)
    raw[i] = gpio.read(PIN_MISO)
    gpio.write(PIN_SCK, gpio.LOW)
    tmr.delay(1)
  end
  
  -- Deselect chip, wait 1 us, clear "busy" flag
  gpio.write(PIN_CS, gpio.HIGH)
  tmr.delay(1)
  reading_bus = false

  return raw
end


-- Decodes temperature values either for TC or reference junction depending on the bit width
function _temp_decode(bin_value)
  
  -- Ignore sign bit for now and convert to decimal number
  local temp_c = tonumber(string.sub(bin_value, 2), 2)
  
  -- Heed the sign bit! 
  if string.sub(bin_value, 1, 1) == 1 then
    temp_c = temp_c * -1
  end

  -- Differentiate between TC or RJ and scale appropriately
  if #bin_value == 14 then
    temp_c = temp_c * 0.25
  elseif #bin_value == 12 then
    temp_c = temp_c * 0.0625
  end

  return temp_c
end


-- Return a table with floating point temperature values and the error bits
-- Sometimes you will get ridiculous (yet legal) temperature values when
-- certain errors happen. This puts error checking responsibility on the
-- receiving system, if it cares about such things.
function mqtt_update_temp(mq)
  -- Update 'raw' data and wait for it to finish
  local data = _read32()
  while reading_bus do end

  -- Make sure the argument is legal
  --err_msg = "\nERROR: Device argument for max31855_swspi.temp() not recognized.\nOptions are \"tc\" for thermocouple or \"rj\" for Reference Junction.")
  mqtt_pub_queue(mq, "/data/temp/rj", _temp_decode(table.concat(data, "", 17, 28)))
  mqtt_pub_queue(mq, "/data/temp/tc", _temp_decode(table.concat(data, "", 1, 14)))
  mqtt_pub_queue(mq, "/data/temp/err", table.concat(data, "", 30, 32))
end




-- Print and publish system info like at bootup but do it whenever
function mqtt_sys_info(mq, pl)
  get_sys_info()
  local err_msg = "\nERROR: MQTT payload for mqtt_sys_info() not a valid argument\nOptions are \"wifi\", \"sys\", or \"mqtt\"."

  if sys_info[pl] == nil then print(err_msg) else 
    for key, val in pairs(sys_info[pl]) do mqtt_pub_queue(mq, "/status/"..MQTT_CLIENTID.."/"..pl, key..":\t"..val) end
  end
end


function main_loop()
  tmr.alarm(5, 5000, 1, function() mqtt_update_temp(mq) end)
end

-- Load up the MQTT functions and variables
dofile("mqtt.lua")
