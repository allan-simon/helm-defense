local baton = require 'baton'

local Concord = require("Concord")
local world = Concord.world()

local player = baton.new {
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


local soldier = Concord.entity(world)
:give("key", "robert")
:give("futureTangible", 100, 100)
:give("velocity", 100, 0)
:give("drawable", 'soldier.png')
:give("playerMovable")
:give("killable", 100)

local ennemy = Concord.entity(world)
:give("key", "michel")
:give("futureTangible", 500, 100, math.deg(90))
:give("velocity", -100, 0)
:give("drawable", 'ennemy.png')
:give("hasTarget", soldier.key.value)
:give("killable", 10)


love.draw = function()
    world:emit("draw")
end

love.update = function (dt)
    player:update()
    world:emit('playerMove', player)
    world:emit('followTarget')
    world:emit("update", dt)
    world:emit("detectCollision")
    world:emit("combat", dt)
    world:emit("removeKilled")
end

love.load = function ()
    world:emit("toTangible")
end
