ESX = nil
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

local hasVan = {}

RegisterServerEvent('MailDelivery:RequestVan')
AddEventHandler('MailDelivery:RequestVan', function(park)
    local src = source
    local xply = ESX.GetPlayerFromId(src)

    if xply.getMoney() >= MailConfig.RentalPrice then
        xply.removeMoney(MailConfig.RentalPrice)
        hasVan[src] = true

        TriggerClientEvent(
            'MailDelivery:VanResponse', src,
            { park = park, outcome = 1 }
        )
    else
        TriggerClientEvent(
            'MailDelivery:VanResponse', src,
            { park = park, outcome = 0 }
        )
    end
end)

RegisterServerEvent('MailDelivery:VanReturned')
AddEventHandler('MailDelivery:VanReturned', function()
    local src = source
    local xply = ESX.GetPlayerFromId(src)

    if hasVan[src] then
        xply.addMoney(MailConfig.RentalPrice)
        hasVan[src] = false
        TriggerClientEvent('MailDelivery:RefundResponse', src, true)
    else
        TriggerClientEvent('MailDelivery:RefundResponse', src, false)
    end
end)

RegisterServerEvent('MailDelivery:DeliveryMade')
AddEventHandler('MailDelivery:DeliveryMade', function()
    local src = source
    local xply = ESX.GetPlayerFromId(src)

    local amount = math.random(ServerMailConfig.MinPayment, ServerMailConfig.MaxPayment)
    xply.addMoney(amount)

    TriggerClientEvent('MailDelivery:PaymentReceived', src, amount)
end)