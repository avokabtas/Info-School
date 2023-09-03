/* Part 2. Изменение данных */

-- Удаление процедур и триггерных функций
DROP PROCEDURE IF EXISTS adding_p2p_check() CASCADE;
DROP PROCEDURE adding_p2p_check(VARCHAR, VARCHAR, VARCHAR, check_status, TIME);
DROP PROCEDURE IF EXISTS adding_verter_check() CASCADE;
DROP PROCEDURE adding_verter_check(VARCHAR, VARCHAR, check_status, TIME);
DROP TRIGGER IF EXISTS trg_update_transferredpoints ON P2P;
DROP FUNCTION IF EXISTS fnc_trg_update_transferredpoints() CASCADE;
DROP TRIGGER IF EXISTS trg_check_xp_correct ON XP;
DROP FUNCTION IF EXISTS fnc_trg_check_xp_correct() CASCADE;


-- 1) Процедура добавления P2P проверки
CREATE
    OR REPLACE PROCEDURE adding_p2p_check(IN checked_peer VARCHAR, IN checking_peer VARCHAR, IN task_name VARCHAR,
                                          status check_status, "time" TIME)
    LANGUAGE plpgsql
AS
$$
BEGIN
    IF status = 'Start' THEN
        INSERT INTO Checks VALUES ((SELECT MAX(ID) + 1 FROM Checks), checked_peer, task_name, CURRENT_DATE);
        INSERT INTO P2P
        VALUES ((SELECT MAX(ID) + 1 FROM P2P),
                (SELECT MAX(ID) FROM Checks), checking_peer, status, "time");
    ELSE
        INSERT INTO P2P
        VALUES ((SELECT MAX(ID) + 1 FROM P2P),
                (SELECT MAX(CheckID)
                 FROM P2P
                 WHERE P2P.State = 'Start'
                   AND P2P.CheckingPeer = adding_p2p_check.checking_peer),
                checking_peer, status, "time");
    END IF;
END
$$;

-- Тестирование процедуры, добавляем запись в таблицы P2P, Checks
CALL adding_p2p_check('harry', 'hermione', 'C3_s21_string+', 'Start', '12:30');
CALL adding_p2p_check('harry', 'hermione', 'C3_s21_string+', 'Success', '13:30');


-- 2) Процедура добавления проверки Verter'ом
CREATE
    OR REPLACE PROCEDURE adding_verter_check(IN checked_peer VARCHAR, IN task_name VARCHAR,
                                             status check_status, "time" TIME)
    LANGUAGE plpgsql
AS
$$
DECLARE
    check_id  BIGINT;
    verter_id BIGINT;
BEGIN
    check_id = (SELECT MAX(CheckID)
                FROM P2P
                         JOIN Checks ON P2P.CheckID = Checks.ID
                WHERE P2P.State = 'Success'
                  AND Checks.Peer = adding_verter_check.checked_peer
                  AND Checks.Task = adding_verter_check.task_name);
    verter_id = (SELECT MAX(ID) + 1 FROM Verter);
    INSERT INTO Verter VALUES (verter_id, check_id, status, "time");
END
$$;

-- Тестирование процедуры, добавляем запись в таблицу Verter
CALL adding_verter_check('harry', 'C3_s21_string+', 'Start', '13:40');
CALL adding_verter_check('harry', 'C3_s21_string+', 'Success', '13:45');


-- 3) Триггерная функция: после добавления записи со статутом "Start" в таблицу P2P, изменить соответствующую запись в таблице TransferredPoints
CREATE OR REPLACE FUNCTION fnc_trg_update_transferredpoints() RETURNS TRIGGER AS
$$
BEGIN
    IF NEW.State = 'Start' THEN
        UPDATE TransferredPoints
        SET PointsAmount = PointsAmount + 1
        WHERE CheckingPeer = NEW.CheckingPeer
          AND CheckedPeer = (SELECT Peer FROM Checks WHERE ID = NEW.CheckID);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_transferredpoints
    AFTER INSERT
    ON P2P
    FOR EACH ROW
EXECUTE FUNCTION fnc_trg_update_transferredpoints();

-- Тестирование функции (PointsAmount++)
SELECT *
FROM TransferredPoints
WHERE CheckedPeer = 'harry'
  AND CheckingPeer = 'hermione';
-- Добавляем запись в таблицы P2P, Checks
CALL adding_p2p_check('harry', 'hermione', 'C3_s21_string+', 'Start', '12:30');


-- 4) Триггерная функция: перед добавлением записи в таблицу XP, проверить корректность добавляемой записи
CREATE OR REPLACE FUNCTION fnc_trg_check_xp_correct()
    RETURNS TRIGGER AS
$$
BEGIN
        IF NEW.XpAmount > (SELECT MaxXP FROM Checks
            JOIN Tasks ON Tasks.Title = Checks.Task
            WHERE Checks.ID = NEW.CheckID) THEN
            RAISE EXCEPTION 'Количество ХР превышает максимальное значение для проекта';
        ELSEIF (SELECT State FROM P2P
                WHERE P2P.CheckID = NEW.CheckID AND P2P.State = 'Failure') = 'Failure' THEN
                RAISE EXCEPTION 'Пир завалил - статус Failure';
        ELSEIF (SELECT State FROM Verter
                WHERE Verter.CheckID = NEW.CheckID AND Verter.State = 'Failure') = 'Failure' THEN
                RAISE EXCEPTION 'Verter завалил - статус Failure';
        END IF;
    RETURN (NEW.ID, NEW.CheckID, NEW.XpAmount);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_xp
    BEFORE INSERT
    ON XP
    FOR EACH ROW
EXECUTE PROCEDURE fnc_trg_check_xp_correct();

-- Тестирование функции
INSERT INTO XP VALUES (6, 2, 750);  -- Все Ок
INSERT INTO XP VALUES (7, 3, 300);  -- Пир завалил - Не Ок
INSERT INTO XP VALUES (8, 2, 1500);  -- XP > MaxXP - Не Ок


-- Удаление всех добавленных записей в Part2
-- Удалим созданное в №1
DELETE FROM P2P WHERE id = 7;
DELETE FROM P2P WHERE id = 8;
DELETE FROM Checks WHERE id = 6;
-- Удалим созданное в №2
DELETE FROM Verter WHERE id = 7;
DELETE FROM Verter WHERE id = 8;
-- Удалим созданное в №3
DELETE FROM P2P WHERE id = 9;
DELETE FROM P2P WHERE id = 10;
DELETE FROM Checks WHERE id = 7;
DELETE FROM Checks WHERE id = 8;
-- Удалим созданное в №4
DELETE FROM XP WHERE id = 6;
