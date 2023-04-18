--Свойства метода доступа
select a.amname, p.name, pg_indexam_has_property(a.oid,p.name)
from pg_am a,
unnest(array['can_order','can_unique','can_multi_col','can_exclude']) p(name)
where a.amname = 'btree' order by a.amname;

--Свойства относящиеся к индексу
select p.name, pg_index_has_property('t_a_idx'::regclass,p.name)
from unnest(array['clusterable','index_scan','bitmap_scan','backward_scan']) p(name);

--Наконец, свойства столбцов:
select p.name, pg_index_column_has_property('t_a_idx'::regclass,1,p.name)
from unnest(array['asc','desc','nulls_first','nulls_last','orderable','distance_orderable','returnable','search_array','search_nulls']) p(name);


--Практика
create database fors;

--создаем обычный индекс
create table test as 
select generate_series as id
	, generate_series::text || (random() * 10)::text as col2 
    , (array['Yes', 'No', 'Maybe'])[floor(random() * 3 + 1)] as is_okay
from generate_series(1, 50000);
create index idx_test_id on test(id);

explain
select id from test where id = 1;




-----------------------------------------------------------------
--Уникальный индекс
create table test as 
select generate_series as id
	, generate_series::text || (random() * 10)::text as col2 
    , (array['Yes', 'No', 'Maybe'])[floor(random() * 3 + 1)] as is_okay
from generate_series(1, 50000);
alter table test add constraint uk_test_id unique(id)                                          
--create unique index idx_test_id on test(id);


explain
select * from test where id = 1;
explain
select id from test where id = 1;
insert into test values (null, 12, 'Yes');
insert into test values (null, 12, 'No');
explain
select * from test where id is null;

alter table test drop constraint uk_test_id;
create unique index idx_test_id on test(id);

explain
select * from test where id is null;

explain select id
from test
order by id;
------------------------------------------------------------------

--Составной индекс
create table test as
select generate_series as id
	, generate_series::text || (random() * 10)::text as col2
    , (array['Yes', 'No', 'Maybe'])[floor(random() * 3 + 1)] as is_okay
from generate_series(1, 50000);
create index idx_test_id_is_okay on test(id, is_okay);


explain
select * from test where id = 1 and is_okay = 'True';
explain
select * from test where id = 1;
explain
select * from test where is_okay = 'True';
explain
select * from test order by id, is_okay;
explain
select * from test order by id desc , is_okay desc;
SET enable_incremental_sort = on;
explain
select * from test order by id , is_okay desc ;

drop table test;

---------------------------------------------------------------------
--индекс на функцию (кол-во данных)
create table test as 
select generate_series as id
	, generate_series::text || (random() * 10)::text as col2 
    , (array['Yes', 'No', 'Maybe'])[floor(random() * 3 + 1)] as is_okay
from generate_series(1, 50000);
create index idx_test_id_is_okay on test(lower(is_okay)); 

explain
select * from test where is_okay = 'True';
explain
select * from test where lower(is_okay) = 'True';

--Частичный индекс
create table test as 
select generate_series as id
	, generate_series::text || (random() * 10)::text as col2 
    , (array['Yes', 'No', 'Maybe'])[floor(random() * 3 + 1)] as is_okay
from generate_series(1, 50000);
create index idx_test_id_100 on test(id) where id < 100;        

explain
select * from test where id < 50;

------------------------------------------------------------------------
--Размер таблиц вместе с индексами
SELECT
    TABLE_NAME,
    pg_size_pretty(table_size) AS table_size,
    pg_size_pretty(indexes_size) AS indexes_size,
    pg_size_pretty(total_size) AS total_size
FROM (
    SELECT
        TABLE_NAME,
        pg_table_size(TABLE_NAME) AS table_size,
        pg_indexes_size(TABLE_NAME) AS indexes_size,
        pg_total_relation_size(TABLE_NAME) AS total_size
    FROM (
        SELECT ('"' || table_schema || '"."' || TABLE_NAME || '"') AS TABLE_NAME
        FROM information_schema.tables
    ) AS all_tables
    ORDER BY total_size DESC

    ) AS pretty_sizes;

---see defenition index
SELECT
    tablename,
    indexname,
    indexdef
FROM
    pg_indexes
WHERE
    schemaname = 'public'
ORDER BY
    tablename,
    indexname;

--Неиспользуемые индексы
SELECT s.schemaname,
       s.relname AS tablename,
       s.indexrelname AS indexname,
       pg_size_pretty(pg_relation_size(s.indexrelid)) AS index_size,
       s.idx_scan
FROM pg_catalog.pg_stat_user_indexes s
   JOIN pg_catalog.pg_index i ON s.indexrelid = i.indexrelid
WHERE s.idx_scan < 10      -- has never been scanned
  AND 0 <>ALL (i.indkey)  -- no index column is an expression
  AND NOT i.indisunique   -- is not a UNIQUE index
  AND NOT EXISTS          -- does not enforce a constraint
         (SELECT 1 FROM pg_catalog.pg_constraint c
          WHERE c.conindid = s.indexrelid)
ORDER BY pg_relation_size(s.indexrelid) DESC;

--Дублирующие индексы
SELECT pg_size_pretty(SUM(pg_relation_size(idx))::BIGINT) AS SIZE, (array_agg(idx))[1] AS idx1,
(array_agg(idx))[2] AS idx2,
(array_agg(idx))[3] AS idx3,
(array_agg(idx))[4] AS idx4
FROM ( SELECT indexrelid::regclass AS idx,
     (indrelid::text ||E'\n'|| indclass::text ||E'\n'||
      indkey::text ||E'\n'|| COALESCE(indexprs::text,'')||E'\n' ||        COALESCE(indpred::text,'')) AS KEY 
     FROM pg_index) sub
GROUP BY KEY
HAVING COUNT(*)>1
ORDER BY SUM(pg_relation_size(idx)) DESC;

-------------------------------------------------------------------
--Практика

create table orders (
    id int,
    user_id int,
    order_date date,
    status text,
    some_text text
);

insert into dbt.orders(id, user_id, order_date, status, some_text)
select generate_series, (random() * 70), date'2019-01-01' + (random() * 300)::int as order_date
        , (array['returned', 'completed', 'placed', 'shipped'])[(random() * 4)::int]
        , concat_ws(' ', (array['go', 'space', 'sun', 'London'])[(random() * 5)::int]
            , (array['the', 'capital', 'of', 'Great', 'Britain'])[(random() * 6)::int]
            , (array['some', 'another', 'example', 'with', 'words'])[(random() * 6)::int]
            )
from generate_series(100001, 1000000);

select *
from dbt.orders
where id < 100;

create index idx_ord_id on dbt.orders(id);

select pg_size_pretty(pg_table_size('orders'));
select pg_size_pretty(pg_table_size('idx_ord_id')); --21 MB
explain
select *
from dbt.orders
where id < 500000;

explain
select *
from dbt.orders
order by id;

explain
select *
from dbt.orders
order by id desc;


drop index if exists idx_ord_order_Date;
create index idx_ord_order_Date on orders(order_date);
explain
select *
from orders
where order_date between date'2020-01-01' and date'2020-02-01';

drop index if exists idx_ord_order_date_inc_status;
create index idx_ord_order_date_inc_status on orders(order_date) include (status);

explain
select order_date, status
from orders
where order_date between date'2020-01-01' and date'2020-02-01';

explain
select order_date, status
from orders
where order_date between date'2020-01-01' and date'2020-02-01'
        and status = 'placed';

explain
select * from orders where some_text ilike 'a%';

drop index if exists idx_order_some_text;
create index idx_order_some_text on orders(order_date);



select some_text, to_tsvector(some_text)
from orders;

select some_text, to_tsvector(some_text) @@ to_tsquery('britains')
from orders;

select some_text, to_tsvector(some_text) @@ to_tsquery('london & capital')
from orders;

select some_text, to_tsvector(some_text) @@ to_tsquery('london | capital')
from orders;

alter table orders drop column if exists some_text_lexeme;
alter table orders add column some_text_lexeme tsvector;
update orders
set some_text_lexeme = to_tsvector(some_text);
explain
select some_text
from orders
where some_text_lexeme @@ to_tsquery('britains');

drop index if exists search_index_ord;
CREATE INDEX search_index_ord ON orders USING GIN (some_text_lexeme);

explain
select *
from orders
where some_text_lexeme @@ to_tsquery('britains');




drop index if exists idx_ord_order_date_status;
create index idx_ord_order_date_status on orders(order_date, status);

explain
select order_date, status
from orders
where order_date between date'2020-01-01' and date'2020-02-01';





--Кластеризация
drop table if exists orders;

create table orders (
    id int,
    user_id int,
    order_date date,
    status text,
    some_text text
);
insert into orders(id, user_id, order_date, status, some_text)
select generate_series, (random() * 70), date'2019-01-01' + (random() * 300)::int as order_date
        , (array['returned', 'completed', 'placed', 'shipped'])[(random() * 4)::int]
        , concat_ws(' ', (array['go', 'space', 'sun', 'London'])[(random() * 5)::int]
            , (array['the', 'capital', 'of', 'Great', 'Britain'])[(random() * 6)::int]
            , (array['some', 'another', 'example', 'with', 'words'])[(random() * 6)::int]
            )
from generate_series(1, 1000000);

select * from orders;

SET work_mem = '64MB';
explain
select * from orders where order_date = '2019-04-26';
create index order_date_idx on orders(order_date);
cluster orders using order_date_idx;
analyse orders;
