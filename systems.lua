local Concord = require("Concord")
local HC = require("HC")
local atan2 = math.atan2



local CollisionSystem = Concord.system({
    pool = {"tangible", "velocity"}
})

local pi = math.pi
local fourth_of_pi = math.pi * 0.25
function CollisionSystem:detectCollision(_)
    local world = self:getWorld()
    for _, e in ipairs(self.pool) do
        local teamNumber = e.team.teamNumber
        local shape = e.tangible.shape
        if shape._ghost == true then
            goto bigContinue
        end
        local velocity = e.velocity
        local collisions = HC.collisions(shape)
        for other, separating_vector in pairs(collisions) do

            if other._ghost == true then
                goto continue
            end


            -- print(shape._key, "with other", other._key)
            local otherE = world:getEntityByKey(other._key)

            shape:move(separating_vector.x*1.0001,  separating_vector.y * 1.0001)
            --if (other
            -- shape:move((otherE.velocity.x - velocity.x)*dt, (otherE.velocity.y - velocity.y)*dt)

            if teamNumber == otherE.team.teamNumber then
                goto continue
            end

            -- we get the angle from the two centroid to know
            -- we normalize to its rotation
            -- if between -45/45 -> up  45/135 -> right etc.
            local tX, tY = other:center()
            local eX, eY = shape:center()

            -- we get the angle between the follower and its target
            local dx = tX - eX
            local dy = tY - eY
            local angle = atan2(dy, dx)
            -- we get the relative angle to the follower
            local relativeAngle = (angle - shape:rotation()) % (2*pi)

            local touchedDirection = "right"
            if relativeAngle < fourth_of_pi then
                touchedDirection = "right"
            elseif relativeAngle < 3*fourth_of_pi then
                touchedDirection = "back"
            elseif relativeAngle < 5 *fourth_of_pi then
                touchedDirection = "left"
            elseif relativeAngle < 7 *fourth_of_pi then
                touchedDirection = "front"
            else
                touchedDirection = "right"
            end

            local otherAngle = (angle + pi) % (2*pi)

            local otherRelativeAngle = (otherAngle - other:rotation()) % (2*pi)
            local otherTouchedDirection = "right"
            if otherRelativeAngle < fourth_of_pi then
                otherTouchedDirection = "right"
            elseif otherRelativeAngle < 3*fourth_of_pi then
                otherTouchedDirection = "back"
            elseif otherRelativeAngle < 5 *fourth_of_pi then
                otherTouchedDirection = "left"
            elseif otherRelativeAngle < 7 *fourth_of_pi then
                otherTouchedDirection = "front"
            else
                otherTouchedDirection = "right"
            end


            velocity.x = 0
            velocity.y = 0
            otherE.velocity.x = 0
            otherE.velocity.y = 0

            -- you attack and the other hence can't move
            -- except if you are touched from the back
            if touchedDirection ~= "back" then
                e:ensure("attacking", otherE.key.value, touchedDirection, otherTouchedDirection)
                otherE:ensure("cantMove", e.key.value)
            end
            --the other attacks and you hence can't move
            -- except if the other is touched from the back
            if otherTouchedDirection ~= "back" then
                otherE:ensure("attacking", e.key.value, otherTouchedDirection, touchedDirection)
                e:ensure("cantMove", otherE.key.value)
            end


            ::continue::
        end
        ::bigContinue::
    end
end


local KillRemoverSystem = Concord.system({
    pool = {"killed"}
})

function KillRemoverSystem:removeKilled()
    local world = self:getWorld()
    for _, e in ipairs(self.pool) do
        print("remove killed")
        if e:has("tangible") then
            HC.remove(e.tangible.shape)
            if e:has("tangibleSquad") then
                for _, point in ipairs(e.tangibleSquad.unitRanks) do
                    HC.remove(point)
                end
            end
        end
        if e:has("inSquad") then
            local squad = world:getEntityByKey(e.inSquad.key)
            squad:ensure("futureTangible")
        end
        e:destroy()
    end
end

--

local FindTargetSystem = Concord.system({pool = {"needTarget", "tangible", "team"} })
function FindTargetSystem:lookForTarget()

    local world = self:getWorld()
    local spatialHash = HC.hash()


    for _, e in ipairs(self.pool) do

        local nearest = nil
        local distance = math.huge


        local eX, eY = e.tangible.shape:center()

        for _, shape in pairs(spatialHash:shapes()) do
            if shape._ghost == true then
                -- some shape like "point" where a unit must stand in squad
                -- or the shape of the squad itsel should not be collidable
                goto continue
            end
            local target = world:getEntityByKey(shape._key)

            if e.team.teamNumber ~= (target:has('team') and target.team.teamNumber or e.team.teamNumber) then

                local x, y = shape:center()
                local currentDistance = (
                    (eX - x)*(eX - x) +
                    (eY - y)*(eY - y)
                )
                if currentDistance < distance then
                    nearest = shape._key
                    distance = currentDistance
                end
            end
            ::continue::
        end

        if nearest ~= nil and not e:has('playerMovable') then
            e:remove('needTarget')
            e:ensure('hasTarget', nearest)
        end

    end
end

--

local entities = require("entities")
local EnemySpawnerSystem = Concord.system({pool = {"killable"} })
function EnemySpawnerSystem:spawn(player)
    local world = self:getWorld()
    local needSpawn = true
    for _, e in ipairs(self.pool) do
        if e:has("team") and e.team.teamNumber == 2 then
            needSpawn = false
            break
        end
    end

    if needSpawn then
        Concord.entity(world)
            :assemble(entities.enemy, player)
    end

end

return {
    CollisionSystem,
    KillRemoverSystem,
    EnemySpawnerSystem,
    FindTargetSystem,
}
