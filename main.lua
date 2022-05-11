local instructions = require "instructions"
ROMS_DIR = "/home/kitten/プロジェクト/Roms/NES/"
ROM = "donkeykong.nes"

local util = require("./util")
local memory = require("./memory")
local cpu = require("./cpu")
local ppu = require("./ppu")

function love.load()
    love.window.setMode(256 * 3, 240 * 3, {})
    love.graphics.setDefaultFilter('nearest', 'nearest')

    -- NES REGISTERS
    REGISTERS = {}
    REGISTERS.A = 0
    REGISTERS.X = 0
    REGISTERS.Y = 0
    REGISTERS.SP = 0xFD
    REGISTERS.PC = 0
    REGISTERS.P = 0x24

    -- NES CPU MEMORY
    CPU_MEM = {}
    memory.init_cpu(CPU_MEM)

    -- NES PPU MEMORY
    PPU_MEM = {}
    memory.init_ppu(PPU_MEM)

    local f = io.open("debug.log", "w")
    f:close()

    util.file_to_bytes(io.open(ROMS_DIR .. ROM, "r"), CPU_MEM.CART, 0x0010,
                       0x8000 - 0x4020, 0x4000)
    util.file_to_bytes(io.open(ROMS_DIR .. ROM, "r"), CPU_MEM.CART, 0x0010,
                       0xC000 - 0x4020, 0x4000)

    util.file_to_bytes(io.open(ROMS_DIR .. ROM, "r"), PPU_MEM.PATTERNTABLE_0,
                       0x0010 + 0x4000, 0, 0x1000)
    util.file_to_bytes(io.open(ROMS_DIR .. ROM, "r"), PPU_MEM.PATTERNTABLE_1,
                       0x0010 + 0x5000, 0, 0x1000)

    REGISTERS.PC = memory.read_cpu(CPU_MEM, 0xFFFD) * 0x100 +
                       memory.read_cpu(CPU_MEM, 0xFFFC)

    -- DEBUG
    REGISTERS.A = 0x3C
    REGISTERS.X = 0xFF
    REGISTERS.Y = 0xAA
    REGISTERS.SP = 0xFA
    REGISTERS.P = 0x04
    CPU_MEM.PPU_STATUS = 0x10

    NMI_OCCURRED = 0

    -- print("RESET VEC:" .. util.hex4:format(REGISTERS.PC))

    RENDER = false
end

function love.update(dt)
    --    TODO Assumes that each instruction is 3 cycles
    for i = 0, 29780 / 3 do
        if RENDER then return end

        io.write("PC:" .. util.hex4:format(REGISTERS.PC) .. " A:" ..
                     util.hex2:format(REGISTERS.A) .. " X:" ..
                     util.hex2:format(REGISTERS.X) .. " Y:" ..
                     util.hex2:format(REGISTERS.Y) .. " P:" ..
                     util.hex2:format(REGISTERS.P) .. " SP:" ..
                     util.hex2:format(REGISTERS.SP))

        print(" CYC:" .. ppu.cycles .. " SL:" .. ppu.scanline)

        local cycles = cpu.tick(CPU_MEM, REGISTERS, ppu.cycles)
        ppu.tick(PPU_MEM, cycles)
    end
end

function draw_tile(colours, tile_index, tile_x, tile_y)
    local patterntable = PPU_MEM["PATTERNTABLE_" .. CPU_MEM.PPU_BACKGROUND]

    for y = 0, 7 do
        local low = patterntable[tile_index * 0x10 + y]
        local high = patterntable[tile_index * 0x10 + y + 8]

        for x = 0, 7 do
            local pix = util.get_bit(low, 7 - x)
            pix = pix + util.get_bit(high, 7 - x) * 2

            table.insert(colours[pix], {x + tile_x * 10, y + tile_y * 10})
        end
    end
end

function love.draw()
    if RENDER then
        local colours = {}
        for i = 0, 3 do colours[i] = {} end

        local nametable = PPU_MEM["NAMETABLE_" .. CPU_MEM.PPU_NAMETABLE]

        for x = 0, 0x1F do
            for y = 0, 0x1F do
                local tile = nametable[x + y * 0x20]

                -- print(util.hex2:format(tile))

                draw_tile(colours, tile, x, y)
            end
        end

        local canv = love.graphics.newCanvas(256, 240)
        love.graphics.setCanvas(canv)
        for i, v in pairs(colours) do
            love.graphics.setColor(i / 3, i / 3, i / 3)
            love.graphics.points(v)
        end

        local scale = 3

        love.graphics.setCanvas()
        love.graphics.draw(canv, 0, 0, 0, scale, scale)
    end
end
