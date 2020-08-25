local onDuty = false
local currentDeliveryArea =  nil
local currentDeliveryBlips = {}
local currentDeliveryPositions = {}

CreateBlip(
    MailConfig.DutyPosition.x, MailConfig.DutyPosition.y, MailConfig.DutyPosition.z,
    MailConfig.JobBlipSprite, MailConfig.JobBlipColor, "Mail Delivery"
)

CreateBlip(
    MailConfig.RentalPosition.x, MailConfig.RentalPosition.y, MailConfig.RentalPosition.z,
    MailConfig.RentalBlipSprite, MailConfig.RentalBlipColor, "Mail Delivery: Rental"
)

local dutyTick = function()
    local pos = GetEntityCoords(PlayerPedId())

    if Vec3Distance(pos, MailConfig.DutyPosition) < 16 then
        if onDuty then
            ShowHelpText('Press ~INPUT_CONTEXT~ to ~r~Stop~s~ delivering mail.')
        else
            ShowHelpText('Press ~INPUT_CONTEXT~ to ~g~Start~s~ delivering mail.')
        end

        if IsControlJustReleased(0, 51) then
            local ped = GetPlayerPed()
            local vehicle = GetVehiclePedIsIn(ped, false)

            if not IsVehicleModel(vehicle, MailConfig.VanModel) or not IsPedSittingInVehicle(ped, vehicle) then
                ShowHelpText('You are not driving a ~r~PostOP Boxville~s~! You can rent one at ~g~Mail Delivery: Rental~s~.')

                Wait(5000)
                return
            end

            onDuty = not onDuty

            if not onDuty then
                DeleteWaypoint()
                for _, blip in ipairs(currentDeliveryBlips) do
                    RemoveBlip(blip)
                end
                currentDeliveryBlips = {}

                return
            end

            -- Grab the delivery region then map it to a delivery route
            -- Then shuffle the route so that you don't get the same drop-offs all the time
            -- Finally, we only want 10-12 deliveries for a route, so grab 10-12 entries from the route
            currentDeliveryArea = MailConfig.DeliveryRegions[math.random(1, #MailConfig.DeliveryRegions)]
            local route = ShuffleTable(MailConfig.DeliveryAreas[currentDeliveryArea])
            local deliveries = math.random(10, 12)
            currentDeliveryPositions = table.move(route, 1, deliveries, 1, {})

            for i, delivery in ipairs(currentDeliveryPositions) do
                local blip = CreateBlip(
                    delivery.x, delivery.y, delivery.z,
                    MailConfig.DeliveryBlipSprite, MailConfig.DeliveryBlipColor,
                    "Delivery Point", false, 1.0
                )

                table.insert(currentDeliveryBlips, i, blip)
            end

            ShowSubtitle("Deliver ~g~"..deliveries.."x~s~ mail and packages in ~y~"..currentDeliveryArea, 5000)
            onDuty = true

            Wait(MailConfig.JobCooldown)
        end
    end
end

local deliveryTick = function()
    if not onDuty then
        return
    end

    local ped = GetPlayerPed()
    local lastVehicle = GetVehiclePedIsIn(ped, true)

    if IsPedGettingIntoAVehicle(ped) or lastVehicle == 0 then
        return
    end

    if not IsVehicleModel(lastVehicle, MailConfig.VanModel) then
        return
    end

    local pos = GetEntityCoords(PlayerPedId())
    local deliveryArea = MailConfig.DeliveryAreaWide[currentDeliveryArea]

    if Vec3Distance(pos, deliveryArea) > 2000000 then
        Wait(4000)
        return
    end

    local col = MailConfig.DutyColor
    for i, delivery in ipairs(currentDeliveryPositions) do
        local distance = Vec3Distance(pos, delivery)

        if distance < 100 then
            DrawMarker(20, -- Upwards facing chevron
                delivery.x, delivery.y, delivery.z,
                0, 0, 0,
                0, 180.0, 0, -- Flip chevron downwards so its like an arrow
                0.5, 0.5, 0.5,
                math.floor(col.x), math.floor(col.y), math.floor(col.z), math.floor(col.w),
                false, false, 2, nil, nil, false
            )
        end

        if distance < 4 then
            if IsPedSittingInAnyVehicle(ped) then
                ShowHelpText('~r~Exit~s~ your Mail Delivery Van.')
                return
            end

            ShowHelpText('Press ~INPUT_CONTEXT~ to Deliver Mail.')

            if IsControlJustReleased(0, 51) then
                RequestAnimDict('mp_safehouselost@')

                local animLoaded = true
                while not HasAnimDictLoaded('mp_safehouselost@') do
                    Wait(1000)

                    -- if animation isn't loading then break out
                    if not HasAnimDictLoaded('mp_safehouselost@') then
                        animLoaded = false
                        break
                    end
                end

                if animLoaded then
                    TaskPlayAnim(
                        ped, 'mp_safehouselost@', 'package_dropoff',
                        8.0, -8.0, -1, 0, 0.0, false, false, false
                    )
                    Wait(1000)
                end

                TriggerServerEvent('MailDelivery:DeliveryMade')

                local blip = currentDeliveryBlips[i]
                if DoesBlipExist(blip) then
                    RemoveBlip(blip)
                end

                table.remove(currentDeliveryBlips, i)
                table.remove(currentDeliveryPositions, i)

                if #currentDeliveryPositions == 0 then
                    ShowNotification("All mail delivered!")
                    ShowNotification("~y~Return to PostOp for another route~s~.")
            
                    onDuty = not onDuty
                end
            end
        end
    end
end

local rentalTick = function()
    local pos = GetEntityCoords(PlayerPedId())

    if Vec3Distance(pos, MailConfig.RentalPosition) < 16 then
        local ped = GetPlayerPed()

        if IsPedSittingInAnyVehicle(ped) then
            local vehicle = GetVehiclePedIsIn(ped, false)
            if not DecorExistOn(vehicle, 'MailDelivery.Rental') then
                ShowHelpText('Exit your vehicle to rent a ~g~Mail Delivery Van~s~.')
                return
            end

            ShowHelpText('Press ~INPUT_CONTEXT~ to return your ~g~Mail Delivery Van~s~.')

            if IsControlJustReleased(0, 51) then
                DeleteVehicleEntity(vehicle)
                ShowNotification("Mail Delivery Van has been returned.")

                TriggerServerEvent('MailDelivery:VanReturned')

                Wait(4000)
                return
            end
            
            return
        end

        ShowHelpText(
            "Press ~INPUT_CONTEXT~ to rent a ~g~Mail Delivery Van~s~ (~r~$" ..
            MailConfig.RentalPrice .. "~s~)."
        )

        if IsControlJustReleased(0, 51) then

            RequestModel(MailConfig.VanModel)

            while not HasModelLoaded(MailConfig.VanModel) do
                Wait(100)
            end

            local park = GetParkingPosition(MailConfig.VehicleSpawnPositions)
            if park < 0 or park > #MailConfig.VehicleSpawnPositions then
                ShowNotification("There are no available parking spots.")
                return
            end

            TriggerServerEvent('MailDelivery:RequestVan', park)
            Wait(4000)
        end
    end
end

local markerTick = function()
    local pos = GetEntityCoords(PlayerPedId())

    if Vec3Distance(pos, MailConfig.RentalPosition) < 2500 then
        local rpos = MailConfig.RentalPosition
        local col = MailConfig.DutyColor
        DrawMarker(1,
            rpos.x, rpos.y, rpos.z,
            0, 0, 0,
            0, 0, 0,
            3.0, 3.0, 3.0,
            -- We have to math.floor here to convert from float to int
            -- DrawMarker does not like floats for color values
            math.floor(col.x), math.floor(col.y), math.floor(col.z), math.floor(col.w),
            false, false, 2, nil, nil, false
        )
    end

    if Vec3Distance(pos, MailConfig.DutyPosition) < 2500 then
        local dpos = MailConfig.DutyPosition
        local col = MailConfig.DutyColor
        DrawMarker(1,
            dpos.x, dpos.y, dpos.z,
            0, 0, 0,
            0, 0, 0,
            3.0, 3.0, 3.0,
            math.floor(col.x), math.floor(col.y), math.floor(col.z), math.floor(col.w),
            false, false, 2, nil, nil, false
        )
    end
end

Citizen.CreateThread(function()
    while true do
        dutyTick()
        Wait(0)
    end
end)


Citizen.CreateThread(function()
    while true do
        deliveryTick()
        Wait(0)
    end
end)


Citizen.CreateThread(function()
    while true do
        rentalTick()
        Wait(0)
    end
end)


Citizen.CreateThread(function()
    while true do
        markerTick()
        Wait(0)
    end
end)

RegisterNetEvent('MailDelivery:VanResponse')
AddEventHandler('MailDelivery:VanResponse', function(data)
    if data.outcome == 0 then
        ShowHelpText("You can't afford a Mail Delivery Van.")
        return
    end

    local parkPos = MailConfig.VehicleSpawnPositions[data.park]

    local vehicle = CreateVehicle(
        MailConfig.VanModel,
        parkPos.x, parkPos.y, parkPos.z, parkPos.w,
        true, false
    )

    SetEntityAsMissionEntity(vehicle, true, true)
    if not DecorExistOn(vehicle, 'MailDelivery.Rental') then
        DecorRegister('MailDelivery.Rental', 2)
        DecorSetBool(vehicle, 'MailDelivery.Rental', true)
    end

    ShowHelpText("Your Mail Delivery van is ready in parking bay ~g~"..data.park.."~s~.")
end)

RegisterNetEvent('MailDelivery:RefundResponse')
AddEventHandler('MailDelivery:RefundResponse', function(refunded)
    if refunded then
        ShowNotification("You have been refunded ~r~$"..MailConfig.RentalPrice.." for your Mail Delivery Van.")
    else
        ShowNotification("Could not confirm ownership of your Mail Delivery Van. You have not been refunded.")
    end
end)

RegisterNetEvent('MailDelivery:PaymentReceived')
AddEventHandler('MailDelivery:PaymentReceived', function(amount)
    ShowNotification("You have received ~g~$"..amount.."~s~ for your delivery.")
end)