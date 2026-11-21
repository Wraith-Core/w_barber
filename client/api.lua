-- =====================================================================
--  client/api.lua  —  w_barber public client API
-- =====================================================================

WCClientApi = {}
local Api = WCClientApi

function Api.isBusy()
    return WCState.inEditor() or (WCServiceFlow and WCServiceFlow.busy()) or (WCBoard and WCBoard.isOpen())
        or (WCBarber and WCBarber.busy()) or false
end

RegisterNetEvent('w_barber:client:openBarber', function(locationId)
    CreateThread(function() WCBarber.open(locationId) end)
end)

exports('OpenBarber', function(locationId)
    CreateThread(function() WCBarber.open(locationId) end)
    return true
end)
exports('IsBusy', function() return Api.isBusy() end)
