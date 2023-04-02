local baton = require 'baton'

local Concord = require("Concord")
local world = Concord.world()

local controller = baton.new {
	controls = {
		left = {'key:a', 'key:left', 'axis:leftx-', 'button:dpleft'},
		right = {'key:d', 'key:right', 'axis:leftx+', 'button:dpright'},
		up = {'key:w', 'key:up', 'axis:lefty-', 'button:dpup'},
		down = {'key:s', 'key:down', 'axis:lefty+', 'button:dpdown'},
		action = {'key:x', 'button:a', 'mouse:1'},
	},
	pairs = {
		move = {'left', 'right', 'up', 'down'}
	},
	joystick = love.joystick.getJoysticks()[1],
}

require('components')
world:addSystems(unpack(require('systems')))

local entities = require("entities")

local allySquad = Concord.entity(world)
    :assemble(entities.allySquad)

local firstPlayer = Concord.entity(world)
    :assemble(entities.soldier, "player1")
    :give("playerMovable")

Concord.entity(world)
    :assemble(entities.enemy, firstPlayer.key.value)


love.draw = function()
    world:emit("draw")
end

local elapsedTime = 0

love.update = function (dt)

    -- be able to plug joystick after game has began
    elapsedTime = elapsedTime + dt
    if  controller.config.joystick == nil and elapsedTime > 5 then
        controller.config.joystick = love.joystick.getJoysticks()[1]
    end

    controller:update()
    world:emit("toTangible")
    world:emit('playerMove', controller)
    world:emit('lookForTarget')
    world:emit('followTarget')

    -- TODO: emit('unit should get to their place in the squad')

    world:emit("update", dt)
    world:emit("detectCollision", dt)
    world:emit("combat", dt)
    world:emit("removeKilled")
    world:emit("spawn")
end

love.load = function ()
end
