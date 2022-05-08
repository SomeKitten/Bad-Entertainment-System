local cpu = {}
local memory = require("./memory")
local util = require("./util")
local instructions = require("./instructions")

cpu.instructions_ran = 0
cpu.cycles_ran = 0

function cpu.tick(mem, regs)
    if regs.PC == 0xFFEE then print(string.char(regs.A)) end

    local inst = memory.read_cpu(mem, regs.PC)

    -- print("PC:" .. util.hex4:format(regs.PC) .. " A:" ..
    --           util.hex2:format(regs.A) .. " X:" .. util.hex2:format(regs.X) ..
    --           " Y:" .. util.hex2:format(regs.Y) .. " P:" ..
    --           util.hex2:format(regs.P) .. " SP:" .. util.hex2:format(regs.SP) ..
    --           " INST:" .. util.hex2:format(inst))

    -- print("inst: " .. util.hex2:format(inst))

    if instructions[inst] then
        regs.PC = regs.PC + 1

        --    TODO Assumes that each instruction is 3 cycles
        local cycles = 3

        instructions[inst](mem, regs)
        cpu.instructions_ran = cpu.instructions_ran + 1
        cpu.cycles_ran = cpu.cycles_ran + 1

        if cpu.cycles_ran % 10000 == 0 then
            print("Ran " .. cpu.instructions_ran .. " instructions")
        end

        if cpu.cycles_ran > 148911 then
            QUIT = true
            -- love.event.quit()
        end

        return cycles
    else
        print("Unknown instruction: " .. util.hex2:format(inst))
        print("AT: " .. util.hex4:format(regs.PC))
        QUIT = true
        -- love.event.quit()
    end
end

return cpu
