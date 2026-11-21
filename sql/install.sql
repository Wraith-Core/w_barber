-- Reference schema for w_barber (applied automatically by server/core/migrations.lua)
-- Note: Character skin, hair, beard & overlays are managed exclusively via w_lib (w.framework).

CREATE TABLE IF NOT EXISTS `w_creators_locations` (
    `id` VARCHAR(64) NOT NULL,
    `type` VARCHAR(16) NOT NULL,
    `data` LONGTEXT NOT NULL,
    `position` INT NOT NULL DEFAULT 0,
    `updated_by` VARCHAR(100) NULL,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
