create database otus;

--progress create index
SELECT
  now()::TIME(0),
  a.query,
  p.phase,
  round(p.blocks_done / p.blocks_total::numeric * 100, 2) AS "% done",
  p.blocks_total,
  p.blocks_done,
  p.tuples_total,
  p.tuples_done,
  ai.schemaname,
  ai.relname,
  ai.indexrelname
FROM pg_stat_progress_create_index p
JOIN pg_stat_activity a ON p.pid = a.pid
LEFT JOIN pg_stat_all_indexes ai on ai.relid = p.relid AND ai.indexrelid = p.index_relid;

-----вычсиление cost-----
drop table test;
create table test as
select generate_series as id
	, generate_series::text || (random() * 10)::text as col2
    , (array['Yes', 'No', 'Maybe'])[floor(random() * 3 + 1)] as is_okay
from generate_series(1, 50000);
select * from test;

analyse test;


explain (buffers,analyse)
select *
from test;

--(число_чтений_диска * seq_page_cost) + (число_просканированных_строк * cpu_tuple_cost)
show seq_page_cost;
show cpu_tuple_cost;
--(382*1)+(50000*0,01)



set seq_page_cost=2;
reset all;


--Nested loop и товарищи--------------------------------
select * from pg_class;
select * from pg_attribute;

analyse pg_class;
analyse pg_attribute;

--nested loop в зависимости от настроек (analyse гляунть что планировщик ошибается)
set enable_seqscan='on';

explain analyse
select *
    from pg_class c
        join pg_attribute a on c.oid = a.attrelid  where c.relname in ( 'pg_class', 'pg_namespace','pg_config','pg_statistic');

    Nested Loop  (cost=0.28..92.43 rows=30 width=505) (actual time=0.105..0.508 rows=88 loops=1)
    Nested Loop  (cost=13.40..94.88 rows=30 width=505) (actual time=0.044..0.115 rows=88 loops=1);


show shared_buffers ;
--Смотрим как меняется использование памяти
explain analyse
select a.attrelid
    from pg_class c
        join pg_attribute a on c.oid = a.attrelid;

explain analyse
select *
    from pg_class c
        join pg_attribute a on c.oid = a.attrelid ;


--Использование темповых файлов
SET work_mem = '64kB';
reset work_mem;
SET enable_hashjoin = on;
SET enable_mergejoin = off;
SET enable_nestloop = off
;
SET log_temp_files = 0;
explain (analyse,buffers)
select *
    from pg_class c
        join pg_attribute a on c.oid = a.attrelid ;
reset work_mem;
reset log_temp_files;
SET enable_hashjoin = on;
SET enable_mergejoin = on;
SET enable_nestloop = on;

create database "join_lessons";

--Непосредствеено соединения

create table bus (id serial,route text,id_model int);
create table model_bus (id serial,name text);;
insert into bus values (1,'Москва-Болшево',1),(2,'Москва-Пушкино',1),(3,'Москва-Ярославль',2),(4,'Москва-Кострома',2),(5,'Москва-Волгорад',3),
                       (6,'Москва-Иваново',null),(7,'Москва-Саратов',null),(8,'Москва-Воронеж',null);
insert into model_bus values(1,'ПАЗ'),(2,'ЛИАЗ'),(3,'MAN'),(4,'МАЗ'),(5,'НЕФАЗ'),(6,'ЗиС'),(7,'Икарус');


select * from bus;
select * from model_bus;
analyse bus;
analyse model_bus;

-- Прямое соединениие
explain
select *
from bus b
join model_bus mb
    on b.id_model=mb.id;

explain
select *
from bus b,model_bus mb
where b.id_model=mb.id;

--left join
explain
select *
from bus b
left join model_bus mb
    on b.id_model=mb.id;

--right join
explain
select *
from bus b
right join model_bus mb
    on b.id_model=mb.id;

--left with null
explain
select *
from bus b
left join model_bus mb on b.id_model=mb.id
where mb.id is null;

--right with null
select *
from bus b
right join model_bus mb on b.id_model=mb.id
where b.id
    is null;


--full join
select *
from bus b
full join model_bus mb on b.id_model=mb.id;

select *
from bus b
full join model_bus mb on b.id_model=mb.id
where b.id is null or mb.id is null;


--cross join
explain
select *
from bus b
cross join model_bus mb;

explain --(join)
select *
from bus b
cross join model_bus mb
where  b.id_model=mb.id;

select *
from bus b,model_bus mb
where 1=1;

----test
create table a (id integer);
create table b (id integer);

insert into a values (1),(1),(1),(1),(1),(1),(1),(1),(1),(1);
insert into b values (1),(1),(1),(1),(1),(1),(1),(1),(1),(1);

insert into a values (1),(2),(3),(4),(5),(6),(7),(8),(9),(10);
insert into b values (1),(2),(3),(4),(5),(6),(7),(8),(9),(10);

select *
from a
    join b on a.id=b.id;

drop table a;
drop table b;


--lateral join

drop table t_product;
CREATE TABLE t_product AS
    SELECT   id AS product_id,
             id * 10 * random() AS price,
             'product ' || id AS product
    FROM generate_series(1, 1000) AS id;

drop table t_wishlist;
CREATE TABLE t_wishlist
(
    wishlist_id        int,
    username           text,
    desired_price      numeric
);

INSERT INTO t_wishlist VALUES
    (1, 'hans', '450'),
    (2, 'joe', '60'),
    (3, 'jane', '1500');

SELECT * FROM t_product LIMIT 10;
SELECT * FROM t_wishlist;

explain
SELECT        *
FROM      t_wishlist AS w
    left join LATERAL  (SELECT      *
        FROM       t_product AS p
        WHERE       p.price < w.desired_price
        ORDER BY p.price DESC
        LIMIT 10
       ) AS x
on true
ORDER BY wishlist_id, price DESC;

explain
SELECT        *
FROM      t_wishlist AS w,
    LATERAL  (SELECT      *
        FROM       t_product AS p
        WHERE       p.price < w.desired_price
        ORDER BY p.price DESC
        LIMIT 5
       ) AS x
ORDER BY wishlist_id, price DESC;


---Пример lateral join  с погодой
drop table if exists temperature;
drop table if exists humidity;

CREATE TABLE temperature(
  ts TIMESTAMP NOT NULL,
  city TEXT NOT NULL,
  temperature INT NOT NULL);

CREATE TABLE humidity(
  ts TIMESTAMP NOT NULL,
  city TEXT NOT NULL,
  humidity INT NOT NULL);

INSERT INTO temperature (ts, city, temperature)
SELECT ts + (INTERVAL '60 minutes' * random()), city, 30*random()
FROM generate_series('2022-01-01' :: TIMESTAMP,
                     '2022-01-31', '1 day') AS ts,
     unnest(array['Moscow', 'Berlin','Volgograd']) AS city;

INSERT INTO humidity (ts, city, humidity)
SELECT ts + (INTERVAL '60 minutes' * random()), city, 100*random()
FROM generate_series('2022-01-01' :: TIMESTAMP,
                     '2022-01-31', '1 day') AS ts,
     unnest(array['Moscow', 'Berlin','Volgograd']) AS city;

select * from temperature;
select * from humidity;

SELECT t.ts, t.city, t.temperature, h.humidity
FROM temperature AS t
LEFT JOIN humidity AS h ON t.ts = h.ts;

SELECT t.ts, t.city, t.temperature, h.humidity
FROM temperature AS t
LEFT JOIN LATERAL
  ( SELECT * FROM humidity
    WHERE city = t.city AND ts <= t.ts
    ORDER BY ts DESC LIMIT 1
  ) AS h ON TRUE
WHERE t.ts < '2022-01-10';

SELECT * FROM temperature WHERE ts < '2022-01-05' ORDER BY ts, city;
SELECT * FROM humidity WHERE ts < '2022-01-05' ORDER BY ts, city;


--Порядок join (параметры планировщика)
drop table test_1000;
CREATE TABLE test_1000 AS
    SELECT    (random()*100)::int AS id,
             'product ' || id AS product
    FROM generate_series(1, 10000) AS id;

select * from test_1000;

drop table test_1;
create table test_1 (id int);
insert into test_1 values (1);

select * from test_1;

SET enable_hashjoin = off;
SET enable_mergejoin = off;
SET enable_nestloop = on;


set join_collapse_limit to 8;    set join_collapse_limit to 1;

explain
select *
from test_1 t1
inner join test_1000 t1000
on t1000.id=t1.id
inner join test_1 t1_2
on t1_2.id=t1000.id;

--Union intersect except

DROP TABLE IF EXISTS top_rated_films;
CREATE TABLE top_rated_films(
	title VARCHAR NOT NULL,
	release_year SMALLINT
);

DROP TABLE IF EXISTS most_popular_films;
CREATE TABLE most_popular_films(
	title VARCHAR NOT NULL,
	release_year SMALLINT
);

INSERT INTO
   top_rated_films(title,release_year)
VALUES
   ('The Shawshank Redemption',1994),
   ('The Godfather',1972),
   ('12 Angry Men',1957);

INSERT INTO
   most_popular_films(title,release_year)
VALUES
   ('An American Pickle',2020),
   ('The Godfather',1972),
   ('Greyhound',2020);

SELECT * FROM top_rated_films;
select * from most_popular_films;

SELECT * FROM top_rated_films
UNION
SELECT * FROM most_popular_films;

SELECT * FROM top_rated_films
UNION all
SELECT * FROM most_popular_films;

SELECT * FROM top_rated_films
INTERSECT
SELECT * FROM most_popular_films;

SELECT * FROM top_rated_films
EXCEPT
SELECT * FROM most_popular_films;


SELECT * FROM  most_popular_films
EXCEPT
SELECT * FROM top_rated_films;


