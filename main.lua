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
local Systems = {}
Concord.utils.loadNamespace("systems/", Systems)
for _, s in pairs(Systems) do
    world:addSystem(s)
end

local entities = require("entities")

local allySquad = Concord.entity(world)
    :assemble(entities.allySquad)
    :give("playerMovable")

local firstPlayer = Concord.entity(world)
    :assemble(entities.soldier, "player1")

love.draw = function()
    world:emit("draw")
end

love.update = function (dt)

    controller:update()
    world:emit("toTangible")
    world:emit('playerMove', controller)
    world:emit('lookForTarget')
    world:emit('followTarget')
    world:emit('followSquad')

    world:emit("update", dt)
    world:emit("detectCollision", dt)
    world:emit("combat", dt)
    world:emit("removeKilled")
    world:emit("spawn")
end

love.load = function ()
end

love.joystickadded = function (_)
    -- TODO: don't know why the function's first parameter
    -- which should be a joystick object does not work as parameter
    controller.config.joystick = love.joystick.getJoysticks()[1]
end
