-- main.lua for led strip
-- by Patrick Lloyd

--------------------------------
-- HARDWARE CONTROL FUNCTIONS --
--------------------------------
-- OoOoOoOo shiny!
ws2812.writergb(PIN_WS2812, TEMP_COLOR_LUT)

-- Determine position of relative temperature indicator
function temp_position(temp)
  -- Check if temp is in correct range. Stupid Lua trick adapted from http://lua-users.org/wiki/TernaryOperator
  -- The +0.001 is so that 'pos' never evaluates to zero during normalization
  local t = (temp > TEMP_MAX and TEMP_MAX) or (temp <= TEMP_MIN and TEMP_MIN + 0.001) or temp

  -- Normalize temp in range and scale to LED strip. It's just algebra, bruh.
  local pos = ((t - TEMP_MIN) * #TEMP_COLOR_LUT / 3.0) / (TEMP_MAX - TEMP_MIN)

  -- Round up to nearest integer
  return math.ceil(pos)
end

-- Write to the LED strip
function update_led_strip(temp, on_off)
  local err_msg = "\nERROR: On/Off argument for update_led_strip() not recognized.\nOptions are \"on\" or \"off\"."

  local str_pos_end = 3 * temp_position(temp)
  local ind_led = {["on"] = string.char(255,255,255), ["off"] = string.char(0, 0, 0)}
  --local displaced = TEMP_COLOR_LUT:sub(str_pos_end-2, str_pos_end)

  if ind_led[on_off] == nil then print(err_ms) else
    -- It doesn't toss errors if substrings are out of bounds! Holy cow!
    ws2812.writergb(PIN_WS2812, TEMP_COLOR_LUT:sub(1, str_pos_end - 3)..ind_led[on_off]..TEMP_COLOR_LUT:sub(str_pos_end + 1))
  end
end

-- Receive MQTT temp data and parse it, then call update_led_strip().
INDICATOR_ON = true
function mqtt_temp_update(mq, pl)
  local on_off = {[true] = "on", [false] = "off"}
  update_led_strip(tonumber(pl), on_off[INDICATOR_ON])
  INDICATOR_ON = not INDICATOR_ON
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
end

-- Load up the MQTT functions and variables
dofile("mqtt.lua")
