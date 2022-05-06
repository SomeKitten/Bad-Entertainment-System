local util = require("./util")
local memory = {}

function memory.read(mem, addr)
    if addr < 0x2000 then
        return mem.RAM[addr]
    elseif addr < 0x4000 then
        return mem.PPU[addr - 0x2000]
    elseif addr < 0x4020 then
        return mem.IO[addr - 0x4000]
    elseif addr < 0xFFFF then
        return mem.CART[addr - 0x4020]
    else
        print("Memory read error: " .. addr)
        return 0
    end
end

function memory.write(mem, addr, val)
    if addr < 0x2000 then
        mem.RAM[addr] = val
    elseif addr < 0x4000 then
        mem.PPU[addr - 0x2000] = val
    elseif addr < 0x4020 then
        mem.IO[addr - 0x4000] = val
    elseif addr < 0xFFFF then
        mem.CART[addr - 0x4020] = val
    else
        print("Memory write error: " .. addr)
    end
end

function memory.init(mem)
    mem.RAM = {}
    mem.PPU = {}
    mem.IO = {}
    mem.CART = {}

    for i = 0, 0x1FFF do mem.RAM[i] = 0 end
    for i = 0, 0x1FFF do mem.PPU[i] = 0 end
    for i = 0, 0x1F do mem.IO[i] = 0 end
    for i = 0, 0xBFDF do mem.CART[i] = 0 end
end

return memory
