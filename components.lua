local Concord = require("Concord")
Concord.component("futureTangible", function(c, x, y, rotation)
    c.x = x or 0
    c.y = y or 0
    c.rotation = rotation or 0
end)

Concord.component("velocity", function(c, maxSpeed, x, y)
    c.maxSpeed = maxSpeed
    c.x = x or 0
    c.y = y or 0
end)

Concord.component("drawable", function(c, imagePath)
    c.image = love.graphics.newImage(imagePath)
    c.width = c.image:getWidth()
    c.height = c.image:getHeight()
end)


Concord.component("attacking",function( c, with, attackingUsingSide, attackedSide)
    c.with = with
    c.attackingUsingSide = attackingUsingSide
    c.attackedSide = attackedSide
end)

Concord.component("cantMove")

Concord.component("playerMovable", function (c)
    c.angles = {}
end)

Concord.component("needTarget")
Concord.component("hasTarget", function(c, target)
    c.target = target
end)

Concord.component("tangible", function(c, shape)
    c.shape = shape
end)

Concord.component("killable", function(c, lifePoint)
    c.lifePoint = lifePoint
end)
Concord.component("killed")
Concord.component("team", function(c, teamNumber)
    c.teamNumber = teamNumber
end)


--
Concord.component("followSquad")
Concord.component("squad", function(c, units)
    c.units = units
end)

Concord.component("tangibleSquad", function(c, unitRanks)
    print(unitRanks)
    c.unitRanks = unitRanks
end)
