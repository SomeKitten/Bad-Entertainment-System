local cpu = {}
local memory = require("./memory")
local util = require("./util")
local instructions = require("./instructions")

cpu.instructions_ran = 0
cpu.cycles_ran = 0

function cpu.tick(mem, regs)
    local inst = memory.read_cpu(mem, regs.PC)

    -- print("inst: " .. util.hex2:format(inst))

    if instructions[inst] then
        regs.PC = regs.PC + 1

        --    TODO Assumes that each instruction is 3 cycles
        local cycles = instructions[inst](mem, regs)

        if not cycles then
            print("MISSING CYCLES: " .. util.hex2:format(inst))
            QUIT = true
        end

        cpu.instructions_ran = cpu.instructions_ran + 1
        cpu.cycles_ran = cpu.cycles_ran + 1

        -- if cpu.cycles_ran % 10000 == 0 then
        --     -- print("Ran " .. cpu.instructions_ran .. " instructions")
        -- end

        -- if cpu.cycles_ran > 100000 then
        --     QUIT = true
        --     -- love.event.quit()
        -- end

        return cycles
    else
        print(inst)
        print("Unknown instruction: " .. util.hex2:format(inst))
        print("AT: " .. util.hex4:format(regs.PC))
        QUIT = true
        -- love.event.quit()

        return 0
    end
end

return cpu
