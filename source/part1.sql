/* Part 1. Создание базы данных */

-- Удаление таблиц, типа и процедур, если они существуют
DROP TABLE IF EXISTS Peers CASCADE;
DROP TABLE IF EXISTS Tasks CASCADE;
DROP TABLE IF EXISTS P2P CASCADE;
DROP TABLE IF EXISTS Verter CASCADE;
DROP TABLE IF EXISTS Checks CASCADE;
DROP TABLE IF EXISTS TransferredPoints CASCADE;
DROP TABLE IF EXISTS Friends CASCADE;
DROP TABLE IF EXISTS Recommendations CASCADE;
DROP TABLE IF EXISTS XP CASCADE;
DROP TABLE IF EXISTS TimeTracking CASCADE;
DROP TYPE IF EXISTS check_status CASCADE;
DROP PROCEDURE IF EXISTS import_csv() CASCADE;
DROP PROCEDURE import_csv(VARCHAR, VARCHAR, CHAR);
DROP PROCEDURE IF EXISTS export_csv() CASCADE;
DROP PROCEDURE export_csv(VARCHAR, VARCHAR, CHAR);

-- Создание таблицы Peers
CREATE TABLE Peers (
    Nickname VARCHAR UNIQUE PRIMARY KEY NOT NULL,
    Birthday DATE NOT NULL
);

-- Создание таблицы Tasks
CREATE TABLE Tasks (
    Title VARCHAR PRIMARY KEY NOT NULL,
    ParentTask VARCHAR DEFAULT NULL,
    MaxXP INTEGER NOT NULL,
    FOREIGN KEY (ParentTask) REFERENCES Tasks (Title)
);

-- Создание типа перечисления для статуса проверки
CREATE TYPE check_status AS ENUM ('Start', 'Success', 'Failure');

-- Создание таблицы Checks
CREATE TABLE Checks (
    ID BIGINT PRIMARY KEY NOT NULL,
    Peer VARCHAR NOT NULL,
    Task VARCHAR NOT NULL,
    Date DATE NOT NULL,
    CONSTRAINT FK_Checks_Peers FOREIGN KEY (Peer) REFERENCES Peers (Nickname),
    CONSTRAINT FK_Checks_Tasks FOREIGN KEY (Task) REFERENCES Tasks (Title)
);

-- Создание таблицы P2P
CREATE TABLE P2P (
    ID BIGINT PRIMARY KEY NOT NULL,
    CheckID INTEGER NOT NULL,
    CheckingPeer VARCHAR,
    State check_status NOT NULL,
    Time TIME NOT NULL,
    CONSTRAINT FK_P2P_Checks FOREIGN KEY (CheckID) REFERENCES Checks (ID),
    CONSTRAINT FK_P2P_Peers FOREIGN KEY (CheckingPeer) REFERENCES Peers (Nickname)
);

-- Создание таблицы Verter
CREATE TABLE Verter (
    ID BIGINT PRIMARY KEY NOT NULL,
    CheckID INTEGER NOT NULL,
    State check_status NOT NULL,
    Time TIME NOT NULL,
    CONSTRAINT FK_Verter_Checks FOREIGN KEY (CheckID) REFERENCES Checks (ID)
);

-- Создание таблицы TransferredPoints
CREATE TABLE TransferredPoints (
    ID BIGINT PRIMARY KEY NOT NULL,
    CheckingPeer VARCHAR NOT NULL,
    CheckedPeer VARCHAR NOT NULL,
    PointsAmount INTEGER NOT NULL,
    CONSTRAINT FK_TransferredPoints_Peers FOREIGN KEY (CheckingPeer) REFERENCES Peers (Nickname),
    CONSTRAINT FK_TransferredPoints__Peers FOREIGN KEY (CheckedPeer) REFERENCES Peers (Nickname)
);

-- Создание таблицы Friends
CREATE TABLE Friends (
    ID BIGINT PRIMARY KEY NOT NULL,
    Peer1 VARCHAR NOT NULL,
    Peer2 VARCHAR NOT NULL,
    CONSTRAINT FK_Friends_Peers FOREIGN KEY (Peer1) REFERENCES Peers (Nickname),
    CONSTRAINT FK_Friends__Peers FOREIGN KEY (Peer2) REFERENCES Peers (Nickname)
);

-- Создание таблицы Recommendations
CREATE TABLE Recommendations (
    ID BIGINT PRIMARY KEY NOT NULL,
    Peer VARCHAR NOT NULL,
    RecommendedPeer VARCHAR NOT NULL,
    CONSTRAINT FK_Recommendations_Peers FOREIGN KEY (Peer) REFERENCES Peers (Nickname),
    CONSTRAINT FK_Recommendations__Peers FOREIGN KEY (RecommendedPeer) REFERENCES Peers (Nickname)
);

-- Создание таблицы XP
CREATE TABLE XP (
    ID BIGINT PRIMARY KEY NOT NULL,
    CheckID BIGINT NOT NULL,
    XPAmount INTEGER NOT NULL,
    CONSTRAINT FK_XP_Checks FOREIGN KEY (CheckID) REFERENCES Checks (ID)
);

-- Создание таблицы TimeTracking
CREATE TABLE TimeTracking (
    ID BIGINT PRIMARY KEY NOT NULL,
    Peer VARCHAR NOT NULL,
    Date DATE NOT NULL,
    Time TIME NOT NULL,
    State SMALLINT NOT NULL CHECK (State IN (1, 2)),
    -- (1 - пришел, 2 - вышел)
    CONSTRAINT FK_TimeTracking_Peers FOREIGN KEY (Peer) REFERENCES Peers (Nickname)
);

-- Добавление данных в таблицы
-- Таблица Peers
INSERT INTO Peers (Nickname, Birthday)
VALUES ('harry', '1980-07-31'),
    ('hermione', '1979-09-19'),
    ('ron', '1980-03-01'),
    ('neville', '1980-07-30'),
    ('draco', '1980-06-05');
    
-- Таблица Tasks
INSERT INTO Tasks (Title, ParentTask, MaxXP)
VALUES ('C2_SimpleBashUtils', NULL, 350),
    ('C3_s21_string+', 'C2_SimpleBashUtils', 750),
    ('C4_s21_math', 'C3_s21_string+', 300),
    ('C5_s21_decimal', 'C4_s21_math', 350),
    ('C6_s21_matrix', 'C5_s21_decimal', 200);
    
-- Таблица Checks
INSERT INTO Checks (ID, Peer, Task, Date)
VALUES (1, 'harry', 'C2_SimpleBashUtils', '2023-01-10'),
    (2, 'hermione', 'C3_s21_string+', '2023-01-01'),
    (3, 'ron', 'C4_s21_math', '2023-02-01'),
    (4, 'neville', 'C5_s21_decimal', '2023-02-03'),
    (5, 'draco', 'C6_s21_matrix', '2023-02-25');
    
-- Таблица P2P
INSERT INTO P2P (ID, CheckID, CheckingPeer, State, Time)
VALUES (1, 1, 'harry', 'Start', '17:00'),
    (2, 1, 'harry', 'Success', '18:00'),
    (3, 2, 'hermione', 'Start', '08:00'),
    (4, 2, 'hermione', 'Success', '09:00'),
    (5, 3, 'ron', 'Start', '15:00'),
    (6, 3, 'ron', 'Failure', '16:00');
    
-- Таблица Verter
INSERT INTO Verter (ID, CheckID, State, Time)
VALUES (1, 1, 'Start', '17:55'),
    (2, 1, 'Success', '18:00'),
    (3, 2, 'Start', '08:55'),
    (4, 2, 'Success', '09:00'),
    (5, 3, 'Start', '15:55'),
    (6, 3, 'Failure', '16:00');
    
-- Таблица TransferredPoints
INSERT INTO TransferredPoints (ID, CheckingPeer, CheckedPeer, PointsAmount)
VALUES (1, 'harry', 'hermione', 1),
    (2, 'hermione', 'harry', 1),
    (3, 'ron', 'neville', 1),
    (4, 'neville', 'ron', 1),
    (5, 'harry', 'draco', 1);
    
-- Таблица Friends
INSERT INTO Friends (ID, Peer1, Peer2)
VALUES (1, 'harry', 'hermione'),
    (2, 'harry', 'ron'),
    (3, 'ron', 'hermione'),
    (4, 'hermione', 'neville'),
    (5, 'neville', 'harry');
    
-- Таблица Recommendations
INSERT INTO Recommendations (ID, Peer, RecommendedPeer)
VALUES (1, 'harry', 'hermione'),
    (2, 'hermione', 'neville'),
    (3, 'ron', 'draco'),
    (4, 'neville', 'ron'),
    (5, 'draco', 'harry');
    
-- Таблица XP
INSERT INTO XP (ID, CheckID, XPAmount)
VALUES (1, 1, 350),
    (2, 2, 750),
    (3, 3, 300),
    (4, 4, 350),
    (5, 5, 200);
    
-- Таблица TimeTracking
INSERT INTO TimeTracking (ID, Peer, Date, Time, State)
VALUES (1, 'harry', '2023-01-10', '16:00', 1),
    (2, 'harry', '2023-01-10', '18:00', 2),
    (3, 'hermione', '2023-01-01', '07:00', 1),
    (4, 'hermione', '2023-01-01', '19:00', 2),
    (5, 'ron', '2023-02-01', '14:00', 1),
    (6, 'ron', '2023-02-01', '18:00', 2),
    (7, 'neville', '2023-02-03', '14:00', 1),
    (8, 'neville', '2023-02-03', '18:00', 2),
    (9, 'draco', '2023-02-25', '12:00', 1),
    (10, 'draco', '2023-02-25', '17:00', 2),
    (11, 'draco', '2023-02-26', '11:00', 1),
    (12, 'draco', '2023-02-26', '20:00', 2);
    
-- Процедуры, позволяющие импортировать и экспортировать данные:
-- Импорт данных
CREATE OR REPLACE PROCEDURE import_csv(
        IN table_name VARCHAR,
        IN file_path VARCHAR,
        IN separator CHAR
    ) LANGUAGE plpgsql AS $$ BEGIN EXECUTE FORMAT(
        'COPY %s FROM ''%s'' DELIMITER ''%s'' CSV HEADER;',
        table_name,
        file_path,
        separator
    );
END $$;
-- Экспорт данных
CREATE OR REPLACE PROCEDURE export_csv(
        IN table_name VARCHAR,
        IN file_path VARCHAR,
        IN separator CHAR
    ) LANGUAGE plpgsql AS $$ BEGIN EXECUTE FORMAT(
        'COPY %s TO ''%s'' DELIMITER ''%s'' CSV HEADER;',
        table_name,
        file_path,
        separator
    );
END $$;


-- Тестирование процедуры, экспорт данных в файл. Проверьте свой абсолютный путь!
CALL export_csv('Peers', '/Users/aliiasatbakova/SQL2_Info21_v1.0-1/src/csv_files/peers.csv', ',');
CALL export_csv('Tasks', '/Users/aliiasatbakova/SQL2_Info21_v1.0-1/src/csv_files/tasks.csv', ',');
CALL export_csv('P2P', '/Users/aliiasatbakova/SQL2_Info21_v1.0-1/src/csv_files/p2p.csv', ',');
CALL export_csv('Verter', '/Users/aliiasatbakova/SQL2_Info21_v1.0-1/src/csv_files/verter.csv', ',');
CALL export_csv('Checks', '/Users/aliiasatbakova/SQL2_Info21_v1.0-1/src/csv_files/checks.csv', ',');
CALL export_csv('TransferredPoints', '/Users/aliiasatbakova/SQL2_Info21_v1.0-1/src/csv_files/transferredpoints.csv', ',');
CALL export_csv('Friends', '/Users/aliiasatbakova/SQL2_Info21_v1.0-1/src/csv_files/friends.csv', ',');
CALL export_csv('Recommendations', '/Users/aliiasatbakova/SQL2_Info21_v1.0-1/src/csv_files/recommendations.csv', ',');
CALL export_csv('XP', '/Users/aliiasatbakova/SQL2_Info21_v1.0-1/src/csv_files/xp.csv', ',');
CALL export_csv('TimeTracking', '/Users/aliiasatbakova/SQL2_Info21_v1.0-1/src/csv_files/timetracking.csv', ',');

-- Тестирование процедуры, импорт данных в файл. Проверьте свой абсолютный путь!
CALL import_csv('Peers', '/Users/aliiasatbakova/SQL2_Info21_v1.0-1/src/csv_files/peers.csv', ',');
CALL import_csv('Tasks', '/Users/aliiasatbakova/SQL2_Info21_v1.0-1/src/csv_files/tasks.csv', ',');
CALL import_csv('P2P', '/Users/aliiasatbakova/SQL2_Info21_v1.0-1/src/csv_files/p2p.csv', ',');
CALL import_csv('Verter', '/Users/aliiasatbakova/SQL2_Info21_v1.0-1/src/csv_files/verter.csv', ',');
CALL import_csv('Checks', '/Users/aliiasatbakova/SQL2_Info21_v1.0-1/src/csv_files/checks.csv', ',');
CALL import_csv('TransferredPoints', '/Users/aliiasatbakova/SQL2_Info21_v1.0-1/src/csv_files/transferredpoints.csv', ',');
CALL import_csv('Friends', '/Users/aliiasatbakova/SQL2_Info21_v1.0-1/src/csv_files/friends.csv', ',');
CALL import_csv('Recommendations', '/Users/aliiasatbakova/SQL2_Info21_v1.0-1/src/csv_files/recommendations.csv', ',');
CALL import_csv('XP', '/Users/aliiasatbakova/SQL2_Info21_v1.0-1/src/csv_files/xp.csv', ',');
CALL import_csv('TimeTracking', '/Users/aliiasatbakova/SQL2_Info21_v1.0-1/src/csv_files/timetracking.csv', ',');


-- Удаление данных из таблиц при необходимости
TRUNCATE TABLE Peers CASCADE;
TRUNCATE TABLE Tasks CASCADE;
TRUNCATE TABLE Checks CASCADE;
TRUNCATE TABLE P2P CASCADE;
TRUNCATE TABLE Verter CASCADE;
TRUNCATE TABLE TransferredPoints CASCADE;
TRUNCATE TABLE Friends CASCADE;
TRUNCATE TABLE Recommendations CASCADE;
TRUNCATE TABLE XP CASCADE;
TRUNCATE TABLE TimeTracking CASCADE;
