-- =====================================================================
--  server/appearance/repository.lua  —  w_barber (100% w_lib framework bridge)
--  Never touches characters_appearence or any framework character table directly.
--  Reads skin + clothes via w.framework:getUserSkin / getUserClothes, and saves
--  hair, beard, eyebrows and makeup exclusively via w.framework:updateUserSkin
--  (works natively on w_core + w_creators, VORP, RSG-Core v1/v2 and QBR-Core).
-- =====================================================================

WCAppearanceRepo = { cache = {} }
local Repo = WCAppearanceRepo

local MIGRATION_WAIT_MS = 10000
local PERSISTED = { rules = false }
local srcByChar = {} -- [charid] = player server id

local function key(charid) return tostring(charid) end

local function schemaReady()
    if type(WCMigrations) ~= 'table' or type(WCMigrations.waitReady) ~= 'function' then return true end
    return WCMigrations.waitReady(MIGRATION_WAIT_MS) == true
end

local function catalogueReady(sex)
    return next(WCCatalog.forSex(sex == 'female' and 'female' or 'male')) ~= nil
end

function Repo.invalidate(charid)
    if charid ~= nil then Repo.cache[key(charid)] = nil end
end

function Repo.degraded()
    return nil
end

function Repo.rememberSource(charid, src)
    if charid ~= nil and tonumber(src) then srcByChar[key(charid)] = math.tointeger(tonumber(src)) end
end

local function u32nz(v)
    local h = WCUtil.u32(v)
    return (h and h ~= 0) and h or nil
end

local function layerByKey(k)
    if type(WCOverlays) ~= 'table' then return nil end
    if WCOverlays.byId and WCOverlays.byId[k] then return WCOverlays.byId[k] end
    for _, layer in ipairs(WCOverlays.layers or {}) do
        if layer.library == k then return layer end
    end
    return nil
end

local function decodeOverlay(layer, value)
    if type(value) ~= 'table' then return nil end
    local opacity = tonumber(value.opacity)
    if opacity == nil then opacity = 1.0 end
    if opacity > 1 then opacity = opacity / 100 end
    if opacity <= 0 then return nil end
    local style = tonumber(value.style)
    if not style then
        local id = tonumber(value.id)
        local grid = tonumber(value.sheetGrid) or 0
        local set = (value.sexe == 'm' or value.sexe == 'f') and value.sexe or nil
        for idx = 1, layer.styles do
            local tex, cell, texSet = WCOverlays.texture(layer, idx)
            if tex == id and (cell or 0) == grid and (set == nil or texSet == nil or texSet == set) then
                style = idx
                break
            end
        end
    end
    if not style then return nil end
    local color = tonumber(value.color) or (tonumber(value.tint0) and (tonumber(value.tint0) + 1)) or 1
    local out = { style = math.floor(style), color = math.floor(color), opacity = opacity + 0.0 }
    if tonumber(value.color2) then out.color2 = math.floor(tonumber(value.color2))
    elseif tonumber(value.tint1) then out.color2 = math.floor(tonumber(value.tint1)) + 1 end
    if tonumber(value.color3) then out.color3 = math.floor(tonumber(value.color3))
    elseif tonumber(value.tint2) then out.color3 = math.floor(tonumber(value.tint2)) + 1 end
    return out
end

local function fromFramework(src, skin, clothes)
    local sex = 'male'
    if type(skin) == 'table' then
        if skin.sex == 2 or skin.sex == 'female' or skin.model == 'mp_female' then sex = 'female' end
    else
        local okP, ped = pcall(GetPlayerPed, src)
        if okP and ped and ped ~= 0 and GetEntityModel(ped) == joaat('mp_female') then sex = 'female' end
    end
    if not catalogueReady(sex) then return nil, 'INTERNAL_ERROR' end

    local app = AppearanceSchema.default(sex)
    if type(skin) == 'table' then
        local model = 'mp_' .. sex
        local headHash = u32nz(skin.headHash)
        if not headHash and (tonumber(skin.headIndex) or tonumber(skin.skinTone)) and w and w.component and w.component.getHeadFromSkinTone then
            local name = w.component.getHeadFromSkinTone(model, tonumber(skin.headIndex) or 1, tonumber(skin.skinTone) or 1)
            headHash = name and u32nz(GetHashKey(name)) or nil
        end
        local eyesHash = u32nz(skin.eyesHash)
        if not eyesHash and tonumber(skin.eyesIndex) and w and w.component and w.component.getEyesFromIndex then
            local name = w.component.getEyesFromIndex(model, tonumber(skin.eyesIndex))
            eyesHash = name and u32nz(GetHashKey(name)) or nil
        end
        local teethHash = u32nz(skin.teethHash)
        if not teethHash and tonumber(skin.teethIndex) and w and w.component and w.component.getTeethFromIndex then
            local name = w.component.getTeethFromIndex(model, tonumber(skin.teethIndex))
            teethHash = name and u32nz(GetHashKey(name)) or nil
        end
        local bodyUpperHash = u32nz(skin.bodyUpperHash)
        if not bodyUpperHash and (tonumber(skin.bodiesIndex) or tonumber(skin.skinTone)) and w and w.component and w.component.getBodiesUpperFromSkinTone then
            local name = w.component.getBodiesUpperFromSkinTone(model, tonumber(skin.bodiesIndex) or 1, tonumber(skin.skinTone) or 1)
            bodyUpperHash = name and u32nz(GetHashKey(name)) or nil
        end
        local bodyLowerHash = u32nz(skin.bodyLowerHash)
        if not bodyLowerHash and (tonumber(skin.bodiesIndex) or tonumber(skin.skinTone)) and w and w.component and w.component.getBodiesLowerFromSkinTone then
            local name = w.component.getBodiesLowerFromSkinTone(model, tonumber(skin.bodiesIndex) or 1, tonumber(skin.skinTone) or 1)
            bodyLowerHash = name and u32nz(GetHashKey(name)) or nil
        end

        app.head.head = headHash or app.head.head
        app.head.eyes = eyesHash or app.head.eyes
        app.head.teeth = teethHash or app.head.teeth
        app.body.upper = bodyUpperHash or app.body.upper
        app.body.lower = bodyLowerHash or app.body.lower
        if type(skin.bodyScale) == 'number' and WCUtil.isFinite(skin.bodyScale) then
            app.body.height = skin.bodyScale
        end
        local rawWeight = tonumber(skin.bodyWeight)
        if rawWeight and rawWeight >= 1 and rawWeight <= 21 and rawWeight % 1 == 0 then
            app.body.weight = math.floor(rawWeight)
        else
            local waistHash = u32nz(skin.bodyWeight)
            if waistHash and AppearanceSchema.WAIST_TYPES then
                for i, wh in ipairs(AppearanceSchema.WAIST_TYPES) do
                    if WCUtil.u32(wh) == waistHash then app.body.weight = i; break end
                end
            end
        end
        local buildHash = u32nz(skin.bodyType)
        if buildHash and AppearanceSchema.BODY_BUILDS then
            for i, bh in ipairs(AppearanceSchema.BODY_BUILDS) do
                if WCUtil.u32(bh) == buildHash then app.body.build = i; break end
            end
        end
        if type(skin.hair) == 'table' then app.hair.style = u32nz(skin.hair.hash) or 0
        elseif skin.hair ~= nil then app.hair.style = u32nz(skin.hair) or 0 end
        if sex == 'male' then
            local beard = skin.beards_complete
            if beard == nil then beard = skin.mustache end
            if type(beard) == 'table' then app.hair.facial = u32nz(beard.hash) or 0
            elseif beard ~= nil then app.hair.facial = u32nz(beard) or 0 end
        end
        if type(skin.expressions) == 'table' then
            for k, v in pairs(skin.expressions) do
                local n = tonumber(v)
                if n and WCUtil.isFinite(n) then
                    if n > 1 or n < -1 then n = n / 100 end
                    app.morph[k] = n + 0.0
                end
            end
        end
        if type(skin.overlays) == 'table' then
            app.overlays = {}
            for k, v in pairs(skin.overlays) do
                local layer = type(k) == 'string' and layerByKey(k) or nil
                if layer and layer.sexes[sex] then
                    local o = decodeOverlay(layer, v)
                    if o then app.overlays[layer.id] = o end
                end
            end
        end
    end

    app.clothing.equipped = {}
    app.clothing.tints = {}
    if type(clothes) == 'table' then
        for category, entry in pairs(clothes) do
            if type(category) == 'string' and WCCatalog.isClothing(category) then
                local rawHash = type(entry) == 'table' and (entry.hash or entry.comp) or entry
                local h = WCCatalog.resolve(sex, category, rawHash)
                if h and h ~= 0 then app.clothing.equipped[category] = h end
            end
        end
    end

    return (AppearanceSchema.sanitize(app, PERSISTED)), nil
end

function Repo.barberSkinPatch(app)
    local patch = { overlays = {} }
    if type(app.hair) == 'table' then
        patch.hair = (app.hair.style and app.hair.style ~= 0) and { hash = app.hair.style } or 0
        if app.sex == 'male' then
            patch.beards_complete = (app.hair.facial and app.hair.facial ~= 0) and { hash = app.hair.facial } or 0
        end
    end
    if type(WCOverlays) == 'table' and type(WCOverlays.layers) == 'table' then
        for _, layer in ipairs(WCOverlays.layers) do
            if (layer.section == 'eyebrows' or layer.section == 'makeup') and layer.sexes[app.sex] then
                local o = app.overlays and app.overlays[layer.id]
                local id, grid, set
                if o then id, grid, set = WCOverlays.texture(layer, o.style) end
                if id ~= nil then
                    local entry = { id = id, opacity = o.opacity, palette = layer.palette, tint0 = o.color - 1 }
                    if grid then entry.sheetGrid = grid end
                    if set then entry.sexe = set end
                    if o.color2 then entry.tint1 = o.color2 - 1 end
                    if o.color3 then entry.tint2 = o.color3 - 1 end
                    patch.overlays[layer.library] = entry
                else
                    patch.overlays[layer.library] = false
                end
            end
        end
    end
    return patch
end

--- Load a character's appearance exclusively via w_lib (w.framework:getUserSkin + getUserClothes).
function Repo.load(charid, opts)
    if charid == nil then return nil, { missing = true } end
    local src = (type(opts) == 'table' and tonumber(opts.src)) or srcByChar[key(charid)]
    if src then Repo.rememberSource(charid, src) end

    if not schemaReady() then
        WCDebug.warn('appearance', 'reading %s refused: migrations not ready', key(charid))
        return nil, { error = 'DATABASE_ERROR' }
    end

    local cached = Repo.cache[key(charid)]
    if cached and (type(opts) ~= 'table' or opts.fresh ~= true) then
        return WCUtil.copy(cached.app), { version = AppearanceSchema.VERSION, cached = true, defaultsUsed = {}, degraded = false }
    end

    if not src then return nil, { missing = true } end

    if type(GetResourceState) == 'function' and GetResourceState('w_creators') == 'started' then
        local okCr, cr = pcall(function() return exports.w_creators:GetAppearance(src) end)
        if okCr and type(cr) == 'table' and type(cr.appearance) == 'table' then
            local app = (AppearanceSchema.sanitize(WCUtil.copy(cr.appearance), PERSISTED))
            Repo.cache[key(charid)] = { app = WCUtil.copy(app) }
            return WCUtil.copy(app), { version = AppearanceSchema.VERSION, cached = false, defaultsUsed = {}, degraded = false }
        end
    end

    local skin, clothes = nil, nil
    if w and w.framework then
        if type(w.framework.getUserSkin) == 'function' then
            local okS, s = pcall(function() return w.framework:getUserSkin(src) end)
            if okS and type(s) == 'table' then skin = s end
        end
        if type(w.framework.getUserClothes) == 'function' then
            local okC, c = pcall(function() return w.framework:getUserClothes(src) end)
            if okC and type(c) == 'table' then clothes = c end
        end
    end

    local app, err = fromFramework(src, skin, clothes)
    if not app then return nil, { error = err or 'INTERNAL_ERROR' } end

    Repo.cache[key(charid)] = { app = WCUtil.copy(app) }
    return WCUtil.copy(app), { version = AppearanceSchema.VERSION, cached = false, defaultsUsed = {}, degraded = false }
end

--- Save barber changes (hair, beard, eyebrows, makeup) exclusively through w_lib (w.framework:updateUserSkin).
function Repo.save(charid, app, _, opts)
    if charid == nil then return false, 'CHARACTER_NOT_FOUND' end
    if not catalogueReady(type(app) == 'table' and app.sex) then return false, 'INTERNAL_ERROR' end
    if not schemaReady() then return false, 'DATABASE_ERROR' end

    local src = (type(opts) == 'table' and tonumber(opts.src)) or srcByChar[key(charid)]
    if not src then return false, 'NO_CHARACTER' end

    app = AppearanceSchema.sanitize(app, PERSISTED)
    Repo.invalidate(charid)

    local patch = Repo.barberSkinPatch(app)
    if w and w.framework and type(w.framework.updateUserSkin) == 'function' then
        local okFw, fwErr = pcall(function()
            w.framework:updateUserSkin(src, WCUtil.copy(patch), false)
        end)
        if not okFw then
            WCDebug.warn('appearance', 'w.framework:updateUserSkin failed for %s: %s', tostring(src), tostring(fwErr))
            return false, 'DATABASE_ERROR'
        end
    end
    if type(GetResourceState) == 'function' and GetResourceState('w_creators') == 'started' and GetResourceState('w_core') ~= 'started' then
        pcall(function()
            exports.w_creators:SetSkin(src, WCUtil.copy(patch), false)
        end)
    end

    Repo.cache[key(charid)] = { app = WCUtil.copy(app) }
    TriggerEvent('w_appearance:updated', src, key(charid), app)
    return true, app
end

AddEventHandler('w_appearance:updated', function(_, charid)
    if charid ~= nil then Repo.invalidate(charid) end
end)

AddEventHandler('playerDropped', function()
    local src = source
    for cid, s in pairs(srcByChar) do
        if s == src then
            srcByChar[cid] = nil
            Repo.cache[cid] = nil
        end
    end
end)
