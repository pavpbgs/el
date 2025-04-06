--общая логика запроса: начинаем с таблицы users, смотрим на схему БД - db_schema.jpg и присоединяем нужные нам таблицы, имея в виду условия задачи 
SELECT
-- выбираем нужные нам столбцы из соединенных таблиц
    c.id AS course_id, --ID курса
    c.name AS course_name, --Название курса
    s.name AS subject_name, --Предмет
    s.project AS subject_type, --Тип предмета
    ct.name AS course_type, --Тип курса
    c.starts_at AS course_start_date, --Дата старта курса
    u.id AS user_id, -- ID ученика
    u.last_name AS user_last_name, --Фамилия ученика
    cities.name AS city_name, --Город ученика
    active, --Ученик не отчислен с курса
    cu.created_at AS course_opened_date, --Дата открытия курса ученику
    --т. к. удобнее нельзя получить кол-во открытых месяцев ученика, рассчитываем это поле следующим образом
    --делим кол-во открытых занятий ученика на кол-во занятий за месяц в курсе, и округляем полученное число вниз.
    --например, кол-во занятий за месяц в курсе - 10. кол-во открытых занятий у ученика - 36. 36/10 = 3,6.
    --округляем вниз - 3. действительно, у ученика открыто 3 полных месяца. отдельно обрабатываем случаи с 0 и null
    CASE
        WHEN COALESCE(lessons_in_month, 0) = 0 THEN 0
        WHEN COALESCE(available_lessons, 0) = 0 THEN 0
        ELSE FLOOR(available_lessons/lessons_in_month)
    END AS months_of_course_open,
    COALESCE(homeworks_done, 0) AS homeworks_done --Число сданных ДЗ ученика на курсе (null преобразуем в 0)
FROM
    users AS u
--INNER JOIN users и course_users, т. к. по условию нужны ученики с курсов
--т. е. те ученики, которые есть не только в users, но и course_users (причем учениками считаются в т. ч. числе отчисленные - они тоже были учениками)
INNER JOIN
    course_users cu
ON
    u.id = cu.user_id
--LEFT JOIN информацию о городах. здесь и далее делаем LEFT JOIN, потому что хотим оставить всю информацию users и course_users, и лишь по возможности добавить данные из других таблиц
LEFT JOIN
    cities
ON
    u.city_id = cities.id
--LEFT JOIN информацию о курсах
LEFT JOIN
    courses AS c
ON 
    cu.course_id = c.id
--LEFT JOIN информацию о типах курсов
LEFT JOIN
    course_types AS ct
ON 
    c.course_type_id = ct.id
--LEFT JOIN информацию о предметах
LEFT JOIN
    subjects AS s
ON 
    c.subject_id = s.id
--LEFT JOIN подзапроса с данными о числе сданных ДЗ учеников
LEFT JOIN
    (
        --берем данные homework_done, группируем по ученику (user_id), считаем количество строк (соотв. количество сданных ДЗ)
        SELECT
            user_id,
            COUNT(homework_id) AS homeworks_done
        FROM
            homework_done
        GROUP BY
            user_id
    ) AS hd
ON 
    u.id = hd.user_id
--по условию, нужны не просто ученики с курсов, но ученики с годовых курсов. годовой тип курсов - это "Годовой" и "Годовой 2.0", фильтруем по их id
WHERE 
    ct.id IN (1, 6)
    AND
--по условию, нужны не просто ученики с годовых курсов, но ученики с годовых курсов ЕГЭ и ОГЭ. тип предмета находится в поле project. фильтруем по тому, чтобы project был или ЕГЭ, или ОГЭ
    s.project IN ('ЕГЭ', 'ОГЭ')