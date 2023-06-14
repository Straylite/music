local djinn_emotes = {
  "VenusDjinn",
  "MercuryDjinn",
  "MarsDjinn",
  "JupiterDjinn"
}

require("settings")
console.clear()
math.randomseed(os.time()) 
local socket = require("socket.core")
local twitch_username = "kirtini"
local twitch_password = "oauth:ec0dnvd3kgqnfrqgcwl4dv2r3b5659"

local twitch_conn = socket.tcp()
twitch_conn:connect("irc.chat.twitch.tv", 6667)

twitch_conn:send("PASS " .. twitch_password .. "\r\n")
twitch_conn:send("NICK " .. twitch_username .. "\r\n")
twitch_conn:send("USER " .. twitch_username .. " 8 * :" .. twitch_username .. "\r\n")
twitch_conn:send("JOIN #" .. "kirtini" .. "\r\n")

local function sendChatMessage(message, target)
  twitch_conn:send("PRIVMSG #" .. twitch_username .. " :" .. message .. "\r\n")
end

local function reconnect_to_twitch()
  twitch_conn:connect("irc.chat.twitch.tv", 6667)

  twitch_conn:send("PASS " .. twitch_password .. "\r\n")
  twitch_conn:send("NICK " .. twitch_username .. "\r\n")
  twitch_conn:send("USER " .. twitch_username .. " 8 * :" .. twitch_username .. "\r\n")
  twitch_conn:send("JOIN #" .. "kirtini" .. "\r\n")
  sendChatMessage("Script is now active!")
end

print("Connected to Twitch chat!")
--sendChatMessage("Script is now active!")

require("ext/tables/djinn_list")
require("ext/tables/type_list")
local timer = 0
local minutes = bot_cooldown_minutes
local catch_timer = 0
local catch_state = false
local catch_time_seconds = bot_catch_time_seconds
local user_list = {}
local catch_chance = bot_catch_chance
local current_djinn = djinn_list[math.random(1,#djinn_list)]
local force = false
local switch = false

local function forceNewDjinn()
  --local emote_rng = math.random(1,4)
  current_djinn = djinn_list[math.random(1,#djinn_list)]
  sendChatMessage(djinn_emotes[type_list[current_djinn]] .. " " .. current_djinn .. " appeared! Type -fight to try your luck!")
  catch_state = true
  force = true
  catch_timer = 0
  switch = true
  for k,v in pairs(user_list) do
    user_list[k] = false
  end
end

local function forceCurrentDjinn()
  local emote_rng = math.random(1,4)
  sendChatMessage(djinn_emotes[type_list[current_djinn]] .. " " .. current_djinn .. " appeared! Type -fight to try your luck!")
  catch_state = true
  force = true
  catch_timer = 0
  switch = true
  for k,v in pairs(user_list) do
    user_list[k] = false
  end
end

local function forceCurrentDjinn_cooldown()
  local emote_rng = math.random(1,4)
  sendChatMessage(djinn_emotes[type_list[current_djinn]] .. " " .. current_djinn .. " appeared! Type -fight to try your luck!")
  catch_state = true
  force = true
  catch_timer = 0
  switch = true
  timer = 0
  for k,v in pairs(user_list) do
    user_list[k] = false
  end
end

local function forceNewDjinn_cooldown()
  local emote_rng = math.random(1,4)
  current_djinn = djinn_list[math.random(1,#djinn_list)]
  sendChatMessage(djinn_emotes[type_list[current_djinn]] .. " " .. current_djinn .. " appeared! Type -fight to try your luck!")
  catch_state = true
  force = true
  catch_timer = 0
  switch = true
  timer = 0
  for k,v in pairs(user_list) do
    user_list[k] = false
  end
end

local function cooldown()
  catch_state = false
  force = false
  catch_timer = 0
  switch = true
  timer = 1
  for k,v in pairs(user_list) do
    user_list[k] = false
  end
end

local function handlePing()
  twitch_conn:send("PONG :tmi.twitch.tv\r\n")
end

local function handleTwitchData(data)
  local nick = data:match(":(.+)!")
  local message = data:match("PRIVMSG #.+ :(.+)")

  if nick and message then
    print(nick .. ": " .. message)
  end

  if user_list[nick] == false or user_list[nick] == nil then
    local rng = math.random(1, catch_chance)
    if catch_state == true then
      if message == "-fight" then
        if rng == 1 then 
          local file = io.open("ext/users/".. nick .. ".txt", "a+")
          local content = file:read("*all")
          file:close()
          if not content:find(current_djinn .. ".") then
            file = io.open("ext/users/".. nick  .. ".txt", "a")
            file:write(current_djinn .. ". ")
            file:close()
          end
          sendChatMessage("@" .. nick .. " caught " .. current_djinn .. "!")
        else 
          sendChatMessage(current_djinn .. " ran away from @" .. nick)
        end
        user_list[nick] = true
      end
    end
  end

  if message == "-djinns" then
    function SEND_STRING(str)
      local words = {}
      for word in str:gmatch("%S+") do
        table.insert(words, word)
      end
      local numWords = #words
      local groupSize = 40
      for i = 1, numWords, groupSize do
        local group = {}
        for j = i, i + groupSize - 1 do
          if j <= numWords then
            table.insert(group, words[j])
          end
        end
        sendChatMessage(nick .. ": " .. table.concat(group, " "))
        socket.sleep(1) -- Delay for 1 second before printing the next group
      end
    end
    local file = io.open("ext/users/".. nick .. ".txt", "a+")
    if file ~= nil then
      local content = file:read("*all")
      file:close()
      local count = 0
      for _ in string.gmatch(content, "%S+") do
        count = count + 1
      end

      if count >= 1 then
        local djinn_string = djinn_emotes[math.random(1,4)] .. " You currently have " .. count ..  "/" .. #djinn_list .. " different djinns. These are: " .. content
        print(djinn_string)
        SEND_STRING(djinn_string)
      elseif count == 0 then
        sendChatMessage("Sadly you do not have any djinns yet...")
      end
    elseif file == nil then
      sendChatMessage("We couldn't find any statistics for you, " .. nick)
    end
  end
end

local function handleTwitchMessage()
  twitch_conn:settimeout(0.001)
  local data, status, partial = twitch_conn:receive("*l")
  if data then
    if data:sub(1, 4) == "PING" then
      handlePing()
      print("got pinged")
    else
      handleTwitchData(data)
    end
  end
end

local function clickButton(x, y, text, callFunction)
  local length = string.len(text)
  gui.drawBox(x, y, x + length * 4 + 2, y + 8, "white", "black")
  gui.pixelText(x + 1, y + 1, text, "white", 0x00000000)
  local mouse = input.getmouse()
  local keybutton = input.get()
  if not mouse["Left"] and keybutton["Ctrl"] then switch = false end
  if mouse["X"] >= x and mouse["X"] <= x + length * 4 + 2 and mouse["Y"] >= y and mouse["Y"] <= y + 8 then
    if mouse["Left"] and keybutton["Ctrl"] and switch == false then
      callFunction()
      switch = true
    end
  end
end

while true do
  local emote_rng = math.random(1,4)

  handleTwitchMessage()

  if force == false then
    timer = timer + 1
  end

  gui.drawBox(0, 0, 500, 500, "black", "black")
  gui.pixelText(0, 0, "Cooldown: " .. timer .. " / " .. (60 * 60) * minutes)
  gui.pixelText(0, 10, "Catch Time: " .. catch_timer .. " / " .. 60 * catch_time_seconds)
  gui.pixelText(0, 20, "Catch State: " .. tostring(catch_state))
  gui.pixelText(0, 30, "Current Djinn: " .. tostring(current_djinn))
  gui.pixelText(0, 40, "Force: " .. tostring(force))

  if timer >= (60 * 60) * minutes then
    timer = 0
    current_djinn = djinn_list[math.random(1, #djinn_list)]
    sendChatMessage(djinn_emotes[type_list[current_djinn]] .. " " .. current_djinn .. " appeared! Type -fight to try your luck!")
    catch_state = true
  end
  if catch_state == true then
    catch_timer = catch_timer + 1
    if catch_timer >= 60 * catch_time_seconds then
      catch_state = false
      catch_timer = 0
      sendChatMessage("Time to catch the djinn passed.")
      for k, v in pairs(user_list) do
        user_list[k] = false
      end
      force = false
    end
  end

  clickButton(0, 50, "Force Current Djinn", forceCurrentDjinn)
  clickButton(0, 60, "Force Current Djinn and Reset Cooldown", forceCurrentDjinn_cooldown)
  clickButton(0, 70, "Force New Djinn", forceNewDjinn)
  clickButton(0, 80, "Force New Djinn and Reset Cooldown", forceNewDjinn_cooldown)
  clickButton(0, 90, "Reset Cooldown", cooldown)

  emu.frameadvance()
end
