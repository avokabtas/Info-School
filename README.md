# InfoSchool

В этом проекте нужно будет создать базу данных с данными о школе 21 и написать процедуры и функции для извлечения информации, а также процедуры и триггеры для ее изменения.

In this project, you will need to create a database with data about School 21 and write procedures and functions to retrieve information, as well as procedures and triggers to change it.

## Русскоязычная версия

<details>
<summary>Анализ и статистика данных по Школе 21.</summary>

### Логическое представление модели базы данных

![SQL2](./images/SQL.png)

*Все поля при описании таблиц перечислены в том же порядке, что и на схеме.*

#### Таблица Peers

- Ник пира
- День рождения

#### Таблица Tasks

- Название задания
- Название задания, являющегося условием входа
- Максимальное количество XP

Чтобы получить доступ к заданию, нужно выполнить задание, являющееся его условием входа.
Для упрощения будем считать, что у каждого задания всего одно условие входа.
В таблице должно быть одно задание, у которого нет условия входа (т.е. поле ParentTask равно null).

#### Статус проверки

Создать тип перечисления для статуса проверки, содержащий следующие значения:
- Start - начало проверки
- Success - успешное окончание проверки
- Failure - неудачное окончание проверки

#### Таблица P2P

- ID
- ID проверки
- Ник проверяющего пира
- [Статус P2P проверки](#статус-проверки)
- Время

Каждая P2P проверка состоит из 2-х записей в таблице: первая имеет статус начало, вторая - успех или неуспех. \
В таблице не может быть больше одной незавершенной P2P проверки, относящейся к конкретному заданию, пиру и проверяющему. \
Каждая P2P проверка (т.е. обе записи, из которых она состоит) ссылается на проверку в таблице Checks, к которой она относится.


#### Таблица Verter

- ID
- ID проверки
- [Статус проверки Verter'ом](#статус-проверки)
- Время 

Каждая проверка Verter'ом состоит из 2-х записей в таблице: первая имеет статус начало, вторая - успех или неуспех. \
Каждая проверка Verter'ом (т.е. обе записи, из которых она состоит) ссылается на проверку в таблице Checks, к которой она относится. \
Проверка Verter'ом может ссылаться только на те проверки в таблице Checks, которые уже включают в себя успешную P2P проверку.

#### Таблица Checks

- ID 
- Ник пира
- Название задания
- Дата проверки

Описывает проверку задания в целом. Проверка обязательно включает в себя **один** этап P2P и, возможно, этап Verter.
Для упрощения будем считать, что пир ту пир и автотесты, относящиеся к одной проверке, всегда происходят в один день.

Проверка считается успешной, если соответствующий P2P этап успешен, а этап Verter успешен, либо отсутствует.
Проверка считается неуспешной, хоть один из этапов неуспешен.
То есть проверки, в которых ещё не завершился этап P2P, или этап P2P успешен, но ещё не завершился этап Verter, не относятся ни к успешным, ни к неуспешным.

#### Таблица TransferredPoints

- ID
- Ник проверяющего пира
- Ник проверяемого пира
- Количество переданных пир поинтов за всё время (только от проверяемого к проверяющему)

При каждой P2P проверке проверяемый пир передаёт один пир поинт проверяющему.
Эта таблица содержит все пары проверяемый-проверяющий и кол-во переданных пир поинтов, то есть, 
другими словами, количество P2P проверок указанного проверяемого пира, данным проверяющим.

#### Таблица Friends

- ID
- Ник первого пира
- Ник второго пира 

Дружба взаимная, т.е. первый пир является другом второго, а второй -- другом первого.

#### Таблица Recommendations

- ID
- Ник пира
- Ник пира, к которому рекомендуют идти на проверку

Каждому может понравиться, как проходила P2P проверка у того или иного пира. 
Пир, указанный в поле Peer, рекомендует проходить P2P проверку у пира из поля RecommendedPeer. 
Каждый пир может рекомендовать как ни одного, так и сразу несколько проверяющих.

#### Таблица XP

- ID
- ID проверки
- Количество полученного XP

За каждую успешную проверку пир, выполнивший задание, получает какое-то количество XP, отображаемое в этой таблице. 
Количество XP не может превышать максимальное доступное для проверяемой задачи. 
Первое поле этой таблицы может ссылаться только на успешные проверки.

#### Таблица TimeTracking

- ID
- Ник пира
- Дата
- Время
- Состояние (1 - пришел, 2 - вышел)

Данная таблица содержит информация о посещениях пирами кампуса. 
Когда пир входит в кампус, в таблицу добавляется запись с состоянием 1, когда покидает - с состоянием 2. 

В заданиях, относящихся к этой таблице, под действием "выходить" подразумеваются все покидания кампуса за день, кроме последнего. 
В течение одного дня должно быть одинаковое количество записей с состоянием 1 и состоянием 2 для каждого пира.

Например:

| ID | Peer  | Date     | Time  | State |
|----|-------|----------|-------|-------|
| 1  | Aboba | 22.03.22 | 13:37 | 1     |
| 2  | Aboba | 22.03.22 | 15:48 | 2     |
| 3  | Aboba | 22.03.22 | 16:02 | 1     |
| 4  | Aboba | 22.03.22 | 20:00 | 2     |

В этом примере "выходом" является только запись с ID, равным 2. Пир с ником Aboba выходил из кампуса на 14 минут.

## Part 1. Создание базы данных

Напишите скрипт *part1.sql*, создающий базу данных и все таблицы, описанные выше. 

Также внесите в скрипт процедуры, позволяющие импортировать и экспортировать данные для каждой таблицы из файла/в файл с расширением *.csv*. \
В качестве параметра каждой процедуры указывается разделитель *csv* файла.

В каждую из таблиц внесите как минимум по 5 записей. 
По мере выполнения задания вам потребуются новые данные, чтобы проверить все варианты работы. 
Эти новые данные также должны быть добавлены в этом скрипте.

Если для добавления данных в таблицы использовались *csv* файлы, они также должны быть выгружены в GIT репозиторий.

*Все задания должны быть названы в формате названий для Школы 21, например A5_s21_memory. \
В дальнейшем принадлежность к блоку будет определяться по содержанию в названии задания названия блока, например "CPP3_SmartCalc_v2.0" принадлежит блоку CPP. \*

## Part 2. Изменение данных

Создайте скрипт *part2.sql*, в который, помимо описанного ниже, внесите тестовые запросы/вызовы для каждого пункта.

##### 1) Написать процедуру добавления P2P проверки
Параметры: ник проверяемого, ник проверяющего, название задания, [статус P2P проверки](#статус-проверки), время. \
Если задан статус "начало", добавить запись в таблицу Checks (в качестве даты использовать сегодняшнюю). \
Добавить запись в таблицу P2P. \
Если задан статус "начало", в качестве проверки указать только что добавленную запись, иначе указать проверку с незавершенным P2P этапом.

##### 2) Написать процедуру добавления проверки Verter'ом
Параметры: ник проверяемого, название задания, [статус проверки Verter'ом](#статус-проверки), время. \
Добавить запись в таблицу Verter (в качестве проверки указать проверку соответствующего задания с самым поздним (по времени) успешным P2P этапом)

##### 3) Написать триггер: после добавления записи со статутом "начало" в таблицу P2P, изменить соответствующую запись в таблице TransferredPoints

##### 4) Написать триггер: перед добавлением записи в таблицу XP, проверить корректность добавляемой записи
Запись считается корректной, если:
- Количество XP не превышает максимальное доступное для проверяемой задачи
- Поле Check ссылается на успешную проверку
Если запись не прошла проверку, не добавлять её в таблицу.

## Part 3. Получение данных

Создайте скрипт *part3.sql*, в который внесите описанные далее процедуры и функции 
(считать процедурами все задания, в которых не указано, что это функция).

##### 1) Написать функцию, возвращающую таблицу TransferredPoints в более человекочитаемом виде
Ник пира 1, ник пира 2, количество переданных пир поинтов. \
Количество отрицательное, если пир 2 получил от пира 1 больше поинтов.

Пример вывода:
| Peer1  | Peer2  | PointsAmount |
|--------|--------|--------------|
| Aboba  | Amogus | 5            |
| Amogus | Sus    | -2           |
| Sus    | Aboba  | 0            |

##### 2) Написать функцию, которая возвращает таблицу вида: ник пользователя, название проверенного задания, кол-во полученного XP
В таблицу включать только задания, успешно прошедшие проверку (определять по таблице Checks). \
Одна задача может быть успешно выполнена несколько раз. В таком случае в таблицу включать все успешные проверки.

Пример вывода:
| Peer   | Task | XP  |
|--------|------|-----|
| Aboba  | C8   | 800 |
| Aboba  | CPP3 | 750 |
| Amogus | DO5  | 175 |
| Sus    | A4   | 325 |

##### 3) Написать функцию, определяющую пиров, которые не выходили из кампуса в течение всего дня
Параметры функции: день, например 12.05.2022. \
Функция возвращает только список пиров.

##### 4) Посчитать изменение в количестве пир поинтов каждого пира по таблице TransferredPoints
Результат вывести отсортированным по изменению числа поинтов. \
Формат вывода: ник пира, изменение в количество пир поинтов

Пример вывода:
| Peer   | PointsChange |
|--------|--------------|
| Aboba  | 8            |
| Amogus | 1            |
| Sus    | -3           |

##### 5) Посчитать изменение в количестве пир поинтов каждого пира по таблице, возвращаемой [первой функцией из Part 3](#1-написать-функцию-возвращающую-таблицу-transferredpoints-в-более-человекочитаемом-виде)
Результат вывести отсортированным по изменению числа поинтов. \
Формат вывода: ник пира, изменение в количество пир поинтов

Пример вывода:
| Peer   | PointsChange |
|--------|--------------|
| Aboba  | 8            |
| Amogus | 1            |
| Sus    | -3           |

##### 6) Определить самое часто проверяемое задание за каждый день
При одинаковом количестве проверок каких-то заданий в определенный день, вывести их все. \
Формат вывода: день, название задания

Пример вывода:
| Day        | Task |
|------------|------|
| 12.05.2022 | A1   |
| 17.04.2022 | CPP3 |
| 23.12.2021 | C5   |

##### 7) Найти всех пиров, выполнивших весь заданный блок задач и дату завершения последнего задания
Параметры процедуры: название блока, например "CPP". \
Результат вывести отсортированным по дате завершения. \
Формат вывода: ник пира, дата завершения блока (т.е. последнего выполненного задания из этого блока)

Пример вывода:
| Peer   | Day        |
|--------|------------|
| Sus    | 23.06.2022 |
| Amogus | 17.05.2022 |
| Aboba  | 12.05.2022 |

##### 8) Определить, к какому пиру стоит идти на проверку каждому обучающемуся
Определять нужно исходя из рекомендаций друзей пира, т.е. нужно найти пира, проверяться у которого рекомендует наибольшее число друзей. \
Формат вывода: ник пира, ник найденного проверяющего

Пример вывода:
| Peer   | RecommendedPeer  |
|--------|-----------------|
| Aboba  | Sus             |
| Amogus | Aboba           |
| Sus    | Aboba           |

##### 9) Определить процент пиров, которые:
- Приступили только к блоку 1
- Приступили только к блоку 2
- Приступили к обоим
- Не приступили ни к одному

Пир считается приступившим к блоку, если он проходил хоть одну проверку любого задания из этого блока (по таблице Checks)

Параметры процедуры: название блока 1, например SQL, название блока 2, например A. \
Формат вывода: процент приступивших только к первому блоку, процент приступивших только ко второму блоку, процент приступивших к обоим, процент не приступивших ни к одному

Пример вывода:
| StartedBlock1 | StartedBlock2 | StartedBothBlocks | DidntStartAnyBlock |
|---------------|---------------|-------------------|--------------------|
| 20            | 20            | 5                 | 55                 |

##### 10) Определить процент пиров, которые когда-либо успешно проходили проверку в свой день рождения
Также определите процент пиров, которые хоть раз проваливали проверку в свой день рождения. \
Формат вывода: процент пиров, успешно прошедших проверку в день рождения, процент пиров, проваливших проверку в день рождения

Пример вывода:
| SuccessfulChecks | UnsuccessfulChecks |
|------------------|--------------------|
| 60               | 40                 |

##### 11) Определить всех пиров, которые сдали заданные задания 1 и 2, но не сдали задание 3
Параметры процедуры: названия заданий 1, 2 и 3. \
Формат вывода: список пиров

##### 12) Используя рекурсивное обобщенное табличное выражение, для каждой задачи вывести кол-во предшествующих ей задач
То есть сколько задач нужно выполнить, исходя из условий входа, чтобы получить доступ к текущей. \
Формат вывода: название задачи, количество предшествующих

Пример вывода:
| Task | PrevCount |
|------|-----------|
| CPP3 | 7         |
| A1   | 9         |
| C5   | 1         |

##### 13) Найти "удачные" для проверок дни. День считается "удачным", если в нем есть хотя бы *N* идущих подряд успешных проверки
Параметры процедуры: количество идущих подряд успешных проверок *N*. \
Временем проверки считать время начала P2P этапа. \
Под идущими подряд успешными проверками подразумеваются успешные проверки, между которыми нет неуспешных. \
При этом кол-во опыта за каждую из этих проверок должно быть не меньше 80% от максимального. \
Формат вывода: список дней

##### 14) Определить пира с наибольшим количеством XP
Формат вывода: ник пира, количество XP

Пример вывода:
| Peer   | XP    |
|--------|-------|
| Amogus | 15000 |

##### 15) Определить пиров, приходивших раньше заданного времени не менее *N* раз за всё время
Параметры процедуры: время, количество раз *N*. \
Формат вывода: список пиров

##### 16) Определить пиров, выходивших за последние *N* дней из кампуса больше *M* раз
Параметры процедуры: количество дней *N*, количество раз *M*. \
Формат вывода: список пиров

##### 17) Определить для каждого месяца процент ранних входов
Для каждого месяца посчитать, сколько раз люди, родившиеся в этот месяц, приходили в кампус за всё время (будем называть это общим числом входов). \
Для каждого месяца посчитать, сколько раз люди, родившиеся в этот месяц, приходили в кампус раньше 12:00 за всё время (будем называть это числом ранних входов). \
Для каждого месяца посчитать процент ранних входов в кампус относительно общего числа входов. \
Формат вывода: месяц, процент ранних входов

Пример вывода:
| Month    | EarlyEntries |  
| -------- | -------------- |
| January  | 15           |
| February | 35           |
| March    | 45           |


</details>


## The English version

<details>
<summary>Data analysis and statistics for School 21.</summary>

### Logical view of database model

![SQL2](./images/SQL.png)

*All fields in the table descriptions are listed in the same order as in the schema.*

#### Peers table

- Peer’s nickname
- Birthday

#### Tasks table

- Name of the task
- Name of the task, which is the entry condition
- Maximum number of XP

To access the task, you must complete the task that is its entry condition.
For simplicity, assume that each task has only one entry condition.
There must be one task in the table that has no entry condition (i.e., the ParentTask field is null).

#### Check status

Create an enumeration type for the check status that contains the following values:
- Start - the check starts
- Success - successful completion of the check
- Failure - unsuccessful completion of the check

#### P2P Table

- ID
- Check ID
- Nickname of the checking peer
- [P2P check status](#check-status)
- Time

Each P2P check consists of 2 table records: the first has a start status, the second has a success or failure status. \
The table cannot contain more than one incomplete P2P check related to a specific task, a peer and a checking peer. \
Each P2P check (i.e. both records of which it consists) refers to the check in the Checks table to which it belongs. 

#### Verter Table

- ID
- Check ID
- [Check status by Verter](#check-status)
- Time

Each check by Verter consists of 2 table records: the first has a start status, the second has a success or failure status. \
Each check by Verter (i.e. both records of which it consists) refers to the check in the Checks table to which it belongs. \
Сheck by Verter can only refer to those checks in the Checks table that already include a successful P2P check.

#### Checks table

- ID
- Peer’s nickname
- Name of the task
- Check date

Describes the check of the task as a whole. The check necessarily includes a **one** P2P step and possibly a Verter step.
For simplicity, assume that peer to peer and autotests related to the same check always happen on the same day.

The check is considered successful if the corresponding P2P step is successful and the Verter step is successful, or if there is no Verter step.
The check is considered a failure if at least one of the steps is unsuccessful. This means that checks in which the P2P step has not yet been completed, or it is successful but the Verter step has not yet been completed, are neither successful nor failed.

#### TransferredPoints table

- ID
- Nickname of the checking peer
- Nickname of the peer being checked
- Number of transferred peer points for all time (only from the one being checked to the checker)

At each P2P check, the peer being checked passes one peer point to the checker.
This table contains all pairs of the peer being checked-the checker and the number of transferred peer points, that is the number of P2P checks of the specified peer by the specified checker.

#### Friends table

- ID
- Nickname of the first peer
- Nickname of the second peer

Friendship is mutual, i.e. the first peer is a friend of the second one, and vice versa.

#### Recommendations table

- ID
- Nickname of the peer
- Nickname of the peer to whom it is recommended to go for the check

Everyone can like how the P2P check was performed by a particular peer. The peer specified in the Peer field recommends passing the P2P check from the peer in the RecommendedPeer field. 
Each peer can recommend either one or several checkers at a time.

#### XP Table

- ID
- Check ID
- Number of XP received

For each successful check, the peer who completes the task receives some amount of XP displayed in this table.
The amount of XP cannot exceed the maximum available number for the task being checked.
The first field of this table can only refer to successful checks.

#### TimeTracking table

- ID
- Peer's nickname
- Date
- Time
- State (1 - in, 2 - out)

This table contains information about peers' visits to campus.
When a peer enters campus, a record is added to the table with state 1, when leaving it adds a record with state 2. 

In tasks related to this table, the "out" action refers to all but the last Campus departure of the day.
There must be the same number of records with state 1 and state 2 for each peer during one day.

For example:

| ID | Peer | Date   | Time | State |
|---|------|--------|------|---|
| 1 | Aboba | 22.03.22 | 13:37 | 1 |
| 2 | Aboba | 22.03.22 | 15:48 | 2 |
| 3 | Aboba | 22.03.22 | 16:02 | 1 |
| 4 | Aboba | 22.03.22 | 20:00 | 2 |

In this example, the only "out" is the record with an ID equal to 2. Peer with the nickname Aboba has been out of campus for 14 minutes.

## Part 1. Creating a database

Write a *part1.sql* script that creates the database and all the tables described above.

Also, add procedures to the script that allow you to import and export data for each table from/to a file with a *.csv* extension. \
The *csv* file separator is specified as a parameter of each procedure.

In each of the tables, enter at least 5 records.
As you progress through the task, you will need new data to test all of your choices.
This new data needs to be added to this script as well.

If *csv* files were used to add data to the tables, they must also be uploaded to the GIT repository.

*All tasks must be named in the format of names for School 21, for example A5_s21_memory. \
In the future, Whether a task belongs to a block will be determined by the name of the block in the task name, e.g. "CPP3_SmartCalc_v2.0" belongs to the CPP block. \*

## Part 2. Changing data

Create a *part2.sql* script, in which, in addition to what is described below, add test queries/calls for each item.

##### 1) Write a procedure for adding P2P check
Parameters: nickname of the person being checked, checker's nickname, task name, [P2P check status]( #check-status), time. \
If the status is "start", add a record in the Checks table (use today's date). \
Add a record in the P2P table. \
If the status is "start", specify the record just added as a check, otherwise specify the check with the unfinished P2P step.

##### 2) Write a procedure for adding checking by Verter
Parameters: nickname of the person being checked, task name, [Verter check status](#check-status), time. \
Add a record to the Verter table (as a check specify the check of the corresponding task with the latest (by time) successful P2P step)

##### 3) Write a trigger: after adding a record with the "start" status to the P2P table, change the corresponding record in the TransferredPoints table

##### 4) Write a trigger: before adding a record to the XP table, check if it is correct
The record is considered correct if:
- The number of XP does not exceed the maximum available for the task being checked
- The Check field refers to a successful check
If the record does not pass the check, do not add it to the table.

### Part 3. Getting data

Create a *part3.sql* script, in which you should include the following procedures and functions
(consider as procedures all tasks that do not specify that they are functions).

##### 1) Write a function that returns the TransferredPoints table in a more human-readable form
Peer's nickname 1, Peer's nickname 2, number of transferred peer points. \
The number is negative if peer 2 received more points from peer 1.

Output example:

| Peer1 | Peer2 | PointsAmount |
|------|------|----|
| Aboba | Amogus | 5  |
| Amogus | Sus  | -2 |
| Sus  | Aboba | 0  |

##### 2) Write a function that returns a table of the following form: user name, name of the checked task, number of XP received
Include in the table only tasks that have successfully passed the check (according to the Checks table). \
One task can be completed successfully several times. In this case, include all successful checks in the table.

Output example:

| Peer   | Task | XP  |
|--------|------|-----|
| Aboba  | C8   | 800 |
| Aboba  | CPP3 | 750 |
| Amogus | DO5  | 175 |
| Sus    | A4   | 325 |

##### 3) Write a function that finds the peers who have not left campus for the whole day
Function parameters: day, for example 12.05.2022. \
The function returns only a list of peers.

##### 4) Calculate the change in the number of peer points of each peer using the TransferredPoints table
Output the result sorted by the change in the number of points. \
Output format: peer's nickname, change in the number of peer points

Output example:
| Peer   | PointsChange |
|--------|--------------|
| Aboba  | 8            |
| Amogus | 1            |
| Sus    | -3           |

##### 5) Calculate the change in the number of peer points of each peer using the table returned by [the first function from Part 3](#1-write-a-function-that-returns-the-transferredpoints-table-in-a-more-human-readable-form)
Output the result sorted by the change in the number of points. \
Output format: peer's nickname, change in the number of peer points

Output example:
| Peer   | PointsChange |
|--------|--------------|
| Aboba  | 8            |
| Amogus | 1            |
| Sus    | -3           |

##### 6) Find the most frequently checked task for each day
If there is the same number of checks for some tasks in a certain day, output all of them. \
Output format: day, task name

Output example:
| Day        | Task |
|------------|------|
| 12.05.2022 | A1   |
| 17.04.2022 | CPP3 |
| 23.12.2021 | C5   |

##### 7) Find all peers who have completed the whole given block of tasks and the completion date of the last task
Procedure parameters: name of the block, for example “CPP”. \
The result is sorted by the date of completion. \
Output format: peer's name, date of completion of the block (i.e. the last completed task from that block)

Output example:
| Peer   | Day        |
|--------|------------|
| Sus    | 23.06.2022 |
| Amogus | 17.05.2022 |
| Aboba  | 12.05.2022 |

##### 8) Determine which peer each student should go to for a check.
You should determine it according to the recommendations of the peer's friends, i.e. you need to find the peer with the greatest number of friends who recommend to be checked by him. \
Output format: peer's nickname, nickname of the checker found

Output example:
| Peer   | RecommendedPeer  |
|--------|-----------------|
| Aboba  | Sus             |
| Amogus | Aboba           |
| Sus    | Aboba           |

##### 9) Determine the percentage of peers who:
- Started only block 1
- Started only block 2
- Started both
- Have not started any of them

A peer is considered to have started a block if he has at least one check of any task from this block (according to the Checks table)

Procedure parameters: name of block 1, for example SQL, name of block 2, for example A. \
Output format: percentage of those who started only the first block, percentage of those who started only the second block, percentage of those who started both blocks, percentage of those who did not started any of them

Output example:
| StartedBlock1 | StartedBlock2 | StartedBothBlocks | DidntStartAnyBlock |
|---------------|---------------|-------------------|--------------------|
| 20            | 20            | 5                 | 55                 |

##### 10) Determine the percentage of peers who have ever successfully passed a check on their birthday
Also determine the percentage of peers who have ever failed a check on their birthday. \
Output format: percentage  of peers who have ever successfully passed a check on their birthday, percentage of peers who have ever failed a check on their birthday

Output example:
| SuccessfulChecks | UnsuccessfulChecks |
|------------------|--------------------|
| 60               | 40                 |

##### 11) Determine all peers who did the given tasks 1 and 2, but did not do task 3
Procedure parameters: names of tasks 1, 2 and 3. \
Output format: list of peers

##### 12) Using recursive common table expression, output the number of preceding tasks for each task
I. e. How many tasks have to be done, based on entry conditions, to get access to the current one. \
Output format: task name, number of preceding tasks

Output example:
| Task | PrevCount |
|------|-----------|
| CPP3 | 7         |
| A1   | 9         |
| C5   | 1         |

##### 13) Find "lucky" days for checks. A day is considered "lucky" if it has at least *N* consecutive successful checks
Parameters of the procedure: the *N* number of consecutive successful checks . \
The time of the check is the start time of the P2P step. \
Successful consecutive checks are the checks with no unsuccessful checks in between. \
The amount of XP for each of these checks must be at least 80% of the maximum. \
Output format: list of days

##### 14) Find the peer with the highest amount of XP
Output format: peer's nickname, amount of XP

Output example:
| Peer   | XP    |
|--------|-------|
| Amogus | 15000 |

##### 15) Determine the peers that came before the given time at least *N* times during the whole time
Procedure parameters: time, *N* number of times . \
Output format: list of peers

##### 16) Determine the peers who left the campus more than *M* times during the last *N* days
Procedure parameters: *N* number of days , *M* number of times . \
Output format: list of peers

##### 17) Determine for each month the percentage of early entries
For each month, count how many times people born in that month came to campus during the whole time (we'll call this the total number of entries). \
For each month, count the number of times people born in that month have come to campus before 12:00 in all time (we'll call this the number of early entries). \
For each month, count the percentage of early entries to campus relative to the total number of entries. \
Output format: month, percentage of early entries

Output example:

| Month    | EarlyEntries |
|----------|--------------|
| January  | 15           |
| February | 35           |
| March    | 45           |

</details>
