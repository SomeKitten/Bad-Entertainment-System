ROMS_DIR = "/home/kitten/プロジェクト/Roms/NES/"
ROM = "nestest.nes"

local util = require("./util")
local memory = require("./memory")
local cpu = require("./cpu")

function love.load()
    love.window.setMode(341, 240, {})

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

    REGISTERS.PC = memory.read_cpu(CPU_MEM, 0xFFFD) * 0x100 +
                       memory.read_cpu(CPU_MEM, 0xFFFC)

    print("RESET VEC:" .. util.hex4:format(REGISTERS.PC))

    QUIT = false
end

function love.update(dt)
    --    Should actually be cycles per second, not instructions per second
    for i = 0, 1790000 / 3 do
        if QUIT then return end
        cpu.tick(CPU_MEM, REGISTERS)
    end
end

function love.draw() end
