console.clear()
local socket = require("socket.core")
local twitch_username = "catchthedjinn"
local twitch_password = "oauth:ec0dnvd3kgqnfrqgcwl4dv2r3b5659"
local channel_name = "xstraylite"

local twitch_conn = socket.tcp()
twitch_conn:connect("irc.chat.twitch.tv", 6667)

twitch_conn:send("PASS " .. twitch_password .. "\r\n")
twitch_conn:send("NICK " .. twitch_username .. "\r\n")
twitch_conn:send("USER " .. twitch_username .. " 8 * :" .. twitch_username .. "\r\n")
twitch_conn:send("JOIN #" .. channel_name .. "\r\n")

local function sendChatMessage(message)
  twitch_conn:send("PRIVMSG #" .. channel_name .. " :" .. message .. "\r\n")
end

local function handlePing()
  twitch_conn:send("PONG :tmi.twitch.tv\r\n")
end

sendChatMessage("Script is now active!")

local djinns = {}  -- Table to store djinn information for each user

local spriteWidth = 24  -- Width of the sprite
local function drawDjinn(x, y, face_direction, nick)
  local xOffset = face_direction < 0 and spriteWidth or 0
  local file = dofile(nick .. ".lua")
  gui.drawImage("djinns/" .. user_djinn .. ".gif", x + xOffset, y, face_direction, 24)
end

local function changeDirection(djinn)
  djinn.direction = -djinn.direction
end

local x = 50
local time = 0
local screenLength = 240 + 600
client.SetGameExtraPadding(0, 0, 710, 0)

while true do
  time = time + 1

  twitch_conn:settimeout(0.001)
  local data, status, partial = twitch_conn:receive("*l")
  if data then
    print(data)  -- Print the received message
    if data:sub(1, 4) == "PING" then
      handlePing()
      print("got pinged")
    else
      local nick = data:match(":(.+)!")
      local message = data:match("PRIVMSG #" .. channel_name .. " :(.+)")
      if nick and message then
        if not djinns[nick] then
          djinns[nick] = {
            x = x,
            baseY = 120,  -- Base y-coordinate of 150 pixels
            direction = math.random(0, 1) == 0 and -1 or 1,
            offset = math.random() * math.pi * 2,  -- Random offset for sinusoidal movement
            movementTimer = 0,
            changeDirectionTimer = 0
          }
        end
        print(nick .. ": " .. message)
      end
    end
  end

  -- Movement
  for nick, djinn in pairs(djinns) do
    -- Random direction change
    if djinn.changeDirectionTimer <= 0 then
      if djinn.movementTimer <= 0 then
        djinn.movementTimer = math.random(20, 240) -- Random duration between 1 and 4 seconds (assuming 60 frames per second)
        djinn.changeDirectionTimer = math.random(600, 1200) -- Random interval between 10 and 20 seconds (assuming 60 frames per second)
        changeDirection(djinn)
      end
    else
      djinn.changeDirectionTimer = djinn.changeDirectionTimer - 1
    end

    if djinn.movementTimer > 0 then
      djinn.x = djinn.x + djinn.direction

      -- Screen edge collision
      if djinn.x <= 0 or djinn.x >= screenLength - 1 then
        changeDirection(djinn)
      end

      djinn.movementTimer = djinn.movementTimer - 1
    end

    -- Sinusoidal movement on y-axis
    local y = math.floor(math.sin(time * 0.1 + djinn.offset) * 3) + 3 + djinn.baseY

    drawDjinn(djinn.x, y, djinn.direction * spriteWidth, nick)
  end

  emu.frameadvance()
end
