-- =====================================================================
--  server/api.lua  —  w_barber public server API
-- =====================================================================

WCApi = {}
local Api = WCApi

local MAX_ID = 64
local fail, ok = WCResult.fail, WCResult.ok

local function playerId(src)
    src = tonumber(src)
    if not src or src <= 0 or src % 1 ~= 0 then return nil end
    src = math.tointeger(src)
    if not GetPlayerName(src) then return nil end
    return src
end

function Api.OpenBarber(src, locationId)
    src = playerId(src)
    if not src then return fail('INVALID_PAYLOAD') end
    if type(locationId) ~= 'string' or locationId == '' or #locationId > MAX_ID then return fail('INVALID_PAYLOAD') end
    if not WCServices.enabled('barbers') then return fail('BARBER_DISABLED') end
    local loc = WCLocations.byId(locationId)
    if not loc or loc.type ~= 'barber' then return fail('LOCATION_NOT_FOUND') end
    if loc.enabled == false then return fail('LOCATION_DISABLED') end
    if not WCLocations.isOpen(loc) then return fail('LOCATION_CLOSED_HOURS') end
    if not WCSessions.accessAllowed(src, loc) then return WCSessions.accessRefusal(src, loc) end
    if not WCSessions.withinRange(src, loc) then return fail('TOO_FAR') end
    TriggerClientEvent('w_barber:client:openBarber', src, locationId)
    return ok({ locationId = locationId })
end

exports('OpenBarber', function(src, id) return Api.OpenBarber(src, id) end)
