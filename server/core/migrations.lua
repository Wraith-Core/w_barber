-- =====================================================================
--  server/core/migrations.lua  —  w_barber idempotent schema migrations
--  Character skin & hair/beard/makeup are read and saved exclusively through
--  w_lib (w.framework), so w_barber never creates or touches any character
--  appearance table (works natively on w_core, VORP, RSG and QBR).
-- =====================================================================

WCMigrations = { list = {}, done = false, ok = nil, applied = {} }
local M = WCMigrations

function M.register(id, fn, verify)
    assert(type(id) == 'string' and type(fn) == 'function', 'WCMigrations.register(id, fn, verify?)')
    assert(verify == nil or type(verify) == 'function', 'WCMigrations.register: verify must be a function')
    for _, m in ipairs(M.list) do
        if m.id == id then error('duplicate migration id ' .. id) end
    end
    M.list[#M.list + 1] = { id = id, fn = fn, verify = verify }
end

function M.tableExists(t)
    local n = w.database.scalar.await(
        'SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ?', { t })
    return (tonumber(n) or 0) > 0
end

function M.waitReady(timeoutMs)
    WCUtil.waitUntil(function() return M.done end, timeoutMs or 30000, 100)
    return M.done and M.ok == true
end

function M.run()
    if M.running then return false, {} end
    M.running = true
    local applied = {}
    local ok, err = pcall(function()
        w.database.query.await([[
            CREATE TABLE IF NOT EXISTS `w_barber_migrations` (
                `id` VARCHAR(64) NOT NULL,
                `applied_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                PRIMARY KEY (`id`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
        ]])
        local seen = {}
        for _, row in ipairs(w.database.query.await('SELECT id FROM w_barber_migrations') or {}) do
            seen[row.id] = true
        end
        for _, m in ipairs(M.list) do
            if not seen[m.id] then
                local stepOk, stepErr = pcall(m.fn)
                if not stepOk then error(('migration %s failed: %s'):format(m.id, tostring(stepErr)), 0) end
                w.database.insert.await('INSERT INTO w_barber_migrations (id) VALUES (?)', { m.id })
                applied[#applied + 1] = m.id
                WCDebug.log('migrations', 'applied %s', m.id)
            elseif m.verify and not m.verify() then
                WCDebug.warn('migrations', '%s is recorded but its schema is missing: applying it again', m.id)
                local stepOk, stepErr = pcall(m.fn)
                if not stepOk then error(('migration %s failed: %s'):format(m.id, tostring(stepErr)), 0) end
                if not m.verify() then error(('migration %s: the schema is still incomplete'):format(m.id), 0) end
                applied[#applied + 1] = m.id
            end
        end
    end)
    M.running = false
    M.done, M.ok, M.applied = true, ok, applied
    if not ok then
        print(('^1[w_barber] database migration stopped: %s^0'):format(tostring(err)))
        return false, applied
    end
    return true, applied
end

M.register('001_barber_locations', function()
    w.database.query.await([[
        CREATE TABLE IF NOT EXISTS `w_creators_locations` (
            `id` VARCHAR(64) NOT NULL,
            `type` VARCHAR(16) NOT NULL,
            `data` LONGTEXT NOT NULL,
            `position` INT NOT NULL DEFAULT 0,
            `updated_by` VARCHAR(100) NULL,
            `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
    ]])
    local existing = tonumber(w.database.scalar.await(
        "SELECT COUNT(*) FROM `w_creators_locations` WHERE `type` = 'barber'")) or 0
    if existing == 0 then
        for index, loc in ipairs((Config and Config.Locations) or {}) do
            if type(loc) == 'table' and loc.type == 'barber' and type(loc.id) == 'string' then
                local data = WCLocations.encode(loc)
                local encoded = data and WCUtil.encode(data)
                if encoded then
                    w.database.query.await(
                        'INSERT IGNORE INTO `w_creators_locations` (`id`, `type`, `data`, `position`) VALUES (?, ?, ?, ?)',
                        { loc.id, 'barber', encoded, index })
                end
            end
        end
    end
end, function()
    return M.tableExists('w_creators_locations')
end)

w.database.ready(function()
    M.run()
end)
