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

local firstPlayer = Concord.entity(world)
    :assemble(entities.soldier, "player1")

Concord.entity(world)
    :assemble(entities.ennemy, firstPlayer.key.value)


love.draw = function()
    world:emit("draw")
end

love.update = function (dt)
    print("update")
    controller:update()
    world:emit("toTangible")
    world:emit('playerMove', controller)
    world:emit('followTarget')
    world:emit("update", dt)
    world:emit("detectCollision")
    world:emit("combat", dt)
    world:emit("removeKilled")
    world:emit("spawn", firstPlayer.key.value)
end

love.load = function ()
end
