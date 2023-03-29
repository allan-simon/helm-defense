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

function CollisionSystem:detectCollision()
    local world = self:getWorld()
    for _, e in ipairs(self.pool) do
        local shape = e.tangible.shape
        local velocity = e.velocity
        local collisions = HC.collisions(shape)
        for other, separating_vector in pairs(collisions) do
            print(shape._key, "with other", other._key)

            velocity.x = 0
            velocity.y = 0
            otherE = world:getEntityByKey(other._key)
            otherE.velocity.x = 0
            otherE.velocity.y = 0

            e:ensure("inCombat", otherE.key.value)
            e:ensure("cantMove")
            otherE:ensure("inCombat", e.key.value)
            otherE:ensure("cantMove")

            shape:move(separating_vector.x,  separating_vector.y)

        end
    end
end

local CombatSystem = Concord.system({
    pool = {"inCombat"}
})

function CombatSystem:combat()
    local world = self:getWorld()
    for _, e in ipairs(self.pool) do
        defender = world:getEntityByKey(e.inCombat.with)
        if defender == nil then
            e:remove("inCombat")
            e:remove("cantMove")
        end
        if (defender:has('killable')) then

            defender.killable.lifePoint = defender.killable.lifePoint - 1
            if defender.killable.lifePoint  <= 0 then
                defender:ensure("killed")
                e:remove("inCombat")
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
        print("coucou")
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
