
function soldier(e, name)
    e
    :give("key", name)
    :give("futureTangible", 100, 100)
    :give("velocity", 100, 0)
    :give("drawable", 'soldier.png')
    :give("playerMovable")
    :give("killable", 100)
end


function ennemy(e, target)
    e
    :give("key")
    :give("futureTangible", 500, 100, math.deg(90))
    :give("velocity", -100, 0)
    :give("drawable", 'ennemy.png')
    :give("hasTarget", target)
    :give("killable", 10)
    :give("enemy")
end


return {
    soldier=soldier,
    ennemy=ennemy
}
