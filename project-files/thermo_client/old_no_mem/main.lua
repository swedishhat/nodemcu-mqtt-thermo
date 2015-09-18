--------------------------------
-- HARDWARE CONTROL FUNCTIONS --
--------------------------------

print(node.heap())

-- Receive MQTT temp data and parse it, then call update_led_strip().
function mqtt_temp_update(mq, pl)
  local t = {}
  if pl == "c" or pl == "f" then
    t = max31855_swspi_temp("tc", pl)
    mqtt_pub_queue(mq, "/data/temp", t.value)
    mqtt_pub_queue(mq, "/data/err", t.err)
  end
end


-- Print and publish system info like at bootup but do it whenever
function mqtt_sys_info(mq, pl)
  local info = get_sys_info()
  local err_msg = 
    "\nERROR: MQTT payload for sys_info() not a valid argument\n"..
    "Options are \"wifi\", \"sys\", or \"mqtt\"."

  if info[pl] == nil then 
    print(err_msg)
  else 
    for key, val in pairs(info[pl]) do
      mqtt_pub_queue(mq, "/status/"..MQTT_CLIENTID.."/"..pl, key..":\t"..val)
    end
  end
end


-- Sub topics to subscribe to and what functions they run
mq_dis = {
  ["/cmd/get_info/"..MQTT_CLIENTID] = mqtt_sys_info,
  ["/cmd/get_temp"] = mqtt_temp_update,
}

-- Load up the MQTT functions and variables
dofile("mqtt.lua")

function main_loop()
  print("Wait and see...")
end