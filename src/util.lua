

---Concatenates two tables. (adds second table onto end of first table)
---https://stackoverflow.com/a/15278426/12861567
---@param table1 table first table
---@param table2 table second table
---@return table the two tables concatenated together
function concatTables(table1, table2)
    --[[for i = 1, #t2 do
        t1[#t1 + 1] = t2[i]
    end
    return t1]] --
    for _, v in ipairs(table2) do
        table1[#table1 + 1] = v
    end
    return table1
end

---Creates a string out of a table.
---Modified from https://stackoverflow.com/a/22460068/12861567
---@param table table the table to make a string out of
---@return string the table represented as a string
function table.toString(table)
    --TODO: maybe shouldnt be table.toString bc that's not right
    if table then
        local tabString = ""
        for k, v in ipairs(table) do
            tabString = tabString .. v .. ", "
        end
        return string.sub(tabString, 1, #tabString - 2)
    else
        return ""
    end
end

---Checks if the given table contains the given value.
---from: https://stackoverflow.com/a/33511182/12861567
---@param table table<any> the table to check
---@param value any the value to look for
---@return boolean true if the value is found, false if not
function hasValue(table, value)
    for _, v in ipairs(table) do
        if v == value then
            return true
        end
    end
    return false
end

---Checks if the every value in the given table equals the given value.
---based on hasValue
---@param table table<any> the table to check
---@param value any the value to look for
---@return boolean true if only the value is found, false if not
function onlyHasValue(table, value)
    for _, v in ipairs(table) do
        if not (v == value) then
            return false
        end
    end
    return true
end

---Counts the number of times the given value is present in the given table.
---@param table table<any> the table to check
---@param value any the value to look for
---@return number the number of instances of the value found in the table
function instancesOf(table, value)
    inst = 0
    for _, v in ipairs(table) do
        if v == value then
            inst = inst + 1
        end
    end
    return inst
end

---Finds and returns the first index of the given value in the given table.
---@param table table<any> the table to check
---@param value any the value to look for
---@return number the first index of the value in the table
function firstIndexOf(table, value)
    for k, v in ipairs(table) do
        if v == value then
            return k
        end
    end
    return 0
end

--TODO: this function doesnt even do what it's supposed to, but even if it did, it's not even used
function indexOfLastInstanceOf(table, value)
    --TODO: would be more efficient in reverse
    for k, v in ipairs(table) do
        if v == value then
            return k
        end
    end
    return 0
end

function tablesEqualOrder(table1, table2)
    for i = 1, #table1 do
        if not (table1[i] == table2[i]) then
            return false
        end
    end
    return true
end

--oc
function areConsecutiveNums(num1, num2)
    --same as (num1 + 1 == num2) or (num1 - 1 == num2)
    return (num1 + 1 == num2) or (num2 + 1 == num1)
end

--TODO doc
--TODO: if they were passed as params, then I modified the table, would it modify the og value?
function swapTableSubTabs(table, index1, index2)
    local temp = table[index1]
    table[index1] = table[index2]
    table[index2] = temp
    return table
end