local Concord = require("Concord")

local DrawSystem = Concord.system({
    pool = {"tangible", "drawable"},
    squad = {"squad", "tangible"}
})

function DrawSystem:draw()
    for _, e in ipairs(self.pool) do
        local shape = e.tangible.shape
        local x, y = shape:center()
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

    for _, e in ipairs(self.squad) do
        e.tangible.shape:draw('line')
        for _, unitRank in ipairs(e.tangibleSquad.unitRanks) do
           unitRank:draw('line')
        end
    end
end

return DrawSystem
