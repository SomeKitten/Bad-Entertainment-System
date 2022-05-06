local memory = require("./memory")
local util = require("./util")

local instructions = {}

instructions.inc16 = function(n)
    n = (n + 1) % 0x10000
    return n
end

instructions.inc8 = function(n)
    n = (n + 1) % 0x100
    return n
end

instructions.dec16 = function(n)
    n = (n - 1) % 0x10000
    return n
end

instructions.dec8 = function(n)
    n = (n - 1) % 0x100
    return n
end

instructions.push = function(mem, regs, val)
    -- print("PUSH: " .. util.hex2:format(val))

    memory.write(mem, 0x0100 + regs.SP, val)
    regs.SP = instructions.dec16(regs.SP)
end

instructions.pull = function(mem, regs)
    regs.SP = instructions.inc16(regs.SP)
    local val = memory.read(mem, 0x0100 + regs.SP)

    -- print("PULL: " .. util.hex2:format(val))

    return val
end

instructions[0x4C] = function(mem, regs)
    -- JMP
    local lo = memory.read(mem, regs.PC)
    local hi = memory.read(mem, instructions.inc16(regs.PC))

    regs.PC = (hi * 0x100) + lo
end

instructions[0xA2] = function(mem, regs)
    -- LDX
    local val = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)

    local z = 0
    if val == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, util.get_bit(val, 7), 7)
    regs.P = util.set_bit(regs.P, z, 1)

    regs.X = val
end

instructions[0x86] = function(mem, regs)
    -- STX
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)

    memory.write(mem, addr, regs.X)
end

instructions[0x20] = function(mem, regs)
    -- JSR
    local lo = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)
    local hi = memory.read(mem, regs.PC)

    -- push hi
    instructions.push(mem, regs, math.floor(regs.PC / 0x100))
    -- push lo
    instructions.push(mem, regs, regs.PC % 0x100)

    regs.PC = (hi * 0x100) + lo
end

instructions[0xEA] = function(mem, regs)
    -- NOP
end

instructions[0x38] = function(mem, regs)
    -- SEC
    regs.P = util.set_bit(regs.P, 1, 0)
end

instructions[0xB0] = function(mem, regs)
    -- BCS
    local val = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)
    if util.get_bit(regs.P, 0) == 1 then regs.PC = regs.PC + val end
end

instructions[0x18] = function(mem, regs)
    -- CLC
    regs.P = util.set_bit(regs.P, 0, 0)
end

instructions[0x90] = function(mem, regs)
    -- BCC
    local val = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)
    if util.get_bit(regs.P, 0) == 0 then regs.PC = regs.PC + val end
end

instructions[0xA9] = function(mem, regs)
    -- LDA
    local val = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)

    local z = 0
    if val == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, util.get_bit(val, 7), 7)
    regs.P = util.set_bit(regs.P, z, 1)

    regs.A = val
end

instructions[0xF0] = function(mem, regs)
    -- BEQ
    local val = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)

    if val > 0x7F then val = val - 0x100 end

    if util.get_bit(regs.P, 1) == 1 then regs.PC = regs.PC + val end
end

instructions[0xD0] = function(mem, regs)
    -- BNE
    local val = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)

    if val > 0x7F then val = val - 0x100 end

    if util.get_bit(regs.P, 1) == 0 then regs.PC = regs.PC + val end
end

instructions[0x85] = function(mem, regs)
    -- STA
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)

    memory.write(mem, addr, regs.A)
end

instructions[0x24] = function(mem, regs)
    -- BIT
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)

    local val = memory.read(mem, addr)
    local val2 = bit.band(val, regs.A)

    local z = 0
    if val2 == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, util.get_bit(val, 7), 7)
    regs.P = util.set_bit(regs.P, util.get_bit(val, 6), 6)
    regs.P = util.set_bit(regs.P, z, 1)
end

instructions[0x70] = function(mem, regs)
    -- BVS
    local val = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)
    if util.get_bit(regs.P, 6) == 1 then regs.PC = regs.PC + val end
end

instructions[0x50] = function(mem, regs)
    -- BVC
    local val = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)
    if util.get_bit(regs.P, 6) == 0 then regs.PC = regs.PC + val end
end

instructions[0x10] = function(mem, regs)
    -- BPL
    local val = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)
    if util.get_bit(regs.P, 7) == 0 then regs.PC = regs.PC + val end
end

instructions[0x60] = function(mem, regs)
    -- RTS
    local lo = instructions.pull(mem, regs)
    local hi = instructions.pull(mem, regs)

    regs.PC = (hi * 0x100) + lo
    regs.PC = instructions.inc16(regs.PC)
end

instructions[0x78] = function(mem, regs)
    -- SEI
    regs.P = util.set_bit(regs.P, 1, 2)
end

instructions[0xF8] = function(mem, regs)
    -- SED
    regs.P = util.set_bit(regs.P, 1, 3)
end

instructions[0x08] = function(mem, regs)
    -- PHP
    local val = regs.P
    val = util.set_bit(val, 1, 5)
    val = util.set_bit(val, 1, 4)

    instructions.push(mem, regs, val)
end

instructions[0x68] = function(mem, regs)
    -- PLA
    local val = instructions.pull(mem, regs)

    regs.A = val

    local z = 0
    if regs.A == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, util.get_bit(regs.A, 7), 7)
    regs.P = util.set_bit(regs.P, z, 1)
end

instructions[0x29] = function(mem, regs)
    -- AND
    local val = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)

    regs.A = bit.band(regs.A, val)

    local z = 0
    if regs.A == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, util.get_bit(regs.A, 7), 7)
    regs.P = util.set_bit(regs.P, z, 1)
end

instructions[0xC9] = function(mem, regs)
    -- CMP
    local val = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)

    local z = 0
    if regs.A == val then z = 1 end

    local c = 0
    if regs.A >= val then c = 1 end

    local val2 = regs.A - val

    regs.P = util.set_bit(regs.P, util.get_bit(val2, 7), 7)
    regs.P = util.set_bit(regs.P, z, 1)
    regs.P = util.set_bit(regs.P, c, 0)
end

instructions[0xD8] = function(mem, regs)
    -- CLD
    regs.P = util.set_bit(regs.P, 0, 3)
end

instructions[0x48] = function(mem, regs)
    -- PHA
    instructions.push(mem, regs, regs.A)
end

instructions[0x28] = function(mem, regs)
    -- PLP
    local val = instructions.pull(mem, regs)

    val = util.set_bit(val, util.get_bit(regs.P, 5), 5)
    val = util.set_bit(val, util.get_bit(regs.P, 4), 4)

    regs.P = val
end

instructions[0x30] = function(mem, regs)
    -- BMI
    local val = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)

    if util.get_bit(regs.P, 7) == 1 then regs.PC = regs.PC + val end
end

instructions[0x09] = function(mem, regs)
    -- ORA
    local val = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)

    regs.A = bit.bor(regs.A, val)

    local z = 0
    if regs.A == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, util.get_bit(regs.A, 7), 7)
    regs.P = util.set_bit(regs.P, z, 1)
end

instructions[0xB8] = function(mem, regs)
    -- CLV
    regs.P = util.set_bit(regs.P, 0, 6)
end

instructions[0x49] = function(mem, regs)
    -- EOR
    local val = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)

    regs.A = bit.bxor(regs.A, val)

    local z = 0
    if regs.A == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, util.get_bit(regs.A, 7), 7)
    regs.P = util.set_bit(regs.P, z, 1)
end

instructions[0x69] = function(mem, regs)
    -- ADC
    local val = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)

    local c = util.get_bit(regs.P, 0)

    local val2 = regs.A + val + c

    local z = 0
    if val2 % 256 == 0 then z = 1 end

    local v = 0
    if util.get_bit(val, 7) == util.get_bit(regs.A, 7) and util.get_bit(val, 7) ~=
        util.get_bit(val2, 7) then v = 1 end

    regs.P = util.set_bit(regs.P, util.get_bit(val2, 7), 7)
    regs.P = util.set_bit(regs.P, z, 1)
    regs.P = util.set_bit(regs.P, util.get_bit(val2, 8), 0)
    regs.P = util.set_bit(regs.P, v, 6)

    regs.A = val2 % 256
end

instructions[0xA0] = function(mem, regs)
    -- LDY
    local val = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)

    regs.Y = val

    local z = 0
    if regs.Y == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, util.get_bit(regs.Y, 7), 7)
    regs.P = util.set_bit(regs.P, z, 1)
end

instructions[0xC0] = function(mem, regs)
    -- CPY
    local val = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)

    local z = 0
    if regs.Y == val then z = 1 end

    local c = 0
    if regs.Y >= val then c = 1 end

    local val2 = regs.Y - val

    regs.P = util.set_bit(regs.P, util.get_bit(val2, 7), 7)
    regs.P = util.set_bit(regs.P, z, 1)
    regs.P = util.set_bit(regs.P, c, 0)
end

instructions[0xE0] = function(mem, regs)
    -- CPX
    local val = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)

    local z = 0
    if regs.X == val then z = 1 end

    local c = 0
    if regs.X >= val then c = 1 end

    local val2 = regs.X - val

    regs.P = util.set_bit(regs.P, util.get_bit(val2, 7), 7)
    regs.P = util.set_bit(regs.P, z, 1)
    regs.P = util.set_bit(regs.P, c, 0)
end

instructions[0xE9] = function(mem, regs)
    -- SBC
    local val = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)

    local c = util.get_bit(regs.P, 0)

    -- (1 - c) = (0 => 1) (1 => 0)
    local val2 = val + (1 - c)
    local result = (regs.A - val2) % 256

    local z = 0
    if result == 0 then z = 1 end

    local v = 0
    if util.get_bit(-val2, 7) == util.get_bit(regs.A, 7) and
        util.get_bit(-val2, 7) ~= util.get_bit(result, 7) then v = 1 end

    local new_c = 0
    if val2 <= regs.A then new_c = 1 end

    regs.P = util.set_bit(regs.P, util.get_bit(result, 7), 7)
    regs.P = util.set_bit(regs.P, z, 1)
    regs.P = util.set_bit(regs.P, new_c, 0)
    regs.P = util.set_bit(regs.P, v, 6)

    regs.A = result
end

instructions[0xC8] = function(mem, regs)
    -- INY
    regs.Y = instructions.inc8(regs.Y)

    local z = 0
    if regs.Y == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, util.get_bit(regs.Y, 7), 7)
    regs.P = util.set_bit(regs.P, z, 1)
end

instructions[0xE8] = function(mem, regs)
    -- INX
    regs.X = instructions.inc8(regs.X)

    local z = 0
    if regs.X == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, util.get_bit(regs.X, 7), 7)
    regs.P = util.set_bit(regs.P, z, 1)
end

instructions[0x88] = function(mem, regs)
    -- DEY
    regs.Y = instructions.dec8(regs.Y)

    local z = 0
    if regs.Y == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, util.get_bit(regs.Y, 7), 7)
    regs.P = util.set_bit(regs.P, z, 1)
end

instructions[0xCA] = function(mem, regs)
    -- DEX
    regs.X = instructions.dec8(regs.X)

    local z = 0
    if regs.X == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, util.get_bit(regs.X, 7), 7)
    regs.P = util.set_bit(regs.P, z, 1)
end

instructions[0xA8] = function(mem, regs)
    -- TAY
    regs.Y = regs.A

    local z = 0
    if regs.Y == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, util.get_bit(regs.Y, 7), 7)
    regs.P = util.set_bit(regs.P, z, 1)
end

instructions[0xAA] = function(mem, regs)
    -- TAX
    regs.X = regs.A

    local z = 0
    if regs.X == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, util.get_bit(regs.X, 7), 7)
    regs.P = util.set_bit(regs.P, z, 1)
end

instructions[0x98] = function(mem, regs)
    -- TYA
    regs.A = regs.Y

    local z = 0
    if regs.A == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, util.get_bit(regs.A, 7), 7)
    regs.P = util.set_bit(regs.P, z, 1)
end

instructions[0x8A] = function(mem, regs)
    -- TXA
    regs.A = regs.X

    local z = 0
    if regs.A == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, util.get_bit(regs.A, 7), 7)
    regs.P = util.set_bit(regs.P, z, 1)
end

instructions[0xBA] = function(mem, regs)
    -- TSX
    regs.X = regs.SP

    local z = 0
    if regs.X == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, util.get_bit(regs.X, 7), 7)
    regs.P = util.set_bit(regs.P, z, 1)
end

instructions[0x8E] = function(mem, regs)
    -- STX
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)
    addr = addr + memory.read(mem, regs.PC) * 0x100
    regs.PC = instructions.inc16(regs.PC)

    memory.write(mem, addr, regs.X)
end

instructions[0x9A] = function(mem, regs)
    -- TXS
    regs.SP = regs.X
end

instructions[0xAE] = function(mem, regs)
    -- LDX
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)
    addr = addr + memory.read(mem, regs.PC) * 0x100
    regs.PC = instructions.inc16(regs.PC)

    regs.X = memory.read(mem, addr)

    local z = 0
    if regs.X == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, util.get_bit(regs.X, 7), 7)
    regs.P = util.set_bit(regs.P, z, 1)
end

instructions[0xAD] = function(mem, regs)
    -- LDA
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)
    addr = addr + memory.read(mem, regs.PC) * 0x100
    regs.PC = instructions.inc16(regs.PC)

    regs.A = memory.read(mem, addr)

    local z = 0
    if regs.A == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, util.get_bit(regs.A, 7), 7)
    regs.P = util.set_bit(regs.P, z, 1)
end

instructions[0x40] = function(mem, regs)
    -- RTI
    local val = instructions.pull(mem, regs)

    val = util.set_bit(val, util.get_bit(regs.P, 5), 5)
    val = util.set_bit(val, util.get_bit(regs.P, 4), 4)

    regs.P = val

    regs.PC = instructions.pull(mem, regs)
    regs.PC = regs.PC + instructions.pull(mem, regs) * 0x100
end

instructions[0x4A] = function(mem, regs)
    -- LSR
    local val = bit.rshift(regs.A, 1) % 0x100

    local z = 0
    if val == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, 0, 7)
    regs.P = util.set_bit(regs.P, z, 1)
    regs.P = util.set_bit(regs.P, regs.A % 2, 0)

    regs.A = val
end

instructions[0x0A] = function(mem, regs)
    -- ASL
    local val = bit.lshift(regs.A, 1) % 0x100

    local z = 0
    if val == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, math.floor(val / 0x80), 7)
    regs.P = util.set_bit(regs.P, z, 1)
    regs.P = util.set_bit(regs.P, math.floor(regs.A / 0x80), 0)

    regs.A = val % 0x100
end

instructions[0x6A] = function(mem, regs)
    -- ROR
    local c = util.get_bit(regs.P, 0)
    regs.P = util.set_bit(regs.P, util.get_bit(regs.P, 0), 7)
    regs.P = util.set_bit(regs.P, util.get_bit(regs.A, 0), 0)

    local val = bit.rshift(regs.A, 1)
    val = val + c * 0x80

    regs.A = val % 0x100

    local z = 0
    if regs.A == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, z, 1)
end

instructions[0x2A] = function(mem, regs)
    -- ROL
    local c = util.get_bit(regs.P, 0)
    regs.P = util.set_bit(regs.P, util.get_bit(regs.A, 6), 7)
    regs.P = util.set_bit(regs.P, util.get_bit(regs.A, 7), 0)

    local val = bit.lshift(regs.A, 1)
    val = val + c

    regs.A = val % 0x100

    local z = 0
    if regs.A == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, z, 1)
end

instructions[0xA5] = function(mem, regs)
    -- LDA
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)

    regs.A = memory.read(mem, addr)

    local z = 0
    if regs.A == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, util.get_bit(regs.A, 7), 7)
    regs.P = util.set_bit(regs.P, z, 1)
end

instructions[0x8D] = function(mem, regs)
    -- STA
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)
    addr = addr + memory.read(mem, regs.PC) * 0x100
    regs.PC = instructions.inc16(regs.PC)

    memory.write(mem, addr, regs.A)
end

instructions[0xA1] = function(mem, regs)
    -- LDA
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)

    addr = (addr + regs.X) % 0x100

    local indirect = memory.read(mem, addr)
    indirect = indirect + memory.read(mem, instructions.inc8(addr)) * 0x100

    regs.A = memory.read(mem, indirect)

    local z = 0
    if regs.A == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, util.get_bit(regs.A, 7), 7)
    regs.P = util.set_bit(regs.P, z, 1)
end

instructions[0x81] = function(mem, regs)
    -- STA
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)

    addr = (addr + regs.X) % 0x100

    local indirect = memory.read(mem, addr)
    indirect = indirect + memory.read(mem, instructions.inc8(addr)) * 0x100

    memory.write(mem, indirect, regs.A)
end

instructions[0x01] = function(mem, regs)
    -- ORA
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)

    addr = (addr + regs.X) % 0x100

    local indirect = memory.read(mem, addr)
    indirect = indirect + memory.read(mem, instructions.inc8(addr)) * 0x100

    regs.A = bit.bor(regs.A, memory.read(mem, indirect))

    local z = 0
    if regs.A == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, util.get_bit(regs.A, 7), 7)
    regs.P = util.set_bit(regs.P, z, 1)
end

instructions[0x21] = function(mem, regs)
    -- AND
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)

    addr = (addr + regs.X) % 0x100

    local indirect = memory.read(mem, addr)
    indirect = indirect + memory.read(mem, instructions.inc8(addr)) * 0x100

    regs.A = bit.band(regs.A, memory.read(mem, indirect))

    local z = 0
    if regs.A == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, util.get_bit(regs.A, 7), 7)
    regs.P = util.set_bit(regs.P, z, 1)
end

instructions[0x41] = function(mem, regs)
    -- EOR
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)

    addr = (addr + regs.X) % 0x100

    local indirect = memory.read(mem, addr)
    indirect = indirect + memory.read(mem, instructions.inc8(addr)) * 0x100

    regs.A = bit.bxor(regs.A, memory.read(mem, indirect))

    local z = 0
    if regs.A == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, util.get_bit(regs.A, 7), 7)
    regs.P = util.set_bit(regs.P, z, 1)
end

instructions[0x61] = function(mem, regs)
    -- ADC
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)

    addr = (addr + regs.X) % 0x100

    local indirect = memory.read(mem, addr)
    indirect = indirect + memory.read(mem, instructions.inc8(addr)) * 0x100

    local val = memory.read(mem, indirect)

    local c = util.get_bit(regs.P, 0)

    local val2 = regs.A + val + c

    local z = 0
    if val2 % 256 == 0 then z = 1 end

    local v = 0
    if util.get_bit(val, 7) == util.get_bit(regs.A, 7) and util.get_bit(val, 7) ~=
        util.get_bit(val2, 7) then v = 1 end

    regs.P = util.set_bit(regs.P, util.get_bit(val2, 7), 7)
    regs.P = util.set_bit(regs.P, z, 1)
    regs.P = util.set_bit(regs.P, util.get_bit(val2, 8), 0)
    regs.P = util.set_bit(regs.P, v, 6)

    regs.A = val2 % 256
end

instructions[0xC1] = function(mem, regs)
    -- CMP
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)

    addr = (addr + regs.X) % 0x100

    local indirect = memory.read(mem, addr)
    indirect = indirect + memory.read(mem, instructions.inc8(addr)) * 0x100

    local val = memory.read(mem, indirect)

    local z = 0
    if regs.A == val then z = 1 end

    local c = 0
    if regs.A >= val then c = 1 end

    local val2 = regs.A - val

    regs.P = util.set_bit(regs.P, util.get_bit(val2, 7), 7)
    regs.P = util.set_bit(regs.P, z, 1)
    regs.P = util.set_bit(regs.P, c, 0)
end

instructions[0xE1] = function(mem, regs)
    -- SBC
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)

    addr = (addr + regs.X) % 0x100

    local indirect = memory.read(mem, addr)
    indirect = indirect + memory.read(mem, instructions.inc8(addr)) * 0x100

    local val = memory.read(mem, indirect)

    local c = util.get_bit(regs.P, 0)

    -- (1 - c) = (0 => 1) (1 => 0)
    local val2 = val + (1 - c)
    local result = (regs.A - val2) % 256

    local z = 0
    if result == 0 then z = 1 end

    local v = 0
    if util.get_bit(-val2, 7) == util.get_bit(regs.A, 7) and
        util.get_bit(-val2, 7) ~= util.get_bit(result, 7) then v = 1 end

    local new_c = 0
    if val2 <= regs.A then new_c = 1 end

    regs.P = util.set_bit(regs.P, util.get_bit(result, 7), 7)
    regs.P = util.set_bit(regs.P, z, 1)
    regs.P = util.set_bit(regs.P, new_c, 0)
    regs.P = util.set_bit(regs.P, v, 6)

    regs.A = result
end

instructions[0xA4] = function(mem, regs)
    -- LDY
    local val = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)

    regs.Y = memory.read(mem, val)

    local z = 0
    if regs.Y == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, util.get_bit(regs.Y, 7), 7)
    regs.P = util.set_bit(regs.P, z, 1)
end

instructions[0x84] = function(mem, regs)
    -- STY
    local val = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)

    memory.write(mem, val, regs.Y)
end

instructions[0xA6] = function(mem, regs)
    -- LDX
    local val = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)

    regs.X = memory.read(mem, val)

    local z = 0
    if regs.X == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, util.get_bit(regs.X, 7), 7)
    regs.P = util.set_bit(regs.P, z, 1)
end

instructions[0x05] = function(mem, regs)
    -- ORA
    local val = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)

    regs.A = bit.bor(regs.A, memory.read(mem, val))

    local z = 0
    if regs.A == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, util.get_bit(regs.A, 7), 7)
    regs.P = util.set_bit(regs.P, z, 1)
end

instructions[0x25] = function(mem, regs)
    -- AND
    local val = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)

    regs.A = bit.band(regs.A, memory.read(mem, val))

    local z = 0
    if regs.A == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, util.get_bit(regs.A, 7), 7)
    regs.P = util.set_bit(regs.P, z, 1)
end

instructions[0x45] = function(mem, regs)
    -- EOR
    local val = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)

    regs.A = bit.bxor(regs.A, memory.read(mem, val))

    local z = 0
    if regs.A == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, util.get_bit(regs.A, 7), 7)
    regs.P = util.set_bit(regs.P, z, 1)
end

instructions[0x65] = function(mem, regs)
    -- ADC
    local val = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)

    val = memory.read(mem, val)

    local c = util.get_bit(regs.P, 0)

    local val2 = regs.A + val + c

    local z = 0
    if val2 % 256 == 0 then z = 1 end

    local v = 0
    if util.get_bit(val, 7) == util.get_bit(regs.A, 7) and util.get_bit(val, 7) ~=
        util.get_bit(val2, 7) then v = 1 end

    regs.P = util.set_bit(regs.P, util.get_bit(val2, 7), 7)
    regs.P = util.set_bit(regs.P, z, 1)
    regs.P = util.set_bit(regs.P, util.get_bit(val2, 8), 0)
    regs.P = util.set_bit(regs.P, v, 6)

    regs.A = val2 % 256
end

instructions[0xC5] = function(mem, regs)
    -- CMP
    local val = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)

    val = memory.read(mem, val)

    local z = 0
    if regs.A == val then z = 1 end

    local c = 0
    if regs.A >= val then c = 1 end

    local val2 = regs.A - val

    regs.P = util.set_bit(regs.P, util.get_bit(val2, 7), 7)
    regs.P = util.set_bit(regs.P, z, 1)
    regs.P = util.set_bit(regs.P, c, 0)
end

instructions[0xE5] = function(mem, regs)
    -- SBC
    local val = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)

    val = memory.read(mem, val)

    local c = util.get_bit(regs.P, 0)

    -- (1 - c) = (0 => 1) (1 => 0)
    local val2 = val + (1 - c)
    local result = (regs.A - val2) % 256

    local z = 0
    if result == 0 then z = 1 end

    local v = 0
    if util.get_bit(-val2, 7) == util.get_bit(regs.A, 7) and
        util.get_bit(-val2, 7) ~= util.get_bit(result, 7) then v = 1 end

    local new_c = 0
    if val2 <= regs.A then new_c = 1 end

    regs.P = util.set_bit(regs.P, util.get_bit(result, 7), 7)
    regs.P = util.set_bit(regs.P, z, 1)
    regs.P = util.set_bit(regs.P, new_c, 0)
    regs.P = util.set_bit(regs.P, v, 6)

    regs.A = result
end

instructions[0xE4] = function(mem, regs)
    -- CPX
    local val = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)

    val = memory.read(mem, val)

    local z = 0
    if regs.X == val then z = 1 end

    local c = 0
    if regs.X >= val then c = 1 end

    local val2 = regs.X - val

    regs.P = util.set_bit(regs.P, util.get_bit(val2, 7), 7)
    regs.P = util.set_bit(regs.P, z, 1)
    regs.P = util.set_bit(regs.P, c, 0)
end

instructions[0xC4] = function(mem, regs)
    -- CPY
    local val = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)

    val = memory.read(mem, val)

    local z = 0
    if regs.Y == val then z = 1 end

    local c = 0
    if regs.Y >= val then c = 1 end

    local val2 = regs.Y - val

    regs.P = util.set_bit(regs.P, util.get_bit(val2, 7), 7)
    regs.P = util.set_bit(regs.P, z, 1)
    regs.P = util.set_bit(regs.P, c, 0)
end

instructions[0x46] = function(mem, regs)
    -- LSR
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)

    local val = memory.read(mem, addr)
    local val2 = bit.rshift(val, 1) % 0x100

    local z = 0
    if val2 == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, 0, 7)
    regs.P = util.set_bit(regs.P, z, 1)
    regs.P = util.set_bit(regs.P, val % 2, 0)

    memory.write(mem, addr, val2)
end

instructions[0x06] = function(mem, regs)
    -- ASL
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)

    local val = memory.read(mem, addr)
    local val2 = bit.lshift(val, 1) % 0x100

    local z = 0
    if val2 == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, math.floor(val2 / 0x80), 7)
    regs.P = util.set_bit(regs.P, z, 1)
    regs.P = util.set_bit(regs.P, math.floor(val / 0x80), 0)

    memory.write(mem, addr, val2)
end

instructions[0x66] = function(mem, regs)
    -- ROR
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)

    local val = memory.read(mem, addr)

    local c = util.get_bit(regs.P, 0)

    local val2 = bit.rshift(val, 1)
    val2 = val2 + c * 0x80

    regs.P = util.set_bit(regs.P, util.get_bit(regs.P, 0), 7)
    regs.P = util.set_bit(regs.P, util.get_bit(val, 0), 0)

    val2 = val2 % 0x100

    memory.write(mem, addr, val2)

    local z = 0
    if val == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, z, 1)
end

instructions[0x26] = function(mem, regs)
    -- ROL
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)

    local val = memory.read(mem, addr)

    local c = util.get_bit(regs.P, 0)

    local val2 = bit.lshift(val, 1)
    val2 = val2 + c

    regs.P = util.set_bit(regs.P, util.get_bit(val, 6), 7)
    regs.P = util.set_bit(regs.P, util.get_bit(val, 7), 0)

    val2 = val2 % 0x100

    memory.write(mem, addr, val2)

    local z = 0
    if val == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, z, 1)
end

instructions[0xE6] = function(mem, regs)
    -- INC
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)

    local val = memory.read(mem, addr)
    local val2 = instructions.inc8(val)

    local z = 0
    if val2 == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, z, 1)
    regs.P = util.set_bit(regs.P, math.floor(val2 / 0x80), 7)

    memory.write(mem, addr, val2)
end

instructions[0xC6] = function(mem, regs)
    -- DEC
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)

    local val = memory.read(mem, addr)
    local val2 = instructions.dec8(val)

    local z = 0
    if val2 == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, z, 1)
    regs.P = util.set_bit(regs.P, math.floor(val2 / 0x80), 7)

    memory.write(mem, addr, val2)
end

instructions[0xAC] = function(mem, regs)
    -- LDY
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)
    addr = addr + memory.read(mem, regs.PC) * 0x100
    regs.PC = instructions.inc16(regs.PC)

    local val = memory.read(mem, addr)

    regs.Y = val

    local z = 0
    if val == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, z, 1)
    regs.P = util.set_bit(regs.P, math.floor(val / 0x80), 7)
end

instructions[0x8C] = function(mem, regs)
    -- STY
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)
    addr = addr + memory.read(mem, regs.PC) * 0x100
    regs.PC = instructions.inc16(regs.PC)

    memory.write(mem, addr, regs.Y)
end

instructions[0x2C] = function(mem, regs)
    -- BIT
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)
    addr = addr + memory.read(mem, regs.PC) * 0x100
    regs.PC = instructions.inc16(regs.PC)

    local val = memory.read(mem, addr)
    local val2 = bit.band(val, regs.A)

    local z = 0
    if val2 == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, util.get_bit(val, 7), 7)
    regs.P = util.set_bit(regs.P, util.get_bit(val, 6), 6)
    regs.P = util.set_bit(regs.P, z, 1)
end

instructions[0x0D] = function(mem, regs)
    -- ORA
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)
    addr = addr + memory.read(mem, regs.PC) * 0x100
    regs.PC = instructions.inc16(regs.PC)

    regs.A = bit.bor(regs.A, memory.read(mem, addr))

    local z = 0
    if regs.A == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, util.get_bit(regs.A, 7), 7)
    regs.P = util.set_bit(regs.P, z, 1)
end

instructions[0x2D] = function(mem, regs)
    -- AND
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)
    addr = addr + memory.read(mem, regs.PC) * 0x100
    regs.PC = instructions.inc16(regs.PC)

    regs.A = bit.band(regs.A, memory.read(mem, addr))

    local z = 0
    if regs.A == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, util.get_bit(regs.A, 7), 7)
    regs.P = util.set_bit(regs.P, z, 1)
end

instructions[0x4D] = function(mem, regs)
    -- EOR
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)
    addr = addr + memory.read(mem, regs.PC) * 0x100
    regs.PC = instructions.inc16(regs.PC)

    regs.A = bit.bxor(regs.A, memory.read(mem, addr))

    local z = 0
    if regs.A == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, util.get_bit(regs.A, 7), 7)
    regs.P = util.set_bit(regs.P, z, 1)
end

instructions[0x6D] = function(mem, regs)
    -- ADC
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)
    addr = addr + memory.read(mem, regs.PC) * 0x100
    regs.PC = instructions.inc16(regs.PC)

    local val = memory.read(mem, addr)

    local c = util.get_bit(regs.P, 0)

    local val2 = regs.A + val + c

    local z = 0
    if val2 % 256 == 0 then z = 1 end

    local v = 0
    if util.get_bit(val, 7) == util.get_bit(regs.A, 7) and util.get_bit(val, 7) ~=
        util.get_bit(val2, 7) then v = 1 end

    regs.P = util.set_bit(regs.P, util.get_bit(val2, 7), 7)
    regs.P = util.set_bit(regs.P, z, 1)
    regs.P = util.set_bit(regs.P, util.get_bit(val2, 8), 0)
    regs.P = util.set_bit(regs.P, v, 6)

    regs.A = val2 % 256
end

instructions[0xCD] = function(mem, regs)
    -- CMP
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)
    addr = addr + memory.read(mem, regs.PC) * 0x100
    regs.PC = instructions.inc16(regs.PC)

    local val = memory.read(mem, addr)

    local z = 0
    if regs.A == val then z = 1 end

    local c = 0
    if regs.A >= val then c = 1 end

    local val2 = regs.A - val

    regs.P = util.set_bit(regs.P, util.get_bit(val2, 7), 7)
    regs.P = util.set_bit(regs.P, z, 1)
    regs.P = util.set_bit(regs.P, c, 0)
end

instructions[0xED] = function(mem, regs)
    -- SBC
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)
    addr = addr + memory.read(mem, regs.PC) * 0x100
    regs.PC = instructions.inc16(regs.PC)

    local val = memory.read(mem, addr)

    local c = util.get_bit(regs.P, 0)

    -- (1 - c) = (0 => 1) (1 => 0)
    local val2 = val + (1 - c)
    local result = (regs.A - val2) % 256

    local z = 0
    if result == 0 then z = 1 end

    local v = 0
    if util.get_bit(-val2, 7) == util.get_bit(regs.A, 7) and
        util.get_bit(-val2, 7) ~= util.get_bit(result, 7) then v = 1 end

    local new_c = 0
    if val2 <= regs.A then new_c = 1 end

    regs.P = util.set_bit(regs.P, util.get_bit(result, 7), 7)
    regs.P = util.set_bit(regs.P, z, 1)
    regs.P = util.set_bit(regs.P, new_c, 0)
    regs.P = util.set_bit(regs.P, v, 6)

    regs.A = result
end

instructions[0xEC] = function(mem, regs)
    -- CPX
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)
    addr = addr + memory.read(mem, regs.PC) * 0x100
    regs.PC = instructions.inc16(regs.PC)

    local val = memory.read(mem, addr)

    local z = 0
    if regs.X == val then z = 1 end

    local c = 0
    if regs.X >= val then c = 1 end

    local val2 = regs.X - val

    regs.P = util.set_bit(regs.P, util.get_bit(val2, 7), 7)
    regs.P = util.set_bit(regs.P, z, 1)
    regs.P = util.set_bit(regs.P, c, 0)
end

instructions[0xCC] = function(mem, regs)
    -- CPY
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)
    addr = addr + memory.read(mem, regs.PC) * 0x100
    regs.PC = instructions.inc16(regs.PC)

    local val = memory.read(mem, addr)

    local z = 0
    if regs.Y == val then z = 1 end

    local c = 0
    if regs.Y >= val then c = 1 end

    local val2 = regs.Y - val

    regs.P = util.set_bit(regs.P, util.get_bit(val2, 7), 7)
    regs.P = util.set_bit(regs.P, z, 1)
    regs.P = util.set_bit(regs.P, c, 0)
end

instructions[0x4E] = function(mem, regs)
    -- LSR
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)
    addr = addr + memory.read(mem, regs.PC) * 0x100
    regs.PC = instructions.inc16(regs.PC)

    local val = memory.read(mem, addr)
    local val2 = bit.rshift(val, 1) % 0x100

    local z = 0
    if val2 == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, 0, 7)
    regs.P = util.set_bit(regs.P, z, 1)
    regs.P = util.set_bit(regs.P, val % 2, 0)

    memory.write(mem, addr, val2)
end

instructions[0x0E] = function(mem, regs)
    -- ASL
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)
    addr = addr + memory.read(mem, regs.PC) * 0x100
    regs.PC = instructions.inc16(regs.PC)

    local val = memory.read(mem, addr)
    local val2 = bit.lshift(val, 1) % 0x100

    local z = 0
    if val2 == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, math.floor(val2 / 0x80), 7)
    regs.P = util.set_bit(regs.P, z, 1)
    regs.P = util.set_bit(regs.P, math.floor(val / 0x80), 0)

    memory.write(mem, addr, val2)
end

instructions[0x6E] = function(mem, regs)
    -- ROR
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)
    addr = addr + memory.read(mem, regs.PC) * 0x100
    regs.PC = instructions.inc16(regs.PC)

    local val = memory.read(mem, addr)

    local c = util.get_bit(regs.P, 0)

    local val2 = bit.rshift(val, 1)
    val2 = val2 + c * 0x80

    regs.P = util.set_bit(regs.P, util.get_bit(regs.P, 0), 7)
    regs.P = util.set_bit(regs.P, util.get_bit(val, 0), 0)

    val2 = val2 % 0x100

    memory.write(mem, addr, val2)

    local z = 0
    if val == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, z, 1)
end

instructions[0x2E] = function(mem, regs)
    -- ROL
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)
    addr = addr + memory.read(mem, regs.PC) * 0x100
    regs.PC = instructions.inc16(regs.PC)

    local val = memory.read(mem, addr)

    local c = util.get_bit(regs.P, 0)

    local val2 = bit.lshift(val, 1)
    val2 = val2 + c

    regs.P = util.set_bit(regs.P, util.get_bit(val, 6), 7)
    regs.P = util.set_bit(regs.P, util.get_bit(val, 7), 0)

    val2 = val2 % 0x100

    memory.write(mem, addr, val2)

    local z = 0
    if val == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, z, 1)
end

instructions[0xEE] = function(mem, regs)
    -- INC
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)
    addr = addr + memory.read(mem, regs.PC) * 0x100
    regs.PC = instructions.inc16(regs.PC)

    local val = memory.read(mem, addr)
    local val2 = instructions.inc8(val)

    local z = 0
    if val2 == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, z, 1)
    regs.P = util.set_bit(regs.P, math.floor(val2 / 0x80), 7)

    memory.write(mem, addr, val2)
end

instructions[0xCE] = function(mem, regs)
    -- DEC
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)
    addr = addr + memory.read(mem, regs.PC) * 0x100
    regs.PC = instructions.inc16(regs.PC)

    local val = memory.read(mem, addr)
    local val2 = instructions.dec8(val)

    local z = 0
    if val2 == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, z, 1)
    regs.P = util.set_bit(regs.P, math.floor(val2 / 0x80), 7)

    memory.write(mem, addr, val2)
end

instructions[0xB1] = function(mem, regs)
    -- LDA
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)

    local indirect = memory.read(mem, addr)
    indirect = indirect + memory.read(mem, instructions.inc8(addr)) * 0x100

    indirect = (indirect + regs.Y) % 0x10000

    regs.A = memory.read(mem, indirect)

    local z = 0
    if regs.A == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, util.get_bit(regs.A, 7), 7)
    regs.P = util.set_bit(regs.P, z, 1)
end

instructions[0x11] = function(mem, regs)
    -- ORA
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)

    local indirect = memory.read(mem, addr)
    indirect = indirect + memory.read(mem, instructions.inc8(addr)) * 0x100

    indirect = (indirect + regs.Y) % 0x10000

    regs.A = bit.bor(regs.A, memory.read(mem, indirect))

    local z = 0
    if regs.A == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, util.get_bit(regs.A, 7), 7)
    regs.P = util.set_bit(regs.P, z, 1)
end

instructions[0x31] = function(mem, regs)
    -- AND
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)

    local indirect = memory.read(mem, addr)
    indirect = indirect + memory.read(mem, instructions.inc8(addr)) * 0x100

    indirect = (indirect + regs.Y) % 0x10000

    regs.A = bit.band(regs.A, memory.read(mem, indirect))

    local z = 0
    if regs.A == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, util.get_bit(regs.A, 7), 7)
    regs.P = util.set_bit(regs.P, z, 1)
end

instructions[0x51] = function(mem, regs)
    -- EOR
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)

    local indirect = memory.read(mem, addr)
    indirect = indirect + memory.read(mem, instructions.inc8(addr)) * 0x100

    indirect = (indirect + regs.Y) % 0x10000

    regs.A = bit.bxor(regs.A, memory.read(mem, indirect))

    local z = 0
    if regs.A == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, util.get_bit(regs.A, 7), 7)
    regs.P = util.set_bit(regs.P, z, 1)
end

instructions[0x71] = function(mem, regs)
    -- ADC
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)

    local indirect = memory.read(mem, addr)
    indirect = indirect + memory.read(mem, instructions.inc8(addr)) * 0x100

    indirect = (indirect + regs.Y) % 0x10000

    local val = memory.read(mem, indirect)

    local c = util.get_bit(regs.P, 0)

    local val2 = regs.A + val + c

    local z = 0
    if val2 % 256 == 0 then z = 1 end

    local v = 0
    if util.get_bit(val, 7) == util.get_bit(regs.A, 7) and util.get_bit(val, 7) ~=
        util.get_bit(val2, 7) then v = 1 end

    regs.P = util.set_bit(regs.P, util.get_bit(val2, 7), 7)
    regs.P = util.set_bit(regs.P, z, 1)
    regs.P = util.set_bit(regs.P, util.get_bit(val2, 8), 0)
    regs.P = util.set_bit(regs.P, v, 6)

    regs.A = val2 % 256
end

instructions[0xD1] = function(mem, regs)
    -- CMP
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)

    local indirect = memory.read(mem, addr)
    indirect = indirect + memory.read(mem, instructions.inc8(addr)) * 0x100

    indirect = (indirect + regs.Y) % 0x10000

    local val = memory.read(mem, indirect)

    local z = 0
    if regs.A == val then z = 1 end

    local c = 0
    if regs.A >= val then c = 1 end

    local val2 = regs.A - val

    regs.P = util.set_bit(regs.P, util.get_bit(val2, 7), 7)
    regs.P = util.set_bit(regs.P, z, 1)
    regs.P = util.set_bit(regs.P, c, 0)
end

instructions[0xF1] = function(mem, regs)
    -- SBC
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)

    local indirect = memory.read(mem, addr)
    indirect = indirect + memory.read(mem, instructions.inc8(addr)) * 0x100

    indirect = (indirect + regs.Y) % 0x10000

    local val = memory.read(mem, indirect)

    local c = util.get_bit(regs.P, 0)

    -- (1 - c) = (0 => 1) (1 => 0)
    local val2 = val + (1 - c)
    local result = (regs.A - val2) % 256

    local z = 0
    if result == 0 then z = 1 end

    local v = 0
    if util.get_bit(-val2, 7) == util.get_bit(regs.A, 7) and
        util.get_bit(-val2, 7) ~= util.get_bit(result, 7) then v = 1 end

    local new_c = 0
    if val2 <= regs.A then new_c = 1 end

    regs.P = util.set_bit(regs.P, util.get_bit(result, 7), 7)
    regs.P = util.set_bit(regs.P, z, 1)
    regs.P = util.set_bit(regs.P, new_c, 0)
    regs.P = util.set_bit(regs.P, v, 6)

    regs.A = result
end

instructions[0x91] = function(mem, regs)
    -- STA
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)

    local indirect = memory.read(mem, addr)
    indirect = indirect + memory.read(mem, instructions.inc8(addr)) * 0x100

    indirect = (indirect + regs.Y) % 0x10000

    memory.write(mem, indirect, regs.A)
end

instructions[0x6C] = function(mem, regs)
    -- JMP
    local lo = memory.read(mem, regs.PC)
    local hi = memory.read(mem, instructions.inc16(regs.PC))

    local addr = (hi * 0x100) + lo
    local lo2 = memory.read(mem, addr)
    addr = (hi * 0x100) + instructions.inc8(lo)
    local hi2 = memory.read(mem, addr)

    regs.PC = (hi2 * 0x100) + lo2
end

instructions[0xB9] = function(mem, regs)
    -- LDA
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)
    addr = addr + memory.read(mem, regs.PC) * 0x100
    regs.PC = instructions.inc16(regs.PC)

    regs.A = memory.read(mem, (addr + regs.Y) % 0x10000)

    local z = 0
    if regs.A == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, util.get_bit(regs.A, 7), 7)
    regs.P = util.set_bit(regs.P, z, 1)
end

instructions[0x19] = function(mem, regs)
    -- ORA
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)
    addr = addr + memory.read(mem, regs.PC) * 0x100
    regs.PC = instructions.inc16(regs.PC)

    regs.A = bit.bor(regs.A, memory.read(mem, (addr + regs.Y) % 0x10000))

    local z = 0
    if regs.A == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, util.get_bit(regs.A, 7), 7)
    regs.P = util.set_bit(regs.P, z, 1)
end

instructions[0x39] = function(mem, regs)
    -- AND
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)
    addr = addr + memory.read(mem, regs.PC) * 0x100
    regs.PC = instructions.inc16(regs.PC)

    regs.A = bit.band(regs.A, memory.read(mem, (addr + regs.Y) % 0x10000))

    local z = 0
    if regs.A == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, util.get_bit(regs.A, 7), 7)
    regs.P = util.set_bit(regs.P, z, 1)
end

instructions[0x59] = function(mem, regs)
    -- EOR
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)
    addr = addr + memory.read(mem, regs.PC) * 0x100
    regs.PC = instructions.inc16(regs.PC)

    regs.A = bit.bxor(regs.A, memory.read(mem, (addr + regs.Y) % 0x10000))

    local z = 0
    if regs.A == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, util.get_bit(regs.A, 7), 7)
    regs.P = util.set_bit(regs.P, z, 1)
end

instructions[0x79] = function(mem, regs)
    -- ADC
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)
    addr = addr + memory.read(mem, regs.PC) * 0x100
    regs.PC = instructions.inc16(regs.PC)

    local val = memory.read(mem, (addr + regs.Y) % 0x10000)

    local c = util.get_bit(regs.P, 0)

    local val2 = regs.A + val + c

    local z = 0
    if val2 % 256 == 0 then z = 1 end

    local v = 0
    if util.get_bit(val, 7) == util.get_bit(regs.A, 7) and util.get_bit(val, 7) ~=
        util.get_bit(val2, 7) then v = 1 end

    regs.P = util.set_bit(regs.P, util.get_bit(val2, 7), 7)
    regs.P = util.set_bit(regs.P, z, 1)
    regs.P = util.set_bit(regs.P, util.get_bit(val2, 8), 0)
    regs.P = util.set_bit(regs.P, v, 6)

    regs.A = val2 % 256
end

instructions[0xD9] = function(mem, regs)
    -- CMP
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)
    addr = addr + memory.read(mem, regs.PC) * 0x100
    regs.PC = instructions.inc16(regs.PC)

    local val = memory.read(mem, (addr + regs.Y) % 0x10000)

    local z = 0
    if regs.A == val then z = 1 end

    local c = 0
    if regs.A >= val then c = 1 end

    local val2 = regs.A - val

    regs.P = util.set_bit(regs.P, util.get_bit(val2, 7), 7)
    regs.P = util.set_bit(regs.P, z, 1)
    regs.P = util.set_bit(regs.P, c, 0)
end

instructions[0xF9] = function(mem, regs)
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)
    addr = addr + memory.read(mem, regs.PC) * 0x100
    regs.PC = instructions.inc16(regs.PC)

    local val = memory.read(mem, (addr + regs.Y) % 0x10000)

    local c = util.get_bit(regs.P, 0)

    -- (1 - c) = (0 => 1) (1 => 0)
    local val2 = val + (1 - c)
    local result = (regs.A - val2) % 256

    local z = 0
    if result == 0 then z = 1 end

    local v = 0
    if util.get_bit(-val2, 7) == util.get_bit(regs.A, 7) and
        util.get_bit(-val2, 7) ~= util.get_bit(result, 7) then v = 1 end

    local new_c = 0
    if val2 <= regs.A then new_c = 1 end

    regs.P = util.set_bit(regs.P, util.get_bit(result, 7), 7)
    regs.P = util.set_bit(regs.P, z, 1)
    regs.P = util.set_bit(regs.P, new_c, 0)
    regs.P = util.set_bit(regs.P, v, 6)

    regs.A = result
end

instructions[0x99] = function(mem, regs)
    -- STA
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)
    addr = addr + memory.read(mem, regs.PC) * 0x100
    regs.PC = instructions.inc16(regs.PC)

    memory.write(mem, (addr + regs.Y) % 0x10000, regs.A)
end

instructions[0xB4] = function(mem, regs)
    -- LDY
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)

    regs.Y = memory.read(mem, (addr + regs.X) % 0x100)

    local z = 0
    if regs.Y == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, util.get_bit(regs.Y, 7), 7)
    regs.P = util.set_bit(regs.P, z, 1)
end

instructions[0x94] = function(mem, regs)
    -- STY
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)

    memory.write(mem, (addr + regs.X) % 0x100, regs.Y)
end

instructions[0x15] = function(mem, regs)
    -- ORA
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)

    regs.A = bit.bor(regs.A, memory.read(mem, (addr + regs.X) % 0x100))

    local z = 0
    if regs.A == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, util.get_bit(regs.A, 7), 7)
    regs.P = util.set_bit(regs.P, z, 1)
end

instructions[0x35] = function(mem, regs)
    -- AND
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)

    regs.A = bit.band(regs.A, memory.read(mem, (addr + regs.X) % 0x100))

    local z = 0
    if regs.A == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, util.get_bit(regs.A, 7), 7)
    regs.P = util.set_bit(regs.P, z, 1)
end

instructions[0x55] = function(mem, regs)
    -- EOR
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)

    regs.A = bit.bxor(regs.A, memory.read(mem, (addr + regs.X) % 0x100))

    local z = 0
    if regs.A == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, util.get_bit(regs.A, 7), 7)
    regs.P = util.set_bit(regs.P, z, 1)
end

instructions[0x75] = function(mem, regs)
    -- ADC
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)

    local val = memory.read(mem, (addr + regs.X) % 0x100)

    local c = util.get_bit(regs.P, 0)

    local val2 = regs.A + val + c

    local z = 0
    if val2 % 256 == 0 then z = 1 end

    local v = 0
    if util.get_bit(val, 7) == util.get_bit(regs.A, 7) and util.get_bit(val, 7) ~=
        util.get_bit(val2, 7) then v = 1 end

    regs.P = util.set_bit(regs.P, util.get_bit(val2, 7), 7)
    regs.P = util.set_bit(regs.P, z, 1)
    regs.P = util.set_bit(regs.P, util.get_bit(val2, 8), 0)
    regs.P = util.set_bit(regs.P, v, 6)

    regs.A = val2 % 256
end

instructions[0xD5] = function(mem, regs)
    -- CMP
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)

    local val = memory.read(mem, (addr + regs.X) % 0x100)

    local z = 0
    if regs.A == val then z = 1 end

    local c = 0
    if regs.A >= val then c = 1 end

    local val2 = regs.A - val

    regs.P = util.set_bit(regs.P, util.get_bit(val2, 7), 7)
    regs.P = util.set_bit(regs.P, z, 1)
    regs.P = util.set_bit(regs.P, c, 0)
end

instructions[0xF5] = function(mem, regs)
    -- SBC
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)

    local val = memory.read(mem, (addr + regs.X) % 0x100)

    local c = util.get_bit(regs.P, 0)

    -- (1 - c) = (0 => 1) (1 => 0)
    local val2 = val + (1 - c)
    local result = (regs.A - val2) % 256

    local z = 0
    if result == 0 then z = 1 end

    local v = 0
    if util.get_bit(-val2, 7) == util.get_bit(regs.A, 7) and
        util.get_bit(-val2, 7) ~= util.get_bit(result, 7) then v = 1 end

    local new_c = 0
    if val2 <= regs.A then new_c = 1 end

    regs.P = util.set_bit(regs.P, util.get_bit(result, 7), 7)
    regs.P = util.set_bit(regs.P, z, 1)
    regs.P = util.set_bit(regs.P, new_c, 0)
    regs.P = util.set_bit(regs.P, v, 6)

    regs.A = result
end

instructions[0xB5] = function(mem, regs)
    -- LDA
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)

    regs.A = memory.read(mem, (addr + regs.X) % 0x100)

    local z = 0
    if regs.A == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, util.get_bit(regs.A, 7), 7)
    regs.P = util.set_bit(regs.P, z, 1)
end

instructions[0x95] = function(mem, regs)
    -- STA
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)

    memory.write(mem, (addr + regs.X) % 0x100, regs.A)
end

instructions[0x56] = function(mem, regs)
    -- LSR
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)

    addr = (addr + regs.X) % 0x100

    local val = memory.read(mem, addr)
    local val2 = bit.rshift(val, 1) % 0x100

    local z = 0
    if val2 == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, 0, 7)
    regs.P = util.set_bit(regs.P, z, 1)
    regs.P = util.set_bit(regs.P, val % 2, 0)

    memory.write(mem, addr, val2)
end

instructions[0x16] = function(mem, regs)
    -- ASL
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)

    addr = (addr + regs.X) % 0x100

    local val = memory.read(mem, addr)
    local val2 = bit.lshift(val, 1) % 0x100

    local z = 0
    if val2 == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, math.floor(val2 / 0x80), 7)
    regs.P = util.set_bit(regs.P, z, 1)
    regs.P = util.set_bit(regs.P, math.floor(val / 0x80), 0)

    memory.write(mem, addr, val2)
end

instructions[0x76] = function(mem, regs)
    -- ROR
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)

    addr = (addr + regs.X) % 0x100

    local val = memory.read(mem, addr)

    local c = util.get_bit(regs.P, 0)

    local val2 = bit.rshift(val, 1)
    val2 = val2 + c * 0x80

    regs.P = util.set_bit(regs.P, util.get_bit(regs.P, 0), 7)
    regs.P = util.set_bit(regs.P, util.get_bit(val, 0), 0)

    val2 = val2 % 0x100

    memory.write(mem, addr, val2)

    local z = 0
    if val == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, z, 1)
end

instructions[0x36] = function(mem, regs)
    -- ROL
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)

    addr = (addr + regs.X) % 0x100

    local val = memory.read(mem, addr)

    local c = util.get_bit(regs.P, 0)

    local val2 = bit.lshift(val, 1)
    val2 = val2 + c

    regs.P = util.set_bit(regs.P, util.get_bit(val, 6), 7)
    regs.P = util.set_bit(regs.P, util.get_bit(val, 7), 0)

    val2 = val2 % 0x100

    memory.write(mem, addr, val2)

    local z = 0
    if val == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, z, 1)
end

instructions[0xF6] = function(mem, regs)
    -- INC
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)

    addr = (addr + regs.X) % 0x100

    local val = memory.read(mem, addr)
    local val2 = instructions.inc8(val)

    local z = 0
    if val2 == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, z, 1)
    regs.P = util.set_bit(regs.P, math.floor(val2 / 0x80), 7)

    memory.write(mem, addr, val2)
end

instructions[0xD6] = function(mem, regs)
    -- DEC
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)

    addr = (addr + regs.X) % 0x100

    local val = memory.read(mem, addr)
    local val2 = instructions.dec8(val)

    local z = 0
    if val2 == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, z, 1)
    regs.P = util.set_bit(regs.P, math.floor(val2 / 0x80), 7)

    memory.write(mem, addr, val2)
end

instructions[0xB6] = function(mem, regs)
    -- LDX
    local val = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)

    regs.X = memory.read(mem, (val + regs.Y) % 0x100)

    local z = 0
    if regs.X == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, util.get_bit(regs.X, 7), 7)
    regs.P = util.set_bit(regs.P, z, 1)
end

instructions[0x96] = function(mem, regs)
    -- STX
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)

    memory.write(mem, (addr + regs.Y) % 0x100, regs.X)
end

instructions[0xBC] = function(mem, regs)
    -- LDY
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)
    addr = addr + memory.read(mem, regs.PC) * 0x100
    regs.PC = instructions.inc16(regs.PC)

    local val = memory.read(mem, addr + regs.X)

    regs.Y = val

    local z = 0
    if val == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, z, 1)
    regs.P = util.set_bit(regs.P, math.floor(val / 0x80), 7)
end

instructions[0x1D] = function(mem, regs)
    -- ORA
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)
    addr = addr + memory.read(mem, regs.PC) * 0x100
    regs.PC = instructions.inc16(regs.PC)

    regs.A = bit.bor(regs.A, memory.read(mem, addr + regs.X))

    local z = 0
    if regs.A == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, util.get_bit(regs.A, 7), 7)
    regs.P = util.set_bit(regs.P, z, 1)
end

instructions[0x3D] = function(mem, regs)
    -- AND
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)
    addr = addr + memory.read(mem, regs.PC) * 0x100
    regs.PC = instructions.inc16(regs.PC)

    regs.A = bit.band(regs.A, memory.read(mem, addr + regs.X))

    local z = 0
    if regs.A == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, util.get_bit(regs.A, 7), 7)
    regs.P = util.set_bit(regs.P, z, 1)
end

instructions[0x5D] = function(mem, regs)
    -- EOR
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)
    addr = addr + memory.read(mem, regs.PC) * 0x100
    regs.PC = instructions.inc16(regs.PC)

    regs.A = bit.bxor(regs.A, memory.read(mem, addr + regs.X))

    local z = 0
    if regs.A == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, util.get_bit(regs.A, 7), 7)
    regs.P = util.set_bit(regs.P, z, 1)
end

instructions[0x7D] = function(mem, regs)
    -- ADC
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)
    addr = addr + memory.read(mem, regs.PC) * 0x100
    regs.PC = instructions.inc16(regs.PC)

    local val = memory.read(mem, addr + regs.X)

    local c = util.get_bit(regs.P, 0)

    local val2 = regs.A + val + c

    local z = 0
    if val2 % 256 == 0 then z = 1 end

    local v = 0
    if util.get_bit(val, 7) == util.get_bit(regs.A, 7) and util.get_bit(val, 7) ~=
        util.get_bit(val2, 7) then v = 1 end

    regs.P = util.set_bit(regs.P, util.get_bit(val2, 7), 7)
    regs.P = util.set_bit(regs.P, z, 1)
    regs.P = util.set_bit(regs.P, util.get_bit(val2, 8), 0)
    regs.P = util.set_bit(regs.P, v, 6)

    regs.A = val2 % 256
end

instructions[0xDD] = function(mem, regs)
    -- CMP
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)
    addr = addr + memory.read(mem, regs.PC) * 0x100
    regs.PC = instructions.inc16(regs.PC)

    local val = memory.read(mem, addr + regs.X)

    local z = 0
    if regs.A == val then z = 1 end

    local c = 0
    if regs.A >= val then c = 1 end

    local val2 = regs.A - val

    regs.P = util.set_bit(regs.P, util.get_bit(val2, 7), 7)
    regs.P = util.set_bit(regs.P, z, 1)
    regs.P = util.set_bit(regs.P, c, 0)
end

instructions[0xFD] = function(mem, regs)
    -- SBC
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)
    addr = addr + memory.read(mem, regs.PC) * 0x100
    regs.PC = instructions.inc16(regs.PC)

    local val = memory.read(mem, addr + regs.X)

    local c = util.get_bit(regs.P, 0)

    -- (1 - c) = (0 => 1) (1 => 0)
    local val2 = val + (1 - c)
    local result = (regs.A - val2) % 256

    local z = 0
    if result == 0 then z = 1 end

    local v = 0
    if util.get_bit(-val2, 7) == util.get_bit(regs.A, 7) and
        util.get_bit(-val2, 7) ~= util.get_bit(result, 7) then v = 1 end

    local new_c = 0
    if val2 <= regs.A then new_c = 1 end

    regs.P = util.set_bit(regs.P, util.get_bit(result, 7), 7)
    regs.P = util.set_bit(regs.P, z, 1)
    regs.P = util.set_bit(regs.P, new_c, 0)
    regs.P = util.set_bit(regs.P, v, 6)

    regs.A = result
end

instructions[0xBD] = function(mem, regs)
    -- LDA
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)
    addr = addr + memory.read(mem, regs.PC) * 0x100
    regs.PC = instructions.inc16(regs.PC)

    regs.A = memory.read(mem, addr + regs.X)

    local z = 0
    if regs.A == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, util.get_bit(regs.A, 7), 7)
    regs.P = util.set_bit(regs.P, z, 1)
end

instructions[0x9D] = function(mem, regs)
    -- STA
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)
    addr = addr + memory.read(mem, regs.PC) * 0x100
    regs.PC = instructions.inc16(regs.PC)

    memory.write(mem, addr + regs.X, regs.A)
end

instructions[0x5E] = function(mem, regs)
    -- LSR
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)
    addr = addr + memory.read(mem, regs.PC) * 0x100
    regs.PC = instructions.inc16(regs.PC)

    addr = addr + regs.X

    local val = memory.read(mem, addr)
    local val2 = bit.rshift(val, 1) % 0x100

    local z = 0
    if val2 == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, 0, 7)
    regs.P = util.set_bit(regs.P, z, 1)
    regs.P = util.set_bit(regs.P, val % 2, 0)

    memory.write(mem, addr, val2)
end

instructions[0x1E] = function(mem, regs)
    -- ASL
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)
    addr = addr + memory.read(mem, regs.PC) * 0x100
    regs.PC = instructions.inc16(regs.PC)

    addr = addr + regs.X

    local val = memory.read(mem, addr)
    local val2 = bit.lshift(val, 1) % 0x100

    local z = 0
    if val2 == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, math.floor(val2 / 0x80), 7)
    regs.P = util.set_bit(regs.P, z, 1)
    regs.P = util.set_bit(regs.P, math.floor(val / 0x80), 0)

    memory.write(mem, addr, val2)
end

instructions[0x7E] = function(mem, regs)
    -- ROR
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)
    addr = addr + memory.read(mem, regs.PC) * 0x100
    regs.PC = instructions.inc16(regs.PC)

    addr = addr + regs.X

    local val = memory.read(mem, addr)

    local c = util.get_bit(regs.P, 0)

    local val2 = bit.rshift(val, 1)
    val2 = val2 + c * 0x80

    regs.P = util.set_bit(regs.P, util.get_bit(regs.P, 0), 7)
    regs.P = util.set_bit(regs.P, util.get_bit(val, 0), 0)

    val2 = val2 % 0x100

    memory.write(mem, addr, val2)

    local z = 0
    if val == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, z, 1)
end

instructions[0x3E] = function(mem, regs)
    -- ROL
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)
    addr = addr + memory.read(mem, regs.PC) * 0x100
    regs.PC = instructions.inc16(regs.PC)

    addr = addr + regs.X

    local val = memory.read(mem, addr)

    local c = util.get_bit(regs.P, 0)

    local val2 = bit.lshift(val, 1)
    val2 = val2 + c

    regs.P = util.set_bit(regs.P, util.get_bit(val, 6), 7)
    regs.P = util.set_bit(regs.P, util.get_bit(val, 7), 0)

    val2 = val2 % 0x100

    memory.write(mem, addr, val2)

    local z = 0
    if val == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, z, 1)
end

instructions[0xFE] = function(mem, regs)
    -- INC
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)
    addr = addr + memory.read(mem, regs.PC) * 0x100
    regs.PC = instructions.inc16(regs.PC)

    addr = addr + regs.X

    local val = memory.read(mem, addr)
    local val2 = instructions.inc8(val)

    local z = 0
    if val2 == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, z, 1)
    regs.P = util.set_bit(regs.P, math.floor(val2 / 0x80), 7)

    memory.write(mem, addr, val2)
end

instructions[0xDE] = function(mem, regs)
    -- DEC
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)
    addr = addr + memory.read(mem, regs.PC) * 0x100
    regs.PC = instructions.inc16(regs.PC)

    addr = addr + regs.X

    local val = memory.read(mem, addr)
    local val2 = instructions.dec8(val)

    local z = 0
    if val2 == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, z, 1)
    regs.P = util.set_bit(regs.P, math.floor(val2 / 0x80), 7)

    memory.write(mem, addr, val2)
end

instructions[0xBE] = function(mem, regs)
    -- LDX
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)
    addr = addr + memory.read(mem, regs.PC) * 0x100
    regs.PC = instructions.inc16(regs.PC)

    addr = (addr + regs.Y) % 0x10000

    regs.X = memory.read(mem, addr)

    local z = 0
    if regs.X == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, util.get_bit(regs.X, 7), 7)
    regs.P = util.set_bit(regs.P, z, 1)
end

-- LOTS OF NOP
instructions[0x04] =
    function(mem, regs) regs.PC = instructions.inc16(regs.PC) end

instructions[0x44] =
    function(mem, regs) regs.PC = instructions.inc16(regs.PC) end

instructions[0x64] =
    function(mem, regs) regs.PC = instructions.inc16(regs.PC) end

instructions[0x0C] = function(mem, regs)
    regs.PC = instructions.inc16(regs.PC)
    regs.PC = instructions.inc16(regs.PC)
end

instructions[0x14] =
    function(mem, regs) regs.PC = instructions.inc16(regs.PC) end

instructions[0x34] =
    function(mem, regs) regs.PC = instructions.inc16(regs.PC) end

instructions[0x54] =
    function(mem, regs) regs.PC = instructions.inc16(regs.PC) end

instructions[0x74] =
    function(mem, regs) regs.PC = instructions.inc16(regs.PC) end

instructions[0xD4] =
    function(mem, regs) regs.PC = instructions.inc16(regs.PC) end

instructions[0xF4] =
    function(mem, regs) regs.PC = instructions.inc16(regs.PC) end

instructions[0x1A] = function(mem, regs) end
instructions[0x3A] = function(mem, regs) end
instructions[0x5A] = function(mem, regs) end
instructions[0x7A] = function(mem, regs) end
instructions[0xDA] = function(mem, regs) end
instructions[0xFA] = function(mem, regs) end

instructions[0x80] =
    function(mem, regs) regs.PC = instructions.inc16(regs.PC) end

instructions[0x82] =
    function(mem, regs) regs.PC = instructions.inc16(regs.PC) end

instructions[0x89] =
    function(mem, regs) regs.PC = instructions.inc16(regs.PC) end

instructions[0xC2] =
    function(mem, regs) regs.PC = instructions.inc16(regs.PC) end

instructions[0xE2] =
    function(mem, regs) regs.PC = instructions.inc16(regs.PC) end

instructions[0x1C] = function(mem, regs)
    regs.PC = instructions.inc16(regs.PC)
    regs.PC = instructions.inc16(regs.PC)
end

instructions[0x3C] = function(mem, regs)
    regs.PC = instructions.inc16(regs.PC)
    regs.PC = instructions.inc16(regs.PC)
end

instructions[0x5C] = function(mem, regs)
    regs.PC = instructions.inc16(regs.PC)
    regs.PC = instructions.inc16(regs.PC)
end

instructions[0x7C] = function(mem, regs)
    regs.PC = instructions.inc16(regs.PC)
    regs.PC = instructions.inc16(regs.PC)
end

instructions[0xDC] = function(mem, regs)
    regs.PC = instructions.inc16(regs.PC)
    regs.PC = instructions.inc16(regs.PC)
end

instructions[0xFC] = function(mem, regs)
    regs.PC = instructions.inc16(regs.PC)
    regs.PC = instructions.inc16(regs.PC)
end

instructions[0xA3] = function(mem, regs)
    -- LAX
    local pc = regs.PC

    -- LDA
    instructions[0xA1](mem, regs)

    regs.PC = pc

    -- LDX
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)

    addr = (addr + regs.X) % 0x100

    local indirect = memory.read(mem, addr)
    indirect = indirect + memory.read(mem, instructions.inc8(addr)) * 0x100

    regs.X = memory.read(mem, indirect)

    local z = 0
    if regs.X == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, util.get_bit(regs.X, 7), 7)
    regs.P = util.set_bit(regs.P, z, 1)
end

instructions[0xA7] = function(mem, regs)
    -- LAX
    local pc = regs.PC
    instructions[0xA5](mem, regs)

    -- LDX
    regs.PC = pc
    instructions[0xA6](mem, regs)
end

instructions[0xAF] = function(mem, regs)
    -- LAX
    local pc = regs.PC
    instructions[0xAD](mem, regs)

    -- LDX
    regs.PC = pc
    instructions[0xAE](mem, regs)
end

instructions[0xB3] = function(mem, regs)
    -- LAX
    local pc = regs.PC
    instructions[0xB1](mem, regs)

    regs.PC = pc

    -- LDX
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)

    local indirect = memory.read(mem, addr)
    indirect = indirect + memory.read(mem, instructions.inc8(addr)) * 0x100

    indirect = (indirect + regs.Y) % 0x10000

    regs.X = memory.read(mem, indirect)

    local z = 0
    if regs.X == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, util.get_bit(regs.X, 7), 7)
    regs.P = util.set_bit(regs.P, z, 1)
end

instructions[0xB7] = function(mem, regs)
    -- LAX
    local pc = regs.PC
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)

    regs.A = memory.read(mem, (addr + regs.Y) % 0x100)

    local z = 0
    if regs.A == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, util.get_bit(regs.A, 7), 7)
    regs.P = util.set_bit(regs.P, z, 1)

    -- LDX
    regs.PC = pc
    instructions[0xB6](mem, regs)
end

instructions[0xBF] = function(mem, regs)
    -- LAX
    local pc = regs.PC
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)
    addr = addr + memory.read(mem, regs.PC) * 0x100
    regs.PC = instructions.inc16(regs.PC)

    regs.A = memory.read(mem, (addr + regs.Y) % 0x10000)

    local z = 0
    if regs.A == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, util.get_bit(regs.A, 7), 7)
    regs.P = util.set_bit(regs.P, z, 1)

    -- LDX
    regs.PC = pc
    instructions[0xBE](mem, regs)
end

instructions[0x83] = function(mem, regs)
    -- SAX
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)

    addr = (addr + regs.X) % 0x100

    local indirect = memory.read(mem, addr)
    indirect = indirect + memory.read(mem, instructions.inc8(addr)) * 0x100

    memory.write(mem, indirect, bit.band(regs.A, regs.X))
end

instructions[0x87] = function(mem, regs)
    -- SAX
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)

    memory.write(mem, addr, bit.band(regs.A, regs.X))
end

instructions[0x8F] = function(mem, regs)
    -- SAX
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)
    addr = addr + memory.read(mem, regs.PC) * 0x100
    regs.PC = instructions.inc16(regs.PC)

    memory.write(mem, addr, bit.band(regs.A, regs.X))
end

instructions[0x97] = function(mem, regs)
    -- SAX
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)

    memory.write(mem, (addr + regs.Y) % 0x100, bit.band(regs.A, regs.X))
end

instructions[0xEB] = function(mem, regs)
    -- USBC
    instructions[0xE9](mem, regs)
end

instructions[0xC3] = function(mem, regs)
    -- DCP

    -- DEC
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)

    addr = (addr + regs.X) % 0x100

    local indirect = memory.read(mem, addr)
    indirect = indirect + memory.read(mem, instructions.inc8(addr)) * 0x100

    local val = memory.read(mem, indirect)
    val = instructions.dec8(val)

    local z = 0
    if val == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, z, 1)
    regs.P = util.set_bit(regs.P, math.floor(val / 0x80), 7)

    memory.write(mem, indirect, val)

    -- CMP
    z = 0
    if regs.A == val then z = 1 end

    local c = 0
    if regs.A >= val then c = 1 end

    val = regs.A - val

    regs.P = util.set_bit(regs.P, util.get_bit(val, 7), 7)
    regs.P = util.set_bit(regs.P, z, 1)
    regs.P = util.set_bit(regs.P, c, 0)
end

instructions[0xC7] = function(mem, regs)
    -- DCP

    -- DEC
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)

    local val = memory.read(mem, addr)
    val = instructions.dec8(val)

    local z = 0
    if val == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, z, 1)
    regs.P = util.set_bit(regs.P, math.floor(val / 0x80), 7)

    memory.write(mem, addr, val)

    -- CMP
    z = 0
    if regs.A == val then z = 1 end

    local c = 0
    if regs.A >= val then c = 1 end

    val = regs.A - val

    regs.P = util.set_bit(regs.P, util.get_bit(val, 7), 7)
    regs.P = util.set_bit(regs.P, z, 1)
    regs.P = util.set_bit(regs.P, c, 0)
end

instructions[0xCF] = function(mem, regs)
    -- DCP

    -- DEC
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)
    addr = addr + memory.read(mem, regs.PC) * 0x100
    regs.PC = instructions.inc16(regs.PC)

    local val = memory.read(mem, addr)
    val = instructions.dec8(val)

    local z = 0
    if val == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, z, 1)
    regs.P = util.set_bit(regs.P, math.floor(val / 0x80), 7)

    memory.write(mem, addr, val)

    -- CMP
    z = 0
    if regs.A == val then z = 1 end

    local c = 0
    if regs.A >= val then c = 1 end

    val = regs.A - val

    regs.P = util.set_bit(regs.P, util.get_bit(val, 7), 7)
    regs.P = util.set_bit(regs.P, z, 1)
    regs.P = util.set_bit(regs.P, c, 0)
end

instructions[0xD3] = function(mem, regs)
    -- DCP

    -- DEC
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)

    local indirect = memory.read(mem, addr)
    indirect = indirect + memory.read(mem, instructions.inc8(addr)) * 0x100

    indirect = (indirect + regs.Y) % 0x10000

    local val = memory.read(mem, indirect)
    val = instructions.dec8(val)

    local z = 0
    if val == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, z, 1)
    regs.P = util.set_bit(regs.P, math.floor(val / 0x80), 7)

    memory.write(mem, indirect, val)

    -- CMP
    z = 0
    if regs.A == val then z = 1 end

    local c = 0
    if regs.A >= val then c = 1 end

    val = regs.A - val

    regs.P = util.set_bit(regs.P, util.get_bit(val, 7), 7)
    regs.P = util.set_bit(regs.P, z, 1)
    regs.P = util.set_bit(regs.P, c, 0)
end

instructions[0xD7] = function(mem, regs)
    -- DCP

    -- DEC
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)

    addr = (addr + regs.X) % 0x100

    local val = memory.read(mem, addr)
    val = instructions.dec8(val)

    local z = 0
    if val == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, z, 1)
    regs.P = util.set_bit(regs.P, math.floor(val / 0x80), 7)

    memory.write(mem, addr, val)

    -- CMP
    z = 0
    if regs.A == val then z = 1 end

    local c = 0
    if regs.A >= val then c = 1 end

    val = regs.A - val

    regs.P = util.set_bit(regs.P, util.get_bit(val, 7), 7)
    regs.P = util.set_bit(regs.P, z, 1)
    regs.P = util.set_bit(regs.P, c, 0)
end

instructions[0xDB] = function(mem, regs)
    -- DCP

    -- DEC
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)
    addr = addr + memory.read(mem, regs.PC) * 0x100
    regs.PC = instructions.inc16(regs.PC)

    addr = (addr + regs.Y) % 0x10000

    local val = memory.read(mem, addr)
    val = instructions.dec8(val)

    local z = 0
    if val == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, z, 1)
    regs.P = util.set_bit(regs.P, math.floor(val / 0x80), 7)

    memory.write(mem, addr, val)

    -- CMP
    z = 0
    if regs.A == val then z = 1 end

    local c = 0
    if regs.A >= val then c = 1 end

    val = regs.A - val

    regs.P = util.set_bit(regs.P, util.get_bit(val, 7), 7)
    regs.P = util.set_bit(regs.P, z, 1)
    regs.P = util.set_bit(regs.P, c, 0)
end

instructions[0xDF] = function(mem, regs)
    -- DCP

    -- DEC
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)
    addr = addr + memory.read(mem, regs.PC) * 0x100
    regs.PC = instructions.inc16(regs.PC)

    addr = addr + regs.X

    local val = memory.read(mem, addr)
    val = instructions.dec8(val)

    local z = 0
    if val == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, z, 1)
    regs.P = util.set_bit(regs.P, math.floor(val / 0x80), 7)

    memory.write(mem, addr, val)

    -- CMP
    z = 0
    if regs.A == val then z = 1 end

    local c = 0
    if regs.A >= val then c = 1 end

    val = regs.A - val

    regs.P = util.set_bit(regs.P, util.get_bit(val, 7), 7)
    regs.P = util.set_bit(regs.P, z, 1)
    regs.P = util.set_bit(regs.P, c, 0)
end

instructions[0xE3] = function(mem, regs)
    -- ISC
    local pc = regs.PC

    -- INC
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)

    addr = (addr + regs.X) % 0x100

    local indirect = memory.read(mem, addr)
    indirect = indirect + memory.read(mem, instructions.inc8(addr)) * 0x100

    local val = memory.read(mem, indirect)
    local val2 = instructions.inc8(val)

    local z = 0
    if val2 == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, z, 1)
    regs.P = util.set_bit(regs.P, math.floor(val2 / 0x80), 7)

    memory.write(mem, indirect, val2)

    -- SBC
    regs.PC = pc
    instructions[0xE1](mem, regs)
end

instructions[0xE7] = function(mem, regs)
    -- ISC
    local pc = regs.PC

    -- INC
    instructions[0xE6](mem, regs)

    -- SBC
    regs.PC = pc
    instructions[0xE5](mem, regs)
end

instructions[0xEF] = function(mem, regs)
    -- ISC
    local pc = regs.PC

    -- INC
    instructions[0xEE](mem, regs)

    -- SBC
    regs.PC = pc
    instructions[0xED](mem, regs)
end

instructions[0xF3] = function(mem, regs)
    -- ISC
    local pc = regs.PC

    -- INC
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)

    addr = addr

    local indirect = memory.read(mem, addr)
    indirect = indirect + memory.read(mem, instructions.inc8(addr)) * 0x100

    indirect = (indirect + regs.Y) % 0x10000

    local val = memory.read(mem, indirect)
    local val2 = instructions.inc8(val)

    local z = 0
    if val2 == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, z, 1)
    regs.P = util.set_bit(regs.P, math.floor(val2 / 0x80), 7)

    memory.write(mem, indirect, val2)

    -- SBC
    regs.PC = pc
    instructions[0xF1](mem, regs)
end

instructions[0xF7] = function(mem, regs)
    -- ISC
    local pc = regs.PC

    -- INC
    instructions[0xF6](mem, regs)

    -- SBC
    regs.PC = pc
    instructions[0xF5](mem, regs)
end

instructions[0xFB] = function(mem, regs)
    -- ISC
    local pc = regs.PC

    -- INC
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)
    addr = addr + memory.read(mem, regs.PC) * 0x100
    regs.PC = instructions.inc16(regs.PC)

    addr = addr + regs.Y

    local val = memory.read(mem, addr)
    local val2 = instructions.inc8(val)

    local z = 0
    if val2 == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, z, 1)
    regs.P = util.set_bit(regs.P, math.floor(val2 / 0x80), 7)

    memory.write(mem, addr, val2)

    -- SBC
    regs.PC = pc
    instructions[0xF9](mem, regs)
end

instructions[0xFF] = function(mem, regs)
    -- ISC
    local pc = regs.PC

    -- INC
    instructions[0xFE](mem, regs)

    -- SBC
    regs.PC = pc
    instructions[0xFD](mem, regs)
end

instructions[0x03] = function(mem, regs)
    -- SLO
    local pc = regs.PC

    -- ASL
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)

    addr = (addr + regs.X) % 0x100

    local indirect = memory.read(mem, addr)
    indirect = indirect + memory.read(mem, instructions.inc8(addr)) * 0x100

    local val = memory.read(mem, indirect)
    local val2 = bit.lshift(val, 1) % 0x100

    local z = 0
    if val2 == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, math.floor(val2 / 0x80), 7)
    regs.P = util.set_bit(regs.P, z, 1)
    regs.P = util.set_bit(regs.P, math.floor(val / 0x80), 0)

    memory.write(mem, indirect, val2)

    -- ORA
    regs.PC = pc
    instructions[0x01](mem, regs)
end

instructions[0x07] = function(mem, regs)
    -- SLO
    local pc = regs.PC

    -- ASL
    instructions[0x06](mem, regs)

    -- ORA
    regs.PC = pc
    instructions[0x05](mem, regs)
end

instructions[0x0F] = function(mem, regs)
    -- SLO
    local pc = regs.PC

    -- ASL
    instructions[0x0E](mem, regs)

    -- ORA
    regs.PC = pc
    instructions[0x0D](mem, regs)
end

instructions[0x13] = function(mem, regs)
    -- SLO
    local pc = regs.PC

    -- ASL
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)

    local indirect = memory.read(mem, addr)
    indirect = indirect + memory.read(mem, instructions.inc8(addr)) * 0x100

    indirect = (indirect + regs.Y) % 0x10000

    local val = memory.read(mem, indirect)
    local val2 = bit.lshift(val, 1) % 0x100

    local z = 0
    if val2 == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, math.floor(val2 / 0x80), 7)
    regs.P = util.set_bit(regs.P, z, 1)
    regs.P = util.set_bit(regs.P, math.floor(val / 0x80), 0)

    memory.write(mem, indirect, val2)

    -- ORA
    regs.PC = pc
    instructions[0x11](mem, regs)
end

instructions[0x17] = function(mem, regs)
    -- SLO
    local pc = regs.PC

    -- ASL
    instructions[0x16](mem, regs)

    -- ORA
    regs.PC = pc
    instructions[0x15](mem, regs)
end

instructions[0x1B] = function(mem, regs)
    -- SLO
    local pc = regs.PC

    -- ASL
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)
    addr = addr + memory.read(mem, regs.PC) * 0x100
    regs.PC = instructions.inc16(regs.PC)

    addr = (addr + regs.Y) % 0x10000

    local val = memory.read(mem, addr)
    local val2 = bit.lshift(val, 1) % 0x100

    local z = 0
    if val2 == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, math.floor(val2 / 0x80), 7)
    regs.P = util.set_bit(regs.P, z, 1)
    regs.P = util.set_bit(regs.P, math.floor(val / 0x80), 0)

    memory.write(mem, addr, val2)

    -- ORA
    regs.PC = pc
    instructions[0x19](mem, regs)
end

instructions[0x1F] = function(mem, regs)
    -- SLO
    local pc = regs.PC

    -- ASL
    instructions[0x1E](mem, regs)

    -- ORA
    regs.PC = pc
    instructions[0x1D](mem, regs)
end

instructions[0x23] = function(mem, regs)
    -- RLA
    local pc = regs.PC

    -- ROL
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)

    addr = (addr + regs.X) % 0x100

    local indirect = memory.read(mem, addr)
    indirect = indirect + memory.read(mem, instructions.inc8(addr)) * 0x100

    local val = memory.read(mem, indirect)

    local c = util.get_bit(regs.P, 0)

    local val2 = bit.lshift(val, 1)
    val2 = val2 + c

    regs.P = util.set_bit(regs.P, util.get_bit(val, 6), 7)
    regs.P = util.set_bit(regs.P, util.get_bit(val, 7), 0)

    val2 = val2 % 0x100

    memory.write(mem, indirect, val2)

    local z = 0
    if val == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, z, 1)

    -- AND
    regs.PC = pc
    instructions[0x21](mem, regs)
end

instructions[0x27] = function(mem, regs)
    -- RLA
    local pc = regs.PC

    -- ROL
    instructions[0x26](mem, regs)

    -- AND
    regs.PC = pc
    instructions[0x25](mem, regs)
end

instructions[0x2F] = function(mem, regs)
    -- RLA
    local pc = regs.PC

    -- ROL
    instructions[0x2E](mem, regs)

    -- AND
    regs.PC = pc
    instructions[0x2D](mem, regs)
end

instructions[0x33] = function(mem, regs)
    -- RLA
    local pc = regs.PC

    -- ROL
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)

    local indirect = memory.read(mem, addr)
    indirect = indirect + memory.read(mem, instructions.inc8(addr)) * 0x100

    indirect = (indirect + regs.Y) % 0x10000

    local val = memory.read(mem, indirect)

    local c = util.get_bit(regs.P, 0)

    local val2 = bit.lshift(val, 1)
    val2 = val2 + c

    regs.P = util.set_bit(regs.P, util.get_bit(val, 6), 7)
    regs.P = util.set_bit(regs.P, util.get_bit(val, 7), 0)

    val2 = val2 % 0x100

    memory.write(mem, indirect, val2)

    local z = 0
    if val == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, z, 1)

    -- AND
    regs.PC = pc
    instructions[0x31](mem, regs)
end

instructions[0x37] = function(mem, regs)
    -- RLA
    local pc = regs.PC

    -- ROL
    instructions[0x36](mem, regs)

    -- AND
    regs.PC = pc
    instructions[0x35](mem, regs)
end

instructions[0x3B] = function(mem, regs)
    -- RLA
    local pc = regs.PC

    -- ROL
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)
    addr = addr + memory.read(mem, regs.PC) * 0x100
    regs.PC = instructions.inc16(regs.PC)

    addr = (addr + regs.Y) % 0x10000

    local val = memory.read(mem, addr)

    local c = util.get_bit(regs.P, 0)

    local val2 = bit.lshift(val, 1)
    val2 = val2 + c

    regs.P = util.set_bit(regs.P, util.get_bit(val, 6), 7)
    regs.P = util.set_bit(regs.P, util.get_bit(val, 7), 0)

    val2 = val2 % 0x100

    memory.write(mem, addr, val2)

    local z = 0
    if val == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, z, 1)

    -- AND
    regs.PC = pc
    instructions[0x39](mem, regs)
end

instructions[0x3F] = function(mem, regs)
    -- RLA
    local pc = regs.PC

    -- ROL
    instructions[0x3E](mem, regs)

    -- AND
    regs.PC = pc
    instructions[0x3D](mem, regs)
end

instructions[0x43] = function(mem, regs)
    -- SRE
    local pc = regs.PC

    -- LSR
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)

    addr = (addr + regs.X) % 0x100

    local indirect = memory.read(mem, addr)
    indirect = indirect + memory.read(mem, instructions.inc8(addr)) * 0x100

    local val = memory.read(mem, indirect)
    local val2 = bit.rshift(val, 1) % 0x100

    local z = 0
    if val2 == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, 0, 7)
    regs.P = util.set_bit(regs.P, z, 1)
    regs.P = util.set_bit(regs.P, val % 2, 0)

    memory.write(mem, indirect, val2)

    -- EOR
    regs.PC = pc
    instructions[0x41](mem, regs)
end

instructions[0x47] = function(mem, regs)
    -- SRE
    local pc = regs.PC

    -- LSR
    instructions[0x46](mem, regs)

    -- EOR
    regs.PC = pc
    instructions[0x45](mem, regs)
end

instructions[0x4F] = function(mem, regs)
    -- SRE
    local pc = regs.PC

    -- LSR
    instructions[0x4E](mem, regs)

    -- EOR
    regs.PC = pc
    instructions[0x4D](mem, regs)
end

instructions[0x53] = function(mem, regs)
    -- SRE
    local pc = regs.PC

    -- LSR
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)

    local indirect = memory.read(mem, addr)
    indirect = indirect + memory.read(mem, instructions.inc8(addr)) * 0x100

    indirect = (indirect + regs.Y) % 0x10000

    local val = memory.read(mem, indirect)
    local val2 = bit.rshift(val, 1) % 0x100

    local z = 0
    if val2 == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, 0, 7)
    regs.P = util.set_bit(regs.P, z, 1)
    regs.P = util.set_bit(regs.P, val % 2, 0)

    memory.write(mem, indirect, val2)

    -- EOR
    regs.PC = pc
    instructions[0x51](mem, regs)
end

instructions[0x57] = function(mem, regs)
    -- SRE
    local pc = regs.PC

    -- LSR
    instructions[0x56](mem, regs)

    -- EOR
    regs.PC = pc
    instructions[0x55](mem, regs)
end

instructions[0x5B] = function(mem, regs)
    -- SRE
    local pc = regs.PC

    -- LSR
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)
    addr = addr + memory.read(mem, regs.PC) * 0x100
    regs.PC = instructions.inc16(regs.PC)

    addr = (addr + regs.Y) % 0x10000

    local val = memory.read(mem, addr)
    local val2 = bit.rshift(val, 1) % 0x100

    local z = 0
    if val2 == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, 0, 7)
    regs.P = util.set_bit(regs.P, z, 1)
    regs.P = util.set_bit(regs.P, val % 2, 0)

    memory.write(mem, addr, val2)

    -- EOR
    regs.PC = pc
    instructions[0x59](mem, regs)
end

instructions[0x5F] = function(mem, regs)
    -- SRE
    local pc = regs.PC

    -- LSR
    instructions[0x5E](mem, regs)

    -- EOR
    regs.PC = pc
    instructions[0x5D](mem, regs)
end

instructions[0x63] = function(mem, regs)
    -- RRA
    local pc = regs.PC

    -- ROR
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)

    addr = (addr + regs.X) % 0x100

    local indirect = memory.read(mem, addr)
    indirect = indirect + memory.read(mem, instructions.inc8(addr)) * 0x100

    local val = memory.read(mem, indirect)

    local c = util.get_bit(regs.P, 0)

    local val2 = bit.rshift(val, 1)
    val2 = val2 + c * 0x80

    regs.P = util.set_bit(regs.P, util.get_bit(regs.P, 0), 7)
    regs.P = util.set_bit(regs.P, util.get_bit(val, 0), 0)

    val2 = val2 % 0x100

    memory.write(mem, indirect, val2)

    local z = 0
    if val == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, z, 1)

    -- ADC
    regs.PC = pc
    instructions[0x61](mem, regs)
end

instructions[0x67] = function(mem, regs)
    -- RRA
    local pc = regs.PC

    -- ROR
    instructions[0x66](mem, regs)

    -- ADC
    regs.PC = pc
    instructions[0x65](mem, regs)
end

instructions[0x6F] = function(mem, regs)
    -- RRA
    local pc = regs.PC

    -- ROR
    instructions[0x6E](mem, regs)

    -- ADC
    regs.PC = pc
    instructions[0x6D](mem, regs)
end

instructions[0x73] = function(mem, regs)
    -- RRA
    local pc = regs.PC

    -- ROR
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)

    local indirect = memory.read(mem, addr)
    indirect = indirect + memory.read(mem, instructions.inc8(addr)) * 0x100

    indirect = (indirect + regs.Y) % 0x10000

    local val = memory.read(mem, indirect)

    local c = util.get_bit(regs.P, 0)

    local val2 = bit.rshift(val, 1)
    val2 = val2 + c * 0x80

    regs.P = util.set_bit(regs.P, util.get_bit(regs.P, 0), 7)
    regs.P = util.set_bit(regs.P, util.get_bit(val, 0), 0)

    val2 = val2 % 0x100

    memory.write(mem, indirect, val2)

    local z = 0
    if val == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, z, 1)

    -- ADC
    regs.PC = pc
    instructions[0x71](mem, regs)
end

instructions[0x77] = function(mem, regs)
    -- RRA
    local pc = regs.PC

    -- ROR
    instructions[0x76](mem, regs)

    -- ADC
    regs.PC = pc
    instructions[0x75](mem, regs)
end

instructions[0x7B] = function(mem, regs)
    -- RRA
    local pc = regs.PC

    -- ROR
    local addr = memory.read(mem, regs.PC)
    regs.PC = instructions.inc16(regs.PC)
    addr = addr + memory.read(mem, regs.PC) * 0x100
    regs.PC = instructions.inc16(regs.PC)

    addr = (addr + regs.Y) % 0x10000

    local val = memory.read(mem, addr)

    local c = util.get_bit(regs.P, 0)

    local val2 = bit.rshift(val, 1)
    val2 = val2 + c * 0x80

    regs.P = util.set_bit(regs.P, util.get_bit(regs.P, 0), 7)
    regs.P = util.set_bit(regs.P, util.get_bit(val, 0), 0)

    val2 = val2 % 0x100

    memory.write(mem, addr, val2)

    local z = 0
    if val == 0 then z = 1 end

    regs.P = util.set_bit(regs.P, z, 1)

    -- ADC
    regs.PC = pc
    instructions[0x79](mem, regs)
end

instructions[0x7F] = function(mem, regs)
    -- RRA
    local pc = regs.PC

    -- ROR
    instructions[0x7E](mem, regs)

    -- ADC
    regs.PC = pc
    instructions[0x7D](mem, regs)
end

return instructions
