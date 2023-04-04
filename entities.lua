local Concord = require("Concord")

local function soldier(e, name)
    e
    :give("key", name)
    :give("futureTangible", 200, 400)
    :give("velocity", 100)
    :give("drawable", 'soldier.png')
    :give("team", 1)
    :give("killable", 100)
end


local function enemy(e, target)
    e
    :give("key")
    :give("futureTangible", 500, 100, math.deg(90))
    :give("velocity", 90)
    :give("drawable", 'ennemy.png')
    :give("needTarget")
    :give("killable", 10)
    :give("team", 2)
end


local function allySquad(e)
    local world = e:getWorld()

    e
    :give("key")
    :give("team", 1)
    :give("futureTangible")
    :give("velocity", 100, 0, 0)

    local keys = {}
    for i = 1,10 do
        local s = Concord.entity(world)
            :assemble(soldier, nil)
            :give("followSquad")
        keys[i] = s.key.value
    end

    e:give("squad", keys)

end


return {
    soldier=soldier,
    enemy=enemy,
    allySquad=allySquad,
}
