local instructions = require "instructions"
ROMS_DIR = "/home/kitten/プロジェクト/Roms/NES/"
ROM = "nestest.nes"

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
    REGISTERS.SP = 0
    REGISTERS.PC = 0
    REGISTERS.P = 0

    -- NES CPU MEMORY
    CPU_MEM = {}
    memory.init_cpu(CPU_MEM)

    -- NES PPU MEMORY
    PPU_MEM = {}
    memory.init_ppu(PPU_MEM)

    -- DEBUG
    REGISTERS.PC = 0xC000
    REGISTERS.SP = 0xFD
    REGISTERS.P = 0x24
    local f = io.open("debug.log", "w")
    f:close()

    util.file_to_bytes(io.open(ROMS_DIR .. ROM, "r"), CPU_MEM.CART, 0x0010,
                       0x8000 - 0x4020, 0x4000)
    util.file_to_bytes(io.open(ROMS_DIR .. ROM, "r"), CPU_MEM.CART, 0x0010,
                       0xC000 - 0x4020, 0x4000)

    util.file_to_bytes(io.open(ROMS_DIR .. ROM, "r"), PPU_MEM.PATTERNTABLE_0,
                       0x0010 + 0x4000, 0, 0x2000)

    -- local copy_start = 0xC000 - 0x4020
    -- for i = copy_start, copy_start + 0x0FFF do
    --     PPU_MEM.PATTERNTABLE_0[i - copy_start] = CPU_MEM.CART[i]
    -- end

    -- for i = copy_start + 0x1000, copy_start + 0x1FFF do
    --     PPU_MEM.PATTERNTABLE_1[i - (copy_start + 0x1000)] = CPU_MEM.CART[i]
    -- end

    REGISTERS.PC = memory.read_cpu(CPU_MEM, 0xFFFD) * 0x100 +
                       memory.read_cpu(CPU_MEM, 0xFFFC)

    NMI = false

    print("RESET VEC:" .. util.hex4:format(REGISTERS.PC))

    QUIT = false
end

function love.update(dt)
    --    TODO Assumes that each instruction is 3 cycles
    for i = 0, 29780 / 3 do
        if QUIT then return end
        local cycles = cpu.tick(CPU_MEM, REGISTERS)
        ppu.tick(PPU_MEM, cycles)

        if NMI and REGISTERS.P >= 0x80 then
            print("NMI")
            NMI = false

            -- push hi
            instructions.push(CPU_MEM, REGISTERS,
                              math.floor(REGISTERS.PC / 0x100))
            -- push lo
            instructions.push(CPU_MEM, REGISTERS, REGISTERS.PC % 0x100)

            local val = REGISTERS.P
            val = util.set_bit(val, 1, 5)
            val = util.set_bit(val, 1, 4)

            instructions.push(CPU_MEM, REGISTERS, val)

            REGISTERS.PC = memory.read_cpu(CPU_MEM, 0xFFFA) +
                               memory.read_cpu(CPU_MEM, 0xFFFB) * 0x100

            print("NMI VEC: " .. util.hex4:format(REGISTERS.PC))
        end
    end
end

function draw_tile(colours, tile_index, tile_x, tile_y)
    for y = 0, 7 do
        local low = PPU_MEM.PATTERNTABLE_0[tile_index * 0x10 + y]
        local high = PPU_MEM.PATTERNTABLE_0[tile_index * 0x10 + y + 8]

        for x = 0, 7 do
            -- local pix = util.get_bit(low, x)
            local pix = 0
            pix = pix + util.get_bit(high, 7 - x) * 2

            table.insert(colours[pix], {x + tile_x * 10, y + tile_y * 10})
        end
    end
end

function love.draw()
    if QUIT then
        local colours = {}
        for i = 0, 3 do colours[i] = {} end

        for x = 0, 0x1F do
            for y = 0, 0x1F do
                local tile = PPU_MEM.NAMETABLE_0[x + y * 0x20]

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
