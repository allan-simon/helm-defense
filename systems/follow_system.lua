local Concord = require("Concord")
local atan2 = math.atan2

local FollowSystem = Concord.system({
    followTargetpool = {"tangible", "velocity", "hasTarget"},
    followSquadPool = {"tangible", "tangibleSquad"},
})

local function goTowardShape(e, targetShape, tolerance)
    tolerance = tolerance or 0

    local tX, tY = targetShape:center()
    local eX, eY = e.tangible.shape:center()

    -- we get the angle between the follower and its target
    local dx = tX - eX
    local dy = tY - eY

    -- no need to for perfect precision
    -- if you reached your destination up to the tolerance threshold
    -- we stop you there
    if ((dx*dx + dy*dy) <  tolerance*tolerance) then
        e.velocity.x = 0
        e.velocity.y = 0
        return
    end

    local angle = atan2(dy, dx) + math.pi * 0.5

    -- and we use it to adapt the velocity to go toward the target
    e.velocity.x = math.sin(angle) * e.velocity.maxSpeed
    e.velocity.y = -1 * math.cos(angle) * e.velocity.maxSpeed

    e.tangible.shape:setRotation(angle)

end

function FollowSystem:followSquad()
    local world = self:getWorld()
    for _, e in ipairs(self.followSquadPool) do

        local unitRanks = e.tangibleSquad.unitRanks

        for _, unitRank in ipairs(unitRanks) do
            local unit = world:getEntityByKey(unitRank._key)
            if unit == nil then
                goto continue
            end
            if unit:has('cantMove') then
                -- we verify the one blocking us is still there
                if world:getEntityByKey(unit.cantMove.blockedByKey) == nil then
                    unit:remove('cantMove')
                else
                    goto continue
                end
            end
            -- we allow a tolerance of 1
            -- otherwise the units would never quite reach the exact point
            -- and would move back and forth continously
            goTowardShape(unit, unitRank, 1)
            -- if the unit has stopped moving it means it has its destination
            -- so we realign it with the squad direction to have the "soldier in line"
            -- feeling
            if unit.velocity.x == 0 and unit.velocity.y == 0 then
                unit.tangible.shape:setRotation(e.tangible.shape:rotation())
            end
            ::continue::
        end
    end
end

function FollowSystem:followTarget()
    local world = self:getWorld()
    for _, e in ipairs(self.followTargetpool) do
        if e:has('cantMove') then
            goto continue
        end

        local target = world:getEntityByKey(e.hasTarget.target)

        goTowardShape(e, target.tangible.shape)

        ::continue::
    end
end

return FollowSystem
