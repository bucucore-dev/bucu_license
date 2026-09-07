-- ============================================================================
-- BUCU License System — Database Schema
-- Stores citizen official identification documents & licenses
-- ============================================================================

CREATE TABLE IF NOT EXISTS `bucu_user_licenses` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `citizenid` VARCHAR(64) NOT NULL,
    `type` VARCHAR(50) NOT NULL,
    `status` TINYINT NOT NULL DEFAULT 1,
    `issued_date` DATE NOT NULL,
    `expires_date` DATE DEFAULT NULL,
    `metadata` LONGTEXT DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_cit_lic` (`citizenid`, `type`),
    INDEX `idx_cit_licenses` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
