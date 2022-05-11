local controller = {}

CONTROLLER = {}
CONTROLLER[0] = 0
CONTROLLER[1] = 0
CONTROLLER[2] = 0
CONTROLLER[3] = 0
CONTROLLER[4] = 0
CONTROLLER[5] = 0
CONTROLLER[6] = 0
CONTROLLER[7] = 0

CONTROLLER_SHIFT = 0
CONTROLLER_POLL = 0

function controller.tick()
    if CONTROLLER_POLL == 1 then
        -- print("RESETTING CONTROLLER_SHIFT")
        CONTROLLER_SHIFT = 0
    end
end

function love.keypressed(key, scancode, isrepeat)
    if isrepeat then return end

    if key == "escape" then love.event.quit() end
    if key == "ralt" then DEBUG_OUTPUT = not DEBUG_OUTPUT end
    if key == "z" then CONTROLLER[0] = 1 end
    if key == "x" then CONTROLLER[1] = 1 end
    if key == "rshift" then CONTROLLER[2] = 1 end
    if key == "return" then CONTROLLER[3] = 1 end
    if key == "up" then CONTROLLER[4] = 1 end
    if key == "down" then CONTROLLER[5] = 1 end
    if key == "left" then CONTROLLER[6] = 1 end
    if key == "right" then CONTROLLER[7] = 1 end
end

function love.keyreleased(key, scancode)
    if key == "escape" then love.event.quit() end
    if key == "z" then CONTROLLER[0] = 0 end
    if key == "x" then CONTROLLER[1] = 0 end
    if key == "rshift" then CONTROLLER[2] = 0 end
    if key == "return" then CONTROLLER[3] = 0 end
    if key == "up" then CONTROLLER[4] = 0 end
    if key == "down" then CONTROLLER[5] = 0 end
    if key == "left" then CONTROLLER[6] = 0 end
    if key == "right" then CONTROLLER[7] = 0 end
end

return controller
