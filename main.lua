ROMS_DIR = "/home/kitten/プロジェクト/Roms/NES/"
ROM = "donkeykong.nes"

local util = require("./util")
local memory = require("./memory")
local cpu = require("./cpu")
local ppu = require("./ppu")

function love.load()
    love.window.setMode(341 * 3, 240 * 3, {})
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
                       0x8000 - 0x4020)
    util.file_to_bytes(io.open(ROMS_DIR .. ROM, "r"), CPU_MEM.CART, 0x0010,
                       0xC000 - 0x4020)

    local copy_start = 0xC000 - 0x4020
    for i = copy_start, copy_start + 0x0FFF do
        PPU_MEM.PATTERNTABLE_0[i - copy_start] = CPU_MEM.CART[i]
    end

    for i = copy_start + 0x1000, copy_start + 0x1FFF do
        PPU_MEM.PATTERNTABLE_1[i - (copy_start + 0x1000)] = CPU_MEM.CART[i]
    end

    REGISTERS.PC = memory.read_cpu(CPU_MEM, 0xFFFD) * 0x100 +
                       memory.read_cpu(CPU_MEM, 0xFFFC)

    print("RESET VEC:" .. util.hex4:format(REGISTERS.PC))

    QUIT = false
end

function love.update(dt)
    --    TODO Assumes that each instruction is 3 cycles
    for i = 0, 29780 / 3 do
        if QUIT then return end
        local cycles = cpu.tick(CPU_MEM, REGISTERS)
        ppu.tick(PPU_MEM, cycles)
    end
end

function love.draw()
    if QUIT then
        local colours = {}
        colours[0] = {}
        colours[1] = {}
        colours[2] = {}
        colours[3] = {}

        local width = 8

        for t = 0, 511 do
            local tx = (t % width)
            local ty = math.floor(t / width)
            local i = t * 16

            for y1 = 0, 7 do
                local upper = memory.read_ppu(PPU_MEM, i + y1)
                local lower = memory.read_ppu(PPU_MEM, i + y1 + 8)

                for x1 = 0, 7 do
                    local pixel = 2 * util.get_bit(upper, x1)
                    pixel = pixel + util.get_bit(lower, x1)

                    table.insert(colours[pixel], {tx * 8 + x1, ty * 8 + y1})
                end
            end
        end

        -- print(DUMP(colours))

        local canv = love.graphics.newCanvas(341, 240)
        love.graphics.setCanvas(canv)
        for i = 0, 3 do
            love.graphics.setColor(1 / 3 * i, 1 / 3 * i, 1 / 3 * i)
            love.graphics.points(colours[i])
        end
        love.graphics.setCanvas()
        love.graphics.draw(canv, 0, 0, 0, 16, 16)
    end
end
