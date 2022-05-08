local ppu = {}

ppu.cycles = 0
ppu.scanline = 0

ppu.tick = function(mem, cycles)
    ppu.cycles = ppu.cycles + cycles

    if ppu.cycles >= 341 then
        ppu.cycles = ppu.cycles % 341
        ppu.scanline = ppu.scanline + 1

        if ppu.scanline == 241 then
            print("NMI SET")
            CPU_MEM.PPU_STATUS = bit.bor(CPU_MEM.PPU_STATUS, 0x80)
        end

        if ppu.scanline >= 262 then
            ppu.scanline = 0

            print("NMI RESET")
            CPU_MEM.PPU_STATUS = bit.band(CPU_MEM.PPU_STATUS, 0x7F)
        end
    end
end

return ppu
