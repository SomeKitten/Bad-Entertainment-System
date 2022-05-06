ROMS_DIR = "/home/kitten/プロジェクト/Roms/NES/"
ROM = "nestest.nes"

local util = require("./util")
local memory = require("./memory")
local cpu = require("./cpu")

function love.load()
    -- NES REGISTERS
    REGISTERS = {}
    REGISTERS.A = 0
    REGISTERS.X = 0
    REGISTERS.Y = 0
    REGISTERS.SP = 0
    REGISTERS.PC = 0
    REGISTERS.P = 0

    -- NES MEMORY
    MEMORY = {}
    memory.init(MEMORY)

    -- DEBUG
    REGISTERS.PC = 0xC000
    REGISTERS.SP = 0xFD
    REGISTERS.P = 0x24
    local f = io.open("debug.log", "w")
    f:close()

    util.file_to_bytes(io.open(ROMS_DIR .. ROM, "r"), MEMORY.CART, 0x0010,
                       0xC000 - 0x4020)

    for i = 0, 8990 do cpu.tick(MEMORY, REGISTERS) end

    love.event.quit(0)
end

function love.update(dt) end

function love.draw() end
