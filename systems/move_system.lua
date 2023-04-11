local Concord = require("Concord")

local MoveSystem = Concord.system({
    pool = {"tangible", "velocity"}
})

function MoveSystem:update(dt)
    for _, e in ipairs(self.pool) do

        -- TODO the rotation change maybe should be there
        -- so handling volte-face of squad (even those not player controlled)
        -- is all done at the same place
        e.tangible.shape:move(
            e.velocity.x * dt,
            e.velocity.y * dt
        )
        if e:has('tangibleSquad') then
            for _, unitRank in ipairs(e.tangibleSquad.unitRanks) do
                unitRank:move(
                    e.velocity.x * dt,
                    e.velocity.y * dt
                )
            end
        end
    end
end

return MoveSystem
