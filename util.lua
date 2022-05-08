local util = {}

util.hex1 = "%01X"
util.hex2 = "%02X"
util.hex4 = "%04X"
util.oct3 = "%03o"

util.file_to_bytes = function(file, byte_array, file_start, arr_start, len)
    local byte = file:read(1)
    local i = -file_start
    while byte do
        if i >= 0 then byte_array[arr_start + i] = byte:byte() end

        byte = file:read(1)
        i = i + 1

        if len ~= 0 and i >= len then break end
    end
end

function print(text)
    local file = io.open("debug.log", "a+")

    file:write(text ~= nil and (tostring(text) .. "\n") or "nil\n")

    file:close()
end

function io.write(text)
    local file = io.open("debug.log", "a+")

    file:write(text ~= nil and tostring(text) or "nil")

    file:close()
end

function util.to_bits(n)
    local t = {}
    for i = 1, 32 do
        n = bit.rol(n, 1)
        if i > 16 then table.insert(t, bit.band(n, 1)) end
    end
    return table.concat(t)
end

function util.to_signed(unsigned, size)
    local max = bit.lshift(1, size)

    return util.wrap(unsigned, -max / 2, max / 2 - 1)
end

function util.wrap(value, min, max)
    if value < min then return max - (min - value - 1) end
    if value > max then return min + (value - max - 1) end
    return value
end

function util.set_bit(value, b, i)
    b = bit.lshift(b, i)
    value = bit.bor(bit.band(value, bit.bnot(bit.lshift(1, i))), b)

    return value
end

function util.get_bit(value, i)
    return bit.rshift(bit.band(value, bit.lshift(1, i)), i)
end

return util
