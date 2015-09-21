-- mqtt.lua for thermometer
-- by Patrick Lloyd

--------------------
-- MQTT SEMAPHORE --
--------------------
-- Brevity is the soul of wit. I should write shorter poems...
--print("Hear\nme dear,\ndare I ask you for\na way to write a semaphore\nto queue a table with topics thus\n"..
--"and reduce thy table to digital dust?\nFor time to make a required action\ndelays a timely satisfaction.\n"..
--"But as much as the thought\nof this bothers me ought,\nI cannot avoid it\none little bit.\nNeed a queue?\n"..
--"I do.")

-- These maintain the queues for publish and subscribe topics

-- Builds a queue for topic subscription. Fill it as fast as you want but it
-- will go through each item at a fixed time specified by MQTT_CMDTIME_MS
sub_list = {}
function mqtt_sub_queue(client, topic)
  table.insert(sub_list, {["client"] = client, ["topic"] = topic})
  
  tmr.alarm(1, MQTT_CMDTIME_MS, 1, function()
    if #sub_list > 0 then
      sub_list[1].client:subscribe(sub_list[1].topic, 0, function()
        print("Subscribed to "..sub_list[1].topic)
        table.remove(sub_list, 1)
      end)
    else
      tmr.stop(1)
    end
  end)
end


-- Builds a queue for topic publishing. Fill it as fast as you want but it
-- will go through each item at a fixed time specified by MQTT_CMDTIME_MS
pub_list = {}
function mqtt_pub_queue(client, topic, message)
  table.insert(pub_list, {["client"] = client, ["topic"] = topic, ["message"] = message})
  
  tmr.alarm(2, MQTT_CMDTIME_MS, 1, function()
    if #pub_list > 0 then
      pub_list[1].client:publish(pub_list[1].topic, pub_list[1].message, 0, 0,
        function()
          print("Published \""..pub_list[1].message.."\" to "..pub_list[1].topic)
          table.remove(pub_list, 1)
        end)
    else
      tmr.stop(2)
    end
  end)
end


----------------------------
-- MQTT SETUP AND CONNECT --
----------------------------
MQTT_SUBS = {["/cmd/get_info/"..MQTT_CLIENTID] = mqtt_sys_info}

-- Initialize mqtt client with keepalive timer of 60sec. No password? I too
-- like to live dangerously...
mq = mqtt.Client(MQTT_CLIENTID, 60, "", "")

-- Set up Last Will and Testament (optional)
mq:lwt("/lwt", "Oh noes! Plz! I don't wanna die!", 0, 0)

-- When client connects, print status message and subscribe to cmd topic
mq:on("connect", function(mq) 
  
  -- Serial status message
  print("---- MQTT Info ----")  
  for key, val in pairs(sys_info.mqtt) do print(key..":\t"..val) end

  -- Subscribe to NodeMCU topics using semaphore stuff above
  for i,_ in pairs(MQTT_SUBS) do mqtt_sub_queue(mq, i) end  
  
  print("")
  main_loop()

end)


-- When client disconnects, print a message and list space left on stack
mq:on("offline", function()
  print ("\nDisconnected from broker")
  print("Heap:\t"..node.heap().."\n")
end)


-- On a publish message receive event, run the message dispatcher and interpret the command
mq:on("message", function(mq,t,pl)
  -- It allows different functions to be run based on the message topic
  if pl ~= nil and MQTT_SUBS[t] ~= nil then MQTT_SUBS[t](mq, pl) end
end)

-- Connect to the broker
mq:connect(MQTT_HOST, MQTT_PORT, 0, 1)