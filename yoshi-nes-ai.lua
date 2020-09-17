--[[]]--

--[[
'FIXME', 'TODO', 'CHANGED', 'XXX', 'IDEA', 'HACK', 'NOTE', 'REVIEW', 'NB', 'BUG', 'QUESTION', 'COMBAK', 'TEMP'
]]--

--[[
Ternary:
    x = a? b : c? d : e;
    equivalent:
    x = a and b or c and d or e
    ? = and
    : = or
]]--


--https://stackoverflow.com/a/15278426/12861567
function combineTables(table1, table2)
    --[[for i = 1, #t2 do
        t1[#t1 + 1] = t2[i]
    end
    return t1]]--
    for k, v in ipairs(table2) do
        table1[#table1 + 1] = v
    end
    return table1
end

--modified https://stackoverflow.com/a/22460068/12861567
function table.toString(table)
    if table then
        string = ""
        for k, v in ipairs(table) do
            string = string..v..", "
        end
        return string.sub(string, 1, #string - 2)
    else
        return ""
    end
end

--https://stackoverflow.com/a/33511182/12861567
function hasValue(table, value)
    for k, v in ipairs(table) do
        if v == value then return true end
    end
    return false
end

--based on function above, returns true if the table only has the value specified
function onlyHasValue(table, value)
    for k, v in ipairs(table) do
        if not(v == value) then
            return false
        end
    end
    return true
end

function instancesOf(table, value)
    inst = 0
    for k, v in ipairs(table) do
        if v == value then inst = inst + 1 end
    end
    return inst
end

function firstIndexOf(table, value)
    for k, v in ipairs(table) do
        if v == value then return k end
    end
    return 0
end

--TODO: would be more efficient in reverse
function indexOfLastInstanceOf(table, value)
    index = 0
    for k, v in ipairs(table) do
        if v == value then index = k end
    end
    return index
end

function tablesEqualOrder(table1, table2)
    for i = 1, #table1 do
        if not(table1[i] == table2[i]) then return false end
    end
    return true
end

--oc
function areConsecutiveNums(num1, num2)
    return num1 + 1 == num2 or num2 + 1 == num1
end

--FCEUX--

--NOTE: 0 = nothing, 1 = goomba, 2 = plant, 3 = boo, 4 = blooper, 5 = top egg, 6 = bottom egg

local board = {
    --[[top   ->  bottom]]--
    {0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0},
    {0, 0, 0, 0, 0, 0, 0, 0}
}

function getFallingPieces()
    return {memory.readbyte(0x045A), memory.readbyte(0x045B), memory.readbyte(0x045C), memory.readbyte(0x045D)}
end

function getMarioPos()
    return memory.readbyte(0x0440)
end

function getMarioOrientation()
    return memory.readbyte(0x0442)
end

function piecesHaveLanded()
    return (memory.readbyte(0x0462) < 2) and (memory.readbyte(0x0463) < 2) and (memory.readbyte(0x0464) < 2) and (memory.readbyte(0x0465) < 2)
end

function anyFallingPieces()
    return not((memory.readbyte(0x0462) == 1) or (memory.readbyte(0x0463) == 1) or (memory.readbyte(0x0464) == 1) or (memory.readbyte(0x0465) == 1))
end

--gets the first piece in a column (table) that is not empty, starting from the top
--TODO: change for loop to for each
--TODO: make all these functions just get the column themselves since i never do anything else
function getTopPiece(column)
    --[[for i = 1, 8 do
        if column[i] > 0 then
            return column[i]
        end
    end
    return 0]]--
    for k, v in ipairs(column) do
        if v > 0 then return v end
    end
    return 0
end

function doColumnsHaveMatch(piece)
    return {getTopPiece(board[1]) == piece, getTopPiece(board[2]) == piece, getTopPiece(board[3]) == piece, getTopPiece(board[4]) == piece}
end

--gets the amount of pieces in a column (table) that are not empty
--TODO: change for loop to for each
function getColumnSize(column)
    for i = 1, 8 do
        if column[i] > 0 then
            return 9 - i
        end
    end
    return 0
end

function getColumn(columnNumber)
    columnTable = {}
    for j = 1, 8 do
        columnTable[j] = memory.readbyte(0x0490 + (j - 1) + ((columnNumber - 1) * 9))
    end
    return columnTable
end

--stores every piece in the 2d table "board"
--NOTE: 8 per row
--NOTE: 2 byte spacing, figure out what they do
--NOTE: reads properly, but doesn't reload sprites.
--NOTE: Reloads for matches!! ex can force any two pieces to match by rewriting 😈
--NOTE: 0490-0497 controls column 1 top-bottom
--NOTE: 0499-04A0 controls column 2
--NOTE: 04A2-04A9 controls column 3
--NOTE: 04AB-04B2 controls column 4
function readBoard()
    for i = 1, 4 do
        --[[for j = 1, 8 do
            board[i][j] = memory.readbyte(0x0490 + (j - 1) + ((i - 1) * 9))
        end]]--
        board[i] = getColumn(i)
    end
end

--TODO: if needs to be more efficient, try to make all nums consecutive
function simplifyMoves_Table(moves)
    print("simplifying "..table.toString(moves))
    if moves then
        i = 1
        while i < #moves + 1 do
            if i < #moves and moves[i] == moves[i + 1] then --AA
                table.remove(moves, i)
                table.remove(moves, i)
                i = 1
            elseif i < #moves - 2 and moves[i] == moves[i + 2] and moves[i + 1] == moves[i + 3] and areConsecutiveNums(moves[i], moves[i + 1]) then --ABAB
                table.remove(moves, i)
                table.remove(moves, i + 2)
                i = 1
            else
                i = i + 1
            end
        end
        print("simplified to "..table.toString(moves))
        return moves
    else
        return {}
    end
end

function generateMoves_Table(goalBoard)
    print("generating moves")
    currentSimBoard = {1, 2, 3, 4}
    moves = {}
    index = 1
    while not(tablesEqualOrder(currentSimBoard, goalBoard) or index > #goalBoard) do
        simIndex = firstIndexOf(currentSimBoard, goalBoard[index])
        table.insert(currentSimBoard, index, currentSimBoard[simIndex])
        table.remove(currentSimBoard, simIndex + 1)
        for i = simIndex - 1, index, - 1 do
            moves[#moves + 1] = i - 1
        end
        print("added moves to move column "..simIndex.." to position "..index)
        print("currentSimBoard = "..table.toString(currentSimBoard))
        index = index + 1
    end
    print("done")
    return simplifyMoves_Table(moves)
end

function swapAtAllPosInTable(moves)
    if #moves > 0 then
        print("swapping at "..table.toString(moves))
        for i = 1, #moves do
            --makes sure that the columns that are being swapped aren't empty to make more efficient
            --makes sure top pieces arent the same
            --TODO: i think it's too fast for its own good...
            --TODO: yep, if one stack is taller than the other, it doesn't update in time.
            --TODO: Either find hex value that shows when they're all swapped and wait for that, or let it be stupid.
            --Letting it be stupid for now
            --if not(getTopPiece(getColumn(moves[i] + 1)) == getTopPiece(getColumn(moves[i] + 2))) then
            swapAtPos(moves[i])
            --[[else
                print("avoided looking stupid :D")
                print("didn't swap at pos "..moves[i].." because both sides are "..getTopPiece(getColumn(moves[i] + 1)))
            end]]--
        end
    end
end

--pauses for a random amount of time
function randomPause(cap)
    if not(cap) then cap = 5 end
    for i = 0, math.random(cap) do
        emu.frameadvance()
    end
end

function putMarioAtPos(pos)
    print("mario needs to move from "..getMarioPos().." to "..pos)
    if getMarioPos() > pos then
        while not(getMarioPos() == pos) do
            print("moving left")
            joypad.set(1, {left = true})
            emu.frameadvance()
            joypad.set(1, {left = false})
            emu.frameadvance()
        end
    elseif getMarioPos() < pos then
        while not(getMarioPos() == pos) do
            joypad.set(1, {right = true})
            emu.frameadvance()
            joypad.set(1, {right = false})
            emu.frameadvance()
        end
    end
    print("moved successfully")
end

function swapAtPos(pos)
    putMarioAtPos(pos)
    originalOrientation = getMarioOrientation()
    targetOrientation = originalOrientation == 0 and 4 or 0
    --TODO: remove print("going to hold A until mario orientation is not "..targetOrientation)
    --TODO: remove print("mario orientation started at "..originalOrientation)
    while getMarioOrientation() == originalOrientation do
        joypad.set(1, {A = true})
        emu.frameadvance()
        joypad.set(1, {A = false})
        emu.frameadvance()
    end
    while not(getMarioOrientation() == targetOrientation) do
        joypad.set(1, {A = false})
        emu.frameadvance()
    end
end

function moveColumn(column, targetPos)
    if column > 0 then
        --TODO: column 1 to pos 2 results in a swap position of 1 instead of 0
        --TODO: make it work for A, 5, high, 1
        print("need to move column "..column.." to position "..targetPos)
        range = targetPos - column
        sign = range / math.abs(range)
        --QUESTION: why the hell does it run when they're equal
        print("iterating from 0 to "..math.abs(range))
        if not(range == 0) then
            for i = 0, math.abs(range) - 1 do
                swapAtPos(column + (i * sign) + ((sign - 3) / 2))
            end
        end
    end
end

--places all falling pieces
--TODO: make for each loop
function placeFallingPieces()
    goalBoard = {0, 0, 0, 0}
    placedPieces = 0
    fallingPieces = getFallingPieces()
    placingOrder = {}
    --TODO: make it ignore situations where there is one match and two pieces both trying to target it
    for i = 1, 4 do
        if fallingPieces[i] == 5 then
            if hasValue(board[1], 6) or hasValue(board[2], 6) or hasValue(board[3], 6) or hasValue(board[4], 6) then
                table.insert(placingOrder, 1, i)
                print("prioritizing the top egg falling in column "..i.." because there is a bottom egg")
            else
                table.insert(placingOrder, i)
            end
        elseif fallingPieces[i] > 0 then
            if hasValue(doColumnsHaveMatch(fallingPieces[i]), true) then
                table.insert(placingOrder, 1, i)
                print("prioritizing the piece "..fallingPieces[i].."because there is a match")
            else
                --TODO: maybe placingOrder[#placingOrder + 1] = i
                table.insert(placingOrder, i)
            end
        end
    end
    print("piecesOrder="..table.toString(placingOrder))
    --TODO: literally what is the point of this
    --TODO: seems to force any top eggs to the far right for some stupid reason
    --TODO: was i high or something
    --[[if not(getTopPiece(board[1]) == 6 or getTopPiece(board[2]) == 6 or getTopPiece(board[3]) == 6 or getTopPiece(board[4]) == 6) then
        for i = 1, #fallingPieces - 1 do
            if fallingPieces[i] == 5 then
                fallingPieces[i] = fallingPieces[i + 1]
                fallingPieces[i + 1] = 5
                i = 1
            end
        end
    end]]--
    startPositions = {}
    endPositions = {}
    for i = 1, #placingOrder do
        currentPos = placingOrder[i]
        if fallingPieces[currentPos] > 0 then
            if placedPieces == 0 then
                goalBoard[currentPos] = bestPieceLocation(fallingPieces[currentPos]) --I think this is right
                endPositions[1] = currentPos
                startPositions[1] = goalBoard[currentPos]
                placedPieces = placedPieces + 1
            else
                placedPieces = placedPieces + 1
                goalBoard[currentPos] = bestPieceLocation(fallingPieces[currentPos], startPositions)
                startPositions[placedPieces] = goalBoard[currentPos]
                endPositions[placedPieces] = currentPos
            end
        end
    end
    for i = 1, 4 do
        if not hasValue(goalBoard, i) then
            for k, v in ipairs(goalBoard) do
                if v == 0 then
                    goalBoard[k] = i
                    break
                end
            end
        end
    end

    --print("want piece "..endPositions[1].." to land on column "..startPositions[1])
    --moveColumn(startPositions[1], endPositions[1])

    print("swapping pieces")
    print("start positions: "..table.toString(startPositions))
    print("end positions: "..table.toString(endPositions))
    print("goalBoard: "..table.toString(goalBoard))


    --swapAtAllPosInTable(generateMoves_Table(startPositions, endPositions))
    swapAtAllPosInTable(generateMoves_Table(goalBoard))
    while not(anyFallingPieces()) do
        emu.frameadvance()
    end

    print("sending the pieces down")
    print("---------------------------------------")

    while not(piecesHaveLanded()) do
        joypad.set(1, {down = true})
        emu.frameadvance()
    end
end

--calculates and returns the best location to place a given piece
--piece cannot be 0, avoidPos can be null.
--TODO: avoid avoidPos
--TODO: if returns 0, can go anywhere
--TODO: for each
function bestPieceLocation(piece, avoidPos)
    assert(piece > 0, "tried to place nothing")
    if not avoidPos then avoidPos = {} end
    --[[if avoidPos then
        if piece == 5 then
            biggestEggStack = 0
            biggestEggStackIndex = 0
            for i = 1, 4 do
                --check as long as it's not the avoidpos
                --if not(hasValue(avoidPos, i) then
                if not(avoidPos == i) then
                    j = 1
                    while board[i][j] == 0 and j < 9 do
                        j = j + 1
                    end
                    count = 0
                    while not(board[i][j] == 6) and j < 9 do
                        count = count + 1
                        j = j + 1
                    end
                    --TODO: seems like it could cause some sort of index oob error if it tried to call board[i][9]
                    if board[i][j] == 6 then
                        count = count + 1
                    end
                    if j == 9 and not(board[i][8] == 6) then
                        count = 0
                    end
                    print("egg stack count of column "..i..": "..count)
                    if count > biggestEggStack then
                        biggestEggStack = count
                        biggestEggStackIndex = i
                    end
                end
            end
            return biggestEggStackIndex
        else
            biggestHeight = 0
            biggestHeightIndex = -1
            for i = 1, 4 do
                --check as long as it's not the avoidpos
                if not(avoidPos == i) then
                    cs = getColumnSize(board[i])
                    if getTopPiece(board[i]) == piece and cs > biggestHeight then
                        biggestHeight = cs
                        biggestHeightIndex = i
                    end
                end
            end
            if not(biggestHeightIndex == -1) then
                return biggestHeightIndex
            end
            smallestHeight = 9
            smallestHeightIndex = 0
            for i = 1, 4 do
                --check as long as it's not the avoidpos
                if not(avoidPos == i) then
                    cs = getColumnSize(board[i])
                    --TODO: remove: print("size of column "..i..": "..cs)
                    if cs < smallestHeight then
                        smallestHeight = cs
                        smallestHeightIndex = i
                    end
                end
            end
            return smallestHeightIndex
        end
    else]]--
    if piece == 5 then
        biggestEggStack = 0
        biggestEggStackIndex = 0
        for i = 1, 4 do
            if not(hasValue(avoidPos, i)) then
                j = 1
                while board[i][j] == 0 and j < 9 do
                    j = j + 1
                end
                count = 0
                while not(board[i][j] == 6) and j < 9 do
                    count = count + 1
                    j = j + 1
                end
                --TODO: seems like it could cause some sort of index oob error if it tried to call board[i][9]
                if board[i][j] == 6 then
                    count = count + 1
                end
                if j == 9 and not(board[i][8] == 6) then
                    count = 0
                end
                print("egg stack count of column "..i..": "..count)
                if count > biggestEggStack then
                    biggestEggStack = count
                    biggestEggStackIndex = i
                end
            end
        end
        return biggestEggStackIndex
    else
        matches = doColumnsHaveMatch(piece)
        biggestHeight = 0
        biggestHeightIndex = -1
        --match pieces
        for i = 1, 4 do
            cs = getColumnSize(board[i])
            if matches[i] and cs > biggestHeight and not(hasValue(avoidPos, i)) then
                biggestHeight = cs
                biggestHeightIndex = i
            end
        end
        if not(biggestHeightIndex == -1) then
            return biggestHeightIndex
        end
        --place on shortest stack
        smallestHeight = 9
        smallestHeightIndex = 0
        oneSize = true
        firstSize = getColumnSize(getColumn(1))
        for i = 1, 4 do
            cs = getColumnSize(getColumn(i))
            --TODO: remove: print("size of column "..i..": "..cs)
            if not(hasValue(avoidPos, i)) then
                oneSize = oneSize and cs == firstSize
                if cs < smallestHeight then
                    smallestHeight = cs
                    smallestHeightIndex = i
                end
            end
        end
        if oneSize then
            print("all columns are "..firstSize.." pieces tall")
            print("going to try to drop piece on a duplicate")
            topPieces = {getTopPiece(board[1]), getTopPiece(board[2]), getTopPiece(board[3]), getTopPiece(board[4])}
            --TODO: not ==
            --TODO: prioritize bottom eggs over duplicates and make them count
            for i = 1, 4 do
                if not(hasValue(avoidPos, i)) and not(topPieces[i] == 0) and instancesOf(topPieces, topPieces[i]) > 1 then
                    print("duplicate found: "..i)
                    return i
                end
            end
            print("duplicate not found")
        end
        return smallestHeightIndex
    end
    --end
end

do
    --stuff--
    --TODO: when finished, change "off" to "on"
    settings = {"A", "1", "low", "1", "off"}

    --handle args
    if arg then
        local count = 1
        for s in arg:gmatch("([^"..", ".."]+)") do
            settings[count] = s
            count = count + 1
        end
    end

    emu.poweron()

    --starts game
    --TODO: make into a function
    --TODO: make sure selector is in the right place instead of counting frames

    randomize = settings[5] == "on"

    --while memory address 00E3 isn't C
    --  aka egg has not shown up
    while not(memory.readbyte(0x00E3) == 199) do
        emu.frameadvance()
    end
    joypad.set(1, {start = true})
    emu.frameadvance()

    --while memory address 0261 isn't C
    --  aka flashing selector has not shown up
    while not(memory.readbyte(0x0261) == 204) do
        emu.frameadvance()
    end

    if randomize then randomPause() end

    --change type to b if chosen
    if settings[1] == "B" then
        joypad.set(1, {right = true})
        emu.frameadvance()
    end

    if randomize then randomPause() end

    joypad.set(1, {down = true})
    emu.frameadvance()
    emu.frameadvance()

    --set level
    if not(settings[2] == "1") then
        --print("that is definititely not a 1, im sure of it")
        for i = 2, (tonumber(settings[2])) do
            joypad.set(1, {right = true})
            emu.frameadvance()
            emu.frameadvance()
        end
    end

    if randomize then randomPause() end

    joypad.set(1, {down = true})
    emu.frameadvance()
    emu.frameadvance()


    --change speed to high if chosen
    if settings[3] == "high" then
        joypad.set(1, {right = true})
        emu.frameadvance()
    end

    if randomize then randomPause() end

    joypad.set(1, {down = true})
    emu.frameadvance()


    --set music
    if not(settings[4] == "1") then
        for i = 2, (tonumber(settings[4])) do
            joypad.set(1, {right = true})
            emu.frameadvance()
            emu.frameadvance()
        end
    end

    if randomize then randomPause() end

    joypad.set(1, {down = true})
    emu.frameadvance()
    emu.frameadvance()

    joypad.set(1, {start = true})
    emu.frameadvance()

    --messes up with b mode apparantly
    while anyFallingPieces() do
        print("waiting")
        joypad.set(1, {down = true})
        emu.frameadvance()
    end

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
        placeFallingPieces()
        emu.frameadvance()
    end
end
