Vec3Distance = function(pointA, pointB)
    return math.abs(
        math.sqrt(
            ((pointB.x - pointA.x)*(pointB.x - pointA.x)) +
            ((pointB.y - pointA.y)*(pointB.y - pointA.y)) +
            ((pointB.z - pointA.z)*(pointB.z - pointA.z))
        )
    )
end

ShuffleTable = function(tbl)
    local t = {}
    -- Copy tbl to t
    for i = 1, #tbl do
        t[i] = tbl[i]
    end
    -- Shuffle t
    for i = #t, 2, -1 do
        local j = math.random(i)
        t[i], t[j] = t[j], t[i]
    end
    return t
end

ShowSubtitle = function(str, duration, instant)
    BeginTextCommandPrint("CELL_EMAIL_BCON")
    AddTextComponentSubstringPlayerName(str)
    EndTextCommandPrint(duration or 2000, instant or 1)
end

ShowNotification = function(str)
    BeginTextCommandThefeedPost("CELL_EMAIL_BCON")
    AddTextComponentSubstringPlayerName(str)
    EndTextCommandThefeedPostTicker(false, false)
end

ShowHelpText = function(str)
    BeginTextCommandDisplayHelp("CELL_EMAIL_BCON")
    AddTextComponentSubstringPlayerName(str)
    EndTextCommandDisplayHelp(0, 0 , 1, -1)
end

DeleteVehicleEntity = function(vehicle)
    SetEntityAsMissionEntity(vehicle, false, false)
    DeleteEntity(vehicle)
end

GetParkingPosition = function(positions)
    for i, pos in ipairs(positions) do
        local closestVeh = GetClosestVehicle(pos.x, pos.y, pos.z, 3.0, 0, 70)
        print(closestVeh)

        if  closestVeh == 0 then
            return i
        end
    end

    return -1
end

CreateBlip = function(x, y, z, sprite, color, description, shortRange, scale)
    local blip = AddBlipForCoord(x, y, z)
    SetBlipSprite(blip, sprite)
    SetBlipColour(blip, color)
    SetBlipAsShortRange(blip, shortRange or true)
    SetBlipScale(blip, scale or 0.86)

    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(description)
    EndTextCommandSetBlipName(blip)
    
    return blip
end