-- =====================================================================
--  config/board.lua  —  w_barber admin board (/barberadmin)
-- =====================================================================

Config.Board = {
    command     = 'barberadmin',
    maxDistance = 80.0,
    radius      = { min = 0.5, max = 10.0, default = 2.0 },
    labelMax    = 48,

    npcModels = {
        barber = { 's_m_m_barber_01', 'u_m_m_valbarber_01', 'a_m_m_valtownfolk_01' },
    },

    chairModels  = { 'p_barberchair01x', 'p_barberchair02x', 'p_barberchair03x' },
    previewModel = 'a_m_m_valtownfolk_01',

    blipSprites = {
        barber = 'blip_shop_barber',
    },
}
