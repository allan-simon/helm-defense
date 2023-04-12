local Concord = require("Concord")
local HC = require("HC")


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

return KillRemoverSystem
