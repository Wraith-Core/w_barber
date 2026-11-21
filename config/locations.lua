-- =====================================================================
--  config/locations.lua  —  w_barber
--  Barber shop locations. Editable in-game with /barberadmin.
-- =====================================================================

Config.LocationDefaults = {
    barber = {
        interactionRadius = 2.0,
        prompt = true,
        npc = false,
        blip = { sprite = 'blip_shop_barber', label = 'الحلاق' },
        camera = 'hair',
        allowedServices = nil,
    },
}

Config.Locations = {
    {
        id = 'valentine_barber', type = 'barber', enabled = true,
        label = 'الحلاق', town = 'فالنتاين',
        coords = vector3(-307.51, 813.96, 118.99),
    },
    {
        id = 'blackwater_barber', type = 'barber', enabled = true,
        label = 'الحلاق', town = 'بلاك ووتر',
        coords = vector3(-814.915, -1367.89, 43.75),
    },
    {
        id = 'saintdenis_barber', type = 'barber', enabled = true,
        label = 'الحلاق', town = 'سانت دينيس',
        coords = vector3(2655.21, -1179.9, 53.27),
    },
    {
        id = 'annesburg_barber', type = 'barber', enabled = true,
        label = 'الحلاق', town = 'آنسبرغ',
        coords = vector3(2924.3, 1343.7, 44.4),
    },
    {
        id = 'armadillo_barber', type = 'barber', enabled = true,
        label = 'الحلاق', town = 'أرماديلو',
        coords = vector3(-3684.22, -2621.05, -13.44),
    },
    {
        id = 'tumbleweed_barber', type = 'barber', enabled = true,
        label = 'الحلاق', town = 'تمبلويد',
        coords = vector3(-5493.4, -2940.7, -0.46),
    },
    {
        id = 'strawberry_barber', type = 'barber', enabled = true,
        label = 'الحلاق', town = 'ستروبيري',
        coords = vector3(-1810.92, -372.15, 162.89),
    },
}
