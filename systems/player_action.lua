local Concord = require("Concord")
local atan2 = math.atan2

local PlayerActionSystem = Concord.system({
    pool = {"tangible", "velocity", "playerMovable"}
})

function PlayerActionSystem:playerMove(player)
    local world = self:getWorld()
    local x, y = player:get('move')

    local angle = nil
    -- if x and y are both 0 it means we're not moving
    -- so we don't have the angle
    if x ~= 0 or y ~= 0 then
        angle = atan2(y, x) + math.pi * 0.5
    end
    for _, e in ipairs(self.pool) do
        if e:has('cantMove') then
            -- we verify the one blocking us is still there
            if world:getEntityByKey(e.cantMove.blockedByKey) == nil then
                e:remove('cantMove')
            else
                goto continue
            end
        end
        e.velocity.x = x * e.velocity.maxSpeed
        e.velocity.y = y * e.velocity.maxSpeed

        local shape = e.tangible.shape
        if angle == nil then
            -- we reinit the angle buffer
            -- when you stop moving, so that the buffer does not grow and grow
            e.playerMovable.angles = {}
            goto continue
        end
        table.insert(e.playerMovable.angles, angle)
        local currentAngle = shape:rotation()
        -- when you release the keys of going in diagonal
        -- during a very short instant you will have only
        -- one key press, not two
        -- so instead we take only the nth last angle to avoid this
        local actualAngle = e.playerMovable.angles[
            -- with the same logic we discard the nth first
            -- input because they are not reliable
            -- TODO: we should do this only for keyboard
            math.max(7, #e.playerMovable.angles - 7)
        ] or currentAngle

        local centerX, centerY = shape:center()

        -- if the angle hasn't changed, there's nothing to do
        if actualAngle == currentAngle then
            goto continue
        end

        if e:has('tangibleSquad') then

            -- if the squad has rotated by nearly 180 degree
            -- we rotate the unit rank on itself rather than on the
            -- squad center, otherwise when doing a 180 degree turn
            -- suddenly the unit at the most left will run to the most right
            -- which is notl
            if (currentAngle - actualAngle) % math.pi < 0.01 then
                for _, unitRank in ipairs(e.tangibleSquad.unitRanks) do
                    unitRank:setRotation(actualAngle)
                end
            else
                for _, unitRank in ipairs(e.tangibleSquad.unitRanks) do
                    unitRank:setRotation(actualAngle, centerX, centerY)
                end
            end
        end
        shape:setRotation(actualAngle)

        ::continue::
    end
end

return PlayerActionSystem
