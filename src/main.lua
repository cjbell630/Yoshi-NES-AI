--[[]] --

--[[
'FIXME', 'TODO', 'CHANGED', 'XXX', 'IDEA', 'HACK', 'NOTE', 'REVIEW', 'NB', 'BUG', 'QUESTION', 'COMBAK', 'TEMP'
]] --

--[[
Ternary:
    x = a? b : c? d : e;
    equivalent:
    x = a and b or c and d or e
    ? = and
    : = or
]] --

--[[package.cpath = package.cpath .. ';D:/JetBrains/Toolbox/apps/IDEA-U/ch-0/202.7319.50.plugins/intellij-emmylua/classes/debugger/emmy/windows/x64/?.dll'
local dbg = require('emmy_core')
dbg.tcpListen('localhost', 9966)]]--

--[[    REQUIRES    ]]--
require "ai" --ai functions

--NOTE: 0 = nothing, 1 = goomba, 2 = plant, 3 = boo, 4 = blooper, 5 = top egg, 6 = bottom egg


--TODO: should this be here or in control?
--pauses for a random amount of time
function randomPause(cap)
    if not cap then
        cap = 5
    end
    for _ = 0, math.random(cap) do
        emu.frameadvance()
    end
end


--[[    MAIN BLOCK      ]]--

do
    --stuff--
    --TODO: when finished, change "off" to "on"
    local settings = { "A", "1", "low", "1", "off" }

    --handle args
    if arg then
        local count = 1
        for s in arg:gmatch("([^" .. ", " .. "]+)") do
            settings[count] = s
            count = count + 1
        end
    end

    emu.poweron()

    --starts game
    --TODO: make into a function
    --TODO: make sure selector is in the right place instead of counting frames

    local randomize = settings[5] == "on"

    --while memory address 00E3 isn't C
    --  aka egg has not shown up
    --TODO: WTF IS THIS???
    while memory.readbyte(0x00E3) ~= 199 do
        emu.frameadvance()
    end
    joypad.set(1, { start = true })
    emu.frameadvance()

    --while memory address 0261 isn't C
    --  aka flashing selector has not shown up
    --TODO: WHY DID I DO THIS???
    while memory.readbyte(0x0261) ~= 204 do
        emu.frameadvance()
    end

    if randomize then
        randomPause()
    end

    --change type to b if chosen
    if settings[1] == "B" then
        joypad.set(1, { right = true })
        emu.frameadvance()
    end

    if randomize then
        randomPause()
    end

    joypad.set(1, { down = true })
    emu.frameadvance()
    emu.frameadvance()

    --set level
    if settings[2] ~= "1" then
        --print("that is definitively not a 1, im sure of it")
        for _ = 2, (tonumber(settings[2])) do
            joypad.set(1, { right = true })
            emu.frameadvance()
            emu.frameadvance()
        end
    end

    if randomize then
        randomPause()
    end

    joypad.set(1, { down = true })
    emu.frameadvance()
    emu.frameadvance()


    --change speed to high if chosen
    if settings[3] == "high" then
        joypad.set(1, { right = true })
        emu.frameadvance()
    end

    if randomize then
        randomPause()
    end

    joypad.set(1, { down = true })
    emu.frameadvance()


    --set music
    if settings[4] ~= "1" then
        for i = 2, (tonumber(settings[4])) do
            joypad.set(1, { right = true })
            emu.frameadvance()
            emu.frameadvance()
        end
    end

    if randomize then
        randomPause()
    end

    joypad.set(1, { down = true })
    emu.frameadvance()
    emu.frameadvance()

    joypad.set(1, { start = true })
    emu.frameadvance()

    --messes up with b mode apparantly
    --TODO: this is supposed to wait until the first blocks are rendered before sending them down
    --bc of this not working, it will not try to calculate a place for the first set of blocks in B mode
    while MemMap:areBlocksFalling() do
        print("waiting")
        joypad.set(1, { down = true })
        emu.frameadvance()
    end



    --[[    MAIN LOOP   ]]--
    while true do
        --main loop
        -- overwrites to 0 when landing, overwrites to new pair when both landed
        --TODO: 051E restarts the screen??? investigate
        --0E60 is weird
        --12F0
        --NOTE: 0300 is 00 when not moving, 23 when moving
        --NOTE: 0440 stores swap position (0, 1, 2)
        --NOTE: 0442 stores orientation. 0 or 4 when not turning
        --NOTE: 0462, 0463, 0464, 0465 are 1 when about to fall, 0 when empty, and 2 when falling


        readBoard()
        placeFallingBlocks()
        emu.frameadvance()

    end
end
