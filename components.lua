local Concord = require("Concord")
Concord.component("futureTangible", function(c, x, y, rotation)
    c.x = x or 0
    c.y = y or 0
    c.rotation = rotation or 0
end)

Concord.component("velocity", function(c, x, y)
    c.x = x or 0
    c.y = y or 0
end)

Concord.component("drawable", function(c, imagePath)
    c.image = love.graphics.newImage(imagePath)
    c.width = c.image:getWidth()
    c.height = c.image:getHeight()
end)

Concord.component("inCombat",function( c, with)
    c.with = with
end)

Concord.component("cantMove")

Concord.component("playerMovable")

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
