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
    mem.PPU_NAMETABLE = 0
    mem.PPU_INCREMENT = 0
    mem.PPU_SPRITE_ADDR = 0
    mem.PPU_BACKGROUND = 0
    mem.PPU_SPRITE_SIZE = 0
    mem.PPU_NMI = 0

    mem.PPU_MASK = 0
    mem.PPU_STATUS = 0
    mem.PPU_SCROLL = 0
    mem.PPU_ADDR = 0
    mem.PPU_DATA = 0

    mem.mapper = {}

    mem.mapper.CART_SHIFT = 0
    mem.mapper.CART_SHIFT_COUNTER = 0

    mem.mapper.PRG_MODE = 0
    mem.mapper.CHR_BANK_0 = 0
    mem.mapper.CHR_BANK_1 = 0
    mem.mapper.PRG_BANK = 0

    for i = 0, 0x7FF do mem.RAM[i] = 0 end
    for i = 0, 0x7 do mem.PPU[i] = 0 end
    for i = 0, 0x1F do mem.IO[i] = 0 end
    for i = 0, 0xBFDF do mem.CART[i] = 0 end
end

function memory.read_cpu(mem, addr)
    if mem == nil then error("'mem' passsed to memory.read_cpu is nil") end
    if addr == nil then error("'addr' passsed to memory.read_cpu is nil") end

    local ret = memory.read_cpu_inner(mem, addr)

    if ret == nil then
        error("The value read from CPU addr " .. util.hex4:format(addr) ..
                  " is nil")
    end

    return ret
end

function memory.read_cpu_inner(mem, addr)
    if addr < 0x2000 then
        addr = bit.band(addr, 0x07FF)
        return mem.RAM[addr]
    elseif addr < 0x4000 then
        -- mirroring
        addr = (addr % 0x0008) + 0x2000
        if addr == 0x2000 then
            return mem.PPU_CTRL
        elseif addr == 0x2001 then
            return mem.PPU_MASK
        elseif addr == 0x2002 then
            -- print("READING PPU_STATUS")

            local val = mem.PPU_STATUS

            mem.PPU_LATCH = 1
            mem.PPU_STATUS = bit.band(mem.PPU_STATUS, 0x7F)

            -- print("READING STATUS: " .. util.hex2:format(val))

            return val
        elseif addr == 0x2003 then
            -- print("READ OAM_ADDR: " .. mem.PPU_OAM_ADDR)

            return mem.PPU_OAM_ADDR
        elseif addr == 0x2004 then
            return PPU_MEM.OAM[mem.PPU_OAM_ADDR]
        elseif addr == 0x2005 then
            return mem.PPU_SCROLL
        elseif addr == 0x2006 then
            return mem.PPU_ADDR
        elseif addr == 0x2007 then
            local val = memory.read_ppu(PPU_MEM, bit.band(mem.PPU_ADDR, 0x3FFF))

            if mem.PPU_INCREMENT == 0 then
                mem.PPU_ADDR = mem.PPU_ADDR + 1
            else
                mem.PPU_ADDR = mem.PPU_ADDR + 32
            end

            return val
        else
            print("Memory read error (CPU): " .. util.hex4:format(addr))
        end
    elseif addr < 0x4020 then
        if addr == 0x4016 then
            -- print("CONTROLLER READ")

            local val = CONTROLLER[CONTROLLER_SHIFT]
            CONTROLLER_SHIFT = CONTROLLER_SHIFT + 1

            if not val then return 1 end
            return val
        else
            return mem.IO[addr - 0x4000]
        end
    elseif addr <= 0xFFFF then
        if MAPPER == 1 then
            if addr >= 0x8000 then
                if mem.mapper.PRG_MODE <= 1 then
                    return FULL_ROM[0x2000 * mem.mapper.PRG_BANK +
                               bit.band(addr, 0x7FFF)]
                end
                if addr < 0xC000 then
                    if mem.mapper.PRG_MODE == 2 then
                        return FULL_ROM[bit.band(addr, 0x1FFF)]
                    else
                        return FULL_ROM[0x2000 * mem.mapper.PRG_BANK +
                                   bit.band(addr, 0x3FFF)]
                    end
                else
                    if mem.mapper.PRG_MODE == 3 then
                        return FULL_ROM[0x2000 * (PRG_BANKS - 1) +
                                   bit.band(addr, 0x3FFF)]
                    else
                        return FULL_ROM[0x2000 * mem.mapper.PRG_BANK +
                                   bit.band(addr, 0x3FFF)]
                    end
                end
            end

            print("PRG RAM NOT IMPLEMENTED")
            return 0
        else
            return mem.CART[addr - 0x4020]
        end
    else
        print("Memory read error (CPU): " .. util.hex4:format(addr))
        return 0
    end
end

function memory.write_cpu(mem, addr, val)
    if addr < 0x2000 then
        addr = bit.band(addr, 0x07FF)
        mem.RAM[addr] = val
    elseif addr < 0x4000 then
        -- mirroring
        addr = (addr % 0x0008) + 0x2000
        if addr == 0x2000 then
            mem.PPU_CTRL = val

            mem.PPU_NAMETABLE = bit.band(val, 0x03)
            mem.PPU_INCREMENT = bit.band(val, 0x04) / 0x04
            mem.PPU_SPRITE_ADDR = bit.band(val, 0x08) / 0x08
            mem.PPU_BACKGROUND = bit.band(val, 0x10) / 0x10
            mem.PPU_SPRITE_SIZE = bit.band(val, 0x20) / 0x20
            mem.PPU_NMI = bit.band(val, 0x80) / 0x80

            mem.PPU_STATUS = bit.band(mem.PPU_STATUS, 0xE0) +
                                 bit.band(val, 0x1F)
        elseif addr == 0x2001 then
            mem.PPU_MASK = val

            mem.PPU_STATUS = bit.band(mem.PPU_STATUS, 0xE0) +
                                 bit.band(val, 0x1F)
        elseif addr == 0x2002 then
            -- nothing
        elseif addr == 0x2003 then
            -- print("WRITE OAM_ADDR: " .. val)

            mem.PPU_OAM_ADDR = val

            mem.PPU_STATUS = bit.band(mem.PPU_STATUS, 0xE0) +
                                 bit.band(val, 0x1F)
        elseif addr == 0x2004 then
            PPU_MEM.OAM[mem.PPU_OAM_ADDR] = val

            mem.PPU_OAM_ADDR = mem.PPU_OAM_ADDR + 1

            mem.PPU_STATUS = bit.band(mem.PPU_STATUS, 0xE0) +
                                 bit.band(val, 0x1F)
        elseif addr == 0x2005 then
            mem.PPU_SCROLL = val

            mem.PPU_STATUS = bit.band(mem.PPU_STATUS, 0xE0) +
                                 bit.band(val, 0x1F)
        elseif addr == 0x2006 then
            -- print("WRITING TO PPU_ADDR: " .. util.hex2:format(val))

            if mem.PPU_LATCH == 1 then
                mem.PPU_LATCH = 0
                mem._PPU_ADDR = bit.band(val, 0x3F)
            else
                mem.PPU_LATCH = 1
                mem.PPU_ADDR = mem._PPU_ADDR * 0x100 + val
            end

            mem.PPU_STATUS = bit.band(mem.PPU_STATUS, 0xE0) +
                                 bit.band(val, 0x1F)

            -- print("PPU_ADDR: " .. util.hex4:format(mem.PPU_ADDR))
        elseif addr == 0x2007 then
            -- print("PPU write to: " .. util.hex4:format(mem.PPU_ADDR))
            memory.write_ppu(PPU_MEM, bit.band(mem.PPU_ADDR, 0x3FFF), val)

            if mem.PPU_INCREMENT == 0 then
                mem.PPU_ADDR = mem.PPU_ADDR + 1
            else
                mem.PPU_ADDR = mem.PPU_ADDR + 32
            end

            mem.PPU_STATUS = bit.band(mem.PPU_STATUS, 0xE0) +
                                 bit.band(val, 0x1F)
        end
    elseif addr < 0x4020 then
        if addr == 0x4014 then
            -- print("OAM DMA: " .. util.hex2:format(val))
            for i = 0, 255 do
                PPU_MEM.OAM[(i + mem.PPU_OAM_ADDR) % 256] =
                    memory.read_cpu(mem, val * 0x100 + i)
            end
        elseif addr == 0x4016 then
            CONTROLLER_POLL = val % 2
        else
            mem.IO[addr - 0x4000] = val
        end
    elseif addr <= 0xFFFF then
        if MAPPER == 1 and addr >= 0x8000 then
            if val >= 0x80 then
                mem.mapper.CART_SHIFT = 0
                mem.mapper.CART_SHIFT_COUNTER = 0
            else
                mem.mapper.CART_SHIFT_COUNTER =
                    mem.mapper.CART_SHIFT_COUNTER + 1
                mem.mapper.CART_SHIFT = bit.rshift(mem.mapper.CART_SHIFT, 1) +
                                            bit.band(val, 1) * 16

                if mem.mapper.CART_SHIFT_COUNTER == 5 then
                    mem.mapper.CART_SHIFT_COUNTER = 0

                    if addr < 0xA000 then
                        mem.mapper.CONTROL = mem.mapper.CART_SHIFT
                        mem.mapper.PRG_MODE =
                            bit.band(mem.mapper.CONTROL, 0x0C) / 0x04
                        mem.mapper.CHR_MODE = bit.rshift(mem.mapper.CONTROL, 4)
                    elseif addr < 0xC000 then
                        mem.mapper.CHR_BANK_0 = mem.mapper.CART_SHIFT
                    elseif addr < 0xE000 then
                        mem.mapper.CHR_BANK_1 = mem.mapper.CART_SHIFT
                    else
                        mem.mapper.PRG_BANK = mem.mapper.CART_SHIFT
                    end

                    mem.mapper.CART_SHIFT = 0
                end
            end
        else
            mem.CART[addr - 0x4020] = val
        end
    else
        print("Memory write error (CPU): " .. util.hex4:format(addr))
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

    mem.PALETTE.UBGP = 0x0F

    mem.PALETTE.BGP0 = {}
    mem.PALETTE.BGP1 = {}
    mem.PALETTE.BGP2 = {}
    mem.PALETTE.BGP3 = {}

    mem.PALETTE.SPP0 = {}
    mem.PALETTE.SPP1 = {}
    mem.PALETTE.SPP2 = {}
    mem.PALETTE.SPP3 = {}

    for i = 0, 0xFFF do mem.PATTERNTABLE_0[i] = 0 end
    for i = 0, 0xFFF do mem.PATTERNTABLE_1[i] = 0 end
    for i = 0, 0x3FF do mem.NAMETABLE_0[i] = 0 end
    for i = 0, 0x3FF do mem.NAMETABLE_1[i] = 0 end
    for i = 0, 0x3FF do mem.NAMETABLE_2[i] = 0 end
    for i = 0, 0x3FF do mem.NAMETABLE_3[i] = 0 end
    for i = 0, 0x1F do mem.PALETTE[i] = 0 end
    for i = 0, 0xFF do mem.OAM[i] = 0 end

    for i = -1, 2 do
        mem.PALETTE.BGP0[i] = 0x0F
        mem.PALETTE.BGP1[i] = 0x0F
        mem.PALETTE.BGP2[i] = 0x0F
        mem.PALETTE.BGP3[i] = 0x0F

        mem.PALETTE.SPP0[i] = 0x0F
        mem.PALETTE.SPP1[i] = 0x0F
        mem.PALETTE.SPP2[i] = 0x0F
        mem.PALETTE.SPP3[i] = 0x0F
    end
end

function memory.read_ppu(mem, addr)
    if mem == nil then error("'mem' passsed to memory.read_ppu is nil") end
    if addr == nil then error("'addr' passsed to memory.read_ppu is nil") end

    local ret = memory.read_ppu_inner(mem, addr)

    if ret == nil then
        error("The value read from PPU addr " .. util.hex4:format(addr) ..
                  " is nil")
    end

    return ret
end

function memory.read_ppu_inner(mem, addr)
    if addr < 0x1000 then
        if MAPPER == 0 then
            return mem.PATTERNTABLE_0[addr]
        else
            print(mem["CHR_BANK_" .. CPU_MEM.mapper.CHR_BANK_0])
            return mem["CHR_BANK_" .. CPU_MEM.mapper.CHR_BANK_0][addr]
        end
    elseif addr < 0x2000 then
        if MAPPER == 0 then
            return mem.PATTERNTABLE_1[addr - 0x1000]
        else
            return mem["CHR_BANK_" .. CPU_MEM.mapper.CHR_BANK_1][addr - 0x1000]
        end
    elseif addr < 0x2400 then
        return mem.NAMETABLE_0[addr - 0x2000]
    elseif addr < 0x2800 then
        return mem.NAMETABLE_1[addr - 0x3000]
    elseif addr < 0x2C00 then
        return mem.NAMETABLE_2[addr - 0x3400]
    elseif addr < 0x3000 then
        return mem.NAMETABLE_3[addr - 0x3800]
    elseif addr < 0x4000 then
        addr = addr % 0x20 + 0x3F00

        if addr == 0x3F04 or addr == 0x3F08 or addr == 0x3F0C then
            return mem.PALETTE[addr - 0x3F00]
        end

        if addr == 0x3F10 or addr == 0x3F14 or addr == 0x3F18 or addr == 0x3F1C then
            addr = addr - 0x10
        end

        if addr == 0x3F00 then
            return mem.PALETTE.UBGP
        elseif addr < 0x3F04 then
            return mem.PALETTE.BGP0[addr - 0x3F01]
        elseif addr < 0x3F08 then
            return mem.PALETTE.BGP1[addr - 0x3F05]
        elseif addr < 0x3F0C then
            return mem.PALETTE.BGP2[addr - 0x3F09]
        elseif addr < 0x3F10 then
            return mem.PALETTE.BGP3[addr - 0x3F0D]
        elseif addr < 0x3F14 then
            return mem.PALETTE.SPP0[addr - 0x3F11]
        elseif addr < 0x3F18 then
            return mem.PALETTE.SPP1[addr - 0x3F15]
        elseif addr < 0x3F1C then
            return mem.PALETTE.SPP2[addr - 0x3F19]
        else
            return mem.PALETTE.SPP3[addr - 0x3F1D]
        end
    else
        print("Memory read error (PPU): " .. util.hex4:format(addr))
        return 0
    end
end

function memory.write_ppu(mem, addr, val)
    -- print("PPU write: " .. util.hex4:format(addr) .. " = " ..
    --           util.hex2:format(val))

    if addr < 0x1000 then
        if MAPPER == 0 then
            mem.PATTERNTABLE_0[addr] = val
        else
            print(mem["CHR_BANK_" .. CPU_MEM.mapper.CHR_BANK_0])
            mem["CHR_BANK_" .. CPU_MEM.mapper.CHR_BANK_0][addr] = val
        end
    elseif addr < 0x2000 then
        if MAPPER == 0 then
            mem.PATTERNTABLE_1[addr - 0x1000] = val
        else
            mem["CHR_BANK_" .. CPU_MEM.mapper.CHR_BANK_1][addr - 0x1000] = val
        end
    elseif addr < 0x2400 then
        mem.NAMETABLE_0[addr - 0x2000] = val
    elseif addr < 0x2800 then
        mem.NAMETABLE_1[addr - 0x3000] = val
    elseif addr < 0x2C00 then
        mem.NAMETABLE_2[addr - 0x3400] = val
    elseif addr < 0x3000 then
        mem.NAMETABLE_3[addr - 0x3800] = val
    elseif addr < 0x4000 then
        print("Writing " .. util.hex2:format(val) .. " to PALETTE addr: " ..
                  util.hex4:format(addr))

        addr = addr % 0x20 + 0x3F00

        if addr == 0x3F04 or addr == 0x3F08 or addr == 0x3F0C then
            mem.PALETTE[addr - 0x3F00] = val
            return
        end

        if addr == 0x3F10 or addr == 0x3F14 or addr == 0x3F18 or addr == 0x3F1C then
            addr = addr - 0x10
        end

        -- print("WRITING TO PALETTE AT " .. util.hex4:format(addr) .. ": " ..
        --           util.hex2:format(val))

        if addr == 0x3F00 then
            mem.PALETTE.UBGP = val
        elseif addr < 0x3F04 then
            mem.PALETTE.BGP0[addr - 0x3F01] = val
        elseif addr < 0x3F08 then
            mem.PALETTE.BGP1[addr - 0x3F05] = val
        elseif addr < 0x3F0C then
            mem.PALETTE.BGP2[addr - 0x3F09] = val
        elseif addr < 0x3F10 then
            mem.PALETTE.BGP3[addr - 0x3F0D] = val
        elseif addr < 0x3F14 then
            mem.PALETTE.SPP0[addr - 0x3F11] = val
        elseif addr < 0x3F18 then
            mem.PALETTE.SPP1[addr - 0x3F15] = val
        elseif addr < 0x3F1C then
            mem.PALETTE.SPP2[addr - 0x3F19] = val
        else
            mem.PALETTE.SPP3[addr - 0x3F1D] = val
        end
    else
        print("Memory write error (PPU): " .. util.hex4:format(addr))
    end
end

return memory
