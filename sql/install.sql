-- Reference schema for w_barber (applied automatically by server/core/migrations.lua)
CREATE TABLE IF NOT EXISTS `characters_appearence` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `charid` VARCHAR(64) NOT NULL,
    `isMale` TINYINT(1) NOT NULL DEFAULT 1,
    `name` VARCHAR(60) DEFAULT NULL,
    `age` INT DEFAULT NULL,
    `faceFeatures` LONGTEXT DEFAULT NULL,
    `overlays` LONGTEXT DEFAULT NULL,
    `components` LONGTEXT DEFAULT NULL,
    `appearance` LONGTEXT NULL,
    `appearance_version` INT NOT NULL DEFAULT 2,
    `updated_at` TIMESTAMP NULL,
    PRIMARY KEY (`id`),
    KEY `charid` (`charid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `w_creators_locations` (
    `id` VARCHAR(64) NOT NULL,
    `type` VARCHAR(16) NOT NULL,
    `data` LONGTEXT NOT NULL,
    `position` INT NOT NULL DEFAULT 0,
    `updated_by` VARCHAR(100) NULL,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
