local Concord = require("Concord")

local MoveSystem = Concord.system({
    pool = {"tangible", "velocity"}
})

function MoveSystem:update(dt)
    for _, e in ipairs(self.pool) do
        e.tangible.shape:move(
            e.velocity.x * dt,
            e.velocity.y * dt
        )
    end
end


local DrawSystem = Concord.system({
    pool = {"tangible", "drawable"}
})

function DrawSystem:draw()
    for _, e in ipairs(self.pool) do
        local shape = e.tangible.shape
        x, y = shape:center()
        love.graphics.draw(
            e.drawable.image,
            x,
            y,
            shape:rotation(),
            1,
            1,
            e.drawable.width * 0.5,
            e.drawable.height * 0.5
        )
    end
end

local PlayerActionSystem = Concord.system({
    pool = {"tangible", "velocity", "playerMovable"}
})

local atan2 = math.atan2
function PlayerActionSystem:playerMove(player)
    local x, y = player:get('move')

    local angle = nil
    -- if x and y are both 0 it means we're not moving
    -- so we don't have the angle
    if x ~= 0 or y ~= 0 then
        angle = atan2(y, x) + math.pi * 0.5
    end
    for _, e in ipairs(self.pool) do
        if e:has('cantMove') then
            goto continue
        end

        if angle ~= nil then
            e.tangible.shape:setRotation(angle)
        end

        e.velocity.x = x * 100
        e.velocity.y = y * 100

        ::continue::
    end
end

local FollowTargetSystem = Concord.system({
    pool = {"tangible", "velocity", "hasTarget"}
})

function FollowTargetSystem:followTarget()
    local world = self:getWorld()
    for _, e in ipairs(self.pool) do
        if e:has('cantMove') then
            goto continue
        end

        local target = world:getEntityByKey(e.hasTarget.target)

        local tX, tY = target.tangible.shape:center()
        local eX, eY = e.tangible.shape:center()

        -- we get the angle between the follower and its target
        local dx = tX - eX
        local dy = tY - eY

        local angle = atan2(dy, dx)

        -- and we use it to adapt the velocity to go toward the target
        e.velocity.x = math.cos(angle) * 90
        e.velocity.y = math.sin(angle) * 90

        ::continue::
    end
end

local DrawableToTangibleSystem = Concord.system({
    pool = {"drawable", "futureTangible"}
})

local HC = require("HC")
function DrawableToTangibleSystem:toTangible()
    for _, e in ipairs(self.pool) do

        local width = e.drawable.width
        local height = e.drawable.height

        local rectangle = HC.rectangle(
            e.futureTangible.x - width * 0.5,
            e.futureTangible.y - height * 0.5,
            width,
            height
        )
        rectangle._key = e.key.value

        e:give(
            'tangible',
            rectangle
        )
        :remove("futureTangible")
    end
end

local CollisionSystem = Concord.system({
    pool = {"tangible", "velocity"}
})

local pi = math.pi
local fourth_of_pi = math.pi * 0.25
function CollisionSystem:detectCollision(dt)
    local world = self:getWorld()
    for _, e in ipairs(self.pool) do
        local shape = e.tangible.shape
        local velocity = e.velocity
        local collisions = HC.collisions(shape)
        for other, separating_vector in pairs(collisions) do
            print(shape._key, "with other", other._key)
            local otherE = world:getEntityByKey(other._key)


             -- shape:move(separating_vector.x*1.0001,  separating_vector.y * 1.0001)
             shape:move((otherE.velocity.x - velocity.x)*dt, (otherE.velocity.y - velocity.y)*dt)

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
                otherE:ensure("cantMove")
            end
            --the other attacks and you hence can't move
            -- except if the other is touched from the back
            if otherTouchedDirection ~= "back" then
                otherE:ensure("attacking", e.key.value, otherTouchedDirection, touchedDirection)
                e:ensure("cantMove")
            end

        end
    end
end

local CombatSystem = Concord.system({
    pool = {"attacking"}
})

function CombatSystem:combat()
    local world = self:getWorld()
    for _, e in ipairs(self.pool) do
        print(e.key.value, " is attacking ", e.attacking.with, "from ", e.attacking.attackingUsingSide)
        defender = world:getEntityByKey(e.attacking.with)
        if defender == nil then
            e:remove("attacking")
            e:remove("cantMove")
        end
        if (defender:has('killable')) then

            local attackPoint = 1
            if e.attacking.attackedSide == 'back' then
                attackPoint = 2
            end


            defender.killable.lifePoint = defender.killable.lifePoint - attackPoint
            if defender.killable.lifePoint  <= 0 then
                defender:ensure("killed")
                e:remove("attacking")
                e:remove("cantMove")
            end
        end

    end
end

local KillRemoverSystem = Concord.system({
    pool = {"killed"}
})

function KillRemoverSystem:removeKilled()
    for _, e in ipairs(self.pool) do
        if e:has("tangible") then
            HC.remove(e.tangible.shape)
        end
        e:destroy()
    end
end


local entities = require("entities")

local EnemySpawnerSystem = Concord.system({pool = {"killable"} })
function EnemySpawnerSystem:spawn(player)
    local world = self:getWorld()
    local needSpawn = true
    for _, e in ipairs(self.pool) do
        if e:has("enemy") then
            needSpawn = false
            break
        end
    end

    if needSpawn then
        Concord.entity(world)
            :assemble(entities.ennemy, player)
    end

end

return {
    DrawSystem,
    PlayerActionSystem,
    DrawableToTangibleSystem,
    FollowTargetSystem,
    MoveSystem,
    CombatSystem,
    CollisionSystem,
    KillRemoverSystem,
    EnemySpawnerSystem,
}
