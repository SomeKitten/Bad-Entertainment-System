local cpu = {}
local memory = require("./memory")
local util = require("./util")
local instructions = require("./instructions")

function cpu.tick(mem, regs)
    print("PC:" .. util.hex4:format(regs.PC) .. " A:" ..
              util.hex2:format(regs.A) .. " X:" .. util.hex2:format(regs.X) ..
              " Y:" .. util.hex2:format(regs.Y) .. " P:" ..
              util.hex2:format(regs.P) .. " SP:" .. util.hex2:format(regs.SP))

    local inst = memory.read(mem, regs.PC)

    -- print("inst: " .. util.hex2:format(inst))

    regs.PC = regs.PC + 1

    if instructions[inst] then
        instructions[inst](mem, regs)
    else
        print("Unknown instruction: " .. util.hex2:format(inst))
    end
end

return cpu
