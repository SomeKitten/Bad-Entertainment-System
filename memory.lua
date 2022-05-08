local util = require("./util")
local memory = {}

function memory.init_cpu(mem)
    mem.RAM = {}
    mem.PPU = {}
    mem.IO = {}
    mem.CART = {}

    -- TODO move ppu registers to PPU_MEM
    mem.PPU_LATCH = 0

    mem.PPU_CTRL = 0
    mem.PPU_MASK = 0
    mem.PPU_STATUS = 0
    mem.PPU_OAM_ADDR = 0
    mem.PPU_OAM_DATA = 0
    mem.PPU_SCROLL = 0
    mem.PPU_ADDR = 0
    mem.PPU_DATA = 0

    for i = 0, 0x7FF do mem.RAM[i] = 0 end
    for i = 0, 0x7 do mem.PPU[i] = 0 end
    for i = 0, 0x1F do mem.IO[i] = 0 end
    for i = 0, 0xBFDF do mem.CART[i] = 0 end
end

function memory.read_cpu(mem, addr)
    if addr < 0x2000 then
        return mem.RAM[addr]
    elseif addr < 0x4000 then
        if addr == 0x2000 then
            return mem.PPU_CTRL
        elseif addr == 0x2001 then
            return mem.PPU_MASK
        elseif addr == 0x2002 then
            local val = mem.PPU_STATUS

            mem.PPU_LATCH = 0
            mem.PPU_STATUS = bit.band(mem.PPU_STATUS, 0x7F)

            return val
        elseif addr == 0x2003 then
            return mem.PPU_OAM_ADDR
        elseif addr == 0x2004 then
            return mem.PPU_OAM_DATA
        elseif addr == 0x2005 then
            return mem.PPU_SCROLL
        elseif addr == 0x2006 then
            return mem.PPU_ADDR
        elseif addr == 0x2007 then
            local val = memory.read_ppu(PPU_MEM, bit.band(mem.PPU_ADDR, 0x3FFF))

            if bit.band(mem.PPU_CTRL, 0x04) == 0 then
                mem.PPU_ADDR = mem.PPU_ADDR + 1
            else
                mem.PPU_ADDR = mem.PPU_ADDR + 32
            end

            return val
        else
            return mem.PPU[addr - 0x2000]
        end
    elseif addr < 0x4020 then
        return mem.IO[addr - 0x4000]
    elseif addr < 0xFFFF then
        return mem.CART[addr - 0x4020]
    else
        print("Memory read error (CPU): " .. addr)
        return 0
    end
end

function memory.write_cpu(mem, addr, val)
    if addr < 0x2000 then
        mem.RAM[addr] = val
    elseif addr < 0x4000 then
        -- mirroring
        addr = ((addr - 0x2000) % 0x0008) + 0x2000
        if addr == 0x2000 then
            mem.PPU_CTRL = val
        elseif addr == 0x2001 then
            mem.PPU_MASK = val
        elseif addr == 0x2002 then
            -- nothing
        elseif addr == 0x2003 then
            mem.PPU_OAM_ADDR = val
        elseif addr == 0x2004 then
            mem.PPU_OAM_DATA = val
        elseif addr == 0x2005 then
            mem.PPU_SCROLL = val
        elseif addr == 0x2006 then
            if mem.PPU_LATCH == 0 then
                mem.PPU_LATCH = 1
                mem.PPU_ADDR = bit.band(mem.PPU_ADDR, 0xFF00) + val
            else
                mem.PPU_LATCH = 0
                mem.PPU_ADDR = bit.band(mem.PPU_ADDR, 0xFF) + val * 0x100
            end
        elseif addr == 0x2007 then
            memory.write_ppu(PPU_MEM, bit.band(mem.PPU_ADDR, 0x3FFF), val)

            if bit.band(mem.PPU_CTRL, 0x04) == 0 then
                mem.PPU_ADDR = mem.PPU_ADDR + 1
            else
                mem.PPU_ADDR = mem.PPU_ADDR + 32
            end
        end
    elseif addr < 0x4020 then
        mem.IO[addr - 0x4000] = val
    elseif addr < 0xFFFF then
        mem.CART[addr - 0x4020] = val
    else
        print("Memory write error (CPU): " .. addr)
    end
end

function memory.init_ppu(mem)
    mem.PATTERNTABLE_0 = {}
    mem.PATTERNTABLE_1 = {}
    mem.NAMETABLE_0 = {}
    mem.NAMETABLE_1 = {}
    mem.NAMETABLE_2 = {}
    mem.NAMETABLE_3 = {}
    mem.PALETTE = {}
    mem.OAM = {}

    for i = 0, 0xFFF do mem.PATTERNTABLE_0[i] = 0 end
    for i = 0, 0xFFF do mem.PATTERNTABLE_1[i] = 0 end
    for i = 0, 0x3FF do mem.NAMETABLE_0[i] = 0 end
    for i = 0, 0x3FF do mem.NAMETABLE_1[i] = 0 end
    for i = 0, 0x3FF do mem.NAMETABLE_2[i] = 0 end
    for i = 0, 0x3FF do mem.NAMETABLE_3[i] = 0 end
    for i = 0, 0x1F do mem.PALETTE[i] = 0 end
    for i = 0, 0xFF do mem.OAM[i] = 0 end
end

function memory.read_ppu(mem, addr, val)
    if addr < 0x1000 then
        return mem.PATTERNTABLE_0[addr]
    elseif addr < 0x2000 then
        return mem.PATTERNTABLE_1[addr - 0x1000]
    elseif addr < 0x2400 then
        return mem.NAMETABLE_0[addr - 0x2000]
    elseif addr < 0x2800 then
        return mem.NAMETABLE_1[addr - 0x3000]
    elseif addr < 0x2C00 then
        return mem.NAMETABLE_2[addr - 0x3400]
    elseif addr < 0x3000 then
        return mem.NAMETABLE_3[addr - 0x3800]
    elseif addr < 0x3F20 then
        return mem.PALETTE[addr - 0x3C00]
    elseif addr < 0x4000 then
        return mem.OAM[addr - 0x3F00]
    else
        print("Memory read error (PPU): " .. addr)
        return 0
    end
end

function memory.write_ppu(mem, addr, val)
    print("PPU write: " .. util.hex4:format(addr) .. " = " ..
              util.hex2:format(val))

    if addr < 0x1000 then
        mem.PATTERNTABLE_0[addr] = val
    elseif addr < 0x2000 then
        mem.PATTERNTABLE_1[addr - 0x1000] = val
    elseif addr < 0x2400 then
        mem.NAMETABLE_0[addr - 0x2000] = val
    elseif addr < 0x2800 then
        mem.NAMETABLE_1[addr - 0x3000] = val
    elseif addr < 0x2C00 then
        mem.NAMETABLE_2[addr - 0x3400] = val
    elseif addr < 0x3000 then
        mem.NAMETABLE_3[addr - 0x3800] = val
    elseif addr < 0x3F20 then
        mem.PALETTE[addr - 0x3C00] = val
    elseif addr < 0x4000 then
        mem.OAM[addr - 0x3F00] = val
    else
        print("Memory write error (PPU): " .. addr)
    end
end

return memory
