---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by cb106.
--- DateTime: 2/11/2021 19:31
---

--REQUIRES--
require "util" --utility functions
require "read_memory" --memory functions

--TODO: if needs to be more efficient, try to make all nums consecutive
function simplifyMoves_Table(moves)
    print("simplifying " .. table.toString(moves))
    local simBoard = board --TODO: does this copy values or address?
    if moves then
        local i = 1
        while i < #moves + 1 do
            local curPos = moves[i]

            if i < #moves and curPos == moves[i + 1] then
                --avoids swapping at the same position twice in a row
                table.remove(moves, i)
                table.remove(moves, i)
                i = 1
                simBoard = board --TODO: does this copy values or address?
            elseif i < #moves - 2 and curPos == moves[i + 2] and moves[i + 1] == moves[i + 3] and areConsecutiveNums(curPos, moves[i + 1]) then
                --avoids swapping in an ABAB pattern
                table.remove(moves, i)
                table.remove(moves, i + 2)
                i = 1
                simBoard = board --TODO: does this copy values or address?
            elseif tablesEqualOrder(simBoard[curPos + 1], simBoard[curPos + 2]) then
                --avoids swapping two columns if they're exactly the same
                print("didn't swap empty columns")
                table.remove(moves, i)
                i = 1
                simBoard = board --TODO: does this copy values or address?
            else -- if move is okay
                simBoard = swapTableSubTabs(simBoard, curPos + 1, curPos + 2)
                i = i + 1
            end
        end
        print("simplified to " .. table.toString(moves))
        return moves
    else
        return {}
    end
end

function generateMoves_Table(goalBoard)
    print("generating moves")
    local currentSimColPositions = { 1, 2, 3, 4 }
    local moves = {}
    local index = 1
    while not (
            tablesEqualOrder(currentSimColPositions, goalBoard) or index > #goalBoard
    ) do
        local simIndex = firstIndexOf(currentSimColPositions, goalBoard[index])
        table.insert(currentSimColPositions, index, currentSimColPositions[simIndex])
        table.remove(currentSimColPositions, simIndex + 1)
        for i = simIndex - 1, index, -1 do
            moves[#moves + 1] = i - 1
        end
        print("added moves to move column " .. simIndex .. " to position " .. index)
        print("currentSimBoard = " .. table.toString(currentSimColPositions))
        index = index + 1
    end
    print("done")
    return simplifyMoves_Table(moves)
end

function swapAtAllPosInTable(moves)
    if #moves > 0 then
        print("swapping at " .. table.toString(moves))
        for i = 1, #moves do
            --makes sure that the columns that are being swapped aren't empty to make more efficient
            --makes sure top blocks arent the same
            --TODO: i think it's too fast for its own good...
            --TODO: yep, if one stack is taller than the other, it doesn't update in time.
            --TODO: Either find hex value that shows when they're all swapped and wait for that, or let it be stupid.
            --Letting it be stupid for now
            --if not(getTopBlock(getColumn(moves[i] + 1)) == getTopBlock(getColumn(moves[i] + 2))) then

            swapAtPos(moves[i])

            --[[else
                print("avoided looking stupid :D")
                print("didn't swap at pos "..moves[i].." because both sides are "..getTopBlock(getColumn(moves[i] + 1)))
            end]] --
        end
    end
end

function putMarioAtPos(pos)
    print("mario needs to move from " .. MemMap:marioPos() .. " to " .. pos)
    if MemMap:marioPos() > pos then
        while MemMap:marioPos() ~= pos do
            print("moving left")
            joypad.set(1, { left = true })
            emu.frameadvance()
            joypad.set(1, { left = false })
            emu.frameadvance()
        end
    elseif MemMap:marioPos() < pos then
        while MemMap:marioPos() ~= pos do
            joypad.set(1, { right = true })
            emu.frameadvance()
            joypad.set(1, { right = false })
            emu.frameadvance()
        end
    end
    print("moved successfully")
end

function swapAtPos(pos)
    putMarioAtPos(pos)
    local startingFrame = MemMap:marioFrame()
    local endingFrame = startingFrame == 0 and 4 or 0
    --TODO: remove print("going to hold A until mario orientation is not "..targetOrientation)
    --TODO: remove print("mario orientation started at "..originalOrientation)
    while MemMap:marioFrame() == startingFrame do
        joypad.set(1, { A = true })
        emu.frameadvance()
        joypad.set(1, { A = false })
        emu.frameadvance()
    end
    while MemMap:marioFrame() ~= endingFrame do
        -- NOTE: says NOT EQUALS
        joypad.set(1, { A = false })
        emu.frameadvance()
    end
end

function moveColumn(column, targetPos)
    if column > 0 then
        --TODO: column 1 to pos 2 results in a swap position of 1 instead of 0
        --TODO: make it work for A, 5, high, 1
        print("need to move column " .. column .. " to position " .. targetPos)
        local range = targetPos - column
        local sign = range / math.abs(range)
        --QUESTION: why the hell does it run when they're equal
        print("iterating from 0 to " .. math.abs(range))
        if range ~= 0 then
            for i = 0, math.abs(range) - 1 do
                swapAtPos(column + (i * sign) + ((sign - 3) / 2))
            end
        end
    end
end

--places all falling blocks
--TODO: make for each loop
function placeFallingBlocks()
    local goalBoard = { 0, 0, 0, 0 }
    local placedBlocks = 0
    local fallingBlocks = MemMap:fallingBlocks()
    local placingOrder = {}
    --TODO: make it ignore situations where there is one match and two blocks both trying to target it
    for i = 1, 4 do
        if fallingBlocks[i] == Blocks.TOP_EGG then
            --TODO: should be repalced with something like "hasValue(board, Blocks.BOTTOM_EGG)"
            if hasValue(board[1], Blocks.BOTTOM_EGG) or
                    hasValue(board[2], Blocks.BOTTOM_EGG) or
                    hasValue(board[3], Blocks.BOTTOM_EGG) or
                    hasValue(board[4], Blocks.BOTTOM_EGG)
            then
                table.insert(placingOrder, 1, i)
                print("prioritizing the top egg falling in column " .. i .. " because there is a bottom egg")
            else
                table.insert(placingOrder, i)
            end
        elseif fallingBlocks[i] ~= Blocks.NONE then
            if hasValue(doColumnsHaveMatch(fallingBlocks[i]), true) then
                table.insert(placingOrder, 1, i)
                print("prioritizing the block " .. fallingBlocks[i] .. "because there is a match")
            else
                --TODO: maybe placingOrder[#placingOrder + 1] = i
                table.insert(placingOrder, i)
            end
        end
    end
    print("blocksOrder=" .. table.toString(placingOrder))
    --TODO: literally what is the point of this
    --TODO: seems to force any top eggs to the far right for some stupid reason
    --TODO: was i high or something
    --[[if not(getTopBlock(board[1]) == 6 or getTopBlock(board[2]) == 6 or getTopBlock(board[3]) == 6 or getTopBlock(board[4]) == 6) then
        for i = 1, #fallingBlocks - 1 do
            if fallingBlocks[i] == 5 then
                fallingBlocks[i] = fallingBlocks[i + 1]
                fallingBlocks[i + 1] = 5
                i = 1
            end
        end
    end]] --
    local startPositions = {}
    local endPositions = {}
    for i = 1, #placingOrder do
        local currentPos = placingOrder[i]
        if fallingBlocks[currentPos] > 0 then
            if placedBlocks == 0 then
                goalBoard[currentPos] = bestBlockLocation(fallingBlocks[currentPos]) --I think this is right
                endPositions[1] = currentPos
                startPositions[1] = goalBoard[currentPos]
                placedBlocks = placedBlocks + 1
            else
                placedBlocks = placedBlocks + 1
                goalBoard[currentPos] = bestBlockLocation(fallingBlocks[currentPos], startPositions)
                startPositions[placedBlocks] = goalBoard[currentPos]
                endPositions[placedBlocks] = currentPos
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

    --print("want block "..endPositions[1].." to land on column "..startPositions[1])
    --moveColumn(startPositions[1], endPositions[1])

    print("swapping blocks")
    print("start positions: " .. table.toString(startPositions))
    print("end positions: " .. table.toString(endPositions))
    print("goalBoard: " .. table.toString(goalBoard))


    --swapAtAllPosInTable(generateMoves_Table(startPositions, endPositions))
    swapAtAllPosInTable(generateMoves_Table(goalBoard))
    while not MemMap:areBlocksFalling() do
        emu.frameadvance()
    end

    print("sending the blocks down")
    print("---------------------------------------")

    while MemMap:areBlocksFalling() do
        joypad.set(1, { down = true })
        emu.frameadvance()
    end
end

--calculates and returns the best location to place a given block
--block cannot be 0, avoidPos can be null.
--TODO: avoid avoidPos
--TODO: if returns 0, can go anywhere
--TODO: for each
function bestBlockLocation(block, avoidPos)
    assert(block > 0, "tried to place nothing")
    if not avoidPos then
        avoidPos = {}
    end
    --[[if avoidPos then
        if block == 5 then
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
                    if getTopBlock(board[i]) == block and cs > biggestHeight then
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
    else]] --

    --TODO: change these magic numbers to Block.XXX
    if block == Blocks.TOP_EGG then
        local biggestEggStack = 0
        local biggestEggStackIndex = 0
        for i = 1, 4 do
            --TODO: what do all the 9s here mean? (and 8s, I think 8s would be 9 - 1)
            if not hasValue(avoidPos, i) then
                local j = 1
                while board[i][j] == 0 and j < 9 do
                    j = j + 1
                end
                local count = 0
                while board[i][j] ~= Blocks.BOTTOM_EGG and j < 9 do
                    count = count + 1
                    j = j + 1
                end
                --TODO: seems like it could cause some sort of index oob error if it tried to call board[i][9]
                if board[i][j] == Blocks.BOTTOM_EGG then
                    count = count + 1
                end
                if j == 9 and board[i][8] ~= Blocks.BOTTOM_EGG then
                    count = 0
                end
                print("egg stack count of column " .. i .. ": " .. count)
                if count > biggestEggStack then
                    biggestEggStack = count
                    biggestEggStackIndex = i
                end
            end
        end
        return biggestEggStackIndex
    else
        local matches = doColumnsHaveMatch(block)
        local biggestHeight = 0
        local biggestHeightIndex = -1
        --match blocks
        local colSize
        for i = 1, 4 do
            colSize = getColumnSize(board[i])
            if matches[i] and colSize > biggestHeight and not (hasValue(avoidPos, i)) then
                biggestHeight = colSize
                biggestHeightIndex = i
            end
        end
        if biggestHeightIndex ~= -1 then
            return biggestHeightIndex
        end
        --place on shortest stack
        local smallestHeight = 9
        local smallestHeightIndex = 0
        --TODO: what is oneSize?
        local oneSize = true
        local firstSize = getColumnSize(getColumn(1))
        for i = 1, 4 do
            colSize = getColumnSize(getColumn(i))
            --TODO: remove: print("size of column "..i..": "..cs)
            if not hasValue(avoidPos, i) then
                oneSize = (oneSize and colSize == firstSize)
                if colSize < smallestHeight then
                    smallestHeight = colSize
                    smallestHeightIndex = i
                end
            end
        end
        if oneSize then
            print("all columns are " .. firstSize .. " blocks tall")
            print("going to try to drop block on a duplicate")
            --TODO: this can be made small
            local topBlocks = { getTopBlock(board[1]), getTopBlock(board[2]), getTopBlock(board[3]), getTopBlock(board[4]) }
            --TODO: not ==
            --TODO: prioritize bottom eggs over duplicates and make them count
            for i = 1, 4 do
                if not (hasValue(avoidPos, i)) and topBlocks[i] ~= 0 and instancesOf(topBlocks, topBlocks[i]) > 1 then
                    print("duplicate found: " .. i)
                    return i
                end
            end
            print("duplicate not found")
        end
        return smallestHeightIndex
    end
    --end
end
