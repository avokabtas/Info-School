/* Part 3. Получение данных */


-- 1) Функция, возвращающая таблицу TransferredPoints в более человекочитаемом виде
-- Ник пира 1, ник пира 2, количество переданных пир поинтов.
-- Количество отрицательное, если пир 2 получил от пира 1 больше поинтов.

CREATE
OR REPLACE FUNCTION fnc_transfers()
    RETURNS TABLE
            (
                Peer1        varchar,
                Peer2        varchar,
                PointsAmount integer
            )
AS
$$
SELECT t.checkingpeer                                                AS Peer1,
       t.checkedpeer                                                 AS Peer2,
       SUM(t.pointsamount) - (SELECT CASE
                                         WHEN SUM(t2.pointsamount) IS NULL THEN 0
                                         ELSE SUM(t2.pointsamount)
                                         END
                              FROM transferredpoints t2
                              WHERE t.checkingpeer = t2.checkedpeer
                                AND t.checkedpeer = t2.checkingpeer) AS PointsAmount
FROM transferredpoints t
group by Peer1, Peer2;
$$
LANGUAGE SQL;

SELECT *
FROM fnc_transfers();


-- 2) Функция, которая возвращает таблицу вида: ник пользователя, название проверенного задания, кол-во полученного XP
-- В таблицу включать только задания, успешно прошедшие проверку (определять по таблице Checks).
-- Одна задача может быть успешно выполнена несколько раз. В таком случае в таблицу включать все успешные проверки.

CREATE
OR REPLACE FUNCTION fnc_completed()
    RETURNS TABLE
            (
                peer varchar,
                task varchar,
                xp   integer
            )
AS
$$
SELECT c.peer, c.task, x.xpamount
FROM checks c
         JOIN xp x ON c.id = x.checkid
WHERE (SELECT v.id
       FROM verter v
       WHERE v.checkid = c.id
         AND v.state = 'Success') > 0;
$$
LANGUAGE SQL;

SELECT *
FROM fnc_completed();


-- 3) Функция, определяющая пиров, которые не выходили из кампуса в течение всего дня
-- Параметры функции: день, например 12.05.2022.
-- Функция возвращает только список пиров.

CREATE
OR REPLACE FUNCTION fnc_tracker(day date)
    RETURNS TABLE
            (
                peer varchar
            )
AS
$$
SELECT t.peer
FROM timetracking t
         JOIN timetracking t2 ON t2.date = $1 AND t2.state = 2
WHERE t.date = $1
  AND t.state = 1
  AND t.time <= '12:00:00'
  AND t2.time >= '18:00:00';
$$
LANGUAGE SQL;

SELECT *
FROM fnc_tracker('2023-01-01');


-- 4) Посчитать изменение в количестве пир поинтов каждого пира по таблице TransferredPoints
-- Результат вывести отсортированным по изменению числа поинтов.
-- Формат вывода: ник пира, изменение в количество пир поинтов

CREATE
OR REPLACE FUNCTION fnc_peer_pts()
    RETURNS TABLE
            (
                Peer         varchar,
                PointsChange integer
            )
AS
$$
SELECT t.checkingpeer                          AS Peer,
       SUM(t.pointsamount) -
       (SELECT SUM(t2.pointsamount)
        FROM transferredpoints t2
        WHERE t.checkingpeer = t2.checkedpeer) AS PointsChange
FROM transferredpoints t
GROUP BY t.checkingpeer;
$$
LANGUAGE SQL;

SELECT *
FROM fnc_peer_pts();


-- 5) Посчитать изменение в количестве пир поинтов каждого пира по таблице, возвращаемой первой функцией из Part 3
-- Результат вывести отсортированным по изменению числа поинтов.
-- Формат вывода: ник пира, изменение в количество пир поинтов

CREATE
OR REPLACE FUNCTION fnc_peer_pts_ver2()
    RETURNS TABLE
            (
                Peer         varchar,
                PointsChange integer
            )
AS
$$
SELECT t.Peer1 AS Peer, SUM(t.PointsAmount) AS PointsChange
FROM fnc_transfers() as t
GROUP BY t.Peer1
ORDER BY 2 DESC;
$$
LANGUAGE SQL;

SELECT *
FROM fnc_peer_pts_ver2();


-- 6) Определить самое часто проверяемое задание за каждый день
-- При одинаковом количестве проверок каких-то заданий в определенный день, вывести их все.
-- Формат вывода: день, название задания

CREATE
OR REPLACE FUNCTION fnc_take_checks_by_day(day date)
    RETURNS TABLE
            (
                counting integer,
                task     varchar
            )
AS
$$
SELECT count(id) as counting, task
FROM checks
WHERE date = $1
group by task;
$$
LANGUAGE SQL;

CREATE
OR REPLACE FUNCTION fnc_take_max_checks_by_day(day date)
    RETURNS integer
AS
$$
SELECT MAX(counting)
FROM fnc_take_checks_by_day($1);
$$
LANGUAGE SQL;

CREATE
OR REPLACE FUNCTION fnc_take_most_checked_tasks()
    RETURNS TABLE
            (
                day  date,
                task varchar
            )
AS
$$
SELECT days.date as Day, tasks.task as Task
FROM (SELECT c.date FROM checks c GROUP BY c.date) days, fnc_take_checks_by_day(days.date) tasks
WHERE tasks.counting = fnc_take_max_checks_by_day(days.date)
ORDER BY 1, 2;
$$
LANGUAGE SQL;

SELECT *
FROM fnc_take_most_checked_tasks();


-- 7) Найти всех пиров, выполнивших весь заданный блок задач и дату завершения последнего задания
-- Параметры процедуры: название блока, например "CPP".
-- Результат вывести отсортированным по дате завершения.
-- Формат вывода: ник пира, дата завершения блока (т.е. последнего выполненного задания из этого блока)

CREATE
OR REPLACE FUNCTION fnc_completed_block(block varchar)
    RETURNS TABLE
            (
                Peer varchar,
                Day  date
            )
AS
$$
SELECT peer as Peer, completed.date
FROM (SELECT c.peer, c.task, c.date
      FROM checks c
               JOIN xp x ON c.id = x.checkid
      WHERE (SELECT v.id
             FROM verter v
             WHERE v.checkid = c.id
               AND v.state = 'Success') > 0) as completed
WHERE task = (SELECT title FROM tasks WHERE title ~ concat('^', $1, '.')
ORDER BY 1 DESC LIMIT 1);
$$
LANGUAGE SQL;

SELECT *
FROM fnc_completed_block('C');


-- 8) Определить, к какому пиру стоит идти на проверку каждому обучающемуся
-- Определять нужно исходя из рекомендаций друзей пира, т.е. нужно найти пира, проверяться у которого рекомендует наибольшее число друзей.
-- Формат вывода: ник пира, ник найденного проверяющего

CREATE
OR REPLACE FUNCTION fnc_recommendation_peer()
    RETURNS TABLE
            (
                Peer            varchar,
                RecommendedPeer varchar
            )
AS
$$
WITH find_all_peers AS (SELECT nickname FROM peers),
     find_all_friends AS (SELECT p.nickname, (CASE WHEN nickname = f.peer1 THEN f.peer2 ELSE f.peer1 END) AS frineds
                          FROM find_all_peers p
                                   JOIN friends f ON p.nickname = f.peer1 OR p.nickname = f.peer2
                          ORDER BY 1),
     find_all_recomendation AS (SELECT ff.nickname, COUNT(recommendedpeer) AS counts, r.recommendedpeer
                                FROM find_all_friends ff
                                         JOIN recommendations r
                                              ON ff.frineds = r.peer
                                GROUP BY ff.nickname, r.recommendedpeer
                                ORDER BY 1)


SELECT fp.nickname,
       (SELECT fr.recommendedpeer
        FROM find_all_recomendation fr
        WHERE fp.nickname = fr.nickname
           LIMIT 1)
FROM find_all_peers fp;
$$
LANGUAGE SQL;

SELECT *
FROM fnc_recommendation_peer();


-- 9) Определить процент пиров, которые:
-- Приступили только к блоку 1; Приступили только к блоку 2; Приступили к обоим; Не приступили ни к одному

CREATE
OR REPLACE FUNCTION fnc_peers_completed(block1 varchar, block2 varchar)
    RETURNS TABLE
            (
                StartedBlock1      float,
                StartedBlock2      integer,
                StartedBothBlocks  integer,
                DidntStartAnyBlock integer
            )
AS
$$

WITH start_first_block AS (SELECT DISTINCT c.peer
                           FROM checks c
                           WHERE task ~ concat('^', $1, '.')),
     start_second_block AS (SELECT DISTINCT c.peer
                            FROM checks c
                            WHERE task ~ concat('^', $2, '.')),
     start_only_first_block AS (SELECT p.nickname
                                FROM peers p
                                EXCEPT
                                SELECT sfb.peer
                                FROM start_first_block sfb),
     start_only_second_block AS (SELECT p.nickname
                                 FROM peers p
                                 EXCEPT
                                 SELECT ssb.peer
                                 FROM start_second_block ssb),
     start_both_blocks AS (SELECT sfb.peer
                           FROM start_first_block sfb
                           INTERSECT
                           SELECT ssb.peer
                           FROM start_second_block ssb),
     start_noone_blocks AS (SELECT p.nickname
                            FROM peers p
                                     LEFT JOIN checks ON
                                p.nickname = checks.peer
                            WHERE peer IS NULL)
SELECT (SELECT count(*) * 100 FROM start_only_first_block) / (SELECT count(*) FROM peers),
       (SELECT count(*) * 100 FROM start_only_second_block) / (SELECT count(*) FROM peers),
       (SELECT count(*) * 100 FROM start_both_blocks) / (SELECT count(*) FROM peers),
       (SELECT count(*) * 100 FROM start_noone_blocks) / (SELECT count(*) FROM peers);
$$
LANGUAGE SQL;

SELECT *
FROM fnc_peers_completed('C2', 'C3');


-- 10) Определить процент пиров, которые когда-либо успешно проходили проверку в свой день рождения
-- Также определите процент пиров, которые хоть раз проваливали проверку в свой день рождения.
-- Формат вывода: процент пиров, успешно прошедших проверку в день рождения, процент пиров, проваливших проверку в день рождения

CREATE
OR REPLACE FUNCTION fnc_peers_checks_on_birthday()
    RETURNS TABLE
            (
                SuccessfulChecks   integer,
                UnsuccessfulChecks integer
            )
AS
$$
WITH count_succes AS (SELECT count(*)
                      FROM peers p
                               JOIN checks c ON to_date(p.birthday, 'mm-dd') = to_date(c.date, 'mm-dd')
                               JOIN verter v ON c.id = v.checkid AND state = 'Success'),
     count_failrule AS (SELECT count(*)
                        FROM peers p
                                 JOIN checks c ON to_date(p.birthday, 'mm-dd') = to_date(c.date, 'mm-dd')
                                 JOIN verter v ON c.id = v.checkid AND state = 'Failure'),
     total_peers AS (SELECT count(*) FROM peers)

SELECT ((SELECT * FROM count_succes) * 100) / (SELECT * FROM total_peers)   AS SuccessfulChecks,
       ((SELECT * FROM count_failrule) * 100) / (SELECT * FROM total_peers) AS UnsuccessfulChecks;
$$
LANGUAGE SQL;

SELECT *
FROM fnc_peers_checks_on_birthday();


-- 11) Определить всех пиров, которые сдали заданные задания 1 и 2, но не сдали задание 3
-- Параметры процедуры: названия заданий 1, 2 и 3.
-- Формат вывода: список пиров

DROP PROCEDURE IF EXISTS peers_did_tasks() CASCADE;
DROP PROCEDURE peers_did_tasks(REFCURSOR, VARCHAR, VARCHAR, VARCHAR);

CREATE
    OR REPLACE PROCEDURE peers_did_tasks(result REFCURSOR, IN task1 VARCHAR, IN task2 VARCHAR, IN task3 VARCHAR)
    LANGUAGE plpgsql
AS
$$
BEGIN
    OPEN result FOR
        WITH cte_table AS (SELECT Checks.ID, Peer, Task, P2P.State AS p2p, Verter.State AS verter
                           FROM Checks
                                    JOIN P2P on Checks.ID = P2P.CheckID
                                    LEFT JOIN Verter ON Checks.ID = Verter.CheckID
                           WHERE P2P.State IN ('Success', 'Failure')
                             AND (Verter.State IN ('Success', 'Failure') OR Verter.State IS NULL)),
             success_task1 AS (SELECT cte_table.Peer
                               FROM cte_table
                                        LEFT JOIN cte_table ct ON ct.Task IN (SELECT Task FROM Checks)
                               WHERE task1 = cte_table.Task
                                 AND (cte_table.p2p = 'Success' AND
                                      (cte_table.verter = 'Success' OR cte_table.verter IS NULL))),
             success_task2 AS (SELECT cte_table.Peer
                               FROM cte_table
                                        LEFT JOIN cte_table ct ON ct.Task IN (SELECT Task FROM Checks)
                               WHERE task2 = cte_table.Task
                                 AND (cte_table.p2p = 'Success' AND
                                      (cte_table.verter = 'Success' OR cte_table.verter IS NULL))),
             failure_task3 AS (SELECT cte_table.Peer
                               FROM cte_table
                                        LEFT JOIN cte_table ct ON ct.Task IN (SELECT Task FROM Checks)
                               WHERE task3 = cte_table.Task
                                 AND (cte_table.p2p = 'Failure' OR cte_table.verter = 'Failure'))
        SELECT *
        FROM (SELECT *
              FROM success_task1
              INTERSECT
              SELECT *
              FROM success_task2) AS success
        INTERSECT
        SELECT *
        FROM failure_task3;
END
$$;

BEGIN;
CALL peers_did_tasks('peer', 'C2_SimpleBashUtils','C3_s21_string+', 'C4_s21_math');
FETCH ALL IN "peer";
END;


-- 12) Используя рекурсивное обобщенное табличное выражение, для каждой задачи вывести кол-во предшествующих ей задач
-- То есть сколько задач нужно выполнить, исходя из условий входа, чтобы получить доступ к текущей.
-- Формат вывода: название задачи, количество предшествующих

DROP PROCEDURE IF EXISTS preceding_tasks() CASCADE;
DROP PROCEDURE preceding_tasks(REFCURSOR);

CREATE
    OR REPLACE PROCEDURE preceding_tasks(IN result REFCURSOR)
    LANGUAGE plpgsql
AS
$$
BEGIN
    OPEN result FOR
        WITH RECURSIVE r (Title, ParentTask, Count) AS
                           (SELECT Title, ParentTask, 0
                            FROM Tasks
                            WHERE ParentTask IS NULL
                            UNION ALL
                            SELECT Tasks.Title, Tasks.ParentTask, Count + 1
                            FROM r,
                                 Tasks
                            WHERE r.Title = Tasks.ParentTask)
        SELECT Title AS Task, Count AS PrevCount
        FROM r;
END
$$;

BEGIN;
CALL preceding_tasks('result');
FETCH ALL IN "result";
END;


-- 13) Найти "удачные" для проверок дни. День считается "удачным", если в нем есть хотя бы N идущих подряд успешных проверки
-- Параметры процедуры: количество идущих подряд успешных проверок N.
-- Временем проверки считать время начала P2P этапа.
-- Под идущими подряд успешными проверками подразумеваются успешные проверки, между которыми нет неуспешных.
-- При этом кол-во опыта за каждую из этих проверок должно быть не меньше 80% от максимального.
-- Формат вывода: список дней

DROP PROCEDURE IF EXISTS find_lucky_days_for_checks() CASCADE;
DROP PROCEDURE find_lucky_days_for_checks(REFCURSOR, INTEGER);

CREATE
    OR REPLACE PROCEDURE find_lucky_days_for_checks(IN result REFCURSOR, IN N INT)
    LANGUAGE plpgsql
AS
$$
BEGIN
    OPEN result FOR
        WITH cte_table AS (SELECT *
                           FROM Checks
                                    JOIN P2P ON Checks.ID = P2P.CheckID
                                    JOIN XP ON Checks.ID = XP.CheckID
                                    JOIN Verter ON Checks.ID = Verter.CheckID
                                    JOIN Tasks ON Checks.Task = Tasks.Title
                           WHERE P2P.State = 'Success'
                             AND Verter.State = 'Success')
        SELECT Date
        FROM cte_table
        WHERE cte_table.XPAmount * 100 / cte_table.MaxXP >= 80
        GROUP BY Date
        HAVING COUNT(Date) >= N;
END
$$;

BEGIN;
CALL find_lucky_days_for_checks('date', 1);
FETCH ALL IN "date";
END;


-- 14) Определить пира с наибольшим количеством XP
-- Формат вывода: ник пира, количество XP

DROP PROCEDURE IF EXISTS peer_max_xp() CASCADE;
DROP PROCEDURE peer_max_xp(REFCURSOR);

CREATE
    OR REPLACE PROCEDURE peer_max_xp(IN result REFCURSOR)
    LANGUAGE plpgsql
AS
$$
BEGIN
    OPEN result FOR
        SELECT Peer, SUM(XPAmount) AS XP
        FROM XP
                 JOIN Checks ON XP.CheckID = Checks.ID
        GROUP BY Peer
        ORDER BY XP DESC
        LIMIT 1;
END
$$;

BEGIN;
CALL peer_max_xp('nickname');
FETCH ALL IN "nickname";
END;


-- 15) Определить пиров, приходивших раньше заданного времени не менее N раз за всё время
-- Параметры процедуры: время, количество раз N.
-- Формат вывода: список пиров

DROP PROCEDURE IF EXISTS peer_came_before_the_given_times() CASCADE;
DROP PROCEDURE peer_came_before_the_given_times(REFCURSOR, TIME, INTEGER);

CREATE
    OR REPLACE PROCEDURE peer_came_before_the_given_times(IN result REFCURSOR, IN check_time TIME, IN N INT)
    LANGUAGE plpgsql
AS
$$
BEGIN
    OPEN result FOR
        SELECT Peer
        FROM TimeTracking
        WHERE State = 1
          AND TimeTracking.Time < check_time
        GROUP BY Peer
        HAVING COUNT(Peer) >= N;
END
$$;

BEGIN;
CALL peer_came_before_the_given_times('nickname', '09:00:00', 1);
FETCH ALL FROM "nickname";
END;


-- 16) Определить пиров, выходивших за последние N дней из кампуса больше M раз
-- Параметры процедуры: количество дней N, количество раз M.
-- Формат вывода: список пиров

DROP PROCEDURE IF EXISTS peer_who_left_the_campus() CASCADE;
DROP PROCEDURE peer_who_left_the_campus(REFCURSOR, INTEGER, INTEGER);

CREATE
    OR REPLACE PROCEDURE peer_who_left_the_campus(IN result REFCURSOR, IN N INT, IN M INT)
    LANGUAGE plpgsql
AS
$$
BEGIN
    OPEN result FOR
        SELECT Peer
        FROM TimeTracking
        WHERE State = 2
          AND TimeTracking.Date > (CURRENT_DATE - N)
        GROUP BY Peer
        HAVING COUNT(Peer) > M;
END
$$;

BEGIN;
CALL peer_who_left_the_campus('nickname', 365, 1);
FETCH ALL FROM "nickname";
END;


-- 17) Определить для каждого месяца процент ранних входов
-- Для каждого месяца посчитать, сколько раз люди, родившиеся в этот месяц, приходили в кампус за всё время (будем называть это общим числом входов).
-- Для каждого месяца посчитать, сколько раз люди, родившиеся в этот месяц, приходили в кампус раньше 12:00 за всё время (будем называть это числом ранних входов).
-- Для каждого месяца посчитать процент ранних входов в кампус относительно общего числа входов.
-- Формат вывода: месяц, процент ранних входов

DROP PROCEDURE IF EXISTS percentage_of_early_entries() CASCADE;
DROP PROCEDURE percentage_of_early_entries(REFCURSOR);

CREATE
    OR REPLACE PROCEDURE percentage_of_early_entries(result INOUT REFCURSOR)
    LANGUAGE plpgsql
AS
$$
BEGIN
    OPEN result FOR
        WITH cte_table AS (SELECT Peer,
                                  Date,
                                  Time,
                                  EXTRACT(MONTH FROM TimeTracking.Date) AS month_number,
                                  TO_CHAR(TimeTracking.Date, 'Month')   AS month_name
                           FROM TimeTracking
                                    JOIN Peers ON TimeTracking.Peer = Peers.Nickname
                               AND EXTRACT(MONTH FROM Peers.Birthday) = EXTRACT(MONTH FROM TimeTracking.Date)
                           WHERE State = 1),
             all_entries AS (SELECT DISTINCT month_name,
                                             SUM(month_number) AS amn
                             FROM cte_table
                             GROUP BY month_name
                             ORDER BY month_name),
             early_entries AS (SELECT DISTINCT month_name,
                                               SUM(month_number) AS emn
                               FROM cte_table
                               WHERE Time < '12:00:00'
                               GROUP BY month_name
                               ORDER BY month_name)
        SELECT early_entries.month_name                                  AS Month,
               (early_entries.emn::FLOAT * 100) / all_entries.amn::FLOAT AS EarlyEntries
        FROM early_entries
                 JOIN all_entries ON early_entries.month_name = all_entries.month_name;
END
$$;

-- для проверки можно поменять месяц рождения у гарри и гермионы на январь
BEGIN;
CALL percentage_of_early_entries('result');
FETCH ALL FROM "result";
END;
