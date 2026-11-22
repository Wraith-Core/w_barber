# w_barber

Standalone RedM barber shops featuring animated barber chairs, hairstyles, beards, eyebrows, teeth, makeup, and optional hair growth for **Wraith Framework RedM**.

## Key Features

- **Full Grooming Studio:** Hairstyles, beards, eyebrows, makeup, hair pomade, and tint palettes.
- **Authentic Barber Chairs:** Interactive seating on map barber chairs (`PROP_PLAYER_BARBER_SEAT`) with face-locked camera and automatic hat removal.
- **Flexible Pricing & Schedules:** Per-service pricing, visit caps, opening hours, and optional job/ACE restrictions.
- **In-Game Admin Board:** `/barberadmin` (ACE `w_barber.admin`) to place and edit barber locations and chairs in-game.

## Installation

1. Place `w_barber` in `resources/[wraith]/w_barber`.
2. Import `sql/install.sql` (or allow auto-migrations on startup).
3. Add `ensure w_barber` to `server.cfg` after `w_lib` and `w_creators`.

## Key Exports

```lua
exports.w_barber:OpenBarber(src, locationId)
exports.w_barber:IsBusy()
```

## Documentation & Links

- **Developer Docs:** https://wraith-core.github.io/docs/#/resources/character-appearance
- **txAdmin Recipe:** https://github.com/Wraith-Core/txAdminRecipe
- **Credits:** See [CREDITS.md](CREDITS.md)
