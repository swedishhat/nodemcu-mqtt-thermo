--------------------
-- MQTT SEMAPHORE --
--------------------
-- Hear 
-- me dear,
-- Dare I ask you for
-- a way to write a semaphore
-- to queue a table with topics thus
-- and reduce thy table to digital dust?
-- For time to make a required action
-- delays a timely satisfaction.
-- But as much as the thought
-- of this bothers me ought,
-- I cannot avoid it
-- one little bit.
-- Need a queue?
-- I do.

-- These maintain the queues for publish and subscribe topics
sub_list = {}
pub_list = {}


-- Builds a queue for topic subscription. Fill it as fast as you want but it
-- will go through each item at a fixed time specified by MQTT_CMDTIME_MS
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
function mqtt_pub_queue(client, topic, message)
  table.insert(pub_list, {
    ["client"] = client,
    ["topic"] = topic,
    ["message"] = message
  })
  
  tmr.alarm(2, MQTT_CMDTIME_MS, 1, function()
    if #pub_list > 0 then
      pub_list[1].client:publish(pub_list[1].topic, pub_list[1].message, 0, 0,
        function()
          --print("Published \""..pub_list[1].message.."\" to "..pub_list[1].topic)
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

-- Initialize mqtt client with keepalive timer of 60sec. No password? I too
-- like to live dangerously...
mq = mqtt.Client(MQTT_CLIENTID, 60, "", "")

-- Set up Last Will and Testament (optional)
-- Broker will publish a message with qos = 0, retain = 0, data = "offline"
-- to topic "/lwt" if client don't send keepalive packet
mq:lwt("/lwt", "Oh noes! Plz! I don't wanna die!", 0, 0)

-- When client connects, print status message and subscribe to cmd topic
mq:on("connect", function(mq) 
  local info = get_sys_info()
  local topics = {[1]="/cmd/#"}
  
  -- Serial status message
  print("\n"..
  "-----------------\n"..
  "--- MQTT Info ---\n"..
  "-----------------")
  for key, val in pairs(info.mqtt) do
    print(key..":\t"..val)
  end


  -- Subscribe to the topics where NodeMCU will get commands from. The
  -- stupid alarm loop is necessary so that we can wait for the MQTT command
  -- to fully finish before running the next one. 500 ms seemed to work okay
  for i = 1, #topics do
    mqtt_sub_queue(mq, topics[i])
  end  
  
  print("")
  main_loop()

end)


-- When client disconnects, print a message and list space left on stack
mq:on("offline", function()
  print ("\nDisconnected from broker")
  print("Heap:\t"..node.heap().."\n")
end)


-- On a publish message receive event, run the message dispatcher and
-- interpret the command
mq:on("message", function(mq,t,pl)
  -- This is like client.message_callback_add() in the Paho python client.
  -- It allows different functions to be run based on the message topic
  if pl ~= nil and mq_dis[t] ~= nil then
    mq_dis[t](mq, pl)
  end
end)


-- Connect to the broker
mq:connect(MQTT_HOST, MQTT_PORT, 0, 1)