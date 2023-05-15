SELECT current_database();

-- создаем 2-х пользователей
CREATE USER bob PASSWORD '12345678';
CREATE USER mike PASSWORD '12345678';

-- открываем новую сессию для Майка:
-- psql -hlocalhost -dtemp_pract -Umike

-- таблица, права на которую есть только у Боба:
CREATE TABLE table4bob
(
    str text
);
GRANT ALL ON TABLE table4bob TO bob;


-- и две функции (пока - по умолчанию - SECURITY INVOKER к тому же владелец - student)
CREATE OR REPLACE FUNCTION f_table4bob()
RETURNS bigint
AS
$$
    SELECT count(*) FROM table4bob;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION f_call4mike()
RETURNS bigint
AS
$$
    SELECT f_table4bob();
$$ LANGUAGE sql;

-- при попытке вызвать в сессии Майка получим ошибку прав доступа
SELECT f_call4mike();
ERROR:  permission denied for table table4bob
CONTEXT:  SQL function "f_table4bob" statement 1

-- переопределим владельца и SECURITY
ALTER FUNCTION f_call4mike() OWNER TO bob;
ALTER FUNCTION f_call4mike() SECURITY DEFINER;

--теперь ОК: 
SELECT f_call4mike();
 f_call4mike 
-------------
           0