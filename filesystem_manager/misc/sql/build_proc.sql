CREATE PROCEDURE GMS_LOCK_LOG
(IN _LK_NAME CHAR(64),
 IN _OWNER_NODE VARCHAR(32),
 IN _OWNER_PID VARCHAR(8),
 IN _ACTION VARCHAR(32),
 IN _STATUS VARCHAR(32),
 IN _LOCAL_TIME INT UNSIGNED)
BEGIN
    DECLARE _COUNT INT;
    DECLARE exit handler for SQLEXCEPTION
    BEGIN
        ROLLBACK;
    END;

    START TRANSACTION;
        INSERT INTO gms_lock_log(lk_name, owner_node, owner_pid, action, status, local_time)
            VALUES (_LK_NAME, _OWNER_NODE, _OWNER_PID, _ACTION, _STATUS, _LOCAL_TIME);

        SELECT COUNT(*) INTO _COUNT FROM gms_lock_log;

        IF _COUNT > 10000 THEN
            DELETE FROM gms_lock_log ORDER BY time LIMIT 1;
        END IF;

    COMMIT;
END
