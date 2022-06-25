ROMS_DIR = "/home/kitten/プロジェクト/Roms/NES/"
ROM = "supermariobros.nes"

local util = require("./util")
local memory = require("./memory")
local cpu = require("./cpu")
local ppu = require("./ppu")
local controller = require("./controller")

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

    iNES_HEADER = {}
    util.file_to_bytes(io.open(ROMS_DIR .. ROM, "r"), iNES_HEADER, 0, 0, 0x10)

    FULL_ROM = {}
    util.file_to_bytes(io.open(ROMS_DIR .. ROM, "r"), FULL_ROM, 0x10, 0, 0)

    MAPPER = bit.rshift(iNES_HEADER[6], 4) + bit.rshift(iNES_HEADER[7], 4) *
                 0x10

    PRG_BANKS = iNES_HEADER[4] -- 0x4000
    CHR_BANKS = iNES_HEADER[5] -- 0x2000

    print("MAPPER: " .. MAPPER)

    if MAPPER == 0 then
        if PRG_BANKS == 1 then
            util.file_to_bytes(io.open(ROMS_DIR .. ROM, "r"), CPU_MEM.CART,
                               0x0010, 0x8000 - 0x4020, 0x4000)
            util.file_to_bytes(io.open(ROMS_DIR .. ROM, "r"), CPU_MEM.CART,
                               0x0010, 0xC000 - 0x4020, 0x4000)

            util.file_to_bytes(io.open(ROMS_DIR .. ROM, "r"),
                               PPU_MEM.PATTERNTABLE_0, 0x0010 + 0x4000, 0,
                               0x1000)
            util.file_to_bytes(io.open(ROMS_DIR .. ROM, "r"),
                               PPU_MEM.PATTERNTABLE_1, 0x0010 + 0x5000, 0,
                               0x1000)
        else
            util.file_to_bytes(io.open(ROMS_DIR .. ROM, "r"), CPU_MEM.CART,
                               0x0010, 0x8000 - 0x4020, 0x8000)

            util.file_to_bytes(io.open(ROMS_DIR .. ROM, "r"),
                               PPU_MEM.PATTERNTABLE_0, 0x0010 + 0x8000, 0,
                               0x1000)
            util.file_to_bytes(io.open(ROMS_DIR .. ROM, "r"),
                               PPU_MEM.PATTERNTABLE_1, 0x0010 + 0x9000, 0,
                               0x1000)
        end
    elseif MAPPER == 1 then
        if CHR_BANKS == 0 then
            PPU_MEM.CHR_BANK_0 = {}
            for j = 0, 0x0FFF do PPU_MEM.CHR_BANK_0[j] = 0 end
        else
            for i = 0, CHR_BANKS - 1 do
                PPU_MEM["CHR_BANK_" .. i] = {}
                for j = 0, 0x0FFF do
                    PPU_MEM["CHR_BANK_" .. i][j] = 0
                end
            end
        end
    else
        print("Unknown mapper: " .. MAPPER)
        QUIT = true
        love.event.quit(0)
    end

    local palette = {}
    util.file_to_bytes(io.open("./NES Classic Edition.pal", "r"), palette, 0, 0,
                       192)

    COLOUR_PALETTE = {}
    for i = 0, 63 do
        COLOUR_PALETTE[i] = {
            palette[i * 3], palette[i * 3 + 1], palette[i * 3 + 2]
        }
    end

    REGISTERS.PC = memory.read_cpu(CPU_MEM, 0xFFFD) * 0x100 +
                       memory.read_cpu(CPU_MEM, 0xFFFC)

    -- DEBUG
    -- REGISTERS.A = 0x00
    -- REGISTERS.X = 0x17
    -- REGISTERS.Y = 0x00
    -- REGISTERS.P = 0x06
    -- REGISTERS.SP = 0xFA
    -- CPU_MEM.PPU_STATUS = 0x10

    print("RESET VEC:" .. util.hex4:format(REGISTERS.PC))

    NMI_OCCURRED = 0

    RENDER = true
    QUIT = false
    DEBUG_OUTPUT = false

    CPU_CYCLES = 0
end

function love.update(dt)
    --    TODO Assumes that each instruction is 3 cycles
    for i = 1, 100000 do
        if QUIT then return end

        if DEBUG_OUTPUT then
            io.write("PC:" .. util.hex4:format(REGISTERS.PC) .. " A:" ..
                         util.hex2:format(REGISTERS.A) .. " X:" ..
                         util.hex2:format(REGISTERS.X) .. " Y:" ..
                         util.hex2:format(REGISTERS.Y) .. " P:" ..
                         util.hex2:format(REGISTERS.P) .. " SP:" ..
                         util.hex2:format(REGISTERS.SP))

            print(" CYC:" .. ppu.cycles .. " SL:" .. ppu.scanline)
        end

        controller.tick()
        local cycles = cpu.tick(CPU_MEM, REGISTERS, ppu.cycles)

        CPU_CYCLES = CPU_CYCLES + cycles

        if ppu.tick(PPU_MEM, cycles) then break end

        if i == 100000 then print("PPU ERROR (not ticking fast enough?)") end
    end
end

function draw_tile(c, tile_index, table_index, p, tile_x, tile_y, flip_horiz,
                   flip_vert)
    local patterntable = PPU_MEM["PATTERNTABLE_" .. table_index]
    local palette = PPU_MEM.PALETTE[p]

    for y = 0, 7 do
        local low = patterntable[tile_index * 0x10 + y]
        local high = patterntable[tile_index * 0x10 + y + 8]

        if flip_vert == 1 then y = 7 - y end

        for x = 0, 7 do
            local pix = util.get_bit(low, 7 - x)
            pix = pix + util.get_bit(high, 7 - x) * 2

            if pix ~= 0 then
                if flip_horiz == 1 then x = 7 - x end

                table.insert(c[palette[pix - 1]],
                             {x + tile_x + 1, y + tile_y + 1})
            end
        end
    end
end

function love.draw()
    if RENDER then
        local canv = love.graphics.newCanvas(256, 240)
        love.graphics.setCanvas(canv)

        -- print("PPU_MEM.PALETTE.UBGP: " .. PPU_MEM.PALETTE.UBGP)
        -- print("COLOUR_PALETTE[PPU_MEM.PALETTE.UBGP]: " ..
        --           tostring(COLOUR_PALETTE[PPU_MEM.PALETTE.UBGP]))

        love.graphics.setColor(COLOUR_PALETTE[PPU_MEM.PALETTE.UBGP][1] / 255,
                               COLOUR_PALETTE[PPU_MEM.PALETTE.UBGP][2] / 255,
                               COLOUR_PALETTE[PPU_MEM.PALETTE.UBGP][3] / 255)
        love.graphics.rectangle("fill", 0, 0, 256, 240)

        local colours = {}
        for i = 0x00, 0x3F do colours[i] = {} end

        local nametable = PPU_MEM["NAMETABLE_" .. CPU_MEM.PPU_NAMETABLE]

        for y = 0, 0x1F do
            for x = 0, 0x1D do
                local tile = nametable[x + y * 0x20]

                local attr_x = math.floor(x / 2)
                local attr_y = math.floor(y / 2)

                local attr = nametable[0x3C0 + math.floor(attr_x / 2) +
                                 math.floor(attr_y / 2) * 0x08]

                local corner_x = attr_x % 2
                local corner_y = attr_y % 2

                local corner = bit.band(bit.rshift(attr,
                                                   corner_y * 4 + corner_x * 2),
                                        3)

                draw_tile(colours, tile, CPU_MEM.PPU_BACKGROUND,
                          "BGP" .. corner, x * 8, y * 8)
            end
        end

        for i, v in pairs(colours) do
            love.graphics.setColor(COLOUR_PALETTE[i][1] / 255,
                                   COLOUR_PALETTE[i][2] / 255,
                                   COLOUR_PALETTE[i][3] / 255)

            love.graphics.points(v)
        end

        colours = {}
        for i = 0x00, 0x3F do colours[i] = {} end

        for i = 0, 63 do
            local attr = PPU_MEM.OAM[i * 4 + 2]
            local palette = bit.band(attr, 0x03)

            local flip_horiz = util.get_bit(attr, 6)
            local flip_vert = util.get_bit(attr, 7)

            draw_tile(colours, PPU_MEM.OAM[i * 4 + 1], CPU_MEM.PPU_SPRITE_ADDR,
                      "SPP" .. palette, PPU_MEM.OAM[i * 4 + 3],
                      PPU_MEM.OAM[i * 4] + 1, flip_horiz, flip_vert)
        end

        for i, v in pairs(colours) do
            love.graphics.setColor(COLOUR_PALETTE[i][1] / 255,
                                   COLOUR_PALETTE[i][2] / 255,
                                   COLOUR_PALETTE[i][3] / 255)

            love.graphics.points(v)
        end

        local scale = 3

        love.graphics.setCanvas()
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(canv, 0, 0, 0, scale, scale)

        love.graphics.print("CPU_CYCLES: " .. CPU_CYCLES, 0, 0)
    end
end
