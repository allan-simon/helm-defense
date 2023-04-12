local Concord = require("Concord")
local HC = require("HC")

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

return FindTargetSystem
