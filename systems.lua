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
    print(x, y)

    local angle = nil
    -- if x and y are both 0 it means we're not moving
    -- so we don't have the angle
    if x ~= 0 or y ~= 0 then
        angle = atan2(y, x) + math.pi * 0.5
    end
    print(angle)
    for _, e in ipairs(self.pool) do
        if angle ~= nil then
            e.tangible.shape:setRotation(angle)
        end
        e.velocity.x = x * 100
        e.velocity.y = y * 100
    end
end

local FollowTargetSystem = Concord.system({
    pool = {"tangible", "velocity", "hasTarget"}
})

function FollowTargetSystem:followTarget()
    for _, e in ipairs(self.pool) do
        local target = e.hasTarget.target

        local tX, tY = target.tangible.shape:center()
        local eX, eY = e.tangible.shape:center()

        -- we get the angle between the follower and its target
        local dx = tX - eX
        local dy = tY - eY

        local angle = atan2(dy, dx)

        -- and we use it to adapt the velocity to go toward the target
        e.velocity.x = math.cos(angle) * 90
        e.velocity.y = math.sin(angle) * 90
    end
end

local DrawableToTangibleSystem = Concord.system({
    pool = {"drawable", "futureTangible"}
})

local HC = require("HC")
function DrawableToTangibleSystem:toTangible()
    for _, e in ipairs(self.pool) do
        print("coucou")

        local width = e.drawable.width
        local height = e.drawable.height
        e:give(
            'tangible',
            HC.rectangle(
                e.futureTangible.x - width * 0.5,
                e.futureTangible.y - height * 0.5,
                width,
                height
            )
        )
        :remove("futureTangible")
    end
end

local CollisionSystem = Concord.system({
    pool = {"tangible"}
})

function CollisionSystem:detectCollision()
    for _, e in ipairs(self.pool) do
        local shape = e.tangible.shape
        local collisions = HC.collisions(shape)
        for other, separating_vector in pairs(collisions) do
            shape:move( separating_vector.x * 0.5,  separating_vector.y * 0.5)
            other:move(-separating_vector.x * 0.5, -separating_vector.y * 0.5)
        end
    end
end

return {
    DrawSystem,
    PlayerActionSystem,
    DrawableToTangibleSystem,
    FollowTargetSystem,
    MoveSystem,
    CollisionSystem,
}
