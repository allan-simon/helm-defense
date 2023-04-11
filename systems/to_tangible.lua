local Concord = require("Concord")
local HC = require("HC")

local ToTangibleSystem = Concord.system({
    pool = {"drawable", "futureTangible"},
    squads = {"futureTangible", "squad"}
})

function ToTangibleSystem:toTangible()
    local world = self:getWorld()
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

    for _, e in ipairs(self.squads) do
        local sumX = 0
        local sumY = 0

        local sumWidth = 0
        local sumHeight = 0

        -- TODO: compute the "circular mean"
        -- local _sumAngleX = 0
        -- local _sumAngleY = 0

        local units = {}
        for _, unitKey in ipairs(e.squad.units) do
            local unit = world:getEntityByKey(unitKey)
            -- remove dead units
            if unit == nil then
                goto continue
            end
            units[#units+1] = unitKey


            local x, y = unit.tangible.shape:center()
            sumX = sumX + x
            sumY = sumY + y

            sumWidth = sumWidth + unit.drawable.width
            sumHeight = sumHeight + unit.drawable.height

            ::continue::
        end
        e.squad.units = units
        if #units == 0 then
            e:ensure('killed')
            goto bigContinue
        end

        local numberUnits = #e.squad.units
        local gap = 2
        -- we add a gap of 2 between each units
        local totalWidth = sumWidth + ((numberUnits - 1) * gap)
        local totalHeight = sumHeight / numberUnits


        local rectangle = HC.rectangle(
            (sumX/numberUnits) - totalWidth* 0.5,
            (sumY/numberUnits) - totalHeight* 0.5,
            totalWidth,
            totalHeight
        )
        rectangle._ghost = true
        local centerX, centerY = rectangle:center()
        print(centerX, centerY)

        local widthOffset = centerX - (totalWidth * 0.5)
        print(widthOffset, "totalWidth", totalWidth)
        local unitRanks = {}
        for _, unitKey in ipairs(e.squad.units) do
            local unit = world:getEntityByKey(unitKey)
            local width = unit.drawable.width;

            local point = HC.point(widthOffset + width*0.5  , centerY)
            point._key = unitKey
            point._ghost = true
            widthOffset = widthOffset + width + gap

            unitRanks[#unitRanks + 1] = point
        end
        rectangle._key = e.key.value

        e:give(
            'tangible',
            rectangle
        )
        :give('tangibleSquad', unitRanks)
        :remove('futureTangible')

        ::bigContinue::
    end
end

return ToTangibleSystem
