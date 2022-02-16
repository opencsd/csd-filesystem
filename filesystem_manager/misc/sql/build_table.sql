CREATE TABLE IF NOT EXISTS mysql_alive_chk (
    `hostname` varchar(255)
);
CREATE TABLE IF NOT EXISTS gms_lock_log (
    `lk_name`    VARCHAR(64) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL,
    `owner_node` VARCHAR(32) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL,
    `owner_pid`  VARCHAR(8)  CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL,
    `action`     VARCHAR(32) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL,
    `status`     VARCHAR(32) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL,
    `local_time` INT UNSIGNED NOT NULL,
    `time`       TIMESTAMP
);
