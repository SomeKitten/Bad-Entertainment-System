local util = require("./util")
local instructions = require("./instructions")
local memory = require("./memory")
local ppu = {}

-- ppu.cycles = 21
ppu.cycles = 27
-- ppu.cycles = 33
ppu.scanline = 0

ppu.tick = function(mem, cycles)
    ppu.cycles = ppu.cycles + cycles * 3

    if ppu.cycles >= 341 then
        ppu.cycles = ppu.cycles % 341
        ppu.scanline = ppu.scanline + 1

        if ppu.scanline == 241 then
            -- print("NMI SET")
            CPU_MEM.PPU_STATUS = bit.bor(CPU_MEM.PPU_STATUS, 0x80)

            -- print("NMI: " .. util.hex2:format(CPU_MEM.PPU_STATUS))

            NMI_OCCURRED = 1
        end

        if ppu.scanline >= 262 then
            ppu.scanline = 0

            -- print("NMI RESET")
            CPU_MEM.PPU_STATUS = bit.band(CPU_MEM.PPU_STATUS, 0x7F)

            NMI_OCCURRED = 0

            return true
        end
    end

    if NMI_OCCURRED == 1 and CPU_MEM.PPU_CTRL >= 0x80 and CPU_MEM.PPU_STATUS >=
        0x80 then
        -- print("NMI")
        NMI_OCCURRED = 0

        -- push hi
        instructions.push(CPU_MEM, REGISTERS, math.floor(REGISTERS.PC / 0x100))
        -- push lo
        instructions.push(CPU_MEM, REGISTERS, REGISTERS.PC % 0x100)

        local val = REGISTERS.P
        val = util.set_bit(val, 1, 5)
        val = util.set_bit(val, 1, 4)

        instructions.push(CPU_MEM, REGISTERS, val)

        REGISTERS.P = bit.bor(REGISTERS.P, 4)

        REGISTERS.PC = memory.read_cpu(CPU_MEM, 0xFFFA) +
                           memory.read_cpu(CPU_MEM, 0xFFFB) * 0x100

        -- print("NMI VEC: " .. util.hex4:format(REGISTERS.PC))
    end

    return false
end

return ppu
