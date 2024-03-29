1. Создаем вм и ставим постгрес.  
```
------------ Ставим Postgresql
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' \
&& wget -qO- https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo tee /etc/apt/trusted.gpg.d/pgdg.asc &>/dev/null \
&& sudo apt update \
&& sudo apt install postgresql postgresql-client -y \
&& systemctl status postgresql
```
2. Создаем бд для тестирования индексов, таблицу в ней и обычный индекс.  
```
--создаем обычный индекс
create table test as 
select generate_series as id
	, generate_series::text || (random() * 10)::text as col2 
    , (array['Yes', 'No', 'Maybe'])[floor(random() * 3 + 1)] as is_okay
from generate_series(1, 50000);

explain
select id from test where id = 1;
                       QUERY PLAN                       
--------------------------------------------------------
 Seq Scan on test  (cost=0.00..789.94 rows=163 width=4)
   Filter: (id = 1)
(2 rows)

create index idx_test_id on test(id);

explain
select id from test where id = 1;
                               QUERY PLAN                                  
-----------------------------------------------------------------------------
 Index Only Scan using idx_test_id on test  (cost=0.29..4.31 rows=1 width=4)
   Index Cond: (id = 1)
(2 rows)
```
Видим, что после создания индекса план улучшился.

3. Индекс на часть таблицы.  
```
create index idx_test_id_less_100 on test(id) where id < 100;   
explain
select * from test where id < 50;
                                QUERY PLAN                                
--------------------------------------------------------------------------
 Index Scan using idx_test_id on test  (cost=0.29..9.16 rows=50 width=31)
   Index Cond: (id < 50)
```  

4. Индекс на поле с функцией.  
```
create index idx_test_id_is_okay on test(lower(is_okay)); 
explain
select * from test where lower(is_okay) = 'true';
                                     QUERY PLAN                                     
------------------------------------------------------------------------------------
 Bitmap Heap Scan on test  (cost=6.23..367.67 rows=250 width=31)
   Recheck Cond: (lower(is_okay) = 'true'::text)
   ->  Bitmap Index Scan on idx_test_id_is_okay  (cost=0.00..6.17 rows=250 width=0)
         Index Cond: (lower(is_okay) = 'true'::text)
``` 

5. Составной индекс.
```
create index idx_test_id_is_okay on test(id, is_okay);
explain
select * from test where id = 1 and is_okay = 'True';
                                    QUERY PLAN                                    
----------------------------------------------------------------------------------
 Index Scan using idx_test_id_less_100 on test  (cost=0.14..8.16 rows=1 width=31)
   Index Cond: (id = 1)
   Filter: (is_okay = 'True'::text)

explain
select * from test where id = 1;
                                    QUERY PLAN                                    
----------------------------------------------------------------------------------
 Index Scan using idx_test_id_less_100 on test  (cost=0.14..8.16 rows=1 width=31)
   Index Cond: (id = 1)

explain
select * from test where is_okay = 'True';
                       QUERY PLAN                       
--------------------------------------------------------
 Seq Scan on test  (cost=0.00..1008.00 rows=1 width=31)
   Filter: (is_okay = 'True'::text)
(2 rows)
```
Как видим индекс используетя, если мы запрашиваем данные по 2-м полям или по первому. При запросе только по второву и последующим полям индекс использоваться не будет.

6. Индекс для полнотекстного поиска.
Создадим таблицу заказов и заполним ее данными.
```
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
from generate_series(100001, 1000000);
```
Нам нужна дополительная колонка, в которой текстовые данные преобразованы в тип tsvector. В нем данные представлены в виде отсортированного списка неповторяющихся лексем.
Создаем эту колонку и индекс для полнотекстового поиска.
```
alter table orders add column some_text_lexeme tsvector;
update orders 
   set some_text_lexeme = to_tsvector(some_text);

CREATE INDEX search_index_ord ON orders USING GIN (some_text_lexeme);
analyse orders;
explain
select some_text
from orders
where some_text_lexeme @@ to_tsquery('britains');
                                         QUERY PLAN                                          
---------------------------------------------------------------------------------------------
 Gather  (cost=2381.40..51277.18 rows=149310 width=14)
   Workers Planned: 2
   ->  Parallel Bitmap Heap Scan on orders  (cost=1381.40..35346.18 rows=62212 width=14)
         Recheck Cond: (some_text_lexeme @@ to_tsquery('britains'::text))
         ->  Bitmap Index Scan on search_index_ord  (cost=0.00..1344.08 rows=149310 width=0)
               Index Cond: (some_text_lexeme @@ to_tsquery('britains'::text))
```

