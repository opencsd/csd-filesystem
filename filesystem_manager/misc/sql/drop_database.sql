DROP DATABASE IF EXISTS girasole;
DROP PROCEDURE IF EXISTS mysql.GIRASOLE_DROP_USER;
CREATE PROCEDURE mysql.GIRASOLE_DROP_USER()
BEGIN
    SET @hosts = 'localhost,%,';

    WHILE (LOCATE(',', @hosts) > 0) DO
        SET @host = SUBSTR(@hosts, 1, LOCATE(',', @hosts) - 1);

        SET @userCnt = 0;
        SELECT COUNT(user) INTO @userCnt FROM mysql.user WHERE mysql.user.User = 'gluesys' AND mysql.user.Host = @host;

        IF @userCnt > 0 THEN
           SET @sql = CONCAT('DROP USER \'gluesys\'@\'', @host, '\'');
           PREPARE stmt1 FROM @sql;
           EXECUTE stmt1;
           DEALLOCATE PREPARE stmt1; 
        END IF;

        SET @hosts = SUBSTR(@hosts, LOCATE(',', @hosts) + 1, LENGTH(@hosts));
    END WHILE;

END;
CALL mysql.GIRASOLE_DROP_USER();
DROP PROCEDURE IF EXISTS mysql.GIRASOLE_DROP_USER;
